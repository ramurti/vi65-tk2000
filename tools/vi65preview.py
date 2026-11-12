"""The vi65 Apple II screenshot's text drawn with vi65's own fonts on the TK2000 screen.

build/vi65-columns.png: the original screenshot (Apple II 80-column card) and the same text at
46, 56 and 70 columns on the TK2000's 280 x 192 hi-res, all shown 2x like the screenshot.
"""
from PIL import Image, ImageDraw

REF = "reference/vi65/code/trunk/"
TEXT = """VI65 editor

A VI implementation for 6502 machines.

This is the "manual" of the multi platform VI65 0.1 editor.

The editor (and the documentation) is far from finished, and
there are a lot of bug. Maybe the next version will be better
;)

Supported platforms:

C64, C128 native, C16/+4, VIC20 (expanded), PET40/80. Atari
8bit, Apple II.

Supported video modes:

  * C64 - 40/53/64/80x25 (VDC 80x25 on C128)
  * C128 - 40/53/64/80x25, VDC 80x25
  * +4 - 40x25, 53/64/80x23
  * C16 - 40x25
  * VIC20 - 22x23, 26/35/40x22
  * PET - 40/80x25""".split("\n")


def tk_screen(fontfile, cell):
    fnt = open(REF + fontfile, "rb").read()[2:]
    cols = 280 // cell
    img = Image.new("L", (280, 192))
    lines = TEXT + [""] * (23 - len(TEXT)) + ["vi65 0.1 soci/singular"]
    for y, line in enumerate(lines):
        for x, ch in enumerate(line[:cols]):
            for r in range(8):
                bits = fnt[8 * ord(ch) + r]
                for c in range(cell):
                    if bits >> (7 - c) & 1:
                        img.putpixel((cell * x + c, 8 * y + r), 255)
    return img.resize((560, 384), Image.NEAREST), cols


def main():
    shots = [(Image.open(REF + "pic/apple.png").convert("L"), "original: Apple II 80-column card (560 px wide)")]
    for fontfile, cell in (("font6x8.fnt", 6), ("font5x8.fnt", 5), ("font4x8.fnt", 4)):
        img, cols = tk_screen(fontfile, cell)
        shots.append((img, f"TK2000 hi-res, {cols} columns ({fontfile}, {cell} px per character)"))
    sheet = Image.new("L", (600, len(shots) * 430), 40)
    d = ImageDraw.Draw(sheet)
    for i, (img, title) in enumerate(shots):
        d.text((4, i * 430 + 4), title, fill=255)
        sheet.paste(img.crop((0, 0, 600, 400)), (0, i * 430 + 22))
    sheet.save("build/vi65-columns.png")


main()
