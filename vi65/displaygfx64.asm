;
;    VI65 (c) 2010-2013 Soci/Singular (soci@c64.rulez.org)
;
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program; if not, write to the Free Software
;    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

		.switch TARGET
		.case C64, PLUGIN
scr             = $e000
col             = $dc00
width2		= 40
height          = 25
cache           = $334
		.case PLUS4
scr             = $e000
col             = $0c00
width2		= 40
height          = 23
cache           = $333
		.case C128
scr             = $a000
col             = $8c00
width2		= 40
height          = 25
cache           = $0b00
		.case VIC20BIG
scr		= $10f0
width2		= 20
height		= 24
cache           = $0334
		.case ATARI800
width2		= 40
height          = 24
cache           = $0489
		.case APPLE2
scr             = $2000
width2          = 40
height          = 24
cache           = $0800
		.endswitch
		.if TARGET==APPLE2
width           = width2*7/5
                .else
width		= width2*8/5
                .fi

gfx             .macro
                sta $ff03
                .endm

displayinit     .proc
                ldx #height-1
-               lda #width2
		sta paintone.caches,x
                lda #255
                sta paintone.cachec,x
                dex
                bpl -
                lda #8
                sta cursor.size
                lda #statusmsg.banner
                jsr setstatusmsg
		.if TARGET!=C128 && TARGET!=ATARI800
                jsr display
                .fi
		.switch TARGET
		.case C64, C128, PLUGIN
                #kernal
		.if TARGET==C128
                lda #$47
                sta $d506
                lda #$7f
                sta $d503
                .fi
                ldx #c2-c1
-               ldy c1-1,x
                lda c2-1,x
                sta $d000,y
                dex
                bne -
                lda #3-(scr >> 14)
                sta $dd00
		.if TARGET==C128
                #gfx
                .else
                #ram
                .fi
                lda #15
cl              sta col,x
                sta col+$100,x
                sta col+$200,x
		sta col+$300,x
                inx
                bne cl
		.if TARGET==C128
                #ram
                .fi
                rts

c1              .byte $15, $20, $11, $16, $18
c2              .byte $00, $06, $3b, $08, ((col >> 6) & $f0)+((scr & $2000) >> 10)
		.case PLUS4
                lda #$06
                sta $ff19
                lda #$37
                sta $ff06
                lda $ff07
                and #$40
                ora #$08
                sta $ff07
                lda #$c3+(scr >> 13)*8
                sta $ff12
                lda #>(col-$400)
                sta $ff14
                ldx #0
                lda #$08
                sta cl+2
                lda #$61
                jsr clr
                lda #$01
                jsr clr
                ldx #79
-               lda #$00
                sta col+23*width2-$400,x
		lda #$66
                sta col+23*width2,x
                dex
                bpl -
                rts

clr             ldy #3
cl              sta $ff00,x
                inx
                bne cl
                inc cl+2
                dey
                bpl cl
                rts
		.case VIC20BIG
		lda #129
-		cmp $9004
		bge -
		inc $9000
		inc $9000
		dec $9001
		dec $9001
		lda #width2
                sta $9002
		lda #height | 1
                sta $9003
		lda #(scr >> 10)*$11+$88
                sta $9005
		ldx #0
		clc
-		txa
		adc #15
		sta scr & ~$3ff,x
		lda #0
		sta $9400,x
		inx
		cpx #width2*height/2
		blt -
		rts
		.case ATARI800
                ldx #$30
                lda #3
                sta iccom,x
                lda #<(dpname)
                sta icba,x
                lda #>(dpname)
                sta icba+1,x
                lda #8
                sta icax1,x
                lda #8
                sta icax2,x
                jsr ciov                ;keyboard
                lda #$70
                sta $2c8                ;border
                lda #$00
                sta $2c5                ;text
                lda #$0a
                sta $2c6                ;background
                lda $2e6
                sta alloc.end+1
                rts

dpname          .text "S:",k_return
		.case APPLE2
		.if TK
                bit $c051       ;mono: the font has single pixels
                bit $c054       ;page 1
                rts
		.fi
                bit $c052       ;nomix
                ;bit $c055       ;page2
                bit $c057       ;hires
                bit $c050       ;graphic
                rts
		.endswitch
                .pend

