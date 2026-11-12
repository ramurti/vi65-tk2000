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

                .if !SIMPLE
kz              .proc
                jsr waitkeyrepeat
                ldx #keylookup.zkeys
                jmp keylookup
                .pend

;n; <h4>zL</h4>

;n; Move the view on the text half a screenwidth to the
;n; right, thus scroll the text half a screenwidth to the
;n; left.

scroll_zL       .proc
                ldx #width/2
                jsr mulrepeatl
		#bitjmp scroll_zl
		.pend

;n; <h4>z&lt;Right&gt; or zl</h4>

;n; Move the view on the text [count] characters to the
;n; right, thus scroll the text [count] characters to the
;n; left.

scroll_zl       .proc
                ldy #4
                lda repeat+1
                bne q
                lda leftcol
                clc
                adc repeat
                bge q
in              cmp (dotstart),y
                blt scroll_zh.fix
q               lda (dotstart),y
                beq scroll_zh.fix
                sec
                sbc #1
                gcs scroll_zh.fix
                .pend

;n; <h4>zH</h4>

;n; Move the view on the text half a screenwidth to the
;n; left, thus scroll the text half a screenwidth to the
;n; right.

scroll_zH       .proc
                ldx #width/2
                jsr mulrepeatl
		#bitjmp scroll_zh
		.pend

;n; <h4>z&lt;Left&gt; or zh</h4>

;n; Move the view on the text [count] characters to the
;n; left, thus scroll the text [count] characters to the
;n; right.

scroll_zh       .proc
                lda repeat+1
                bne q
		lda leftcol
                sec
                sbc repeat
                bge fix
q               lda #0
fix             sta leftcol
                ldx dotpos
                cmp dotpos
                blt +
                clc
                tax
+               adc #width-1
                bge +
                cmp dotpos
                bge +
                tax
+               stx dotpos
                rts
                .pend

;n; <h4>ze</h4>

;n; Scroll the text horizontally to position the cursor
;n; at the end (right side) of the screen.

scroll_ze       .proc
                lda dotpos
                sec
                sbc #width-1
                bge +
                lda #0
+		#bitjmp scroll_zs.in
		.pend

;n; <h4>zs</h4>

;n; Scroll the text horizontally to position the cursor
;n; at the start (left side) of the screen.

scroll_zs       .proc
                lda dotpos
in		jmp scroll_zh.fix
                .pend
                .fi

scroll_ctrl_f   .proc
                ldx #height-3
                .if SIMPLE
                stx repeat
                .else
                jsr mulrepeatl
                .fi
		#bitjmp scroll_ctrl_e
		.pend
;n; <h4>CTRL-E</h4>

;n; Scroll window [count] lines downwards in the buffer.

scroll_ctrl_e   .proc
                lda topline
                clc
                adc repeat
                tax
                lda topline+1
                adc repeat+1
                bcc u
                lda #255
j               tax
u               tay
		cpx lines
                sbc lines+1
                tya
                blt +
                ldx lines
                lda lines+1
+               stx topline
		sta topline+1
		cpx dotline
                sbc dotline+1
                blt +
                lda topline+1
tl              jsr toline
                jmp motion_uparrow

+               cmp #255
                bne ki
                lda dotline
                sbc topline
                cmp #height-1
                blt +
ki              txa
                adc #height-3
                tax
                lda topline+1
                adc #0
                bcc tl
                lda #255
                tax
                gcs tl
+		rts
                .pend

scroll_ctrl_b   .proc
                ldx #height-3
                .if SIMPLE
                stx repeat
                .else
                jsr mulrepeatl
                .fi
		#bitjmp scroll_ctrl_y
		.pend
;n; <h4>CTRL-Y</h4>

;n; Scroll window [count] lines upwards in the buffer.

scroll_ctrl_y   .proc
                lda topline
                sec
                sbc repeat
                tax
                lda topline+1
                sbc repeat+1
                bge scroll_ctrl_e.u
                lda #0
                tax
                geq scroll_ctrl_e.tl
                .pend
