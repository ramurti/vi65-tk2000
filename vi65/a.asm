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

;h; <html><head><title>VI65 text editor home</title>
;h; <style>img {margin:0.5ex} h1, h3, h4 {font-family:sans-serif;} h1, h3 {font-variant:small-caps} body {width:80ex;font-family:serif}</style>
;h; </head><body>
;h; <h1>VI65 text editor</h1>
;h; <p>A VI implementation for 6502 machines.</p>

;h; <p>This is the "manual" of the multi platform VI65 0.3 editor.</p>

;h; <p>The editor (and the documentation) is far from finished, and there are
;h; a lots of bugs. Maybe the next version will be better ;)</p>

;h; <h3>Supported platforms:</h3>

;h; <p>Commodore 64, 128, 16, Plus 4, VIC20 (expanded), PET 40/80.
;h; Atari 8bit, Apple II.
;h; There's a plugin version for the <a href="http://ide64.org">IDE64</a> filemanager too.</p>

;h; <h3>Supported text modes:</h3>

;h; <ul>
;h; <li>C64 - 40/53/64/80x25 (VDC 80x25 on C128)
;h; <li>C128 - 40/53/64/80x25, VDC 80x25
;h; <li>+4 - 40x25, 53/64/80x23
;h; <li>C16 - 40x25
;h; <li>VIC20 - 22x23, 26/35/40x24
;h; <li>PET - 40/80x25
;h; <li>ATARI - 40/53/64/80x24
;h; <li>APPLE II - 40/46/56/80x24
;h; </ul>
;h; <p>Some text modes use custom 4x8, 5x8 and 6x8 charsets on graphic screen.</p>

;h; <h3>Screenshots:</h3>
;h; <a href="pic/c128vdc.png"><img src="pic/c128vdc.png" width=200 border=0 alt="C128 VDC" align="center" title="C128 in VDC 80x25"></a>
;h; <a href="pic/c64.png"><img src="pic/c64.png" width=200 border=0 alt="C64" align="center" title="C64 in 64x25"></a>
;h; <a href="pic/c16.png"><img src="pic/c16.png" width=200 border=0 alt="C16" align="center" title="C16 in 40x25"></a>
;h; <a href="pic/vic20.png"><img src="pic/vic20.png" width=200 border=0 alt="VIC20" align="center" title="VIC20 in 40x22"></a>
;h; <a href="pic/apple.png"><img src="pic/apple.png" width=200 border=0 alt="APPLE II" align="center" title="Apple II in 80x24"></a>
;h; <a href="pic/atari.png"><img src="pic/atari.png" width=200 border=0 alt="ATARI 800" align="center" title="Atari 800 in 53x24"></a>
;h; <a href="pic/pet.png"><img src="pic/pet.png" width=200 border=0 alt="PET" align="center" title="PET in 80x25"></a>
;h; <a href="pic/plus4.png"><img src="pic/plus4.png" width=200 border=0 alt="+4" align="center" title="Plus4 in 80x23"></a>

;h; <h3>Limitations:</h3>

;h; <ul>
;h; <li>251 characters in a line
;h; <li>65535 lines of text (memory runs out faster...)
;h; <li>65535 maximum count
;h; <li>Platform native text format only
;h; <li>Paste register only limited by the amount of memory
;h; <li>No extra memory support yet
;h; <li>Single buffer editing for now
;h; </ul>

;h; <p>The following key description was mostly copied from the
;h; VIM 7.2 manual.</p>

;t; <h3>Download</h3>
;t; <p><a href="vi65_v0.1.zip">VI65 v0.1</a></p>
;t; <p><a href="vi65_v0.2.zip">VI65 v0.2</a></p>
;t; <p><a href="vi65_v0.3.zip">VI65 v0.3</a></p>
;t; <p>That's all for now.</p>
;t; <p>VI65 (C) 2010-2023 Soci/Singular &lt;soci at server c64.rulez.org&gt;</p>
;t; </body></html>

;m; <h3>Motion keys</h3>

;n; <h3>Normal mode keys</h3>

SIMPLE		= false

C16             = 16
C64             = 64
C128            = 128
PLUS4           = 4
VIC20           = 20
VIC20BIG        = 21
PET80           = 8
PET40           = 7
ATARI800        = 800
APPLE2          = 2

PLUGIN          = 65

;TK2000: TARGET=APPLE2 with -DTK=1 (same hi-res screen; keyboard, memory and start differ)
		.weak
TK		= 0
		.endweak

;TARGET          = VIC20BIG
;GFX             = 2

loadw		.segment
                lda #<\1
                sta \2
                lda #>\1
                sta \2+1
                .endm

movew		.segment
                lda \1
                sta \2
                lda \1+1
                sta \2+1
		.endm

pha:		.segment
                lda \@
                pha
                .endm

pla:		.segment
                pla
                sta \@
                .endm

bitjmp		.macro
		.switch (\1)-u
		.case 1
		.byte $24
		.case 2
		.byte $2c
		.default
		jmp \1
		.endswitch
u		.endm

		.virtual {ATARI800: $80, APPLE2: $77, : $11}[TARGET]
zpstart
freehelps       .fill 2           ;free memory list
freehelpd       .fill 2
freehelp        .fill 2
freehelp2       .fill 2

memtop          .fill 2

allocline       .fill 2

currentline     .fill 2

screen          .fill 2

currenttext     .fill 2

;--------------- active buffer -------------
dotstart        .fill 2         ;dot start
lines           .fill 2         ;number of lines
dotline         .fill 2         ;dot line
;--------------- active window -------------
dotpos          .fill 1       	;dot position
activebuf       .fill 1
topline         .fill 2       	;top line
leftcol         .fill 1       	;left column
;-------------------------------------------
repeat          .fill 2
inclusive       .fill 1
linewise        .fill 1
tregister	.fill 1
error           .fill 1
oneless         .fill 1
activewin       .fill 1

num             .fill 3+2
zpend
		.endv

		.switch TARGET
		.case C64, PLUGIN
                *= $801-2

		.if (GFX==1) || (GFX==2) || (GFX==3)
memoryend       = $dc00
                .else
memoryend       = $ff00
                .fi

status          = $90
time            = $a2
keybuffer       = 631
keyrepeatdelay  = 651
drive           = $ba
zpsave          = $02c0
		.if GFX==0
linebuffer      = $ff00
                .else
linebuffer      = $0400
                .fi
virq            = $314
kernal          .macro
                dec $01
                .endm
ram             .macro
                inc $01
                .endm
		.case VIC20BIG
                *= $1201-2

memoryend       = $8000
status          = $90
time            = $a2
keybuffer       = 631
keyrepeatdelay  = 651
drive           = $ba
linebuffer      = $150
virq            = $314
kernal          .macro
                .endm
ram             .macro
                .endm
		.case VIC20
                *= $1001-2

memoryend       = $1e00
status          = $90
time            = $a2
keybuffer       = 631
keyrepeatdelay  = 651
drive           = $ba
linebuffer      = $0150
virq            = $314
kernal          .macro
                .endm
ram             .macro
                .endm
		.case C16
                *= $1001-2

memoryend       = $4000
status          = $90
time            = $a5
keybuffer       = $527
keyrepeatdelay  = 1345
drive           = $ae
linebuffer      = $065e
virq            = $314
kernal          .macro
                .endm
ram             .macro
                .endm
		.case PLUS4
                *= $1001-2

		.if GFX != 0
memoryend       = $e000
                .else
memoryend       = $fd00
                .fi