displayexit     .proc
                #kernal
		.switch TARGET
		.case C64, C128, PLUGIN
		.if TARGET==C128
                lda #$04
                sta $d506
                .fi
                lda #27
                sta $d011
                lda #$14
                sta $d018
                lda #3
                sta $dd00
                lda #147
                jmp chrout
		.case C16, PLUS4
		lda #$1b
                sta $ff06
                lda #$c7
                sta $ff12
                lda #$08
                sta $ff14
                lda #147
		jmp chrout
		.case VIC20BIG
		lda #129
-		cmp $9004
		bge -
		dec $9000
		dec $9000
		inc $9001
		inc $9001
		lda #22
                sta $9002
		lda #23*2
                sta $9003
		lda #$c0
		sta $9005
		lda #147
		jmp chrout
		.case ATARI800
		ldx #$20
                lda #12
                sta iccom,x
                jsr ciov                ;close
		ldx #$10
                lda #12
                sta iccom,x
                jmp ciov                ;close
		.default
		.if TK
                jmp ($fffc)             ;TK2000: back to BASIC by a reset
		.fi
                rts
		.endswitch
                .pend

displaylowinit  .proc
p3              = num
		.switch TARGET
		.case ATARI800
                lda $58
                clc
                adc #<(width2*8-8)
                sta p3
                lda $59
                adc #>(width2*8-8)
                sta p3+1
		.case APPLE2
                #loadw (scr+8*1024-8), p3
		.default
                #loadw scr, p3
		.endswitch

                ldx #0
                stx cursor.kk+1
                rts
                .pend

displaylow      .proc
p2              = screen
x               = num+2
ln              = num+3
sor             = num+4
p3              = num

                stx paintone.ao+1
                sta paintone.cursorcol+1

                ldx windows.start,y
                lda windows.end,y
                sta leng+1                      ;length of window

loop            jsr paintone

		.switch TARGET
		.case VIC20BIG
                lda p3
                and #8
                beq +
                eor p3
                sta p3
                jmp ek

+               lda p3
                sec
                sbc #<(width2*16-8)
                sta p3
                lda p3+1
                sbc #>(width2*16-8)
                sta p3+1
ek
		.case ATARI800
		lda p3
                clc
                adc #<(width2*7)
                sta p3
                lda p3+1
                adc #>(width2*7)
                sta p3+1
		.case APPLE2
		lda p3
                clc
                adc #<(128-40)
                sta p3
                lda p3+1
                adc #>(128-40)
                sta p3+1
                lda p3
                sec
                sbc #<(1024*8-8)
                tay
                lda p3+1
                sbc #>(1024*8-8)
                cpy #128
                rol
                and #7
                bne +
                lda p3
                sec
                sbc #<(1024-40)
                sta p3
                lda p3+1
                sbc #>(1024-40)
                sta p3+1
+
		.endswitch
		.if TK
                jsr tkpoll              ;keys pressed during the redraw
		.fi

                ldx sor
                inx
leng		cpx #height-1
                bne loop
                rts
                .pend

		.if TARGET==APPLE2 && !TK
                .cerror *>$2000
*               = $4000
                .fi

paintone        .proc
p2              = screen
xp		= num+2
ln              = num+3
sor             = num+4
p3              = num

                stx sor
                lda dotline
                cmp lines
                lda dotline+1
                sbc lines+1
                bcs +
                pha #>(dotnext-1)
                pha #<(dotnext-1)
+               lda cachec,x
                cmp leftcol
                bne ng
                ldy cachel,x
                cpy dotstart
                bne ng
                lda cacheh,x
                cmp dotstart+1
                bne ng
garbagehi       cmp #0
                blt +
		bne ng
garbagelo       cpy #0
                bge ng
+
		.switch TARGET
		.case VIC20BIG
                lda p3
                adc #<(width2*16)
                sta p3
                lda p3+1
                adc #>(width2*16)
                sta p3+1
		.case ATARI800
                lda p3
                adc #width2
                sta p3
                bcc +
                inc p3+1
+
		.case APPLE2
                lda p3
                adc #40
                sta p3
                bcc +
                inc p3+1
+
		.default
                lda p3
                adc #<(width2*8)
                sta p3
                lda p3+1
                adc #>(width2*8)
                sta p3+1
		.endswitch
                jmp jo

