"""Accented letters (Latin-1 $C0-$FF) for the TK2000 build of vi65, from the 5x8 font's own letters.

vi65/latin1.fnt: 64 glyphs x 8 bytes, the bit order of font5x8.fnt (bit 7 = left), included by
font.asm after the 128 ASCII glyphs. Codes without a glyph here are blank.
Lower case: the letter as it is (rows 2-6) and the accent on rows 0-1. Capitals: the letter
squeezed to rows 2-6 (rows that repeat are dropped), so the accent fits above it the same way;
the cedilla goes on row 7, below the letter.

Usage: accents.py                 writes vi65/latin1.fnt
       accents.py --preview PNG   also draws the glyphs and some words, 4x
"""
import sys

FONT = "vi65/font5x8.fnt"
OUT = "vi65/latin1.fnt"

ACCENTS = {
    "acute": ["...#..", "..#..."],
    "grave": [".#....", "..#..."],
    "circ": ["..##..", ".#..#."],
    "tilde": ["..#.#.", ".#.#.."],
}
# Latin-1 code: (base letter, accent); cedillas are drawn apart
LETTERS = {
    0xC0: ("A", "grave"), 0xC1: ("A", "acute"), 0xC2: ("A", "circ"), 0xC3: ("A", "tilde"),
    0xC9: ("E", "acute"), 0xCA: ("E", "circ"), 0xCD: ("I", "acute"),
    0xD3: ("O", "acute"), 0xD4: ("O", "circ"), 0xD5: ("O", "tilde"), 0xDA: ("U", "acute"),
}
LETTERS.update({c + 0x20: (b.lower(), a) for c, (b, a) in LETTERS.items()})


def glyph(font, ch):
    return [font[ord(ch) * 8 + r] for r in range(8)]


def squeeze(rows, n):
    """rows (top to bottom) down to n, dropping the repeated row nearest the middle each time"""
    rows = list(rows)
    while len(rows) > n:
        dups = [i for i in range(len(rows) - 1) if rows[i] == rows[i + 1]]
        mid = (len(rows) - 1) / 2
        i = min(dups, key=lambda i: abs(i + 0.5 - mid)) if dups else len(rows) // 2
        del rows[i]
    return rows


def bits(text):
    return sum(0x80 >> i for i, c in enumerate(text) if c == "#")


def build(font):
    out = bytearray(64 * 8)
    for code, (base, accent) in LETTERS.items():
        g = glyph(font, base)
        if base.isupper():
            g = [0, 0] + squeeze(g[0:7], 5) + [0]
        elif base == "i":
            g = [0, 0] + g[2:]          # the dot goes
        top = [bits(r) for r in ACCENTS[accent]]
        g[0], g[1] = top
        out[(code - 0xC0) * 8:(code - 0xBF) * 8] = bytes(g)
    for code, base in ((0xC7, "C"), (0xE7, "c")):
        g = glyph(font, base)
        g[7] = bits("..#...")
        out[(code - 0xC0) * 8:(code - 0xBF) * 8] = bytes(g)
    return out


def preview(font, latin, png):
    from PIL import Image
    text = ["ÁÉÍÓÚ ÀÂÊÔ ÃÕ Ç", "áéíóú àâêô ãõ ç", "CORAÇÃO coração", "Ação, não, avô, você",
            "AÇÃO É ÁGUA", "it's 'x' A&B"]
    img = Image.new("1", (5 * 22, 8 * len(text)))
    for y, line in enumerate(text):
        for x, ch in enumerate(line):
            c = ord(ch)
            g = latin[(c - 0xC0) * 8:(c - 0xBF) * 8] if c >= 0xC0 else font[c * 8:c * 8 + 8]
            for r in range(8):
                for i in range(5):
                    if g[r] & (0x80 >> i):
                        img.putpixel((x * 5 + i, y * 8 + r), 1)
    img.resize((img.width * 4, img.height * 4)).save(png)


if __name__ == "__main__":
    font = open(FONT, "rb").read()[2:]
    latin = build(font)
    open(OUT, "wb").write(latin)
    if sys.argv[1:2] == ["--preview"]:
        preview(font, latin, sys.argv[2])