status          = $90
time            = $a5
keybuffer       = $527
keyrepeatdelay  = 1345
drive           = $ae
linebuffer      = $065e
virq            = $314
kernal          .macro
                sta $ff3e
                .endm
ram             .macro
                sta $ff3f
                .endm
		.case PET40, PET80
                *= $401-2

memoryend       = $8000
status          = $96
time            = $8f
keybuffer       = 623
		.if TARGET==PET80
keyrepeatdelay  = $e5
		.elsif TARGET==PET40
keyrepeatdelay  = 1002
                .fi
drive           = $d4
linebuffer      = $0150
virq            = $90
kernal          .macro
                .endm
ram             .macro
                .endm
		.case C128
                *= $1c01-2

memoryend       = $ff00
status          = $90
time            = $a2
keybuffer       = $34a
keyrepeatdelay  = 2595
drive           = $ba
linebuffer      = $0c00
virq            = $314
kernal          .macro
                sta $ff02
                .endm
ram             .macro
                sta $ff01
                .endm
		.case ATARI800
                *=$0800-6

memoryend       = $bc00
linebuffer      = $0600
time            = $14
keybuffer       = $480-1
virq            = $224
kernal          .macro
                .endm
ram             .macro
                .endm
		.case APPLE2
		.if TK
                *=$4000

memoryend       = $c000         ;the text may use hi-res page 2 ($a000), never shown
		.else
                *=$0c00-4

memoryend       = $bc00
		.fi
linebuffer      = $0900
status          = 2
drive           = 2
kernal          .macro
                .endm
ram             .macro
                .endm
		.endswitch

		.switch TARGET
		.case ATARI800
k_cursorup      = 28
k_cursordown    = 29
k_cursorleft    = 30
k_cursorright   = 31
k_del           = 126
k_return        = 155
k_ins           = 255
k_control       = -128
		.case APPLE2
k_cursordown    = 10
k_cursorup      = 11
k_cursorleft    = 255
k_cursorright   = 21
k_del           = 8
k_return        = 13
k_ins           = 255
		.if TK
k_control	= 96            ;the source is ASCII here: "e"-96 = CTRL-E
		.else
k_control	= 64
		.fi
		.default
k_cursordown    = 17
k_cursorup      = 145
k_cursorleft    = 157
k_cursorright   = 29
k_del           = 20
k_return        = 13
k_ins           = 148
k_control	= 64
		.endswitch

		.switch TARGET
		.case PLUGIN
                *=$1000-2

                .word $1000
                rts
                rts
                rts
                jsr $ffbd
                jmp start
		.case ATARI800
                .word $ffff
                .word *+4
                .word prgend-1
                jmp start
		.case APPLE2
		.if !TK
                .word *+4
                .word prgend-*-2
		.fi
                jmp start
		.default
                .word *+2
                .word ss, 2010
                .null $9e, format("%d", start)
ss              .word 0
		.endswitch

		.if TARGET==VIC20BIG && GFX!=0
		*= $1ff0		;gfxhez!
                .fi

		.switch TARGET
		.case C128
fkeys           .byte $85, $89, $86, $8a, $87, $8b, $88, $8c, $83, $84
		.case PLUS4, C16
fkeys           .byte $85, $86, $87, $89, $8a, $8b, $8c, $88
		.case ATARI800
kbname          .text "K:",k_return
		.endswitch

		.switch TARGET
		.case C64, PLUGIN
nmiram          sec
                .byte $90
irqram          clc
		pha
                pha $01
                lda #$37
                sta $01

		pha #>irq_return
		pha #<irq_return
                pha #$28
                bcs +
                jmp ($fffe)
+               jmp ($fffa)

irq_return      pla $01
                pla
                rti

irq             .proc
                lsr $c6
                bcc +
                ldx waitkey.write+1
                dex
                bpl e
                ldx #8
e               cpx waitkey.read+1
                beq +
                lda keybuffer
                sta keybuffer+1,x
                stx waitkey.write+1
+
old             jmp $ffff
                .pend

		.case VIC20, VIC20BIG

irq             .proc
                lsr $c6
                bcc +
                ldx waitkey.write+1
                dex
                bpl e
                ldx #8
e               cpx waitkey.read+1
                beq +
                lda keybuffer
                sta keybuffer+1,x
                stx waitkey.write+1
+
old             jmp $ffff
                .pend

		.case PET40, PET80

irq             .proc
                lsr $9e
                bcc +
                ldx waitkey.write+1
                dex
                bpl e
                ldx #8
e               cpx waitkey.read+1
                beq +
                lda keybuffer
                sta keybuffer+1,x
                stx waitkey.write+1
+
old             jmp $ffff
                .pend

		.case C128
irq             .proc
                ldx $d2
                lda $100a,x
                lsr $d1
                bcs u
                lsr $d0
                bcc +
                lda keybuffer
u               ldx waitkey.write+1
                dex
                bpl e
                ldx #8
e               cpx waitkey.read+1
                beq +
                sta keybuffer+1,x
                stx waitkey.write+1
+
old             jmp $ffff
                .pend
		.case ATARI800
irq             .proc
                bit critical
                bmi +
                ldx 764
                inx
                beq +
                dex
                lda #255
                sta 764
                txa

                ldx waitkey.write+1
                dex
                bpl e
                ldx #8
e               cpx waitkey.read+1
                beq +
                sta keybuffer+1,x
                stx waitkey.write+1
+
old             jmp $ffff
                .pend
		.case PLUS4, C16
		.if TARGET==PLUS4
irqram          pha
                sta $ff3e

		pha #>irq_return
		pha #<irq_return
                pha #$28
                jmp ($fffe)

irq_return      sta $ff3f
                pla
                rti
                .fi

irq             .proc
                ldx $55e
                lda $567,x
                lsr $55d
                bcs u
                lsr $ef
                bcc +
                lda keybuffer
u               ldx waitkey.write+1
                dex
                bpl e
                ldx #8
e               cpx waitkey.read+1
                beq +
                sta keybuffer+1,x
                stx waitkey.write+1
+
old             jmp $ffff
                .pend

		.endswitch

start
		.if TK
                cld
                ldx #$ff
                txs
		.fi
                ldx #zpend-zpstart-1
-               lda zpstart,x
                sta zpsave,x
                dex
                bpl -
		.switch TARGET
		.case C64, PLUGIN
                #loadw irqram, $fffe
                #loadw nmiram, $fffa
                sei
                #movew virq, irq.old+1
                #loadw irq, virq
                cli
                lda #128
                sta 650
		lda #$37
                sta $01
                lda #>memoryend
                sta alloc.end+1
		.case C128
                sei
                #movew virq, irq.old+1
                #loadw irq, virq
                ldx #9
-               lda #1
                sta $1000,x
                lda fkeys,x
                sta $100a,x
                dex
                bpl -
                stx $d8
                lda #$3f
                sta $d501               ;kernal
                lda #$00
                sta $d502               ;ram
                cli
                sta $ff00
                lda #>memoryend
                sta alloc.end+1
		.case VIC20, VIC20BIG
                lda $38
                sta alloc.end+1
                sei
                ldx #$40
                txs
                #movew virq, irq.old+1
                #loadw irq, virq
                cli
                lda #128
                sta 650
		.case PLUS4, C16
		.if TARGET==C16
                lda $38
                bpl +
                lda #$80
+               sta alloc.end+1
		.elsif TARGET==PLUS4
		.if GFX==0
                lda $38
                sta alloc.end+1
                .fi

                #loadw irqram, $fffe
                .fi
                #kernal
                sei
                #movew virq, irq.old+1
                #loadw irq, virq
                ldx #7
