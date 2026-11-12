"""The files on a tape as text (what VI65's :w wrote, e.g. the emulator's recorded.ct2):
ct2txt.py TAPE.ct2 [OUTDIR]  -> one NAME.txt per file (CR -> newline), and a list on stdout.
"""
import os
import struct
import sys


def files(tape):
    data = open(tape, 'rb').read()
    assert data[:4] == b'CTK2', 'not a CT2 tape'
    pos, cur = 4, None
    while pos + 4 <= len(data):
        cid, size = data[pos:pos + 2], struct.unpack('<H', data[pos + 2:pos + 4])[0]
        body = data[pos + 4:pos + 4 + size]
        pos += 4 + size
        if cid != b'DA' or len(body) < 9:
            continue
        name = bytes(c & 0x7F for c in body[:6]).decode('ascii').rstrip()
        if body[7] == 0:
            if cur:
                yield cur
            cur = [name, bytearray()]
        elif cur:
            cur[1] += body[8:-1]
    if cur:
        yield cur


def main():
    out = sys.argv[2] if len(sys.argv) > 2 else '.'
    for name, text in files(sys.argv[1]):
        path = os.path.join(out, (name or 'NONAME') + '.txt')
        open(path, 'w', encoding='ascii', errors='replace').write(text.replace(b'\r', b'\n').decode('ascii', 'replace'))
        print(f"{name}: {len(text)} bytes -> {path}")


if __name__ == '__main__':
    main()
