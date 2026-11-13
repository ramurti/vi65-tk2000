"""Copies a TKDOS 3.3 disk image (.dsk, DOS 3.3 sector order) and adds a binary file (type B) to it.

TKDOS uses the Apple DOS 3.3 disk format: VTOC on track 17 sector 0, catalog chained from it, a
track/sector list per file. A B file starts with its load address and length (2 bytes each).

Usage: mkdsk.py MASTER.dsk BIN ADDR NAME OUT.dsk
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


def add(img, data, name):
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
    entry = bytes(tsl) + b"\x04" + bytes(c | 0x80 for c in name.upper().ljust(30).encode()) \
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
    addr = int(addr, 0)
    code = open(binfile, "rb").read()
    img = bytearray(open(master, "rb").read())
    assert len(img) == 143360, "not a 140K .dsk"
    add(img, bytes((addr & 0xFF, addr >> 8, len(code) & 0xFF, len(code) >> 8)) + code, name)
    open(out, "wb").write(img)
    print("%s: %s added, %d bytes at $%04X" % (out, name, len(code), addr))
