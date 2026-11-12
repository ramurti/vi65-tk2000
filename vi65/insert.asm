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

;n; <h4>A</h4>

;n; Append text at the end of the line.

kA              .proc
                jsr tolastchar
		#bitjmp ka
		.pend
;n; <h4>a</h4>

;n; Append text after the cursor times.  If the
;n; cursor is in the first column of an empty line Insert
;n; starts there.

ka              .proc
                inc dotpos
                gne insertmode
                .pend
;n; <h4>I</h4>

;n; Insert text before the first non-blank in the line

kI              .proc
                jsr motion_uparrow
		#bitjmp insertmode
		.pend

insertmode	.proc
                dec tochar.mode+1
                lda #statusmsg.insert
                jsr setstatusmsg
                ldx #marks.start
                jsr setmark
                ;ldx #references.start
                ;jsr insertref2
                ;ldx #references.end
                ;jsr insertref
loop            lsr display.now
                ldx #1
                stx repeat
                dex
                stx repeat+1
                stx oneless
                jsr waitkey
		.if TK
                jsr deadkey             ;' and & before a letter: accents (tk.asm)
                bcs loop
		.fi
		ldx #keylookup.insertkeys
                jsr keylookup
                jmp loop

exit            pla
                pla
                ldx #<(notxt-4)
                lda #>(notxt-4)
                jsr setstatus
                inc tochar.mode+1
                ;ldx #references.end
                ;jsr deleteref
                ;ldx #references.start
                ;jsr deleteref2
                jmp motion_h

notxt           .text 0

put             tya
                ldx #keylookup.motionkeys2
                jsr keylookup
		.if TARGET==ATARI800
                cpy #$7d
                bge baj
                cpy #32
                blt baj
                .else
		tya
		asl a
                cmp #64
                blt baj		;no control chars
                .fi
put2
                sty ichar
                jsr normcolumn
                sta dotpos
                #loadw fakeinsert, currenttext
                jmp inserttext

baj             rts

kreturn         jsr split
                bcs baj
                lda #1
                sta repeat
		lsr a
                sta repeat+1
                jsr motion_j
                jmp motion_0

fakeinsert      = *-4
		.byte 1
ichar           .byte 0
                .pend

;i; CTRL-Y
;i;
;i; Insert the character which is above the cursor.
;i;
insert_ctrl_y   .proc
		ldy #2
		#bitjmp insert_ctrl_e.in
		.pend
;i; CTRL-E
;i;
;i; Insert the character which is below the cursor.
;i;
insert_ctrl_e   .proc
                ldy #0
in		lda (dotstart),y
                sta currenttext
                iny
                lda (dotstart),y
                sta currenttext+1
                ldy #4
                lda dotpos
                cmp (currenttext),y
                bcc +
                rts

+               adc #5
                tay
                lda (currenttext),y
                tay
                sec
                gcs insertmode.put2
                .pend

append_c        .proc
                pha
                ldy #4
                lda (dotstart),y
                clc
                adc #1
                jsr modline
                pla
                bcs e
                pha
                ldy #4
                lda (currentline),y
                beq +
                tax

-               iny
                lda (currentline),y
                sta (dotstart),y
                dex
                bne -
+               iny
                pla
                sta (dotstart),y
e               rts
                .pend

inserttext      .proc
		ldy #4
                lda (currenttext),y
                sta il+1
                clc
                adc (dotstart),y
                bcs baj
                jsr linemod
                bcc +
baj             rts

+               ldy #4
                lda (currentline),y
                sec
                sbc dotpos
                sta en+1

                ldx dotpos
                beq +

-               iny
		lda (currentline),y
                sta (allocline),y
                dex
                bne -
+
                lda currenttext
                sec
                sbc dotpos
                sta currenttext
                bcs +
                dec currenttext+1
+

il              ldx #0
                beq +
                txa
                clc
                adc dotpos
                sta dotpos
                lda currentline
                sec
                sbc il+1
                sta currentline
		bcs y2
                dec currentline+1
y2

-               iny
		lda (currenttext),y
                sta (allocline),y
                dex
                bne -
+

en              ldx #0
                clc
		gcc currenttoalloc
		.pend

currenttoalloc  .proc
                beq +
-               iny
		lda (currentline),y
                sta (allocline),y
                dex
                bne -
+               rts
                .pend

currenttoalloc2 .proc
                clc
                adc dotstart
                sta currentline
                lda #0
                adc dotstart+1
                sta currentline+1
                txa
                jmp currenttoalloc
                .pend

linemod2        .proc
		jsr alloc
                bcs err

                ldy #0
                lda (dotstart),y
                sta (allocline),y
                sta currentline
                iny
                lda (dotstart),y
                sta (allocline),y
                sta currentline+1
                iny
                lda allocline
                sta (currentline),y
                iny
                lda allocline+1
                sta (currentline),y

		lda (dotstart),y
                sta (allocline),y
                sta currentline+1
		lda #1
		sta (dotstart),y
                dey
		lda (dotstart),y
                sta (allocline),y
                sta currentline
                dey
                lda allocline+1
                sta (currentline),y
                dey
                lda allocline
                sta (currentline),y
err		rts
                .pend

linemod         .proc
                jsr linemod2
                bcs setdottoalloc.x
                #movew dotstart, currentline
		gcc setdottoalloc
		.pend

setdottoalloc   .proc
                #movew allocline, dotstart
x               rts
                .pend

rerefbefore     .proc
                jsr deleteref
		#bitjmp refbefore
		.pend

; cursor+ to X ref
;
refbefore       .proc
                lda dotstart+1
                sta references.prev+1,x
                lda dotstart
                sta references.prev,x
                ldy #0
                lda (dotstart),y
                sta currentline
                sta references.next,x
                txa
                clc
                adc #<references
                pha
                sta (dotstart),y
                iny
                lda (dotstart),y
                sta currentline+1
                sta references.next+1,x
                lda #0
                adc #>references
                sta (dotstart),y
                ldy #3
                gne refafter.common
		.pend

rerefafter      .proc
                jsr deleteref
		#bitjmp refafter
		.pend
;
; cursor- to X ref
;
refafter        .proc
                lda dotstart+1
                sta references.next+1,x
                lda dotstart
                sta references.next,x
                ldy #2
                lda (dotstart),y
                sta currentline
                sta references.prev,x
                txa
                clc
                adc #<references
                pha
                sta (dotstart),y
                iny
                lda (dotstart),y
                sta currentline+1
                sta references.prev+1,x
                lda #0
                adc #>references
                sta (dotstart),y
                ldy #1
common          sta (currentline),y
                dey
                pla
                sta (currentline),y
                lda activebuf
                sta references.buf,x
                lda #255
                sta references.len,x
                rts
                .pend

deleteref       .proc
                tax
                tay
		#bitjmp borona
		.pend

borona          .proc
		lda references.prev,y
                sta currentline
                lda references.prev+1,y
                sta currentline+1
                ldy #0
                lda references.next,x
                sta allocline
                sta (currentline),y
                iny
                lda references.next+1,x
                sta allocline+1
                sta (currentline),y
                iny
                lda currentline
                sta (allocline),y
                iny
                lda currentline+1
                sta (allocline),y
                rts
                .pend

reftocursor     .proc
		lda references,x
                sta dotstart
                lda references+1,x
                sta dotstart+1
                rts
                .pend
