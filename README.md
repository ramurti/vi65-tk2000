# VI65 for the TK2000

A vi text editor for the TK2000: [VI65](https://sourceforge.net/projects/vi65/) by Soci/Singular
(2010-2013, GPL v2), built from its Apple II hi-res target. The TK2000 has no text mode; VI65
draws its own 5 × 8 font on the hi-res screen: **56 columns × 24 lines**, upper and lower case.

## Load and use

In the emulator: F2 -> insert `dist/vi65.ct2`, type `LOADT`, RETURN, F6 (play). It starts by
itself after about a minute. On a real TK2000: `LOADT` and play `dist/vi65.wav` (made by
`make dist`, not in git).

The editor starts with one empty line in normal mode, as vi. VI65 has a subset of vi
(`reference/vi65/bin/doc.txt`; the manual copies VIM's text, the code has less):

- insert: `i a I A o O` (CTRL-C to leave), CTRL-H deletes, the arrows move, CTRL-E / CTRL-Y
  insert the character below/above;
- delete and change: `x X D C s S J`, `d c y` + a motion (`dd`, `d$`, `cc`, `yy`), `p P`;
- motions: `h j k l` (and the arrows), `0 ^ $ |`, `f t F T`, `H M L`, `G gg`, `+ -` RETURN,
  SPACE, marks (`m` then `'` or the backquote, which the TK2000 lacks); counts (`3dd`, `5j`);
- scroll: CTRL-F, CTRL-B, CTRL-E, CTRL-Y, `z` commands;
- `/` search, CTRL-G (file information);
- `:e :ene :f :w :wq :q`: files on tape (below).

Not in VI65: word motions (`w b e`), undo (`u`), `n`, `r`, `.`.

Checked in the emulator so far: insert, RETURN, CTRL-C, CTRL-H, LEFT in insert mode and in the
`:` line, all SHIFT letters and symbols, CTRL+SHIFT symbols, `x dd yy p G gg`, `/` search, key
repeat, `:w` and `:e` on tape (a 9K file of 300 lines loaded, edited, saved and compared), a file
too big, `:q` and `CALL 16387`.

### Files on tape

- **`:w name`** saves the text on tape: press REC (and PLAY) on the recorder first. The status
  line says "writing the tape", then "saved".
- **`:e name`** loads a file: type it, then press PLAY. The status line says "reading the tape"
  until the file is found and read; the lines appear as they are read, and you can already move
  and edit while the rest loads.
- The name is cut to **6 characters, in upper case** (the TK2000's tape names): `:w notes` saves
  `NOTES`. The files are plain text (CR after each line), so `LOADT NOTES` in BASIC reads them
  too, and other files on the tape are skipped as LOADT does.
- **No way to cancel a load** other than RESET (it waits for the tape, as LOADT). A file bigger
  than the free memory (about 24K, less 5 bytes per line) is refused with "out of memory" before
  it is read; stop the tape then.
- `:e` replaces the text (VI65 doesn't ask about unsaved changes).

In the emulator, what the TK2000 saves goes to `recorded.ct2`, next to the inserted tape (the
emulator's own recording, from Nov 2026): insert it to load the file back. `tools/ct2txt.py
TAPE.ct2` writes the files of a tape as `.txt`; `tools/txt2ct2.py FILE.txt NAME OUT.ct2` turns a
text into a tape for `:e`.

### Leaving and coming back

`:q` goes back to BASIC (by a reset); the text stays in memory. **`CALL 16387`** returns to the
editor with the text, the cursor and the file name as they were (`CALL 16384` starts it again,
empty). BASIC programs, `HGR2` and `NEW` don't touch the text area (`$60A3-$BEFF`), but loading
another program over it does.

### Keys

The TK2000 has no lower case keys and no ESC; the keyboard (`vi65/tk.asm`) maps:

| Key | Gives |
|---|---|
| a letter | the lower case letter (vi's commands) |
| SHIFT + letter | the upper case letter |
| SHIFT + 1 2 3 4 5 6 7 8 9 0 | `! " # $ % & ' ( ) *` |
| SHIFT + `:` `,` `.` `?` | `; < > /` |
| CTRL + SHIFT + I O P K L | `- = + ^ @` (the symbols the TK2000 prints on them) |
| **CTRL + C** | **ESC** (leaves insert mode, as in vim) |
| **CTRL + H** | **backspace**: deletes the character before the cursor in insert mode and in the `:` and `/` lines |
| CTRL + letter | the control code (CTRL-F, CTRL-B, CTRL-E, CTRL-Y...) |
| arrows | move the cursor, also in insert mode and in the `:` line |

A held key repeats after 0,5 s, 15 times a second. Keys typed while the screen is redrawn are
kept (up to 8) and processed after it: the TK2000 has no keyboard latch, and fast typing lost
keys before this.

Missing on the keyboard: `[ ] { } \ | ~ _` and the backquote.

## Not done yet

- Files on disk.
- `:q` leaves the screen in mono with the text.
- Tested only in the emulator.

## Build

Needs 64tass (`brew install tass64`; Debian/Ubuntu `apt install 64tass`), Python 3 and, for the
test runner, the emulator's source and SDL2.

```sh
make            # build/vi65.ct2
make dist       # dist/vi65.ct2 and dist/vi65.wav
make build/run  # the headless emulator (EMU = the emulator's src/, default ~/pessoal/tk2000/src)
```

`build/run build/vi65.ct2 -t 80 $(python3 tools/keys.py 56 'ihello{esc}') -s 79:shot.ppm` types
keys at emulated times and takes a screenshot (`tools/keys.py` explains the key syntax; the
editor is ready about 54 s after LOADT). `-r rec.ct2` records what it saves on tape, `-i
TIME:FILE.ct2` inserts a tape and plays it (`tools/harness/run.cpp`).

## How the TK2000 version differs from the Apple II one

The source is VI65's svn trunk (`vi65/`, the original in `reference/vi65/code/`), assembled with
`TARGET=2 GFX=2 TK=1`. Every change is under `.if TK`:

- loads at `$4000` (the Apple version at `$0C00`); the text uses `$60A3-$BEFF` (hi-res page 2
  included, never shown): about 24K;
- screen: mono (`$C051`; the font has single pixels) and page 1; the Apple's `$C052`/`$C057` are
  the TK2000's tape relay, not touched;
- keyboard: `tk.asm` scans the matrix in place of the Apple's `$C000` latch, and the display
  polls it between lines (`tkpoll`) so keys aren't lost during redraws;
- LEFT gives code 31 (`k_cursorleft`) and moves; on the Apple it is CTRL-H, which deletes in
  insert mode;
- CTRL keys: `k_control` = 96, as the Apple target's source is ASCII ("e"-96 = CTRL-E);
- starts with an empty line (the Apple version loads `doc.seq` from the disk at start);
- files on tape with the ROM's `SAVET`/`LOADT` routines (`$EC9A`, `$EDAE`) in place of DOS
  (`tk.asm`): `:w` writes the text in the free memory and saves it from there; `:e` loads it
  below `$BF00` (the header's address is changed while the ROM prints the file name through
  CSW, which also keeps the ROM's messages off the screen) and takes the lines from there as the
  Apple version takes them from DOS, alloc using only the memory already read;
- `:q` jumps to the reset vector; `CALL 16387` (`$4003`) resumes, swapping the zero page back.

## How VI65 draws the letters

No pre-built table: the font is 8 bytes per character; 7 characters of 5 pixels fill exactly 5
screen bytes, and the code is unrolled for each of the 7 positions, shifting each glyph row into
place and carrying the spill into the next byte. Lines are redrawn only when they change.

## Earlier experiments

The project started as an 80-column idea (`tools/font.py`, `tools/preview.py`: a 3 × 5 font,
two characters per byte); 3,5 pixels per character makes every second pair of letters touch, so
it moved to VI65. `tools/vi65preview.py` compares VI65's fonts at 46, 56 and 70 columns.

## License

VI65 is GPL v2 (`vi65/COPYING`); the TK2000 changes are under the same license.