ng
		lda leftcol
                sta cachec,x
		lda caches,x
                sta b+1
                lda dotstart
                sta cachel,x
		lda dotstart+1
                sta cacheh,x
                lda #0
		sta xp
                sta ez+1
		.if TARGET==APPLE2
                sta q+1
                .fi
                lda dotline
                cmp lines
                lda dotline+1
                sbc lines+1
                bcc +
		.if TARGET==APPLE2
                lda #"~"+128
                .else
                lda #"-"
                .fi
                jsr er
                ldy #0
                sty ln
                geq lp2
+
		ldy #4
                lda (dotstart),y
                sec
                sbc leftcol
                bge +
                lda #0
+               cmp #width+1
                blt +
                lda #width
+		sta ln

		tya
                sec
                adc leftcol
                adc dotstart
                sta currenttext
                lda #0
                adc dotstart+1
                sta currenttext+1

		.if TARGET==APPLE2
                jsr get
lp2             sta u1+2
                lda p2
                sta u1+1
                inc q+1
                jsr get
-
                lda p3
                sec
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		lda (p2),y
                lsr
                ror
                tax
                ror
                lsr
                and #%01100000
u1              ora tmpl,y
                sta (p3),y
                txa
                and #%00000111
                sta tmpl,y
                dey
                bpl -
                inc q+1
                jsr get2
-
                lda p3
                sec
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		lda (p2),y
                asl
                asl
                asl
                cmp #$80
                and #%01111000
                ora tmpl,y
                sta (p3),y
                lda #0
                rol
                sta tmpl,y
                dey
                bpl -
                jsr get2
-
                lda (p2),y
                asl
                ora tmpl,y
                sta tmpl,y
                dey
                bpl -
                jsr get
-
                lda p3
                sec
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		lda (p2),y
                lsr
                tax
                ror
                lsr
                and #%01000000
                ora tmpl,y
                sta (p3),y
                txa
                sta tmpl,y
                dey
                bpl -
                jsr get2
-
                lda p3
                sec
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		lda (p2),y
                lsr
                ror
                ror
                tax
                ror
                lsr
                and #%01110000
                ora tmpl,y
                sta (p3),y
                txa
                and #%00000011
                sta tmpl,y
                dey
                bpl -
                jsr get2
-
                lda p3
                sec
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		lda (p2),y
                asl
                asl
                ora tmpl,y
                sta (p3),y
                dey
                bpl -
                iny
                sty q+1
                jsr get2
                jmp lp2
                .else
                jsr get
lp2             sta u1+2
                lda p2
                sta u1+1
                jsr get
-
		.if TARGET==ATARI800
                lda p3
                sec
                sbc #width2-1
                sta p3
                bcs +
                dec p3+1
+
                .fi
		lda (p2),y
		asl a
		rol a
		rol a
                tax
		rol a
		and #%00000111
u1              ora tmpl,y
                sta (p3),y
		txa
		and #%11000000
                sta tmpl,y
                dey
                bpl -
                jsr get2

-               lda (p2),y
		lsr a
		lsr a
                ora tmpl,y
                sta tmpl,y
                dey
                bpl -
                jsr get
-
		.if TARGET==ATARI800
                lda p3
                sbc #width2-1-1
                sta p3
                bcs +
                dec p3+1
+
                .fi
		lda (p2),y
		asl a
                ldx tmpl,y
                sta tmpl,y
                txa
                adc #0
                sta (p3),y
                dey
                bpl -
                jsr get2

		.if TARGET==ATARI800
                clc
                .fi
-
		.if TARGET==ATARI800
                lda p3
                sbc #width2-1-1
                sta p3
                bcs +
                dec p3+1
+
                .fi
		lda (p2),y
		lsr a
		lsr a
		lsr a
		lsr a
                ora tmpl,y
                sta (p3),y
                lda #0
		ror a
                sta tmpl,y
                dey
                bpl -
                jsr get2

-               lda (p2),y
		lsr a
                ora tmpl,y
                sta tmpl,y
                dey
                bpl -
                jsr get
-
		.if TARGET==ATARI800
                lda p3
                sec
                sbc #width2-1
                sta p3
                bcs +
                dec p3+1
