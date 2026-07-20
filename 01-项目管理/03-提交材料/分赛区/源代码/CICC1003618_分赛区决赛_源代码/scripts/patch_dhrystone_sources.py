from pathlib import Path
import sys


def patch_text(text: str, strip_noinline: bool, source_name: str, require_score_patch: bool) -> str:
    if strip_noinline:
        text = "\n".join(
            line for line in text.splitlines()
            if "#pragma GCC optimize" not in line
        ) + "\n"

    old = "Dhrystones_Per_Second = (HZ * Number_Of_Runs) / User_Time;"
    new = (
        "Dhrystones_Per_Second = "
        "(long)(((long long)HZ * (long long)Number_Of_Runs) / "
        "(long long)User_Time);"
    )
    if require_score_patch and old not in text:
        raise RuntimeError(f"missing Dhrystone score expression in {source_name}")
    patched = text.replace(old, new)
    if require_score_patch and patched == text:
        raise RuntimeError(f"failed to patch Dhrystone score expression in {source_name}")
    return patched


def main() -> int:
    if len(sys.argv) != 5:
        print(
            "usage: patch_dhrystone_sources.py <main.c> <core.c> "
            "<out_dir> <strip_noinline:0|1>",
            file=sys.stderr,
        )
        return 1

    main_src = Path(sys.argv[1])
    core_src = Path(sys.argv[2])
    out_dir = Path(sys.argv[3])
    strip_noinline = sys.argv[4] == "1"
    out_dir.mkdir(parents=True, exist_ok=True)

    (out_dir / "dhrystone_main.c").write_text(
        patch_text(
            main_src.read_text(encoding="utf-8"),
            strip_noinline,
            str(main_src),
            require_score_patch=True,
        ),
        encoding="utf-8",
    )
    (out_dir / "dhrystone.c").write_text(
        patch_text(
            core_src.read_text(encoding="utf-8"),
            strip_noinline,
            str(core_src),
            require_score_patch=False,
        ),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
