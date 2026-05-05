# CICC1003618 submission context:
# File role: scripts/make_word_hex.py is part of the reproducible build, simulation or reporting script.
# Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
# Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
# Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
# Verification note: functional changes require matching simulation logs or FPGA reports.
# Maintenance note: update documents, metrics and hashes when this file changes.

import pathlib
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: make_word_hex.py <input.bin> <output.mem32.hex>")
        return 1

    input_path = pathlib.Path(sys.argv[1])
    output_path = pathlib.Path(sys.argv[2])

    data = input_path.read_bytes()
    if len(data) % 4 != 0:
        data += b"\x00" * (4 - (len(data) % 4))

    words = []
    for offset in range(0, len(data), 4):
        chunk = data[offset:offset + 4]
        word = int.from_bytes(chunk, byteorder="little", signed=False)
        words.append(f"{word:08X}")

    output_path.write_text("\n".join(words) + ("\n" if words else ""), encoding="ascii")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