+
                .fi
		lda (p2),y
		asl a
                tax
		rol a
		rol a
                and #%00000011
                ora tmpl,y
                sta (p3),y
                txa
		asl a
                sta tmpl,y
                dey
                bpl -
                jsr get2

		.if TARGET==ATARI800
                clc
                .fi
-
		.if TARGET==ATARI800
                lda p3
                sbc #width2-1-1
                sta p3
                bcs +
                dec p3+1
+
                .fi
		lda (p2),y
		lsr a
		lsr a
		lsr a
                ora tmpl,y
                sta (p3),y
                dey
                bpl -
                jsr get2
                jmp lp2
                .fi

get2		.if TARGET==APPLE2
                lda p3
                clc
                adc #<(1024*8-8+1)
                sta p3
                lda p3+1
                adc #>(1024*8-8+1)
                sta p3+1
		.elsif TARGET==ATARI800
                lda p3
                clc
                adc #<(width2*8-8+1)
                sta p3
                lda p3+1
                adc #>(width2*8-8+1)
                sta p3+1
                .else
		.if TARGET==VIC20BIG
                lda #16
                .else
                lda #8
                .fi
                clc
		adc p3
                sta p3
                bcc +
                inc p3+1
+
                .fi
		inc xp

get		.if TARGET==C128
                #ram
                .fi
ez              ldy #0
                cpy ln
                bge fin

		lda (currenttext),y
er		asl a
		rol a
		rol a
		rol a
                tax
                and #$f0
		ror a
                adc #<font
                sta p2
                txa
                and #7
                tax
		.if TARGET==C128
                #gfx
                .fi
                lda class,x
		adc #0
                sta p2+1

                inc ez+1
                ldy #7
                rts

fin             pla
                pla

		.if TARGET==C128
                #gfx
                .fi
		ldx xp
		.if TARGET==APPLE2
                ldy #7
q               lda #0
                .else
                tya
                ldy #7
                and #7
                .fi
                beq b
		inc xp
		lsr a
                bne k
-
		.if TARGET==ATARI800
                lda p3
                sec
                sbc #width2-1
                sta p3
                bcs +
                dec p3+1
+
		.elsif TARGET==APPLE2
                lda p3
                sec
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		.fi
		lda (p2),y
                sta (p3),y
                dey
                bpl -
                gmi l2
k
		.if TARGET==ATARI800
                lda p3
                sec
                sbc #width2-1
                sta p3
                bcs +
                dec p3+1
+
		.elsif TARGET==APPLE2
                lda p3
                sec
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		.fi
		lda tmpl,y
                sta (p3),y
                dey
                bpl k
l2
		.if TARGET==ATARI800
                lda p3
                clc
                adc #<(width2*8-8)
                sta p3
                lda p3+1
                adc #>(width2*8-8)
                sta p3+1
		.elsif TARGET==APPLE2
                lda p3
                clc
                adc #<(1024*8-8)
                sta p3
                lda p3+1
                adc #>(1024*8-8)
                sta p3+1
                .fi
l               ldy #7
		.if TARGET==ATARI800 || TARGET==APPLE2
                inc p3
                bne +
                inc p3+1
+
                .else
		.if TARGET==VIC20BIG
                lda #15
                .else
                tya
                .fi
                sec
		adc p3
                sta p3
                bcc +
                inc p3+1
+
                .fi
		inx
b               cpx #width2
		bge ko2
		.if TARGET==ATARI800
-               lda p3
                sec
                sbc #width2-1
                sta p3
                bcs +
                dec p3+1
+               lda #0
                sta (p3),y
                dey
                bpl -
		.elsif TARGET==APPLE2
                sec
-               lda p3
                sbc #<1023
                sta p3
                lda p3+1
                sbc #>1023
                sta p3+1
		lda #0
                sta (p3),y
                dey
                bpl -
                .else
                lda #0
-               sta (p3),y
                dey
                sta (p3),y
                dey
                bpl -
                .fi
                gmi l2

ko2		cpx #width2
                blt l

		ldx sor
		lda xp
                sta caches,x
jo
		.if TARGET==C128
                #ram
                .fi

u               lda activewin
ao              cmp #0
                bne nc
                lda dotline
		cmp marks.line+marks.cursor
                bne nc
                lda dotline+1
                cmp marks.line+1+marks.cursor
                beq +
nc              rts