-               lda #1
                sta $55f,x
                lda fkeys,x
                sta $567,x
                dex
                bpl -
                cli
		.case PET40, PET80
                sei
                #movew virq, irq.old+1
                #loadw irq, virq
                cli
                lda $35
                sta alloc.end+1
                ldx #$40
                txs
                lda #14
                jsr $ffd2
		.case ATARI800
                sei
                #movew virq, irq.old+1
                #loadw irq, virq
                cli
                lda $2e6
                sta alloc.end+1
                lda #20
                sta 729                 ;repeat wait
                lda #3
                sta 730                 ;repeat speed
                lda #0
                sta 702                 ;shift lock
                lda #255
                sta 731                 ;noclick
                ldx #$10
                lda #3
                sta iccom,x
                lda #<(kbname)
                sta icba,x
                lda #>(kbname)
                sta icba+1,x
                lda #4
                sta icax1,x
                lda #0
                sta icax2,x
                jsr ciov                ;keyboard
		.case APPLE2
		.if TK
                lda #>memoryend
                sta alloc.end+1
		.else
                lda $74
                sta alloc.end+1
                lda #1
                sta $aab6               ;dos language flag
                sta $76                 ;current line number
                sta $33                 ;prompt char
		.fi
		.endswitch
                dec alloc.end+1
		jsr clearmem

                ;.comment
                .if TARGET!=PLUGIN && !TK
                ldy #7
                cpy #width-3
                blt +
                ldy #width-3
+               sty filename
                iny
-               dey
		lda nu,y
                sta filename+1,y
                tya
                bne -
                jsr load
                jmp +
nu              .text "doc.seq"
+
                .fi
                ;.endc
		.if TARGET==PLUGIN
                ldy $b7
                cpy #width-3
                blt +
                ldy #width-3
+               sty filename
                iny
-               dey
		lda ($bb),y
                sta filename+1,y
                tya
                bne -
                jsr load
+               .else
                lda #0
                sta filename
		.if TK
                jsr notempty            ;no file loaded: start with one empty line
		.fi
                .fi
                jsr displayinit

		.if SIMPLE
                jsr waitkey
-		jsr insertmode
                jsr cmdmode
                jmp -
                .else
kloop2          lsr display.now

                ldx #1
                stx oneless
                stx repeat
                stx waitkeyrepeat.norepeat
                dex
                stx repeat+1
                stx linewise
                ldx #buffers.unnamed
		stx tregister
	        jsr waitkeyrepeat

                sec
                ror error
                ldx #keylookup.normalkeys
                jsr keylookup
                bit error
                bmi kloop2
            ;    dec 1
           ;     inc $d020
          ;      inc 1
                jmp kloop2

motiontry       tya
                ldx #keylookup.motionkeys
                .fi
keylookup       .proc
                tay
                sta j+1
-               inx
		lda keys-1,x
                beq +
j               cmp #0
                bne -
+               txa
		asl a
                tax
		pha keyroutines-1,x
                pha keyroutines-2,x
rrts            rts

keys
                .logical 0
                .if !SIMPLE
normalkeys      .byte "x", "X", "D", "C", "s", "S"
                .byte "y", "p", "P"
                .byte "o", "O"
                .byte "i", k_ins, "I"
                .byte "a", "A"
                .byte "J"
                .byte "d", "g", "z", "c"
                .byte "m"
                .byte "g"-k_control, ":", "/"
                .byte "e"-k_control, "y"-k_control
                .byte "f"-k_control
                .byte "b"-k_control
                .byte 0
                .fi

insertkeys      .byte k_del
                .byte 27, 3
                .byte k_return
                .byte "e"-k_control, "y"-k_control
                .byte 0

motionkeys
                .byte "h"
                .if !SIMPLE
                .byte 8
		.byte "j", 10, 14
                .byte "k", 16
                .byte "l"
                .byte k_del, 32
                .byte "0"
                .byte "f", "t"
                .byte "F", "T"
                .byte "$"
                .byte 94, 169
                .byte "H", "M", "L"
                .byte "G"
                .byte 95, "'"
                .byte "+", k_return
		.byte "-"
		.byte "g"
                .fi
motionkeys2     .byte k_cursordown
                .byte k_cursorup
                .byte k_cursorright
                .byte k_cursorleft
                .byte 19, 147
		.byte 136
                .byte 133
                .byte 0

                .if !SIMPLE
gkeys           .byte "I"
gkeysmotion	.byte "g"
                .byte "m"
                .byte "0", 19
                .byte "$", 147
                .byte 0

zkeys           .byte "h", k_cursorleft
                .byte "l", k_cursorright
                .byte "H", "L"
                .byte "s", "e"
                .byte 0
                .fi

cmdkeys         .byte k_cursorright
                .byte k_cursorleft
                .byte 19, 147
                .byte "b"-k_control, "e"-k_control
		.byte 27, 3
                .byte k_del, k_return
                .byte 0
                .here

keyroutines
                .if !SIMPLE
                .rta kx, kX, kD, kC, ks, kS
                .rta ky, kp, kP
                .rta ko, kO
		.rta insertmode, insertmode, kI
                .rta ka, kA
                .rta kJ
                .rta kd, kg, kz, kc
                .rta motion_m
                .rta ctrlg, cmdmode, searchmode
                .rta scroll_ctrl_e, scroll_ctrl_y
                .rta scroll_ctrl_f
                .rta scroll_ctrl_b
                .rta motiontry
                .fi

                .rta kX
                .rta insertmode.exit, insertmode.exit
                .rta insertmode.kreturn
                .rta insert_ctrl_e, insert_ctrl_y
                .rta insertmode.put

                .rta motion_h
                .if !SIMPLE
                .rta motion_h
                .rta motion_j, motion_j, motion_j
                .rta motion_k, motion_k
                .rta motion_l
                .rta motion_backspace, motion_space
                .rta motion_0
                .rta motion_f, motion_t
                .rta motion_F, motion_T
                .rta motion_dollar
                .rta motion_uparrow, motion_bar
                .rta motion_H, motion_M, motion_L
                .rta motion_G
                .rta motion_backtick, motion_tick
                .rta motion_plus, motion_plus
		.rta motion_minus
		.rta motion_g
                .fi
                .rta motion_j
                .rta motion_k
                .if SIMPLE
                .rta motion_space
                .rta motion_backspace
                .else
                .rta motion_l
                .rta motion_h
                .fi
                .rta motion_0, motion_dollar
                .rta scroll_ctrl_f
                .rta scroll_ctrl_b
                .rta rrts

                .if !SIMPLE
		.rta kgI
		.rta motion_gg
                .rta motion_gm
                .rta motion_g0, motion_g0
                .rta motion_gdollar, motion_gdollar
                .rta rrts

                .rta scroll_zh, scroll_zh
                .rta scroll_zl, scroll_zl
                .rta scroll_zH, scroll_zL
                .rta scroll_zs, scroll_ze
                .rta rrts
                .fi

                .rta motion_l
                .rta cmd_h
                .rta cmd_0, motion_dollar
                .rta cmd_0, motion_dollar
                .rta cmd_exit, cmd_exit
                .rta cmd_X, cmd_return
                .rta cmd_put
                .pend

waitkey         .proc
-
		.if TK
                jsr tkget
                bcs +
                jsr display
                jsr cursorup
                jmp -
+
		.elsif TARGET==APPLE2
                lda $c000
                bmi +
                jsr display
                jsr cursorup
                jmp -

