;
;    VI65 (c) 2010-2023 Soci/Singular (soci@c64.rulez.org)
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

;
; There was a python script shuffling around the glyphs and swapping bit order.
; It wasn't python 3 compatible and so was rewritten by Caitlin Shaw in C. However
; over the year the assembler became capable of doing this on its own without
; the need of any temporary files.
;

fnt		= binary(FONTFILE, 2)

		.if TARGET==ATARI800
		.text fnt[$20*8:$60*8]
		.text fnt[$88*8:$89*8]
		.text fnt[$0b*8:$0c*8]
		.text fnt[$0a*8:$0b*8]
		.text fnt[$1d*8:$1e*8]
		.text fnt[$13*8:$14*8]
		.text fnt[$0e*8:$0f*8]
		.text fnt[$89*8:$8c*8]
		.text fnt[$0c*8:$0d*8]
		.text fnt[$8c*8:$8d*8]
		.text fnt[$1c*8:$1d*8]
		.text fnt[$1e*8:$1f*8]
		.text fnt[$17*8:$18*8]
		.text fnt[$0f*8:$10*8]
		.text fnt[$1b*8:$1c*8]
		.text fnt[$8d*8:$8e*8]
		.text fnt[$10*8:$11*8]
		.text fnt[$80*8:$82*8]
		.text fnt[$8e*8:$8f*8]
		.text fnt[$02*8:$03*8]
		.text fnt[$14*8:$15*8]
		.text fnt[$12*8:$13*8]
		.text fnt[$11*8:$12*8]
		.text fnt[$01*8:$02*8]
		.text fnt[$0d*8:$0e*8]
		.text fnt[$8f*8:$90*8]
		.text fnt[$86*8:$87*8]
		.text fnt[$90*8:$91*8]
		.text fnt[$87*8:$88*8]
		.text fnt[$91*8:$93*8]
		.text fnt[$61*8:$7b*8]
		.text fnt[$93*8:$94*8]
		.text fnt[$83*8:$84*8]
		.text fnt[$94*8:$97*8]
		.elsif TARGET==APPLE2
fnt2		= bytes(bits(fnt)[::-1])[::-1]
		.text fnt2[$40*8:$60*8]
		.text fnt2[$20*8:$40*8]
		.text fnt2[$40*8:$80*8]
		.else
		.text fnt[$40*8:$41*8]
		.text fnt[$61*8:$7b*8]
		.text fnt[$5b*8:$5c*8]
		.text fnt[$a3*8:$a4*8]
		.text fnt[$5d*8:$5e*8]
		.text fnt[$86*8:$88*8]
		.text fnt[$20*8:$27*8]
		.text fnt[$b4*8:$b5*8]
		.text fnt[$28*8:$40*8]
		.text fnt[$80*8:$81*8]
		.text fnt[$41*8:$5b*8]
		.text fnt[$81*8:$86*8]
		.text fnt[$00*8:$20*8]
		.fi
