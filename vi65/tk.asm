;
;    TK2000 keyboard for VI65 (the rest of the TK2000 target is TARGET=APPLE2 with TK=1)
;
;    The TK2000 has no ASCII latch: the 8 x 6 key matrix is scanned here and turned into the
;    codes the Apple II version reads from $c000 (ASCII, arrows as CTRL codes).
;
;    plain key           lower case letter, digit, , . : ? space
;    SHIFT + key         upper case letter, or the symbol printed on a digit or punctuation key
;                        (1-0: ! " # $ % & ' ( ) *, : ; , . ?: < > /)
;    CTRL + letter       control code (CTRL-C leaves insert mode, as ESC; CTRL-H deletes)
;    CTRL alone          pressed and released with no other key: CTRL-C (ESC)
;    CTRL + SHIFT + key  the symbol printed on I O P K L (- = + ^ @), else as SHIFT
;    arrows, RETURN      31 (k_cursorleft), CTRL-U, CTRL-J, CTRL-K, CTRL-M
;
;    Accents, in insert mode (deadkey): ' then a vowel = acute, ' then c = ç, " then a or o =
;    tilde (capitals too, Latin-1 codes, glyphs from tools/accents.py); ' or " then space =
;    the sign alone; then any other key = the sign and that key.
;
;    Keys pressed while the screen is redrawn are kept: the display calls tkpoll between lines
;    and waitkey reads them first (tkget). Without this, fast typing lost keys during redraws.
;
;    A held key repeats after REPEAT1 calls, then every REPEAT2 calls (measured in the
;    emulator: about 2.900 calls a second while vi65 waits for a key).

kbout           = $c000
kbin            = $c010
ctrlon          = $c05f
ctrloff         = $c05e

REPEAT1         = 1450         ;0,5 s
REPEAT2         = 190          ;15 a second
BUFSIZE         = 8

;C=1 and A = the next key: a kept one first, then the keyboard; C=0 if none
tkget           .proc
                lda bufn
                bne +
                jmp tkkey
+               lda buf
                pha
                ldx #0
-               lda buf+1,x
                sta buf,x
                inx
                cpx #BUFSIZE-1
                bne -
                dec bufn
                pla
                sec
                rts
                .pend

;keeps a key just pressed (not a repeat) while the screen is being redrawn
tkpoll          .proc
                jsr tkkey
                bcc +
                ldx repeating
                bne +
                ldx bufn
                cpx #BUFSIZE
                bcs +
                sta buf,x
                inc bufn
+               rts
                .pend

;C=1 and A = the code of a key just pressed (or repeating); C=0 if none
tkkey           .proc
                lda #0
                sta repeating
                jsr scan
                jsr ctrltap
                bcc +
                rts
+               cpx held
                beq same
                stx held
                cpx #255
                beq none
                lda #<REPEAT1
                sta count
                lda #>REPEAT1
                sta count+1
                bne code
same            cpx #255
                beq none
                lda count
                bne +
                dec count+1
+               dec count
                lda count
                ora count+1
                bne none
                lda #<REPEAT2
                sta count
                lda #>REPEAT2
                sta count+1
                inc repeating
code            lda #1                  ;SHIFT: row 0 alone, column 0
                sta kbout
                lda kbin
                and #1
                sta shift
                lda #0
                sta kbout
                sta ctrlon
                lda kbin                ;CTRL: column 0 while enabled
                sta ctrloff
                and #1
                beq plain
                lda keys,x              ;CTRL + letter
                cmp #"a"
                blt plain
                ldy shift
                bne upper
                and #$1f
                sec
                rts
upper           lda symbols,x       ;CTRL + SHIFT + letter
                sec
                rts
plain           ldy shift
                beq +
                lda shifted,x
                gne got
+               lda keys,x
got             cmp #1                  ;0: no character
                rts
none            clc
                rts
                .pend

;C=1 and A = 3 (CTRL-C, ESC) when CTRL is released and no other key was pressed while it was
;down; X (the key down, from scan) kept
ctrltap         .proc
                lda #0
                sta kbout
                sta ctrlon
                lda kbin
                sta ctrloff
                and #1
                beq up
                cpx #255
                bne used
                lda ctrlalone
                bne +
                inc ctrlalone           ;CTRL down alone
+               clc
                rts
used            lda #2                  ;CTRL + a key: no ESC on release
                sta ctrlalone
                clc
                rts
up              ldy ctrlalone
                lda #0
                sta ctrlalone
                cpy #1
                bne +
                lda #3
                sec
                rts
+               clc
                rts
                .pend

;insert mode: A = a key. C=1: ' or " kept, wait for the next key; else A = the key to use
;(an accented letter, the sign alone, or the key, the sign inserted before it)
deadkey         .proc
                ldx dead
                bne second
                cmp #"'"
                beq +
                cmp #'"'
                bne no
+               sta dead                ;C=1
                rts
no              clc
                rts
second          sta dkey
                lda #0
                sta dead
                lda dkey
                cmp #" "
                beq alone
                ldy #0
-               txa
                cmp pairs,y
                bne +
                lda dkey
                cmp pairs+1,y
                bne +
                lda pairs+2,y
                clc
                rts
+               iny
                iny
                iny
                lda pairs,y
                bne -
                txa                     ;no accent: the sign, then the key
                tay
                jsr insertmode.put2
                lda dkey
                clc
                rts
alone           txa
                clc
                rts

pairs           .byte "'", "a", $e1, "'", "e", $e9, "'", "i", $ed, "'", "o", $f3, "'", "u", $fa
                .byte "'", "A", $c1, "'", "E", $c9, "'", "I", $cd, "'", "O", $d3, "'", "U", $da
                .byte "'", "c", $e7, "'", "C", $c7
                .byte '"', "a", $e3, '"', "o", $f5, '"', "A", $c3, '"', "O", $d5
                .byte 0
                .pend

dead            .byte 0
dkey            .byte 0

;X = index (row * 6 + column) of the first key down, 255 if none
scan            .proc
                ldy #7
-               lda rowbit,y
                sta kbout
                lda kbin
                and rowmask,y
                beq +
                cpy #0
                bne found
                sta col                 ;row 0: less the row 1 keys pressed meanwhile
                lda #2
                sta kbout
                lda kbin
                eor #$ff
                and col
                bne found
+               dey
                bpl -
                ldx #255
                gne done
found           ldx #255
-               inx
                lsr a
                bcc -
                stx col
                tya
                asl a
                sta row2
                asl a
                adc row2
                adc col
                tax
done            lda #0
                sta kbout
                rts
                .pend

;row 0 is read together with row 1 (and row 1 alone taken out): with KBOUT = $01 alone and
;SHIFT down, the emulator answers SHIFT only, and SHIFT + B V C X Z were lost
rowbit          .byte $03, $02, $04, $08, $10, $20, $40, $80
rowmask         .byte $3e, $3e, $3f, $3f, $3f, $3f, $3f, $3f    ;column 0 of rows 0-1: SHIFT

keys            .text 0, "bvcxz"
                .text 0, "gfdsa"
                .text " ", "trewq"
                .text 31, "54321"
                .text 21, "67890"
                .text 10, "yuiop"
                .text 11, "hjkl:"
                .text 13, "nm,.?"
shifted         .text 0, "BVCXZ"
                .text 0, "GFDSA"
                .text " ", "TREWQ"
                .text 31, "%$#", '"', "!"
                .text 21, "&'()*"
                .text 10, "YUIOP"
                .text 11, "HJKL;"
                .text 13, "NM<>/"
symbols         .text 0, "BVCXZ"        ;CTRL + SHIFT + letter
                .text 0, "GFDSA"
                .text 0, "TREWQ"
                .fill 12
                .text 0, "YU-=+"
                .text 0, "HJ^@", 0
                .text 0, "NM"

held            .byte 255
repeating       .byte 0
bufn            .byte 0
buf             .fill BUFSIZE
count           .word 0
shift           .byte 0
ctrlalone       .byte 0                 ;0 up, 1 down alone, 2 down with a key
col            .byte 0
row2            .byte 0

;
;    Files on tape, with the ROM's SAVET and LOADT routines: plain text, a CR after each line,
;    the name's first 6 characters in upper case (LOADT "NAME" in BASIC finds them too).
;
;    :w writes the text below alloc's limit (tktop: $BF00, or TKDOS's HIMEM) and saves it from there. :e loads the file
;    there too (the ROM loads to the address in the file's header; the header is moved while the
;    ROM prints the file name, through CSW), then the lines are taken from it as the Apple version
;    reads them from DOS, while alloc may only use the memory below what is still to be read.
;    The ROM's tape messages are not printed (they would draw on the editor's screen).