+               and #$7f
                sta $c010
                .else
read            ldx #0
write           cpx #0
                bne +
                jsr display
                jsr cursorup
                jmp -

+               dex
                bpl +
                ldx #8
+               lda keybuffer+1,x
                stx read+1
                .fi
		.if TARGET==ATARI800
                sec
                ror critical
                sta 764
                ldx #$10
                lda #7
                sta iccom,x
                lda #<(ej+1)
                sta icba,x
                lda #>(ej+1)
                sta icba+1,x
                lda #1
                sta icbl,x
		lsr a
                sta icbl+1,x
                jsr ciov
                lsr critical
ej              lda #0
                .fi
                pha
                jsr cursoroff

		.if TARGET!=ATARI800 && TARGET!=APPLE2
                lda keyrepeatdelay
		lsr a
                beq +
                lda #2
                sta keyrepeatdelay
+
                .fi
                pla
                rts
                .pend

cursorup        .proc
		.if TARGET==APPLE2
                lda #0
                inc *-1
                bne +
                .else
                lda time
                and #$f0
cp              cmp #0
                beq +
                sta cp+1
                .fi
                jmp cursor
+               rts
                .pend

                .if !SIMPLE
waitkeyrepeat   .proc
		jsr waitkey
                cmp #"1"
                blt ik
                cmp #"9"+1
                blt +
ik              rts

+               and #15
		ldx repeat+1
                stx a2+1
                ldx repeat
                stx a1+1
		ldx #0
                stx repeat+1
                stx norepeat
-               sta repeat
                jsr waitkey
                cmp #"0"
                blt ik2
                cmp #"9"+1
                bge ik2
                and #15
                pha
                ldx #10
                jsr mulrepeatl
                pla
                clc
                adc repeat
                bcc -
                inc repeat+1
                bne -
                lda #255
                sta repeat+1
                gne -

ik2             pha
a1              ldx #0
a2              lda #0
		jsr mulrepeat
                pla
                rts

norepeat        .byte 1
                .pend
                .fi

display         .proc
now             = *+1
                lda #0
                beq +
                lda loading
                bne load.part
                geq garbageone
+
                jsr cursoroff
                jsr displaylowinit
                inc now

                pha activewin
                sta oa+1

                lda #windows.main
                jsr doit
                lda #windows.status
                jsr doit

                lda #255
                sta paintone.garbagehi+1

                pla
                jmp selectwin

doit            jsr selectwin

                ldx #marks.cursor
                jsr setmark

                jsr normcolumn
                pha
		sec
                sbc leftcol
                blt +
                cmp #width
                blt ok
+               pla
                pha
                sec
                sbc #width/2
                bcs +
                lda #0
+               sta leftcol

ok              lda dotline
                sec
                sbc topline
                tax
                lda dotline+1
                sbc topline+1
                blt +
                cpx #height-1
                sbc #0
                blt ok2
+               lda dotline
                sec
                sbc #height/2
                tax
                lda dotline+1
                sbc #0
                bcs +
                lda #0
                tax
+               sta topline+1
                stx topline
ok2
                ldx topline
                lda topline+1
                jsr toline

                .comment
                lda tochar.mode+1
                beq +
                ldx line
                lda line+1
                ldy #0
                jsr ctrlg.tst
                lda #"-"
                sta linebuffer+1,y
                iny
                ldx lines
                lda lines+1
                jsr ctrlg.tst
                lda #"-"
                sta linebuffer+1,y
                iny
                sty t+1
                ldy #2
                lda (dotstart),y
                tax
                iny
                lda (dotstart),y
t               ldy #0
                jsr ctrlg.tst
                lda #"-"
                sta linebuffer+1,y
                iny
                ldx dotstart
                lda dotstart+1
                jsr ctrlg.tst
                lda #"-"
                sta linebuffer+1,y
                iny
                sty t2+1
                ldy #0
                lda (dotstart),y
                tax
                iny
                lda (dotstart),y
t2              ldy #0
                jsr ctrlg.tst
+
                ;lda #"-"
                ;sta linebuffer+1,y
                ;iny
                ;ldx line0
                ;lda line0+1
                ;jsr ctrlg.tst
                .endc
                pla
oa              ldx #0
                ldy activewin
		jsr displaylow
                ldy #marks.cursor
                jmp tomark
                .pend

normcolumn      .proc                   ;C=1 if last char or over
		lda dotpos
		#bitjmp normcolumn2
		.pend

normcolumn2     .proc
		ldy #4
                cmp (dotstart),y
                blt +
                lda (dotstart),y
                beq +
                sbc oneless
+               rts
                .pend

kg              .proc
                jsr waitkey
                ldx #keylookup.gkeys
                jmp keylookup
                .pend

;n; <h4>gI</h4>

;n; Insert text in column 1.

kgI             .proc
		jsr motion_0
                jmp insertmode
                .pend

;n; <h4>c{motion}</h4>

;n; Delete {motion} text <!--[into register x]--> and start
;n; insert.

kc              .proc
		lsr cursor.size
		jsr waitkeyrepeat
                asl cursor.size
		#bitjmp kC.in
		.pend
;n; <h4>C</h4>

;n; Delete from the cursor position to the end of the
;n; line and [count]-1 more lines <!--[into register x]-->, and
;n; start insert. Synonym for c$

kC              .proc
                lda #"$"
in		#bitjmp ks.in
		.pend
;n; <h4>s</h4>

;n; Delete [count] characters <!--[into register x]--> and start
;n; insert (s stands for Substitute).  Synonym for "cl"

ks              .proc
                lda #"l"
in		#bitjmp kS.in
		.pend
;n; <h4>S</h4>

;n; Delete [count] lines <!--[into register x]--> and start
;n; insert.  Synonym for "cc" linewise.

kS              .proc
                lda #"c"
in
                lsr cursor.size
		cmp #"c"
                jsr kd.in
                asl cursor.size
                lda linewise
                bne kO
                geq insertmode
                .pend

;n; <h4>y{motion}</h4>

;n; Yank {motion} text <!--[into register x]-->.

ky              .proc
                pha dotpos
                lsr cursor.size
		jsr waitkeyrepeat
                cmp #"y"
                jsr kd.in
                asl cursor.size
                ldx #1
                stx repeat
                dex
                stx repeat+1
                jsr kP
                pla
                jmp tochar
                .pend

;n; <h4>d{motion}</h4>

;n; Delete text that {motion} moves over <!--[into register
;n; x]-->.

kd              .proc
                lsr cursor.size
		jsr waitkeyrepeat
                cmp #"d"
                jsr in
                asl cursor.size
                lda dotpos
                jmp tochar

in              bne +
                lda #0
                jsr sbcrepeat
                lda #"j"

+		#bitjmp kD.in
                .pend
;n; <h4>D</h4>

;n; Delete the characters under the cursor until the end
;n; of the line and [count]-1 more lines <!--[into register
;n; x];--> synonym for "d$".

kD              .proc
                lda #"$"
in		#bitjmp kx.in
		.pend
;n; <h4>x</h4>

;n; Delete [count] characters under and after the cursor
;n; <!--[into register x]--> (not linewise).  Does the same as
;n; "dl".

kx              .proc
                lda #"l"
in		#bitjmp kX.in
		.pend
;n; <h4>X</h4>

;n; Delete [count] characters before the cursor <!--[into
;n; register x]--> (not linewise).  Does the same as "dh".

kX              .proc
refstart        = num
refend          = num+1
morelines       = num+2

                lda #"h"
