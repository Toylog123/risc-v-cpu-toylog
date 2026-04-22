import pathlib
import sys


def main() -> int:
    # Convert a flat little-endian binary into one 32-bit word per line for ROM/RAM loaders.
    if len(sys.argv) != 3:
        print("usage: make_word_hex.py <input.bin> <output.mem32.hex>")
        return 1

    input_path = pathlib.Path(sys.argv[1])
    output_path = pathlib.Path(sys.argv[2])

    data = input_path.read_bytes()
    # Pad short tails so every emitted line is a complete 32-bit word.
    if len(data) % 4 != 0:
        data += b"\x00" * (4 - (len(data) % 4))

    words = []
    for offset in range(0, len(data), 4):
        chunk = data[offset:offset + 4]
        # The hardware memory images expect canonical uppercase hex words.
        word = int.from_bytes(chunk, byteorder="little", signed=False)
        words.append(f"{word:08X}")

    output_path.write_text("\n".join(words) + ("\n" if words else ""), encoding="ascii")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
