// Headless TK2000 runner for testing: loads a .ct2 with LOADT, holds keys, takes screenshots
// and dumps memory, all in emulated time.
//
// run TAPE.ct2|DISK.dsk (booted with CALL 49408; times from then) [-t SECONDS] [-s TIME:FILE.ppm]... [-k TIME:DURATION:KEY]... [-m ADDR:LEN]...
//     [-a TIME:DURATION:FILE.wav] [-w TIME:ADDR:HEXBYTES] [-T TIME:TEXT] [-r FILE.ct2] [-i TIME:FILE.ct2]
//   times in emulated seconds counted from Play; KEY = left right up down space return ctrl or a letter, S-KEY with SHIFT;
//   -T types TEXT (letters as plain keys, \n = RETURN) with the emulator's typing queue;
//   -a records the emulator's audio output (CAudio's samples, as the SDL player gets them);
//   -r appends what the program writes to tape to FILE.ct2; -i inserts FILE.ct2 at TIME and plays it
#include "pch.h"
#include "Bus.h"
#define private public                 // the CPU's registers, printed with the memory dumps
#include "Cpu6502.h"
#undef private
#include "Rom.h"
#include "Ram.h"
#include "Video.h"
#include "Audio.h"
#include "Keyboard.h"
#include "Tape.h"
#include "Disk.h"

// CRam keeps its memory private (friend CMachine); it is the first member after the vtable
struct SRamLayout { void* vtable; byte ram[0x10000]; };
static_assert(sizeof(CRam) == sizeof(SRamLayout), "CRam layout changed");

CBus bus;
CCpu6502 cpu{ bus };
CRam ramDev{ bus };
byte* ram = reinterpret_cast<SRamLayout*>(&ramDev)->ram;
CRom rom{ bus, ram };
CVideo video{ bus, ram };
CAudio audio{ bus, cpu };
CKeyboard kb{ bus };
CTape tape{ bus, cpu };
CDisk disk{ bus, rom };

static double now = 0;		// emulated seconds since Play

// the audio output between two times, written as a WAV (mono, 16 bit)
struct SWavRec : CObserver<sAudioMsg> {
	double from = -1, to = -1;
	std::string file;
	std::vector<int16_t> samples;
	void notify(sAudioMsg& m) override {
		if (from >= 0 && now >= from && now < to) {
			samples.insert(samples.end(), m.bufferPtr, m.bufferPtr + m.count);
		}
	}
	void write(int rate) {
		FILE* f = fopen(file.c_str(), "wb");
		uint32_t data = (uint32_t)samples.size() * 2, riff = 36 + data, fmt = 16, r = rate, br = rate * 2;
		uint16_t pcm = 1, ch = 1, align = 2, bits = 16;
		fwrite("RIFF", 1, 4, f); fwrite(&riff, 4, 1, f); fwrite("WAVEfmt ", 1, 8, f);
		fwrite(&fmt, 4, 1, f); fwrite(&pcm, 2, 1, f); fwrite(&ch, 2, 1, f); fwrite(&r, 4, 1, f);
		fwrite(&br, 4, 1, f); fwrite(&align, 2, 1, f); fwrite(&bits, 2, 1, f);
		fwrite("data", 1, 4, f); fwrite(&data, 4, 1, f);
		fwrite(samples.data(), 2, samples.size(), f);
		fclose(f);
	}
} wavRec;

static void run(double secs) {
	const uint64_t chunk = (uint64_t)(CPU_CLOCK * MS_TO_RUN / 1000.0);
	const uint64_t end = cpu.getCumulativeCycles() + (uint64_t)(secs * CPU_CLOCK);
	while (cpu.getCumulativeCycles() < end) {
		const uint64_t s = cpu.getCumulativeCycles();
		while (cpu.getCumulativeCycles() - s < chunk) {
			cpu.executeOpcode();
		}
		bus.updateAll(cpu.getCumulativeCycles());
	}
}

static void shot(const std::string& file) {
	SRGB* fb = video.getFrameBuffer();
	FILE* f = fopen(file.c_str(), "wb");
	fprintf(f, "P6 %d %d 255\n", VIDEOWIDTH, VIDEOHEIGHT);
	fwrite(fb, 3, VIDEOWIDTH * VIDEOHEIGHT, f);
	fclose(f);
}

static SDL_Keycode keyCode(const std::string& name) {
	if (name == "left") return SDLK_LEFT;
	if (name == "right") return SDLK_RIGHT;
	if (name == "up") return SDLK_UP;
	if (name == "down") return SDLK_DOWN;
	if (name == "space") return SDLK_SPACE;
	if (name == "return") return SDLK_RETURN;
	if (name == "fire") return SDLK_PERIOD;
	if (name == "ctrl") return SDLK_LCTRL;
	return (SDL_Keycode)tolower(name[0]);
}

static void key(SDL_Keycode code, bool down, bool shift) {
	SDL_KeyboardEvent e{};
	e.keysym.sym = code;
	e.keysym.mod = shift ? KMOD_LSHIFT : KMOD_NONE;
	e.state = down ? SDL_PRESSED : SDL_RELEASED;
	kb.keyEvent(e);
}

static void dump(const std::vector<std::pair<int, int>>& mems) {
	if (!mems.empty()) {
		printf("  PC=%04X S=%02X A=%02X X=%02X Y=%02X\n", cpu.mRegPC.value, cpu.mRegS, cpu.mRegA, cpu.mRegX, cpu.mRegY);
	}
	for (auto& [addr, len] : mems) {
		printf("  [%04X]", addr);
		for (int i = 0; i < len; i++) {
			printf(" %02X", ram[(addr + i) & 0xFFFF]);
		}
		printf("\n");
	}
}

