import pathlib
import re
import sys


def parse_clock_hz(raw: str) -> int:
    digits = re.sub(r"[^0-9]", "", raw)
    if not digits:
        raise ValueError(f"unable to parse clock from {raw!r}")
    return int(digits)


def require_last(pattern: str, text: str, name: str) -> str:
    matches = re.findall(pattern, text, re.MULTILINE)
    if not matches:
        raise ValueError(f"missing {name}")
    return matches[-1]


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print(
            "usage: report_dhrystone_result.py <log_path> <clock_hz> [summary_path]",
            file=sys.stderr,
        )
        return 2

    log_path = pathlib.Path(sys.argv[1])
    clock_hz = parse_clock_hz(sys.argv[2])
    summary_path = (
        pathlib.Path(sys.argv[3])
        if len(sys.argv) == 4
        else log_path.with_suffix(".summary.txt")
    )

    text = log_path.read_text(encoding="utf-8", errors="replace")

    try:
        runs = int(
            require_last(
                r"Trying\s+(\d+)\s+runs through Dhrystone:",
                text,
                "run count",
            )
        )
    except ValueError:
        runs = int(require_last(r"DHRYSTONE_RUNS=(\d+)", text, "run count"))
    microseconds_per_run = int(
        require_last(
            r"Microseconds for one run through Dhrystone:\s+(\d+)",
            text,
            "microseconds per run",
        )
    )
    dhrystones_per_second = int(
        require_last(
            r"Dhrystones per Second:\s+(\d+)",
            text,
            "dhrystones per second",
        )
    )
    completion_cycles = int(
        require_last(
            r"PASS: dhrystone completed at PC=[0-9a-fA-F]+ in (\d+) cycles",
            text,
            "completion cycles",
        )
    )

    dmips = dhrystones_per_second / 1757.0
    dmips_per_mhz = dmips / (clock_hz / 1_000_000.0)
    total_seconds = runs / float(dhrystones_per_second)
    total_ticks = int(round(total_seconds * clock_hz))

    lines = [
        f"log_path={log_path}",
        f"clock_hz={clock_hz}",
        f"runs={runs}",
        f"microseconds_per_run={microseconds_per_run}",
        f"dhrystones_per_second={dhrystones_per_second}",
        f"dmips={dmips:.6f}",
        f"dmips_per_mhz={dmips_per_mhz:.6f}",
        f"total_seconds={total_seconds:.6f}",
        f"estimated_total_ticks={total_ticks}",
        f"completion_cycles={completion_cycles}",
        "benchmark=Dhrystone 2.2",
        "measurement_mode=host-parsed-from-uart-log",
        (
            "competition_report_line="
            f"DMIPS/MHz (host-parsed): {dmips_per_mhz:.6f} / "
            f"Dhrystones/s {dhrystones_per_second} / runs {runs}"
        ),
    ]
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