+               lda #255
                sta ao+1
		.switch TARGET
		.case VIC20BIG
                lda p3
                sbc #<(width2*16)
                sta p2
                lda p3+1
                sbc #>(width2*16)
		.case ATARI800
                lda p3
                sbc #<(width2-8)
                sta p2
                lda p3+1
                sbc #>(width2-8)
		.case APPLE2
                lda p3
                sbc #<(40-8)
                sta p2
                lda p3+1
                sbc #>(40-8)
		.default
                lda p3
                sbc #<(width2*8)
                sta p2
                lda p3+1
		sbc #>(width2*8)
		.endswitch
                tax
cursorcol       lda #0
                sbc leftcol
		sta xp
		asl a
		asl a
		adc xp
		.if TARGET==APPLE2
                ldy #255
                bcc +
                ldy #35
                adc #3
+
                sec
-               iny
		sbc #7
                bcs -
		adc #7
                pha
                tya
                clc
                adc p2
                sta cursor.at1+1
                bcc +
                inx
+               stx cursor.at2+1
                pla
                tay
                lda tochar.mode+1
                cmp #1
                lda #%00000011
                blt +
                lda #%00011111
                gne +

-		asl a
                cmp #$80
                rol cursor.kk+1
+               dey
		bpl -
                and #$7f
                .else
                tay
		.if TARGET==ATARI800
		ror a
		lsr a
		lsr a
                clc
                .else
		and #$f8
		.if TARGET==VIC20BIG
		asl a
                .fi
                bcc +
                clc
                inx
+
                .fi
                adc p2
                sta cursor.at1+1
                bcc +
                inx
+               stx cursor.at2+1
                tya
                and #7
                tay
                lda tochar.mode+1
                cmp #1
                lda #%11000000
                blt +
                lda #%11111000
                gne +

-		lsr a
                ror cursor.kk+1
+               dey
		bpl -
                .fi
                sta cursor.k+1

                lda #1
                gne cursor.in

		.if TARGET==ATARI800
class           .byte >(font+2*8*32),>font,>(font+8*32),>(font+3*8*32)
                .byte >(font+2*8*32),>font,>(font+8*32),>(font+3*8*32)
		.elsif TARGET==APPLE2
class           .byte >(font+0*8*32),>(font+8*32),>(font+2*8*32),>(font+3*8*32)
                .byte >(font+0*8*32),>(font+8*32),>(font+2*8*32),>(font+3*8*32)
                .else
class           .byte >font,>(font+8*32),>font,>(font+2*8*32)
		.byte >(font+2*8*32),>(font+3*8*32),>(font+2*8*32),>(font+3*8*32)
                .fi

		.virtual cache
tmpl            .fill 8
cachec          .fill height
cachel          .fill height
cacheh          .fill height
caches          .fill height
		.endv

FONTFILE	= "font5x8.fnt"
font		.include "font.asm"

                .pend

cursoroff       .proc
                lda cursor.on+1
		beq cursor.xp
		gne cursor
		.pend

cursor          .proc
on              lda #0
                eor #1
in              sta on+1

		.if TARGET==ATARI800 || TARGET==APPLE2
at1             lda #0
                sta screen
at2             lda #0
                sta screen+1

size            = *+1
		ldx #8
-
		.if TARGET==ATARI800
		lda screen
                sec
                sbc #width2
                sta screen
                bcs +
                dec screen+1
+
		.elsif TARGET==APPLE2
                lda screen+1
                sec
                sbc #>1024
                sta screen+1
                .fi
		ldy #0
		lda (screen),y
k               eor #0
                sta (screen),y
                iny
                lda (screen),y
kk              eor #0
                sta (screen),y
                dex
                bne -
                .else
at1             lda #<scr
                sta screen
at2             lda #>scr
                sta screen+1
		.if TARGET==C128
                #gfx
                .fi
size            = *+1
		ldx #8
		ldy #7
-               lda (screen),y
k               eor #0
                sta (screen),y
                dey
                dex
                bne -

		ldx cursor.size
		.if TARGET==VIC20BIG
                ldy #23
                .else
                ldy #15
                .fi
-               lda (screen),y
kk              eor #0
                sta (screen),y
                dey
                dex
                bne -
		.if TARGET==C128
                #ram
                .fi
                .fi
xp		rts
                .pend
