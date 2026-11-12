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
width           = 80
height          = 25
cache           = $334
		.case PLUS4
scr             = $e000
col             = $0c00
width           = 80
height          = 23
cache           = $333
		.case C128
scr             = $a000
col             = $8c00
width           = 80
height          = 25
cache           = $0b00
		.case VIC20BIG
scr		= $10f0
width		= 40
height		= 24
cache           = $0334
		.case ATARI800
width           = 80
height          = 24
cache           = $0489
		.endswitch
width2          = width/2

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
		.if (TARGET!=C128) && (TARGET!=ATARI800)
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
		.default
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
		rts
		.endswitch

                .pend

displaylowinit  .proc
p3              = num
		.if TARGET==ATARI800
                lda $58
                clc
                adc #<(width2*8-8)
                sta p3
                lda $59
                adc #>(width2*8-8)
                sta p3+1
                .else
                #loadw scr, p3
                .fi
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

		.if TARGET==VIC20BIG
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
		.elsif TARGET==ATARI800
		lda p3
                clc
                adc #<(width2*7)
                sta p3
                lda p3+1
                adc #>(width2*7)
                sta p3+1
                .fi

                ldx sor
                inx
leng		cpx #height-1
                bne loop
		rts
                .pend

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
garbagehi	cmp #0
		blt +
		bne ng
garbagelo       cpy #0
                bge ng
+
		.if TARGET==VIC20BIG
                lda p3
                adc #<(width2*16)
                sta p3
                lda p3+1
                adc #>(width2*16)
                sta p3+1
		.elsif TARGET==ATARI800
                lda p3
                adc #width2
                sta p3
                bcc +
                inc p3+1
+
		.else
                lda p3
                adc #<(width2*8)
                sta p3
                lda p3+1
                adc #>(width2*8)
                sta p3+1
                .fi
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
		lda dotline
                cmp lines
                lda dotline+1
                sbc lines+1
                bcc +
                lda #0
                sta ln
                tay
                lda #"-"
                gne er
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

lp
ez              ldy #0
lp2		cpy ln
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
                lda class,x
		adc #0
                sta p2+1

                tya
                iny
		lsr a
                bcs k1
                lda p2
                sta u1+1
                lda p2+1
                sta u1+2
                gcc lp2

k1              sty ez+1
		.if TARGET==C128
                #gfx
                .fi

                ldy #7
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
u1              ora tmpl,y
                sta (p3),y
                dey
                bpl -

		.if TARGET==C128
                #ram
                .fi

		.if TARGET==ATARI800
                lda p3
                ;clc
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
                ;sec
		adc p3
                sta p3
                bcc lp
                inc p3+1
                .fi
                jmp lp

fin
		.if TARGET==C128
                #gfx
                .fi
                tya
                ldy #7
		lsr a
		sta xp
                tax
                bcc b
		inc xp
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
                sta (p3),y
                dey
                bpl -
l2
		.if TARGET==ATARI800
                lda p3
                clc
                adc #<(width2*8-8)
                sta p3
                lda p3+1
                adc #>(width2*8-8)
                sta p3+1
                .fi
l               ldy #7
		.if TARGET==ATARI800
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
		.if TARGET==VIC20BIG
                lda p3
                sbc #<(width2*16)
                sta p2
                lda p3+1
                sbc #>(width2*16)
		.elsif TARGET==ATARI800
                lda p3
                sbc #<(width2-8)
                sta p2
                lda p3+1
                sbc #>(width2-8)
                .else
                lda p3
                sbc #<(width2*8)
                sta p2
                lda p3+1
                sbc #>(width2*8)
                .fi
                tax
cursorcol       lda #0
                sbc leftcol
		tay
		.if TARGET==ATARI800
		lsr a
                clc
                .else
		asl a
		asl a
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
                bcc +
                inx
+
		.if TARGET==ATARI800
                sta cursor.at1+1
                stx cursor.at2+1
                .else
                sta cursor.at1+1
                sta cursor.at2+1
                stx cursor.at1+2
                stx cursor.at2+2
                .fi

                tya
		lsr a
                lda #%11110000
                bcc +
                lda #%00001111
+               ldy tochar.mode+1
                bne +
                and #%11001100
+		sta cursor.k+1

                lda #1
		gne cursor.in

		.if TARGET==ATARI800
class           .byte >(font+2*8*32),>font,>(font+8*32),>(font+3*8*32)
                .byte >(font+2*8*32),>font,>(font+8*32),>(font+3*8*32)
		;.byte >(font+3*8*32),>(font+8*32),>(font+2*8*32),>font
                ;.byte >(font+3*8*32),>(font+8*32),>(font+2*8*32),>font
                .else
class           .byte >font,>(font+8*32),>font,>(font+2*8*32)
		.byte >(font+2*8*32),>(font+3*8*32),>(font+2*8*32),>(font+3*8*32)
                .fi

		.virtual cache
tmpl            .fill 8
cachec          .fill height
cachel          .fill height
cacheh          .fill height
caches		.fill height
		.endv

FONTFILE	= "font4x8.fnt"
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

		.if TARGET==ATARI800
at1             lda #0
                sta screen
at2             lda #0
                sta screen+1
                ldy #0

size            = *+1
		ldx #8
-               lda screen
                sec
                sbc #width2
                sta screen
                bcs +
                dec screen+1
+               lda (screen),y
k               eor #0
                sta (screen),y
                dex
                bne -
                .else
		.if TARGET==C128
                #gfx
                .fi
size            = *+1
                ldx #8
                ldy #7
-
at1		lda scr,y
k               eor #0
at2             sta scr,y
                dey
                dex
                bne -
		.if TARGET==C128
                #ram
                .fi
                .fi
xp		rts
                .pend