struct SEvent { double t; int kind; std::string arg; SDL_Keycode code; };	// kind: 0 shot, 1 key down, 2 key up, 3 poke, 4 type, 5 tape

int main(int argc, char** argv) {
	if (argc < 2) {
		fprintf(stderr, "usage: run TAPE.ct2 [-t SECONDS] [-s TIME:FILE.ppm] [-k TIME:DURATION:KEY] [-m ADDR:LEN]"
			" [-a TIME:DURATION:FILE.wav] [-w TIME:ADDR:HEXBYTES]\n");
		return 2;
	}
	double total = 30;
	std::vector<SEvent> events;
	std::vector<std::pair<int, int>> mems;
	for (int i = 2; i + 1 < argc; i += 2) {
		std::string opt = argv[i], val = argv[i + 1];
		if (opt == "-t") {
			total = atof(val.c_str());
		} else if (opt == "-s") {
			auto c = val.find(':');
			events.push_back({ atof(val.substr(0, c).c_str()), 0, val.substr(c + 1), 0 });
		} else if (opt == "-k") {
			auto c1 = val.find(':'), c2 = val.find(':', c1 + 1);
			double t = atof(val.substr(0, c1).c_str()), d = atof(val.substr(c1 + 1, c2 - c1 - 1).c_str());
			std::string name = val.substr(c2 + 1), sh = name.rfind("S-", 0) == 0 && name.size() > 2 ? "S" : "";
			SDL_Keycode k = keyCode(sh.empty() ? name : name.substr(2));
			events.push_back({ t, 1, sh, k });
			events.push_back({ t + d, 2, sh, k });
		} else if (opt == "-a") {
			auto c1 = val.find(':'), c2 = val.find(':', c1 + 1);
			wavRec.from = atof(val.substr(0, c1).c_str());
			wavRec.to = wavRec.from + atof(val.substr(c1 + 1, c2 - c1 - 1).c_str());
			wavRec.file = val.substr(c2 + 1);
			audio.attach(&wavRec);
		} else if (opt == "-w") {
			auto c = val.find(':');
			events.push_back({ atof(val.substr(0, c).c_str()), 3, val.substr(c + 1), 0 });
		} else if (opt == "-T") {
			auto c = val.find(':');
			std::string text;
			for (size_t k = c + 1; k < val.size(); k++) {
				if (val[k] == '\\' && k + 1 < val.size() && val[k + 1] == 'n') { text += '\n'; k++; } else { text += val[k]; }
			}
			events.push_back({ atof(val.substr(0, c).c_str()), 4, text, 0 });
		} else if (opt == "-r") {
			tape.setRecordFile(val);
		} else if (opt == "-i") {
			auto c = val.find(':');
			events.push_back({ atof(val.substr(0, c).c_str()), 5, val.substr(c + 1), 0 });
		} else if (opt == "-m") {
			auto c = val.find(':');
			mems.push_back({ (int)strtol(val.substr(0, c).c_str(), nullptr, 16), atoi(val.substr(c + 1).c_str()) });
		}
	}
	std::sort(events.begin(), events.end(), [](auto& a, auto& b) { return a.t < b.t; });

	bus.resetAll();
	cpu.reset();
	run(3.0);
	const std::string media = argv[1];
	const bool isDisk = media.size() > 4 && media.substr(media.size() - 4) == ".dsk";
	if (isDisk ? !disk.insert(argv[1]) : !tape.insertCt2(argv[1])) {
		fprintf(stderr, "cannot read %s\n", argv[1]);
		return 1;
	}
	kb.typeText(isDisk ? "CALL 49408\n" : "LOADT\n");
	while (kb.isTyping()) {
		run(0.1);
	}
	if (!isDisk) {
		tape.play();
	}
	bool tapeEnded = isDisk;
	size_t next = 0;
	const double step = MS_TO_RUN / 1000.0;
	while (true) {
		while (next < events.size() && events[next].t <= now + 1e-9) {
			auto& e = events[next++];
			if (e.kind == 0) {
				shot(e.arg);
				printf("t=%.1f shot %s\n", now, e.arg.c_str());
				dump(mems);
			} else if (e.kind == 3) {			// ADDR:HEXBYTES written into the RAM
				auto c = e.arg.find(':');
				int a = (int)strtol(e.arg.substr(0, c).c_str(), nullptr, 16);
				for (size_t k = c + 1; k + 1 < e.arg.size() + 1 && k + 2 <= e.arg.size(); k += 2) {
					ram[a++] = (byte)strtol(e.arg.substr(k, 2).c_str(), nullptr, 16);
				}
			} else if (e.kind == 4) {
				kb.typeText(e.arg);
			} else if (e.kind == 5) {
				if (!tape.insertCt2(e.arg.c_str())) {
					fprintf(stderr, "cannot read %s\n", e.arg.c_str());
				}
				tape.play();
				printf("t=%.1f tape %s\n", now, e.arg.c_str());
			} else {
				key(e.code, e.kind == 1, e.arg == "S");
			}
		}
		if (now >= total - 1e-9) {
			break;
		}
		run(step);
		now += step;
		if (!tapeEnded && !tape.getPlayState()) {
			tapeEnded = true;
			printf("t=%.1f tape stopped\n", now);
		}
	}
	printf("t=%.1f end\n", now);
	if (tape.getRecordedBlocks()) {
		printf("recorded: %u blocks -> %s\n", tape.getRecordedBlocks(), tape.getRecordFile().c_str());
	}
	if (wavRec.from >= 0) {
		wavRec.write(audio.getSampleRate());
		printf("audio: %zu samples -> %s\n", wavRec.samples.size(), wavRec.file.c_str());
	}
	dump(mems);
	return 0;
}
