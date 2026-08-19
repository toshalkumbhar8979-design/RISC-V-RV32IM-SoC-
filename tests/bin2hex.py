#!/usr/bin/env python3
"""bin2hex.py — convert a flat binary into Verilog hex files.
    bin2hex.py <in.bin> <out.hex>          -> 32-bit words (little end)
    bin2hex.py --bytes <in.bin> <out.hex>  -> one byte per line
"""
import sys, struct

def to_words(data):
    while len(data) % 4:
        data += b"\x00"
    out = []
    for i in range(0, len(data), 4):
        out.append(struct.unpack_from("<I", data, i)[0])
    return out

def main():
    bytemode = len(sys.argv) == 4 and sys.argv[1] == "--bytes"
    n = 3 if bytemode else 3
    args = sys.argv[1:]
    if not args:
        print("usage: bin2hex.py [--bytes] <in.bin> <out.hex>")
        sys.exit(1)
    if args[0] == "--bytes":
        bytemode, args = True, args[1:]
    with open(args[0], "rb") as f:
        data = f.read()
    if bytemode:
        with open(args[1], "w") as f:
            for b in data:
                f.write("%02x\n" % b)
        print("wrote %d bytes -> %s" % (len(data), args[1]))
    else:
        with open(args[1], "w") as f:
            for w in to_words(data):
                f.write("%08x\n" % w)
        print("wrote %d words -> %s" % (len(data)//4, args[1]))

if __name__ == "__main__":
    main()