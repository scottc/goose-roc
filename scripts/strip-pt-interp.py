#!/usr/bin/env python3
from __future__ import annotations
import struct
import sys

PT_INTERP, PT_NULL = 3, 0

def main() -> None:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <elf>", file=sys.stderr)
        sys.exit(2)
    path = sys.argv[1]
    with open(path, "rb") as f:
        data = bytearray(f.read())
    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        sys.exit("need ELF64 LE")
    e_phoff = struct.unpack_from("<Q", data, 32)[0]
    e_phentsize = struct.unpack_from("<H", data, 54)[0]
    e_phnum = struct.unpack_from("<H", data, 56)[0]
    n = 0
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        if struct.unpack_from("<I", data, off)[0] == PT_INTERP:
            struct.pack_into("<I", data, off, PT_NULL)
            n += 1
            print(f"PT_INTERP -> PT_NULL (phdr {i})")
    if n == 0:
        print("no PT_INTERP")
    with open(path, "wb") as f:
        f.write(data)

if __name__ == "__main__":
    main()
