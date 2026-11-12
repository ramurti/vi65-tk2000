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

;n; <h4>/</h4>

;n; Search for text.

searchmode      .proc
                lda loading
                beq +
semmi	        rts
+
		lda #"/"
                jsr cmdline_input
                beq semmi
                dex
                beq semmi

                pha dotline+1
                pha dotline
                pha dotpos
                inc dotpos

loop            ldy #4
                tya
                sec
                adc (dotstart),y
                sta m+1
                tya
                sec
                adc dotpos
                sta m2+1

l2              ldx #2
m2              ldy #0
                lda linebuffer,x
                dey
-               iny
m       	cpy #0
                bge +
		cmp (dotstart),y
                bne -
                sty m2+1
		iny

-               cpx linebuffer
                bge ok
	       	cpy m+1
                bge +
                lda (dotstart),y
                iny
                inx
                eor linebuffer,x
                beq -
                inc m2+1
                gne l2

+               ldx dotline
                ldy dotline+1
                inx
                bne +
                iny
                beq baj
+               cpx lines
                tya
                sbc lines+1
                bge baj
                jsr dotnext
                lda #0
                sta dotpos
                geq loop

ok              lda m2+1
                sec
                sbc #5
                jsr tochar
                pla
                pla
                pla
                rts

baj             pla
                sta dotpos
                pla
                tax
                pla
                jsr toline
                lda #statusmsg.notfound
                jmp setstatusmsg
                .pend
;------------------------------------------
cmdmode         .proc
cmdcc           = num

                lda loading
                beq +
semmi           rts

+               lda #":"
                jsr cmdline_input
                beq semmi
                lda #0
                sta linebuffer+1,x
                sta cmdcc

                ldy #255
next            ldx #0
                lda #32
-               inx
		cmp linebuffer-1,x
                beq -
nextchr         iny
                inx
                lda cmds,y
                bne +
                lda #statusmsg.notcmd
                jmp setstatusmsg

+               bpl +
                and #$7f
                cmp linebuffer,x
                bne ne
                inx
                gne ne

+		cmp linebuffer,x
                beq nextchr
ne              lda linebuffer,x
                clc
                beq cmdok
                eor #32
                beq cmdok
                cmp #"!"^32
                beq cmdok2

notthis         inc cmdcc
                inc cmdcc
-		iny
                lda cmds,y
                bpl -
                gmi next

cmdok2          inx
cmdok           lda linebuffer,x
                eor #32
                beq cmdok2
		ldy cmdcc
                pha cmdprg+1,y
                pha cmdprg,y
                dex
                lda linebuffer+1,x
                rts

cmds            .shift "edit"   ;e[dit]
                .shift "enew"   ;ene[w]
                .shift "file"   ;f[ile]
                .shift "quit"   ;q[uit]
                .shift "write"  ;w[rite]
                .shift "wq"  	;wq
                .byte 0

cmdprg          .rta edit
		.rta new
                .rta file
                .rta exit
                .rta write
                .rta writequit

;n; <h4>:q[uit]</h4>

;n; Quit. No question for unsaved changes yet!

exit            pla
		pla
		.if TARGET in (C64, PLUGIN, C128, VIC20, VIC20BIG, PLUS4, C16, PET40, PET80, ATARI800)
                sei
                #movew irq.old+1, virq
                cli
                .fi
                ldx #zpend-zpstart-1
-               lda zpsave,x
                sta zpstart,x
                dex
                bpl -
		jmp displayexit

;n; <h4>:f[ile] [filename]</h4>

;n; Set/print filename

file            beq no
                txa
                eor #255
                sec
                adc linebuffer
                cmp #width-3
                blt +
                lda #width-3
+               sta filename

                ldy #0
-               iny
                inx
                lda linebuffer,x
                sta filename,y
                cpy filename
                blt -
no
                lda #0
                sta linebuffer
                lda #34
                jsr lb_append_char
                ldx #<(filename-4)
                lda #>(filename-4)
                jsr lb_append_str
                lda #34
                jsr lb_append_char

                ldx #<(linebuffer-4)
                lda #>(linebuffer-4)
                jmp setstatus

;n; <h4>:e[dit] [filename]</h4>

;n; Edit file. File is loaded in the background,
;n; the loaded part can be edited imediately.
;n; Paste register is not cleared!

edit            jsr file
                jmp load

;n; <h4>:ene[w]</h4>

;n; Edit a new, unnamed buffer.
new		jsr freebuf
		jmp notempty

;n; <h4>:wq [filename]</h4>

;n; Write file and quit.

writequit       jsr write
                jmp exit

;n; <h4>:w[rite] [filename]</h4>

;n; Write file.

write           jsr file
                jmp save
                .pend

cmdline_input   .proc
                sta m+1
                pha activewin
                lda #windows.status
                jsr selectwin

                lda #0
                jsr linemod
                bcs cmd_return.baj

m               ldy #0
                jsr insertmode.put2

                lsr oneless
                dec tochar.mode+1

-               lsr display.now
		ldx #1
                stx repeat
                dex
                stx repeat+1
                jsr waitkey
		ldx #keylookup.cmdkeys
		jsr keylookup
                jmp -
                .pend

cmd_X           .proc
                ldx dotpos
                dex
                bne kX
                ldy #4
                lda (dotstart),y
		lsr a
                beq cmd_exit
                rts
                .pend

cmd_put         .proc
		.if TARGET==ATARI800
                cpy #32
                blt cmd_h.x
                cpy #$7d
                bge cmd_h.x
                .else
                tya
		asl a
                cmp #$40
                blt cmd_h.x
                .fi
                jmp insertmode.put2
		.pend

cmd_h           .proc
                ldx dotpos
                dex
                bne motion_h
x               rts
                .pend

cmd_0           .proc
                lda #1
                sta dotpos
                rts
                .pend

cmd_exit        .proc
                lda #0
                jsr linemod
		#bitjmp cmd_return
		.pend

cmd_return      .proc
                pla
                pla

                inc tochar.mode+1
                ldy #4
                lda (dotstart),y
                sta linebuffer
                beq +
                tax
-               iny
                lda (dotstart),y
                sta linebuffer-4,y
                dex
                bne -
+
baj		pla
                jsr selectwin
                ldx linebuffer
                rts
                .pend

lb_append_char	.proc
                ldx linebuffer
                sta linebuffer+1,x
                inc linebuffer
                rts
                .pend

lb_append_str	.proc
                stx currenttext
                sta currenttext+1
                ldy #4
                tya
                sec
                adc (currenttext),y
                sta m+1
                ldx linebuffer
-               iny
m               cpy #0
                bge +
                lda (currenttext),y
                sta linebuffer+1,x
                inx
                bne -
+               stx linebuffer
		rts
                .pend