in		pha
                lda #0
                sta inclusive
                sta linewise
                jsr normcolumn
                sta dotpos
                ldx #marks.start
                jsr setmark
                ldx #references.end
                jsr refbefore
                ldx #references.start
                jsr refafter
                pla
                lsr oneless
                php
                ldx #keylookup.motionkeys
                jsr keylookup
                plp
                rol oneless
                ldx #marks.end
                jsr setmark
                lda #references.end
                jsr refsetup

                lda marks.line+marks.start
                eor dotline
                bne +
                lda marks.line+1+marks.start
                eor dotline+1
+               cmp #1
                ror morelines

                lda dotpos
                cmp marks.pos+marks.start
                lda dotline
                sbc marks.line+marks.start
                lda dotline+1
                sbc marks.line+1+marks.start
                lda linewise
                bge +
                bne lw1
                bit morelines
                bpl ej
                jsr refswaped
ej              lda refstart
                jsr rerefbefore
                jmp lw2

lw1             lda refstart
                jsr rerefafter
                ldx refend
                jsr reftocursor
lw2             ldx #marks.start
                ldy #marks.end
                jsr swapmark
                jmp i
+
                bne lw3
                lda refend
                bit morelines
                bpl ej2
                jsr refswaped
                clc
                adc #2
ej2             pha
		lda refend
                jsr rerefafter
                pla
                tax
                jmp lw4

lw3             lda refend
                jsr rerefbefore
                ldx refend
lw4             jsr reftocursor
		lda marks.line+marks.start
                sta dotline
                lda marks.line+1+marks.start
                sta dotline+1
i
                lda marks.pos+marks.start
                sta dotpos

                pha activebuf
		lda tregister
                jsr selectbuf
                jsr freebuf

		ldx #references.insert
                jsr refbefore

                pla
                jsr selectbuf

		ldx tregister
                lda linewise
                sta buffers.linewise,x
                sec
                bne linew

                bit morelines
                bmi max

		lda marks.pos+marks.end
                sec
                sbc dotpos
                clc
                adc inclusive
                blt +
max             lda #255
+               sta repeat

                jsr cutchars

                clc
linew           lda marks.line+marks.end
                sbc marks.line+marks.start
                sta repeat
                lda marks.line+1+marks.end
                sbc marks.line+1+marks.start
                bge +
                lda #0
                sta repeat
+               sta repeat+1
                ldx linewise
                beq +
                inc repeat
                bne +
		inc repeat+1
+
		ldx tregister
                lda buffers.lines,x
                clc
                adc repeat
                sta buffers.lines,x
                lda buffers.lines+1,x
                adc repeat+1
                sta buffers.lines+1,x

                ldy #references.insert
                ldx refstart
                jsr borona
                ldy refend
                ldx #references.insert
                jsr borona
                ldy refstart
                ldx refend
                jsr borona
j
                lda lines
                sec
                sbc repeat
                sta lines
                lda lines+1
                sbc repeat+1
                sta lines+1

                ldx #endmarks-marks
-               ldy marks-3,x
                cpy dotline
                lda marks-2,x
                sbc dotline+1
                blt +                   ;before, not moved
                tya
                sbc repeat
                sta marks-3,x
                tay
                lda marks-2,x
                sbc repeat+1
                sta marks-2,x
                blt b                   ;lost...
                cpy dotline
                sbc dotline+1
                bge +                   ;after, adjusted
b               lda #255
                sta marks-1,x
+               dex
                dex
                dex
                bne -

		jsr notempty

                lda linewise
                beq +
                jmp motion_uparrow
+
                bit morelines
                bmi +
                rts
+
		lda marks.pos+marks.end
                clc
                adc inclusive
                blt +
                lda #255
+               sta repeat

                lda #0
                sta dotpos
                jmp cutchars


refswaped       lda #references.start
refsetup        sta refend
                eor #references.end^references.start
                sta refstart
tul             rts

cutchars
                ldy #4
                lda (dotstart),y
                sec
                sbc dotpos
                blt tul
                beq tul
                cmp repeat
                bge +
                sta repeat
+
                lda repeat
                jsr alloc
                bcs +
		lda tregister
                clc
                adc #buffers-references
                tax
                jsr append_buff2
                lda dotpos
                ldx repeat
                ldy #4
                jsr currenttoalloc2

+               ldy #4
		lda (dotstart),y
                sec
                sbc repeat
		jsr linemod2
                bcs ur

                ldy #4
                lda (allocline),y
                pha
                lda #0
                ldx dotpos
                jsr currenttoalloc2
                pla
                sec
                sbc dotpos
                tax
                lda repeat
                jsr currenttoalloc2
                jmp setdottoalloc

ur              rts

                .pend
;n; <h4>O</h4>

;n; Begin a new line above the cursor and insert text

ko              .proc
                jsr dotnext
		#bitjmp kO
		.pend
;n; <h4>o</h4>

;n; Begin a new line below the cursor and insert text

kO              .proc
                lda #0
                jsr append_help
                jsr insert_help
                jmp insertmode
                .pend

;n; <h4>p</h4>

;n; Put the text <!--[from register x]--> after the cursor
;n; [count] times.

kp              .proc
		ldy tregister
                lda buffers.linewise,y
                beq +
                jsr dotnext
                jmp kP

+		inc dotpos
		#bitjmp kP
		.pend

;n; <h4>P</h4>

;n; Put the text <!--[from register x]--> before the cursor
;n; [count] times.

kP              .proc

		ldy tregister
                lda buffers.linewise,y
                bne nl
        	lda buffers.prev,y
                ldx buffers.prev+1,y
                sta currenttext
                stx currenttext+1
                ldy #4
                lda (currenttext),y
                clc
                adc dotpos
                pha
                jsr inserttext
                pla
                bcc +
                rts
+               sbc #1-1
		jmp tochar
nl
                jsr doit
                jsr insert_help
                jmp motion_uparrow

doit            ldx #marks.start
                jsr setmark

                pha activebuf
		lda tregister
                jsr selectbuf
lp
		lda lines
                eor #255
                sta screen
                lda lines+1
                eor #255
                sta screen+1
                jmp +

-               ldy #4
		lda (dotstart),y
                jsr append_help
                bcs ejj
                jsr copy_cursor_to_alloc
+               jsr dotnext

                inc screen
                bne -
                inc screen+1
                bne -

                lda repeat
                bne +
                dec repeat+1
+               dec repeat
                bne lp
                lda repeat+1
                bne lp
ejj
                pla
                jmp selectbuf
                .pend

insert_help     .proc
                ldx #references.insert
                jsr refafter

                pha activebuf
                lda #buffers.help
                jsr selectbuf
                ldx #references.start
                jsr refbefore
                ldx #references.end
                jsr refafter
                pla
                jsr selectbuf

                ldy #references.insert
                ldx #references.start
                jsr borona
                ldy #references.end
                ldx #references.insert
                jsr borona
                ldy #references.start
                ldx #references.end
                jsr borona

                ldx #references.start
                jsr reftocursor

                ldx #endmarks-marks
-               lda dotline
                clc
                sbc marks-3,x
                lda dotline+1
                sbc marks-2,x
                bge +                   ;before, ok
                lda marks-3,x
                adc buffers.lines+buffers.help
                sta marks-3,x
                lda marks-2,x           ;adjust
                adc buffers.lines+1+buffers.help
                sta marks-2,x
+               dex
                dex
                dex
                bne -

                lda lines
                clc
                adc buffers.lines+buffers.help
                sta lines
                lda lines+1
                adc buffers.lines+1+buffers.help
                sta lines+1
                stx buffers.lines+buffers.help
                stx buffers.lines+1+buffers.help
                rts
                .pend

