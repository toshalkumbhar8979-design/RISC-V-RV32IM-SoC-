#!/usr/bin/env python3
"""bin2hex.py — convert a flat binary (riscv code image) into a Verilog
word-hex (.hex) file: one 8-hex-digit little-endian word per line."""
import sys, struct

def main():
    if len(sys.argv) != 3:
        print("usage: bin2hex.py <input.bin> <output.hex>")
        sys.exit(1)
    with open(sys.argv[1], "rb") as f:
        data = f.read()
    # pad to multiple of 4
    while len(data) % 4:
        data += b"\x00"
    with open(sys.argv[2], "w") as f:
        for i in range(0, len(data), 4):
            w = struct.unpack_from("<I", data, i)[0]
            f.write("%08x\n" % w)
    print("wrote %d words -> %s" % (len(data)//4, sys.argv[2]))

if __name__ == "__main__":
    main()