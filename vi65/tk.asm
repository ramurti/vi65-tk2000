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
;    CTRL + SHIFT + key  the symbol printed on I O P K L (- = + ^ @), else as SHIFT
;    arrows, RETURN      31 (k_cursorleft), CTRL-U, CTRL-J, CTRL-K, CTRL-M
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
                cpx held
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
col             .byte 0
row2            .byte 0

;
;    Files on tape, with the ROM's SAVET and LOADT routines: plain text, a CR after each line,
;    the name's first 6 characters in upper case (LOADT "NAME" in BASIC finds them too).
;
;    :w writes the text below alloc's limit ($BF00) and saves it from there. :e loads the file
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
cout            = $fdf0
TAPETOP         = (>memoryend-1)*256    ;alloc's limit

;save: the text goes from memtop up (nothing may alloc until it is saved: the status line first)
tkwopen         .proc
                lda #statusmsg.writing
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
                sty tky
                ldy tkp+1
                cpy #>TAPETOP
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
                lda tkfull
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
                tsx
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
                lda tkp
                cmp #<TAPETOP
                lda tkp+1
                sbc #>TAPETOP
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
                lda #>TAPETOP
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
                ldx #0
-               lda #" "
                cpx filename
                bcs +
                lda filename+1,x
                cmp #"a"
                blt +
                cmp #"z"+1
                bge +
                and #$df
+               ora #$80
                sta tapename,x
                inx
                cpx #6
                bne -
                rts
                .pend

hook            .proc
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
                lda #<cout
                sta csw
                lda #>cout
                sta csw+1
                rts
                .pend

;the ROM's character output while it reads or writes: nothing printed. The bell ends a load
;or a save: after "ERR" it is an error. While reading, the header of the file wanted is moved
;below TAPETOP (it is in memory when its name is printed, before the ROM uses it).
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
                sec                     ;the new start, below TAPETOP and above memtop
                lda #<(TAPETOP-1)
                sbc tklen
                tax
                lda #>(TAPETOP-1)
                sbc tklen+1
                bcc big
                tay
                cpx memtop
                sbc memtop+1
                bcc big
                stx tapestart
                sty tapestart+1
                lda #<(TAPETOP-1)
                sta tapeend
                lda #>(TAPETOP-1)
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
tklen           .word 0
tkstart         .word 0
