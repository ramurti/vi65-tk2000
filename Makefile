# VI65 for the TK2000: the Apple II hi-res target (56 columns) with the TK2000 keyboard
VI65 = $(wildcard vi65/*.asm) vi65/font5x8.fnt vi65/latin1.fnt

all: build/vi65.ct2

# the accented letters, made from font5x8.fnt
vi65/latin1.fnt: vi65/font5x8.fnt tools/accents.py
	python3 tools/accents.py

build/vi65.bin: $(VI65)
	64tass -b -B -C vi65/a.asm -o $@ -DTARGET=2 -DGFX=2 -DTK=1 -L build/vi65.lst --labels=build/vi65.lbl -q

build/vi65.ct2: build/vi65.bin tools/mkct2.py
	python3 tools/mkct2.py build/vi65.bin 0x4000 0x4000 VI65 $@

build/run: tools/harness/run.cpp
	EMU=$${EMU:-$$HOME/pessoal/tk2000/src}; c++ -std=c++17 -O2 -w -I$$EMU $$(sdl2-config --cflags) \
	  -include $$EMU/pch.h $< $$EMU/{Bus,Cpu6502,Rom,Ram,Video,Audio,Keyboard,Tape,Disk}.cpp \
	  $$(sdl2-config --libs) -o $@

.PHONY: all

# dist/vi65.wav is for a real TK2000 (play it into the cassette input); it stays local
dist: build/vi65.ct2
	cp build/vi65.ct2 dist/
	python3 tools/ct2wav.py dist/vi65.ct2 dist/vi65.wav

.PHONY: dist
