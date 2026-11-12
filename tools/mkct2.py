#!/usr/bin/env python3
"""Build a self-starting TK2000 tape image (.ct2) from a binary.

Usage: mkct2.py program.bin load_address start_address NAME output.ct2 [extra.bin@address ...]

The tape holds the files, all loaded with LOADT:
  1. A zero page file ($0036-$0070). It points the output vector (CSW, $36) to a small
     loader at $0050; when the ROM prints after loading, the loader runs, reads the next
     files with the ROM routine $EDAE and jumps to the program.
  2. The program itself.
  3. The extra files (up to 2), each at its address; FILE@ADDR< puts it before the program (a
     loading screen at $2000 shows while the rest loads).

TK2000 tape format (as produced by the ROM):
  - each file is a header block followed by data blocks of up to 256 bytes
  - block = name (6 chars, high bit set) + number of data blocks + block index (0 = header)
            + payload + checksum (XOR of all previous bytes of the block, inverted)
  - header payload = start address, end address (little endian)
CT2 container: "CTK2", then chunks "CA" (long leader), "CB" (sync), "DA" (data), with a
16-bit little-endian size.
"""
import struct
import sys

ZP_START, ZP_END = 0x0036, 0x0070
LOADER = 0x0050


def zero_page_file(start_address, files):
    zp = bytearray(ZP_END - ZP_START + 1)

    def poke(addr, value):
        zp[addr - ZP_START] = value & 0xFF

    def poke16(addr, value):
        poke(addr, value)
        poke(addr + 1, value >> 8)

    # Monitor variables overwritten while this file loads: they must hold, when written,
    # the values the ROM loader has at that moment (A1 = current address, A2 = end, ...)
    poke16(0x36, LOADER)        # CSW: output vector -> our loader
    poke16(0x38, LOADER)        # KSW: input vector
    poke16(0x3A, 0x0078)
    poke16(0x3C, 0x003C)        # A1: address being loaded when $3C is written
    poke16(0x3E, ZP_END)        # A2: end address of this file
    poke16(0x40, ZP_START)      # A3: start address of this file
    # Loader: same ROM calls the commercial tapes use, then the program
    code = [
        0xA9, 0xF0, 0x85, 0x36,     # LDA #$F0 / STA $36   CSW back to the ROM COUT ($FDF0)
        0xA9, 0xFD, 0x85, 0x37,     # LDA #$FD / STA $37
        0x20, 0x74, 0xFB,           # JSR $FB74
        0x20, 0x00, 0xEC,           # JSR $EC00            hi-res page 1 variables
        0x20, 0x32, 0xF8,           # JSR $F832
        0x8D, 0x50, 0xC0,           # STA $C050            color video (a loading screen)
    ]
    code += [0x20, 0xAE, 0xED] * files  # JSR $EDAE            read the next file from tape
    code += [0x4C, start_address & 0xFF, start_address >> 8]  # JMP start
    assert LOADER + len(code) <= ZP_END + 1
    for i, b in enumerate(code):
        poke(LOADER + i, b)
    return bytes(zp)


def block(name, count, index, payload):
    data = bytearray(name) + bytes([count, index]) + payload
    checksum = 0xFF
    for b in data:
        checksum ^= b
    return bytes(data) + bytes([checksum])


def tape_file(name, address, data):
    end = address + len(data) - 1
    count = (len(data) + 255) // 256
    blocks = [block(name, count, 0, struct.pack('<HH', address, end))]
    for i in range(count):
        blocks.append(block(name, count, i + 1, data[i * 256:(i + 1) * 256]))
    return blocks


def ct2(files):
    out = bytearray(b'CTK2')
    for blocks in files:
        for i, b in enumerate(blocks):
            if i == 0:
                out += b'CA' + struct.pack('<H', 0)     # long leader before each file
            out += b'CB' + struct.pack('<H', 0)
            out += b'DA' + struct.pack('<H', len(b)) + b
    return bytes(out)


def main():
    if not 6 <= len(sys.argv) <= 8:
        sys.exit(__doc__)
    program = open(sys.argv[1], 'rb').read()
    load = int(sys.argv[2], 0)
    start = int(sys.argv[3], 0)
    name = bytes(c | 0x80 for c in sys.argv[4].upper()[:6].ljust(6).encode('ascii'))
    extra = [(open(f, 'rb').read(), int(a.rstrip('<'), 0), a.endswith('<'))
             for f, a in (x.split('@') for x in sys.argv[6:])]
    files = [tape_file(name, ZP_START, zero_page_file(start, 1 + len(extra)))]
    files += [tape_file(name, a, d) for d, a, first in extra if first]
    files.append(tape_file(name, load, program))
    files += [tape_file(name, a, d) for d, a, first in extra if not first]
    open(sys.argv[5], 'wb').write(ct2(files))


if __name__ == '__main__':
    main()
