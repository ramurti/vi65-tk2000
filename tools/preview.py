"""Previews of the 3 x 5 font on the TK2000 screen (mono, 280 x 192), as PNG in build/.

  build/preview-80.png  80 columns: 3.5 pixels per character, two per byte
  build/preview-70.png  70 columns: 4 pixels per character (3 + a gap)
"""
from PIL import Image

from font import CHARS, rows

TEXT = """\
O TK2000 COLOR FOI LANCADO PELA MICRODIGITAL EM 1984, COM 64K DE MEMORIA.
NAO TINHA MODO TEXTO, ENTAO A ROM DESENHAVA AS LETRAS NA TELA GRAFICA, EM 40 COLUNAS.
ESTE TESTE MOSTRA 80 COLUNAS COM UMA FONTE DE 3 PIXELS, DUAS LETRAS EM CADA BYTE.
"""


def screen(cols, pitch, lines):
    img = Image.new("1", (280, 192))
    for y, text in enumerate(lines[:24]):
        for x, ch in enumerate(text[:cols]):
            ch = ch if ch in CHARS else " "
            if pitch == 3.5:
                px = 7 * (x // 2) + 4 * (x % 2)
            else:
                px = pitch * x
            for r, bits in enumerate(rows(ch)):
                for c in range(3):
                    if bits >> c & 1:
                        img.putpixel((px + c, 8 * y + r), 1)
    return img


def save(img, name):
    # mono TK2000 on a 4:3 screen: pixels a bit taller than wide
    big = img.convert("L").resize((280 * 4, 192 * 4 * 7 // 8 * 8 // 7), Image.NEAREST)
    big.save(f"build/{name}")


def page(cols):
    charset = " ".join(CHARS[1:])
    lines = [charset, ""]
    words = " ".join(TEXT.split()).split(" ")
    line = ""
    for w in words:
        if len(line) + 1 + len(w) > cols:
            lines.append(line)
            line = w
        else:
            line = (line + " " + w).strip()
    lines.append(line)
    lines.append("")
    ruler = "".join(str(i % 10) for i in range(1, cols + 1))
    lines.append(ruler)
    filler = "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG, 1234567890. "
    while len(lines) < 24:
        lines.append((filler * 3)[(len(lines) * 7) % len(filler):][:cols])
    return lines


if __name__ == "__main__":
    save(screen(80, 3.5, page(80)), "preview-80.png")
    save(screen(70, 4, page(70)), "preview-70.png")
