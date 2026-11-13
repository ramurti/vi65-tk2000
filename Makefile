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

# dist/vi65.wav is for a real TK2000 (play it into the cassette input; local, too big for git);
# dist/vi65.dsk is the TKDOS master disk (MASTER) without its demo programs, with VI65 (BRUN VI65)
# and The Art of War in Portuguese, a file per chapter (samples/guerra*.txt, :e guerra1)
MASTER ?= $(HOME)/pessoal/tkdos2000.dsk
DEMOS = RENUMERADOR "RENUMERADOR INSTRUCOES" RENUM.INSTR "LISTA TELEFONICA" LISTATEL \
	"CRIA TEXTO" "LE TEXTO" "DEMO CORES" OTHELLO
BOOK = 1 2 3 4 5 6 7 8 9 10 11a 11b 12 13

dist: build/vi65.ct2 tools/mkdsk.py $(BOOK:%=samples/guerra%.txt)
	cp build/vi65.ct2 dist/
	python3 tools/ct2wav.py dist/vi65.ct2 dist/vi65.wav
	cp $(MASTER) dist/vi65.dsk
	python3 tools/mkdsk.py dist/vi65.dsk --delete $(DEMOS)
	python3 tools/mkdsk.py dist/vi65.dsk build/vi65.bin 0x4000 VI65 dist/vi65.dsk
	for n in $(BOOK); do python3 tools/mkdsk.py dist/vi65.dsk --text samples/guerra$$n.txt GUERRA$$n \
	  dist/vi65.dsk || exit 1; done

.PHONY: dist