csw             = $36
tkp             = $3a                   ;the text being written or read (monitor's PC: unused)
tapename        = $0460                 ;6 characters, high bit set, $A0 after the name
tapeblock       = $0467                 ;block just read: 0 = a header
tapestart       = $0468                 ;the header: start, end (inclusive)
tapeend         = $046a
tapewanted      = $0474                 ;the name LOADT looks for (ROM's copy)
tapewrite       = $ec9a                 ;A1 ($3c) to A2 ($3e)
taperead        = $edae
bell            = $fbd9

;save: the text goes from memtop up (nothing may alloc until it is saved: the status line first)
tkwopen         .proc
                jsr isdisk
                bcc +
                jmp dkwopen
+               lda #statusmsg.writing
                jsr tkshow
                jsr garbage
                lda memtop
                sta tkp
                sta tkstart
                lda memtop+1
                sta tkp+1
                sta tkstart+1
                lda #0
                sta tkfull
                rts
                .pend

;A = a byte of the text to save (X and Y kept)
tkput           .proc
                pha
                lda dkmode
                beq +
                pla
                jmp dkput
+               pla
                sty tky
                ldy tkp+1
                cpy tktop
                bcs full
                ldy #0
                sta (tkp),y
                inc tkp
                bne +
                inc tkp+1
+               ldy tky
                rts
full            lda #1
                sta tkfull
                ldy tky
                rts
                .pend

;saves what tkput wrote
tkwrite         .proc
                lda dkmode
                beq +
                jmp dkwrite
+               lda tkfull
                beq +
                lda #statusmsg.nomem
                jmp setstatusmsg
+               jsr name
                lda tkstart
                sta $3c
                lda tkstart+1
                sta $3d
                lda tkp
                sec
                sbc #1
                sta $3e
                lda tkp+1
                sbc #0
                sta $3f
                lda #0
                sta reloc
                jsr hook
                jsr tapewrite
                jsr unhook
                lda #statusmsg.saved
                jmp setstatusmsg
                .pend

;load: C=1 if the file couldn't be read (the status line says why)
tkread          .proc
                jsr isdisk
                bcc +
                jmp dkread
+               tsx
                stx tksp
                lda #statusmsg.reading
                jsr tkshow
                jsr garbage
                jsr name
                lda #$ff                ;no block read yet (the ROM would match a stale header)
                sta tapeblock
                sta reloc
                jsr hook
                jsr taperead
                jsr unhook
                lda tkerr
                beq +
                lda #statusmsg.ioerr
                jsr setstatusmsg
                sec
                rts
+               lda tapestart
                sta tkp
                lda tapestart+1
                sta tkp+1
                sta alloc.end+1
                ldx #<(insertmode.notxt-4)  ;the status line cleared (below the text read)
                lda #>(insertmode.notxt-4)
                jsr setstatus
                clc
                rts
                .pend

;C=1 at the end of the file read, else A = its next byte
tkgetc          .proc
                lda dkmode
                beq +
                jmp dkgetc
+               lda tkp+1
                cmp tktop
                bcs +
                ldy #0
                lda (tkp),y
                inc tkp
                bne +
                inc tkp+1
                ldy tkp+1               ;alloc may now use this page
                sty alloc.end+1
                clc
+               rts
                .pend

;end of a load: alloc may use all its memory again
tkclose         .proc
                lda dkmode
                beq +
                jmp dkclose
+               lda tktop
                sta alloc.end+1
                rts
                .pend

;the status message A shown before the tape starts
tkshow          .proc
                jsr setstatusmsg
                lsr display.now
                jmp display
                .pend

;the file name for the ROM, from vi65's
name            .proc
                jsr tprefix
                lda #0
                bcc +
                lda #2                  ;t: left out
+               sta tkofs
                ldx #0
-               txa
                clc
                adc tkofs
                tay
                lda #" "
                cpy filename
                bcs +
                lda filename+1,y
                jsr upper
+               ora #$80
                sta tapename,x
                inx
                cpx #6
                bne -
                rts
                .pend

hook            .proc
                lda csw
                sta oldcsw
                lda csw+1
                sta oldcsw+1
                lda #<tkcout
                sta csw
                lda #>tkcout
                sta csw+1
                lda #0
                sta tkerr
                sta tklast
                rts
                .pend

unhook          .proc
                lda oldcsw              ;the ROM's or TKDOS's
                sta csw
                lda oldcsw+1
                sta csw+1
                rts
                .pend

;the ROM's character output while it reads or writes: nothing printed. The bell ends a load
;or a save: after "ERR" it is an error. While reading, the header of the file wanted is moved
;below tktop (it is in memory when its name is printed, before the ROM uses it).
tkcout          .proc
                sta tkchar
                stx tkx
                sty tky
                cmp #$87
                bne +
                lda tklast
                cmp #"R"|$80
                bne bel
                sta tkerr
bel             jsr bell
                jmp out
+               sta tklast
                lda reloc
                beq out
                lda tapeblock
                bne out
                ldx #5
-               lda tapename,x
                cmp tapewanted,x
                bne out
                dex
                bpl -
                sec                     ;length - 1
                lda tapeend
                sbc tapestart
                sta tklen
                lda tapeend+1
                sbc tapestart+1
                sta tklen+1
                ldy tktop               ;the new start, below tktop and above memtop
                dey
                sty tklen+2
                sec
                lda #$ff
                sbc tklen
                tax
                lda tklen+2
                sbc tklen+1
                bcc big
                tay
                cpx memtop
                sbc memtop+1
                bcc big
                stx tapestart
                sty tapestart+1
                lda #$ff
                sta tapeend
                lda tklen+2
                sta tapeend+1
out             lda tkchar
                ldx tkx
                ldy tky
                rts
big             ldx tksp                ;too big: back from tkread, the tape is not read
                txs
                jsr unhook
                lda #statusmsg.nomem
                jsr setstatusmsg
                sec
                rts
                .pend

tkfull          .byte 0
tkerr           .byte 0
tklast          .byte 0
reloc           .byte 0
tkchar          .byte 0
tkx             .byte 0
tky             .byte 0
tksp            .byte 0
tklen           .fill 3                 ;length - 1, and tktop - 1
tkstart         .word 0
tkofs           .byte 0
oldcsw          .word 0
tktop           .byte >memoryend-1      ;alloc's limit (TKDOS: HIMEM's page)

;C=1 if the file name starts with t: (the tape, when TKDOS is loaded)
tprefix         .proc
                lda filename
                cmp #2
                bcc no
                lda filename+2
                cmp #":"
                bne no
                lda filename+1
                ora #$20
                cmp #"t"
                bne no
                sec
                rts
no              clc
                rts
                .pend

;C=1 when the file is on disk: TKDOS loaded and no t:
isdisk          .proc
                lda dos
                beq no
                jsr tprefix
                bcs no
                sec
                rts
no              clc
                rts
                .pend

upper           .proc
                cmp #"a"
                blt +
                cmp #"z"+1
                bge +
                and #$df
+               rts
                .pend

;
;    Files on disk, with TKDOS 3.3 (the Apple's DOS 3.3, at the same addresses: hooks in CSW and
;    KSW, commands printed after CTRL-D). Used when TKDOS is loaded and the name has no t:. The
;    files are text files as TKDOS BASIC writes them: characters with bit 7 set, CR after each
;    line; the accented letters, which would clash with that, as control codes (accents).
;    MAXFILES 1 at the start leaves more memory: the editor opens one file at a time.
;
;    TKDOS errors (END OF DATA at the end of a file too) come through its ONERR vector to dkfail,
;    which returns from the routine that saved the stack in dksp (the dk... routines with "C=1:
;    a TKDOS error"). The BASIC state TKDOS looks at is set for each use and put back after it:
;    a program running (else the commands are refused, or TKDOS goes back to the prompt), ONERR.

dosonerr        = $d8                   ;BASIC's ONERR flag
curlin          = $76                   ;BASIC's line number, high byte ($FF: direct mode)
prompt          = $33                   ;">": direct mode too, for TKDOS
dosvec          = $9d5a                 ;TKDOS's ONERR exit
doslang         = $aab6
dosmode         = $aa52                 ;0: at the start of a line
himem           = $73

;A = the end page of the memory for the text; TKDOS: detected, MAXFILES 1
dosinit         .proc
                lda $3d0                ;TKDOS's vectors: JMP, JMP, JMP
                cmp #$4c
                bne no
                lda $3d3
                cmp #$4c
                bne no
                lda $3d6
                cmp #$4c
                bne no
                inc dos
                jsr dosbegin
                jsr maxf
                jsr dosend
                lda himem+1
                rts
no              lda #>memoryend
                rts

maxf            tsx                     ;C=1: a TKDOS error
                stx dksp
                lda #dostext.maxfiles
                jsr doscmd
                clc
                rts
                .pend

;load: C=1 if the file couldn't be opened (the status line says why)
dkread          .proc
                lda #statusmsg.dreading
                jsr tkshow
                jsr dosbegin
                jsr open
                bcc +
                jsr dkclose
                sec
                rts
+               ldx #<(insertmode.notxt-4)  ;the status line cleared
                lda #>(insertmode.notxt-4)
                jsr setstatus
                clc
                rts

open            tsx                     ;C=1: a TKDOS error
                stx dksp
                lda #dostext.close
                jsr doscmd
                lda #dostext.verify     ;FILE NOT FOUND (OPEN would make an empty one)
                jsr doscmd
                lda #dostext.open
                jsr doscmd
                lda #dostext.read
                jsr doscmd
                clc
                rts
                .pend

;C=1 at the end of the file (or on an error), else A = its next byte (X kept)
dkgetc          .proc
                stx tkx
                lda dkerr
                bne end
                jsr get
                bcs end
                and #$7f
                cmp #$20
                bcs ok
                cmp #k_return
                beq ok
                ldx #accents.code-accents.latin1-1
-               cmp accents.code,x
                beq +
                dex
                bpl -
                bmi ok
+               lda accents.latin1,x
ok              ldx tkx
                clc
                rts
end             ldx tkx
                sec
                rts

get             tsx                     ;C=1: a TKDOS error
                stx dksp
                jsr moncin
                clc
                rts
                .pend

;save: the file opened (emptied) for writing; errors are told by dkwrite
dkwopen         .proc
                lda #statusmsg.dwriting
                jsr tkshow
                jsr dosbegin
                jmp open

open            tsx                     ;C=1: a TKDOS error
                stx dksp
                lda #dostext.close
                jsr doscmd
                lda #dostext.open       ;DELETE needs the file; OPEN makes it if it isn't there
                jsr doscmd
                lda #dostext.delete     ;else the old end would stay after a shorter text
                jsr doscmd
                lda #dostext.open
                jsr doscmd
                lda #dostext.write
                jsr doscmd
                clc
                rts
                .pend

;A = a byte of the text to save (X and Y kept)
dkput           .proc
                sta tkchar
                stx tkx
                sty tky
                ldx dkerr
                bne out
                cmp #k_return
                bne +
                lda #$0d
                bne put
+               cmp #$c0
                bcc put
                ldx #accents.code-accents.latin1-1
-               cmp accents.latin1,x
                beq +
                dex
                bpl -
                lda #"?"
                bne put
+               lda accents.code,x
put             ora #$80
                jsr out1
out             lda tkchar
                ldx tkx
                ldy tky
                rts

out1            tsx                     ;C=1: a TKDOS error
                stx dksp
                jsr moncout
                clc
                rts
                .pend

;end of a save
dkwrite         .proc
                jsr dkclose
                lda dkerr
                bne +
                lda #statusmsg.saved
                jmp setstatusmsg
+               rts
                .pend

;the file closed, TKDOS's state put back; an error on the status line (END OF DATA isn't one)
dkclose         .proc
                lda dkmode
                beq done
                lda #0
                sta dkmode
                lda dkerr
                pha
                jsr close
                pla
                beq +
                sta dkerr               ;the first error is the one told
+               jsr dosend
                lda dkerr
                beq done
                cmp #5
                beq done
                cmp #6
                bne +
                lda #statusmsg.notfound
                jmp setstatusmsg
+               lda #statusmsg.ioerr
                jmp setstatusmsg
done            rts

close           tsx                     ;C=1: a TKDOS error
                stx dksp
                lda #dostext.close
                jsr doscmd
                clc
                rts
                .pend

;TKDOS errors come to dkfail, BASIC as TKDOS wants it while a program runs
dosbegin        .proc
                jsr $fe93               ;PR#0 and IN#0 (the ROM's tape routines may leave
                jsr $fe89               ;KSW changed), then TKDOS connects its hooks ($A851)
                jsr $3ea
                lda dosonerr
                sta saved
                lda curlin
                sta saved+1
                lda dosvec
                sta saved+2
                lda dosvec+1
                sta saved+3
                lda doslang
                sta saved+4
                lda prompt
                sta saved+5
                lda #$ff
                sta dosonerr
                lda #1
                sta curlin
                sta prompt
                sta doslang
                sta dkmode
                lda #<dkfail
                sta dosvec
                lda #>dkfail
                sta dosvec+1
                lda #0
                sta dkerr
                rts