append_help	.proc
                jsr alloc
                bcs append_buff.e
		ldx #buffers.help+buffers-references
		#bitjmp append_buff2
		.pend

append_buff2    .proc
                inc buffers.lines-(buffers-references),x
                bne +
                inc buffers.lines+1-(buffers-references),x
+
		#bitjmp append_buff
		.pend

append_buff     .proc
		ldy #3
                lda references.prev+1,x
                sta currentline+1
                sta (allocline),y
                dey
                lda references.prev,x
                sta currentline
                sta (allocline),y
                dey
                lda (currentline),y
                sta (allocline),y
                lda allocline+1
                sta references.prev+1,x
                sta (currentline),y
                dey
                lda (currentline),y
                sta (allocline),y
                lda allocline
                sta references.prev,x
                sta (currentline),y
e               rts
                .pend

copy_cursor_to_alloc .proc
                ldy #4
                lda (dotstart),y
                beq e
                tax
-               iny
                lda (dotstart),y
                sta (allocline),y
                dex
                bne -
e               rts
                .pend

;n; <h4>J</h4>

;n; Join 2 lines.

kJ		.proc
		jsr islastline
		beq j
		ldy #1
                lda (dotstart),y
		sta currentline+1
                dey
                lda (dotstart),y
                sta currentline
                ldy #4
                clc
                lda (dotstart),y
                beq +
                adc #4
                tay
                lda (dotstart),y
                ldy #4
                eor #32
                beq +
                lda #1
+               sta ej+1
		lsr a
                lda (dotstart),y
		adc (currentline),y
                bcs j
                jsr linemod
                bcc +
j               rts

+               ldy #4
                lda (currentline),y
                sta u+1
                pha
                iny
                tax
                beq +
-               lda (currentline),y
                sta (allocline),y
                iny
		dex
                bne -
+               lda ej+1
                beq +
                lda #32
                sta (allocline),y
+
                ldy #1
                lda (allocline),y
                sta currentline+1
                dey
                lda (allocline),y
                sta currentline
                lda (currentline),y
                sta (allocline),y
                iny
                lda (currentline),y
                sta (allocline),y
                ldy #3
                lda #1
                sta (currentline),y
                pla
                clc
ej              adc #0
                adc allocline
                sta allocline
                bcc +
                inc allocline+1
+               ldy #4
                lda (currentline),y
                iny
                tax
                beq +

-               lda (currentline),y
                sta (allocline),y
                iny
                dex
                bne -

+               ldy #1
                lda (dotstart),y
                sta currentline+1
                dey
                lda (dotstart),y
                sta currentline
                ldy #3
                lda dotstart+1
                sta (currentline),y
                dey
                lda dotstart
                sta (currentline),y

		lda lines
		bne +
		dec lines+1
+		dec lines

                ldx #endmarks-marks
-		ldy marks-3,x
                lda marks-2,x
		cmp dotline+1
		bne +
		cpy dotline
+		blt +			;before, not moved
		beq +			;same not moved
		cpy #1
		dey
		sbc #0
		dec marks-3,x
		sta marks-2,x
		cpy dotline		;after, adjusted
		bne +
                sbc dotline+1
		bne +			;after, adjusted
b		lda #255
		sta marks-1,x
+               dex
                dex
                dex
                bne -

u		lda #0
		jmp tochar
                .pend

split           .proc
                ldy #4
                lda (dotstart),y
                sec
                sbc dotpos
                jsr alloc
                bcs baj
                ldy #1
                lda #0
                sta (allocline),y
                iny
                lda #<fakelist
                sta (allocline),y
                iny
                lda #>fakelist
                sta (allocline),y
                lda allocline
                sta fakelist
                lda allocline+1
                sta fakelist+1

                lda dotpos
        	jsr linemod
                lda fakelist
                sta allocline
                lda fakelist+1
                sta allocline+1
                bcc +
                ldy #3
                lda #1
                sta (allocline),y
baj             rts

+               inc lines
                bne +
                inc lines+1
+               ldx dotpos
                beq +
                ldy #4
-               iny
                lda (currentline),y
                sta (dotstart),y
                dex
                bne -
+
                ldy #4
                lda (allocline),y
                beq +
                tax

                lda currentline
                clc
                adc dotpos
                sta currentline
                bcc e
                inc currentline+1
e

-               iny
                lda (currentline),y
                sta (allocline),y
                dex
                bne -
+
                ldy #0
                lda (dotstart),y
                sta (allocline),y
                sta currentline
                lda allocline
                sta (dotstart),y
                iny
                lda (dotstart),y
                sta (allocline),y
                sta currentline+1
                lda allocline+1
                sta (dotstart),y
                iny
                lda dotstart
                sta (allocline),y
                iny
                lda dotstart+1
                sta (allocline),y

                lda allocline+1
                sta (currentline),y
                dey
                lda allocline
                sta (currentline),y
                clc
                rts
                .pend

fakelist        .word 0

alloc           .proc
                pha
                clc
                adc #5
                bcs +
                adc memtop
                tay
                lda memtop+1
                adc #0
end             cmp #>memoryend
                blt fits
                jsr garbage
                jsr garbage
+               pla
                bcc alloc
                lda #statusmsg.nomem
                jsr setstatusmsg
                sec
                rts

fits            ldx memtop
                stx allocline
                ldx memtop+1
                stx allocline+1

		sta memtop+1
                sty memtop
                ldy #4
                pla (allocline),y   ;size
                ;clc
                rts
                .pend

garbage         .proc
-               jsr garbageone
                bne -
                rts
		.pend

garbageone      .proc
		lda freehelps
                cmp memtop
                lda freehelps+1
                sbc memtop+1
                bcc +
                lda freehelpd+1
                beq baj
                sta memtop+1
                lda freehelpd
                sta memtop
                clc
baj
                lda #<memory
                sta freehelps
                lda #>memory
                sta freehelps+1
                lda #0
                sta freehelpd+1
		rts

+               ldy #3
                lda (freehelps),y
                cmp #1
                beq free
                ldx freehelpd+1
                beq skip

                sta freehelp+1
                dey
                lda (freehelps),y
                sta freehelp
                dey
                lda (freehelps),y
                sta freehelp2+1
                txa
                sta (freehelp),y
                dey
                lda (freehelps),y
                sta freehelp2
                lda freehelpd
                sta (freehelp),y        ;prev link to free space
                ldy #2
                sta (freehelp2),y        ;next link to free space
                iny
                txa
                sta (freehelp2),y

                iny
                tya
                sec
                adc (freehelps),y
		lsr a
                tax

		lda freehelps
                eor dotstart
                bne +
                lda freehelps+1
                eor dotstart+1
                bne +
                #movew freehelpd, dotstart
+               ldy #0
-               lda (freehelps),y
                sta (freehelpd),y
                iny
                lda (freehelps),y
                sta (freehelpd),y
                iny
                dex
                bne -
                bcc +
                lda (freehelps),y
                sta (freehelpd),y
                iny
                clc
+               tya
                adc freehelpd
                sta freehelpd
                tya
                bcc n
                clc
                inc freehelpd+1
                gcc n

free            lda freehelpd+1
                bne skip
                lda freehelps
                sta freehelpd
                sta paintone.garbagelo+1
                lda freehelps+1
                sta freehelpd+1
                sta paintone.garbagehi+1
skip		ldy #4
                tya
                sec
                adc (freehelps),y
