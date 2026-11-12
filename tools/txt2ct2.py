"""A text file as a tape for VI65's :e (and LOADT): txt2ct2.py FILE.txt NAME OUT.ct2

The lines end with CR, as :w writes them; the name is cut to 6 characters, in upper case.
The text is read as UTF-8 and written in Latin-1, as the editor keeps accented letters
(characters Latin-1 lacks become ?).
The text goes to $6000 in the header (VI65 moves it; LOADT in BASIC loads it there).
"""
import sys

from mkct2 import ct2, tape_file

ADDRESS = 0x6000


def main():
    text = open(sys.argv[1], encoding='utf-8', errors='replace').read()
    data = '\r'.join(text.splitlines()).encode('latin-1', 'replace') + b'\r'
    name = bytes(c | 0x80 for c in sys.argv[2].upper()[:6].ljust(6).encode('ascii'))
    open(sys.argv[3], 'wb').write(ct2([tape_file(name, ADDRESS, data)]))
    print(f"{sys.argv[3]}: {len(data)} bytes, {(len(data) + 255) // 256} blocks")


if __name__ == '__main__':
    main()