saved           .fill 6
                .pend

dosend          .proc
                lda dosbegin.saved
                sta dosonerr
                lda dosbegin.saved+1
                sta curlin
                lda dosbegin.saved+2
                sta dosvec
                lda dosbegin.saved+3
                sta dosvec+1
                lda dosbegin.saved+4
                sta doslang
                lda dosbegin.saved+5
                sta prompt
                lda #0
                sta dkmode
                rts
                .pend

;a TKDOS error (X = its code): back from the routine that saved dksp, C=1
dkfail          .proc
                txa
                bne +
                lda #255
+               sta dkerr
                ldx dksp
                txs
                sec
                rts
                .pend

;CTRL-D, the TKDOS command A, the file name if the command ends with a space, CR
doscmd          .proc
                tay
                lda #0                  ;TKDOS's output state: start of a line (as after a CR,
                sta dosmode             ;without printing one), where CTRL-D starts a command
                lda #$84
                jsr moncout
-               lda dostext,y
                beq +
                ora #$80
                jsr moncout
                iny
                bne -
+               lda dostext-1,y
                cmp #" "
                bne +
                ldx #0
-               cpx filename
                bcs +
                lda filename+1,x
                jsr upper
                ora #$80
                jsr moncout
                inx
                bne -
+               lda #$8d
                jmp moncout
                .pend

dostext         .proc
                .logical 0
maxfiles        .null "MAXFILES 1"
close           .null "CLOSE"
verify          .null "VERIFY "
open            .null "OPEN "
read            .null "READ "
delete          .null "DELETE "
write           .null "WRITE "
                .here
                .pend

;the accented letters (Latin-1) and their codes in disk files (no 4: CTRL-D, no 13: CR)
accents         .proc
latin1          .byte $e1, $e9, $ed, $f3, $fa, $e2, $ea, $f4, $e0, $e3, $f5, $e7
                .byte $c1, $c9, $cd, $d3, $da, $c2, $ca, $d4, $c0, $c3, $d5, $c7
code            .byte 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 14
                .byte 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26
                .pend

dos             .byte 0                 ;1: TKDOS loaded
dkmode          .byte 0                 ;1: a disk file is being read or written
dkerr           .byte 0                 ;TKDOS's error code, 0 if none
dksp            .byte 0
