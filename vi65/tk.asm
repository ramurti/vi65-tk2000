;
;    TK2000 keyboard for VI65 (the rest of the TK2000 target is TARGET=APPLE2 with TK=1)
;
;    The TK2000 has no ASCII latch: the 8 x 6 key matrix is scanned here and turned into the
;    codes the Apple II version reads from $c000 (ASCII, arrows as CTRL codes).
;
;    plain key           lower case letter, digit, , . : ? space
;    SHIFT + key         upper case letter, or the symbol printed on the key
;                        (1-0: ! " # $ % & ' ( ) *, I O P: - = +, K L: ^ @, : ; , . ?: < > /)
;    CTRL + letter       control code (CTRL-C leaves insert mode, as ESC)
;    CTRL + SHIFT + key  upper case letter (for I O P K L, whose SHIFT gives a symbol)
;    arrows, RETURN      CTRL-H (also delete in insert mode), CTRL-U, CTRL-J, CTRL-K, CTRL-M
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
upper           and #$df
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
                bne found
                dey
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

rowbit          .byte $01, $02, $04, $08, $10, $20, $40, $80
rowmask         .byte $3e, $3e, $3f, $3f, $3f, $3f, $3f, $3f    ;column 0 of rows 0-1: SHIFT

keys            .text 0, "bvcxz"
                .text 0, "gfdsa"
                .text " ", "trewq"
                .text 8, "54321"
                .text 21, "67890"
                .text 10, "yuiop"
                .text 11, "hjkl:"
                .text 13, "nm,.?"
shifted         .text 0, "BVCXZ"
                .text 0, "GFDSA"
                .text " ", "TREWQ"
                .text 8, "%$#", '"', "!"
                .text 21, "&'()*"
                .text 10, "YU-=+"
                .text 11, "HJ^@;"
                .text 13, "NM<>/"

held            .byte 255
repeating       .byte 0
bufn            .byte 0
buf             .fill BUFSIZE
count           .word 0
shift           .byte 0
col             .byte 0
row2            .byte 0
