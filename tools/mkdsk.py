"""Copies a TKDOS 3.3 disk image (.dsk, DOS 3.3 sector order) and adds a binary file (type B) or
a text file (type T) to it.

TKDOS uses the Apple DOS 3.3 disk format: VTOC on track 17 sector 0, catalog chained from it, a
track/sector list per file. A B file starts with its load address and length (2 bytes each). A T
file is written as VI65's :w writes it: bit 7 set, CR after each line, the accented letters as
the control codes of vi65/tk.asm (accents), a 0 at the end.

Usage: mkdsk.py MASTER.dsk BIN ADDR NAME OUT.dsk
       mkdsk.py MASTER.dsk --text FILE.txt NAME OUT.dsk   (FILE.txt in UTF-8)
"""
import sys


def sector(img, t, s):
    return (t * 16 + s) * 256


def free_sectors(img, vtoc):
    """free sectors from the VTOC bitmap, from track 18 up and then 16 down, as DOS does"""
    for t in list(range(18, 35)) + list(range(16, 2, -1)):
        bits = img[vtoc + 0x38 + t * 4] << 8 | img[vtoc + 0x39 + t * 4]
        for s in range(15, -1, -1):
            if bits & (1 << s):
                yield t, s


def take(img, vtoc, t, s):
    i = vtoc + 0x38 + t * 4 + (0 if s >= 8 else 1)
    img[i] &= ~(1 << (s & 7)) & 0xFF


# vi65/tk.asm, accents: Latin-1 letter -> code in a disk file
ACCENTS = dict(zip("áéíóúâêôàãõçÁÉÍÓÚÂÊÔÀÃÕÇ",
                   (1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26)))


def text(t):
    out = bytearray()
    for line in t.splitlines():
        for ch in line:
            c = ACCENTS.get(ch, ord(ch))
            assert c < 128, "no code for " + ch
            out.append(c | 0x80)
        out.append(0x8D)
    return bytes(out) + b"\0"


def add(img, data, name, kind=0x04):
    vtoc = sector(img, 17, 0)
    nsec = (len(data) + 255) // 256
    assert nsec <= 122, "one track/sector list only"
    free = free_sectors(img, vtoc)
    tsl = next(free)
    secs = [next(free) for _ in range(nsec)]
    for t, s in [tsl] + secs:
        take(img, vtoc, t, s)
    o = sector(img, *tsl)
    img[o:o + 256] = bytes(256)
    for i, (t, s) in enumerate(secs):
        img[o + 0x0C + i * 2:o + 0x0E + i * 2] = bytes((t, s))
        p = sector(img, t, s)
        chunk = data[i * 256:(i + 1) * 256]
        img[p:p + 256] = chunk + bytes(256 - len(chunk))
    entry = bytes(tsl) + bytes((kind,)) + bytes(c | 0x80 for c in name.upper().ljust(30).encode()) \
        + bytes(((nsec + 1) & 0xFF, (nsec + 1) >> 8))
    t, s = img[vtoc + 1], img[vtoc + 2]
    while t:
        c = sector(img, t, s)
        for i in range(7):
            e = c + 0x0B + i * 35
            if img[e] in (0, 0xFF):
                img[e:e + 35] = entry
                return
            assert bytes(img[e + 3:e + 33]) != entry[3:33], name + " is already on the disk"
        t, s = img[c + 1], img[c + 2]
    sys.exit("catalog full")


if __name__ == "__main__":
    master, binfile, addr, name, out = sys.argv[1:]
    img = bytearray(open(master, "rb").read())
    assert len(img) == 143360, "not a 140K .dsk"
    if binfile == "--text":
        data = text(open(addr, encoding="utf-8").read())
        add(img, data, name, 0x00)
        print("%s: %s added, text, %d bytes" % (out, name, len(data)))
    else:
        addr = int(addr, 0)
        code = open(binfile, "rb").read()
        add(img, bytes((addr & 0xFF, addr >> 8, len(code) & 0xFF, len(code) >> 8)) + code, name)
        print("%s: %s added, %d bytes at $%04X" % (out, name, len(code), addr))
    open(out, "wb").write(img)