n               adc freehelps
                sta freehelps
                bcc +
                inc freehelps+1
+               ora #1          ;z=1
		rts
                .pend
; CTRL-G
;
; free memory

ctrlg           .proc
;		 lda activebuf
;		 eor #buffers.file^buffers.unnamed
;		 jmp selectbuf

                jsr garbage
                ldy #0
-               lda freetxt,y
                sta linebuffer+1,y
                iny
                cpy #5
                blt -
                lda #0
                sec
                sbc memtop
                tax
                lda alloc.end+1
                sbc memtop+1
                jsr tst
                ldx #<(linebuffer-4)
                lda #>(linebuffer-4)
                jmp setstatus

tst             jsr konv
                ldx #253
-               lda num+3,x
                jsr hex
                inx
                bne -
                lda hex.e+1
                bne +
                iny
+               sty linebuffer
                rts

konv            stx num+3
                sta num+4
                lda #0
                sta num
                sta num+1
                sta num+2
                sta hex.e+1
		php
                sei
                sed
                sec

-               rol num+3
                rol num+4
                bne +
                lda num+3
                bne +
                plp
                rts

+               ldx #2
-               lda num,x
                adc num,x
                sta num,x
                dex
                bpl -
                gmi --

freetxt         .text "free:"
                .pend

hex             .proc
                pha
		lsr a
		lsr a
		lsr a
		lsr a
                jsr o
                pla
o               and #15
                cmp #10
                blt +
                adc #$26
+
		eor #$30
		sta linebuffer+1,y
		eor #$30
e               ora #0
                beq +
		sta e+1
                iny
+               rts
                .pend

clearmem        .proc
                #ram
                lda #0
                sta paintone.garbagehi+1
                ldx #endmarks-marks
                lda #255
-               sta marks,x
                dex
                bpl -
                stx activebuf
                stx activewin
                jsr garbageone.baj
		#loadw memory, memtop

                jsr newbuf
                inc lines
                lda #buffers.status
                sta activebuf
                jsr setbuf

                jsr newwin
                lda #windows.status
                sta activewin
                jsr setwin

                jsr newbuf
                lda #buffers.unnamed
                sta activebuf
                jsr setbuf

                jsr newbuf
                lda #buffers.help
                sta activebuf
                jsr setbuf

                jsr newbuf
                lda #buffers.file
                sta activebuf

                jsr newwin
                lda #windows.main
                sta activewin
                rts
                .pend

newwin          .proc
                lda #0
                sta dotpos
                sta topline
                sta topline+1
                sta leftcol
                rts
		.pend

selectwin       .proc
                cmp activewin
                beq +
                jsr setwin

                ldy activewin
                lda windows.buffer,y
                jsr selectbuf

                ldy activewin
                lda windows.topline,y
                sta topline
                lda windows.topline+1,y
                sta topline+1
                lda windows.leftcol,y
                sta leftcol
                lda windows.pos,y
                sta dotpos
                ldx windows.line,y
                lda windows.line+1,y
                jmp toline
+               rts
                .pend

setwin          .proc
                ldy activewin
                sta activewin

                lda activebuf
                sta windows.buffer,y
                lda topline
                sta windows.topline,y
                lda topline+1
                sta windows.topline+1,y
                lda leftcol
                sta windows.leftcol,y
                lda dotline
                sta windows.line,y
                lda dotline+1
                sta windows.line+1,y
                lda dotpos
                sta windows.pos,y
                rts
                .pend

freebuf         .proc
                jmp +

-               sta dotstart
                stx dotstart+1
+       	ldy #3
                lda (dotstart),y
                tax
                lda #1
                sta (dotstart),y
                dey
                lda (dotstart),y
                cpx #1
                bne -
                lda activebuf
		#bitjmp newbuf
		.pend

newbuf          .proc
                lda #0
                jsr alloc
                ldy #0
                sty dotline
                sty dotline+1
                sty lines
                sty lines+1
                lda allocline
                sta dotstart
                sta (allocline),y
                ldy #2
                sta (allocline),y
                lda allocline+1
                sta dotstart+1
                dey ;1
                sta (allocline),y
                ldy #3
                sta (allocline),y
                rts
                .pend

selectbuf       .proc
                cmp activebuf
                beq +
                jsr setbuf

                lda activebuf
                tay
                clc
                adc #buffers-references
                tax
                lda buffers.refline,y
                sta dotline
                lda buffers.refline+1,y
                sta dotline+1
                lda buffers.lines,y
                sta lines
                lda buffers.lines+1,y
                sta lines+1
                jsr reftocursor
                txa
                jmp deleteref
+               rts
                .pend

setbuf          .proc
                ldy activebuf
                sta activebuf
                tya
                clc
                adc #buffers-references
                tax
                lda dotline
                sta buffers.refline,y
                lda dotline+1
                sta buffers.refline+1,y
                lda lines
                sta buffers.lines,y
                lda lines+1
                sta buffers.lines+1,y
                jmp refafter
                .pend

notempty	.proc
		lda lines
		ora lines+1
		beq +			; can't have 0 lines
		rts
+					;lda #0
                jsr append_help
		jmp insert_help
		.pend

statusmsg       .proc
		.logical 0
noname          .ptext "-- no file name --"
nomem           .ptext "-- out of memory --"
noline          .ptext "-- empty --"
insert          .ptext "-- insert --"
notfound        .ptext "-- not found --"
notcmd          .ptext "-- not a command --"
ioerr           .ptext "-- i/o error --"
banner          .ptext "vi65 0.3 soci/singular"
                .here
                .pend

setstatusmsg    .proc
                clc
                adc #<(statusmsg-4)
                tax
                lda #>(statusmsg-4)
                adc #0
		#bitjmp setstatus
		.pend

setstatus       .proc
                stx currenttext
                sta currenttext+1
                pha activewin
                lda #windows.status
                jsr selectwin

                ldy #4
                lda (currenttext),y
                pha
                inc alloc.end+1
                jsr linemod
                dec alloc.end+1
                pla
                bcs +
                beq +
                tax
                ldy #5
-               lda (currenttext),y
                sta (dotstart),y
                iny
                dex
                bne -

+               pla
                jmp selectwin
		.pend

load            .proc
                jsr checkname
		.if TK                  ;TK2000: no files yet
                lda #statusmsg.ioerr
                jmp setstatusmsg
		.fi
                jsr freebuf
                lda #0
                sta dotpos
                sta topline
                sta topline+1
                ldx #references.load
                jsr refbefore
		.if TARGET==ATARI800
                lda #4
                jsr open
		.elsif TARGET==APPLE2
                lda #255
                sta $d8                 ;onerr flag
                lda #<nomem
                sta $9d5a
                lda #>nomem
                sta $9d5b
                tsx
                stx oldsp+1
                lda #close.rd
                jsr open
                .else
                #kernal
                ldy #0
                jsr open
                ldx #1
                jsr chkin
                #ram
		bcs failed
                .fi
                lda #1
                sta loading

		.if TARGET!=ATARI800 && TARGET!=APPLE2
                ldx #k_return
                lda filename+1
                cmp #"$"
                bne +
                #kernal
                jsr chrin
                jsr chrin
                #ram
                ldx #0
+               stx eol+1
                .fi

part

loop		.if TARGET==ATARI800
                ldx #$20
                lda #5
                sta iccom,x
                lda #<(linebuffer+1)
                sta icba,x
                lda #>(linebuffer+1)
                sta icba+1,x
                lda #255
                sta icbl,x
                lda #0
                sta icbl+1,x
                jsr ciov                ;input
                bmi nomem
                ldx icbl+$20
                dex
		.elsif TARGET==APPLE2
                ldx #0
