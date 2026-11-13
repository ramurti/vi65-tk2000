# VI65 for the TK2000 / MPF-II — reference card

[Português](vi65-refcard-pt.md) · English

A vi text editor for the TK2000 and the Microprofessor II (MPF-II): 56 columns × 24 lines, upper and lower case, Portuguese
accents, files on tape or on disk (TKDOS 3.3). Based on VI65 by Soci/Singular (GPL v2).

## Starting

| | |
|---|---|
| From tape | `LOADT`, then play `vi65.wav` (real TK2000) or `vi65.ct2` (emulator); about 1 min |
| From disk | boot TKDOS (`CALL 49408`), then `BRUN VI65`; about 15 s |
| Back to the text after `:q` | `CALL 16387` |
| Start again, empty | `CALL 16384` |

The editor starts in **normal mode** (keys are commands). `i`, `a`, `o`... go to **insert
mode** (keys are text); **CTRL** pressed and released alone (ESC) goes back to normal mode.

## The TK2000 keyboard

| Key | Gives |
|---|---|
| letter | lower case letter |
| SHIFT + letter | upper case letter |
| **CTRL alone** (press and release) | **ESC** |
| CTRL + C | ESC too |
| CTRL + H | backspace |
| SHIFT + 1 ... 0 | `! " # $ % & ' ( ) *` |
| SHIFT + `:` `,` `.` `?` | `; < > /` |
| CTRL + SHIFT + I O P K L | `- = + ^ @` |
| arrows | move the cursor (also in insert mode) |

Not on the keyboard: `[ ] { } \ | ~ _` and the backquote.

## Cursor movement

**Characters**

| | |
|---|---|
| **arrows** | left, down, up, right |
| `h` `j` `k` `l` | left, down, up, right |
| SPACE / CTRL-H | right / left |
| CTRL-N CTRL-J / CTRL-P | down / up |

**Lines**

| | |
|---|---|
| `0` | start of the line |
| `^` | first non-blank character |
| `$` | end of the line |
| `+` RETURN | first non-blank of the next line |
| `-` | first non-blank of the previous line |

**Find in the line**

| | |
|---|---|
| `f`*c* / `F`*c* | to the next / previous *c* |
| `t`*c* / `T`*c* | to just before the next / after the previous *c* |

**Screen and file**

| | |
|---|---|
| `H` `M` `L` | top, middle, bottom line of the screen |
| `gg` / `G` | first / last line |
| *n*`G` | line *n* |

**Marks**

| | |
|---|---|
| `m`*x* | mark the line as *x* (a letter) |
| `'`*x* | go to the line marked *x* |

A number before a motion repeats it: `5j` goes 5 lines down.

## Scrolling

| | |
|---|---|
| CTRL-F / CTRL-B | one screen forward / back (page down / up) |
| CTRL-D / CTRL-U | half a screen down / up, the cursor too |
| CTRL-E / CTRL-Y | one line down / up |

Lines longer than 56 columns: `zh` `zl` scroll one column left / right, `zH` `zL` half a screen,
`zs` `ze` put the cursor at the start / end of the screen; `g0` `gm` `g$` go to the first,
middle, last column of the screen.

## Inserting text

| | |
|---|---|
| `i` / `a` | insert before / after the cursor |
| `I` / `A` | insert at the start / end of the line |
| `gI` | insert in column 1 |
| `o` / `O` | open a new line below / above |
| **ESC** (CTRL alone) | back to normal mode |

**In insert mode**

| | |
|---|---|
| CTRL-H | delete the character before the cursor |
| RETURN | split the line |
| CTRL-E / CTRL-Y | copy the character below / above the cursor |
| arrows | move without leaving insert mode |

## Accents (in insert mode)

Type the sign, then the letter, one after the other:

| Keys | Give |
|---|---|
| `'` then `a e i o u` | á é í ó ú |
| `'` then `A E I O U` | Á É Í Ó Ú |
| `'` then `c` / `C` | ç / Ç |
| `"` then `a o` / `A O` | ã õ / Ã Õ |
| `'` or `"` then SPACE | `'` or `"` alone |
| `'` or `"` then another key | the sign, then the key: `it's` |

`'` is SHIFT + 7 and `"` is SHIFT + 2. Example: **coração** = `c o r a ' c " a o`.

## Deleting and changing

| | |
|---|---|
| `x` / `X` | delete the character under / before the cursor |
| `dd` | delete the line |
| `D` | delete to the end of the line |
| `d`*motion* | delete to where the motion goes: `dj`, `d$`, `dG`, `dtx` |
| `J` | join the next line to this one |
| `s` | change the character (delete it, then insert) |
| `S` / `cc` | change the whole line |
| `C` | change to the end of the line |
| `c`*motion* | change to where the motion goes: `c$`, `cfx` |

## Copy and paste

| | |
|---|---|
| `yy` | copy (yank) the line |
| `y`*motion* | copy to where the motion goes: `y$`, `yj` |
| `p` / `P` | paste after / before the cursor |

A number repeats: `3dd` deletes 3 lines, `2yy` copies 2.

## Search

| | |
|---|---|
| `/`*text* RETURN | search forward for *text* |

## Files

| | |
|---|---|
| `:w` *name* | save |
| `:w` | save under the current name |
| `:e` *name* | load (replaces the text, without asking) |
| `:wq` | save and quit |
| `:q` | quit to BASIC (the text stays in memory; no question about unsaved changes) |
| `:ene` | new empty text |
| `:f` *name* | give the text a name, without saving |
| CTRL-G | show the file name |

**Where the files go:** with TKDOS loaded, `:w name` and `:e name` use the disk, and
`:w t:name`, `:e t:name` the tape. Without TKDOS everything goes to tape.

**Disk:** names of up to 30 characters, stored in upper case (`nota` → `NOTA`); `CATALOG` lists
them as type `T`. Files are TKDOS text files, which BASIC can read.

**Tape:** names of up to 6 characters. Before `:w`, press REC on the recorder; after `:e`, press
PLAY. Several files can go on one tape, one after the other; `:e name` skips the others. About
7 s per 1K of text.

**Memory:** about 22K of text, or 12K with TKDOS.

**Command line:** LEFT or CTRL-H deletes, ESC cancels, RETURN runs.

## Not available

Word motions (`w b e`), undo (`u`), repeat (`.`), next match (`n`), replace (`r`), registers.