-               jsr moncin
                and #$7f
                cmp #k_return
                beq +
                sta linebuffer+1,x
                inx
                cpx #250
                blt -
+
                .else
                ldx #0
                lda filename+1
                cmp #"$"
                bne ndir
                #kernal
                jsr chrin
                jsr chrin
                jsr chrin
                tax
                jsr chrin
                #ram
                ldy #0
		jsr ctrlg.tst
                lda status
                bne nomem
                lda #32
                sta linebuffer+1,y
                iny
                tya
                tax
                #kernal
                jsr chrin
                #ram
                cmp #32
                bge eol
ndir
-               #kernal
		jsr chrin
                #ram
eol             cmp #k_return
                beq +
                sta linebuffer+1,x
                inx
                cpx #250
                bge +
                lda status
                beq -
                eor #$40
                beq +
                dex
                beq nomem
+
		.fi

		stx linebuffer
                txa
                jsr alloc
                bcs +
		lda lines
		ora lines+1
		bne o2
		#movew allocline, dotstart
o2
                inc lines
                bne o
                inc lines+1
o
                ldx #references.load
                jsr append_buff

		ldy #4
                ldx linebuffer-4,y
                beq +
-               iny
                lda linebuffer-4,y
                sta (allocline),y
                dex
		bne -

+
		.if TARGET==ATARI800 || TARGET==APPLE2
                bcc j
                .else
                bcs nomem
                lda status
                beq j
                .fi

nomem
		.if TARGET==APPLE2
oldsp           ldx #0
                txs
                .fi
failed
		jsr close

		.if TARGET!=ATARI800 && TARGET!=APPLE2
                lda status
                and #$bf
                beq +
                lda #statusmsg.ioerr
                jsr setstatusmsg
+
                .fi

                lda #references.load
                jsr deleteref
                lda #0
                sta loading
                geq +

j
		.if TARGET==APPLE2
                lda $c000
                bmi +
                .else
		lda waitkey.read+1
                eor waitkey.write+1
                bne +
                .fi
                jsr cursorup
                lda topline
                clc
                adc #height
                eor lines
                bne loop
                lda topline+1
                adc #0
                eor lines+1
                bne loop
+               lsr display.now

		jmp notempty
		.pend

loading         .byte 0

checkname       .proc
                lda filename
                bne +
                pla
                pla
                lda #statusmsg.noname
                jmp setstatusmsg
+               rts
                .pend

save            .proc
                jsr checkname
		.if TK                  ;TK2000: no files yet
                lda #statusmsg.ioerr
                jmp setstatusmsg
		.fi
		.if TARGET==ATARI800
                lda #8
                jsr open
		.elsif TARGET==APPLE2
                lda #255
                sta $d8                 ;onerr flag
                lda #<ki
                sta $9d5a
                lda #>ki
                sta $9d5b
                tsx
                stx oldsp+1
                lda #close.wr
                jsr open
                .else
                #kernal
                ldy #1
                jsr open
                ldx #1
                jsr chkout
		#ram
		bcs failed
                .fi

                lda dotline
                sta old1+1
                lda dotline+1
                sta old2+1

                clc
                jsr tolinesub
                lda lines
                ora lines+1
                beq ki

loop
		.if TARGET==ATARI800
                ldx #$20
                lda #9
                sta iccom,x
                lda dotstart
                clc
                adc #5
                sta icba,x
                lda dotstart+1
                adc #0
                sta icba+1,x
                ldy #4
                lda (dotstart),y
                bne +
                lda #11
                sta iccom,x
                lda #<(kbname+2)
                sta icba,x
                lda #>(kbname+2)
                sta icba+1,x
                lda #1
+               sta icbl,x
		lda #0
                sta icbl+1,x
                jsr ciov                ;output
		.elsif TARGET==APPLE2
		ldy #4
                lda (dotstart),y
                beq +
                tax
-               iny
                lda (dotstart),y
                eor #$80
                cmp #$84
                beq +
                jsr moncout
+               dex
                bne -
+               lda #k_return^$80
                jsr moncout
                .else
		ldy #4
                lda (dotstart),y
                beq +
                tax
-               iny
                lda (dotstart),y
		#kernal
                jsr chrout
                #ram
                dex
                bne -
+               lda #k_return
		#kernal
                jsr chrout
                #ram
                lda status
                bne ki
                .fi

 	      	lda lines
                clc
                sbc dotline
                tax
                lda lines+1
                sbc dotline+1
                bcc ki
                bne +
                txa
                beq ki
+
                jsr dotnext
                jmp loop
ki
		.if TARGET==APPLE2
oldsp           ldx #0
                txs
                .fi
failed
                jsr close

		.if TARGET!=ATARI800 && TARGET!=APPLE2
                lda status
                beq +
                lda #statusmsg.ioerr
                jsr setstatusmsg
+
                .fi

old1            ldx #0
old2            lda #0
                jmp toline
                .pend

mulrepeatl      .proc
                lda #0
		geq mulrepeat
		.pend

mulrepeat	.proc
                stx num
                sta num+1
                ldx #0
                ldy #0

-               lsr num+1
                ror num
                bcc paros
                tya
                clc
                adc repeat
                tay
                txa
                adc repeat+1
                tax
                bcc paros
                ldx #255
                ldy #255
paros
                asl repeat
                rol repeat+1
                bne -
                lda repeat
                bne -
                sty repeat
                stx repeat+1
                rts
                .pend

                .include "motion.asm"
                .include "scroll.asm"
                .include "insert.asm"
                .include "cmdline.asm"
                .include "io.asm"
		.if TK
                .include "tk.asm"
		.fi
		.if GFX==1
                .include "displaygfx53.asm"
		.elsif GFX==2
                .include "displaygfx64.asm"
		.elsif GFX==3 && TARGET!=APPLE2
                .include "displaygfx80.asm"
		.elsif GFX==4
                .include "displayvdc.asm"
                .else
                .include "displaytxt.asm"
                .fi
prgend          = buffers+buffers.file

windows         .proc
buffer          = *             ;displayed buffer
line            = *+1           ;cursor line
pos             = *+3      	;cursor column

topline         = *+4      	;top line
leftcol         = *+6       	;left column

start           = *+7
end             = *+8
                .logical 0
main            .fill 7
                .byte 0
                .byte height-1

status          .fill 7
                .byte height-1
                .byte height
                .here
                .pend

references      .proc
next            = *+0
prev            = *+2
len             = *+4
buf             = *+5
                .logical 0
load            .fill 6
temp            .fill 6
start           .fill 6
end             .fill 6
insert          .fill 6
                .here
                .pend

buffers_s	.struct
next		.word ?
prev		.word ?
len		.byte ?
buf		.byte ?

refline		.word ?			;line of reference
lines		.word ?			;number of lines

linewise	.byte ?
		.ends

buffers		.proc
		.union
		.dstruct buffers_s
		.struct
		.logical 0
file		.dstruct buffers_s
unnamed		.dstruct buffers_s
status		.dstruct buffers_s
help		.dstruct buffers_s
                .here
		.ends
		.endu
                .pend

marks           .proc
line            = *
pos             = *+2
                .logical 0
		.fill 3*26      ;a-z
start           .fill 3
end             .fill 3
cursor          .fill 3
                .here
                .pend
endmarks

filename        .fill width-2

		.if TARGET!=C64 && TARGET!=PLUGIN
zpsave          .fill zpend-zpstart
                .fi
memory
