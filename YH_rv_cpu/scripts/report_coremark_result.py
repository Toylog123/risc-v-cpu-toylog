import pathlib
import re
import sys


def parse_clock_hz(raw: str) -> int:
    # Accept inputs such as "100000000UL" passed straight from batch files.
    digits = re.sub(r"[^0-9]", "", raw)
    if not digits:
        raise ValueError(f"unable to parse clock from {raw!r}")
    return int(digits)


def require(pattern: str, text: str, name: str) -> str:
    # Fail fast when the log shape changes so we never write a misleading summary.
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise ValueError(f"missing {name}")
    return match.group(1)


def yes_no(flag: bool) -> str:
    return "yes" if flag else "no"


def main() -> int:
    # The summary path is optional so short and strict wrappers can share this parser.
    if len(sys.argv) not in (3, 4):
        print(
            "usage: report_coremark_result.py <log_path> <clock_hz> [summary_path]",
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

    # Parse directly from the simulator log rather than relying on target-side formatting.
    text = log_path.read_text(encoding="utf-8", errors="replace")

    coremark_size = int(require(r"^CoreMark Size\s*:\s*(\d+)\s*$", text, "CoreMark Size"))
    total_ticks = int(require(r"^Total ticks\s*:\s*(\d+)\s*$", text, "Total ticks"))
    iterations = int(require(r"^Iterations\s*:\s*(\d+)\s*$", text, "Iterations"))
    compiler_version = require(
        r"^Compiler version\s*:\s*(.+?)\s*$", text, "Compiler version"
    )
    compiler_flags = require(
        r"^Compiler flags\s*:\s*(.+?)\s*$", text, "Compiler flags"
    )
    memory_location = require(
        r"^Memory location\s*:\s*(.+?)\s*$", text, "Memory location"
    )
    completion_cycles = int(
        require(
            r"^PASS: coremark completed at PC=[0-9a-fA-F]+ in (\d+) cycles\s*$",
            text,
            "completion cycles",
        )
    )

    # Distinguish a clean EEMBC-valid run from the intentionally short reportable path.
    validation_clean = "Correct operation validated." in text
    full_workload = all(
        token in text for token in ("[0]crclist", "[0]crcmatrix", "[0]crcstate")
    )
    performance_profile = "2K performance run parameters for coremark." in text
    runtime_floor_violation = (
        "ERROR! Must execute for at least 10 secs for a valid result!" in text
    )
    seed_warning = (
        "Cannot validate operation for these seed values, please compare with "
        "results on a known platform."
    ) in text
    errors_detected = re.search(r"^Errors detected\s*$", text, re.MULTILINE) is not None
    short_runtime_only = (
        runtime_floor_violation
        and errors_detected
        and full_workload
        and performance_profile
        and not seed_warning
        and not validation_clean
    )

    # Host-side float math keeps score precision even when the target path truncates seconds.
    total_seconds = total_ticks / float(clock_hz)
    iterations_per_sec = iterations / total_seconds if total_seconds > 0 else 0.0
    coremark_per_mhz = iterations_per_sec / (clock_hz / 1_000_000.0)
    strict_eembc_10s = validation_clean and total_seconds >= 10.0
    competition_reportable = full_workload and performance_profile and (
        validation_clean or short_runtime_only
    )
    if validation_clean:
        validation_mode = "eembc_validated"
    elif short_runtime_only:
        validation_mode = "short_runtime_only"
    elif seed_warning:
        validation_mode = "seed_not_validatable"
    elif errors_detected:
        validation_mode = "errors_detected"
    else:
        validation_mode = "unknown"

    # The output is flat key=value text so both humans and batch scripts can consume it.
    report_lines = [
        f"log_path={log_path}",
        f"clock_hz={clock_hz}",
        f"coremark_size={coremark_size}",
        f"total_ticks={total_ticks}",
        f"total_seconds={total_seconds:.6f}",
        f"iterations={iterations}",
        f"iterations_per_sec={iterations_per_sec:.6f}",
        f"coremark_per_mhz={coremark_per_mhz:.6f}",
        f"compiler_version={compiler_version}",
        f"compiler_flags={compiler_flags}",
        f"memory_location={memory_location}",
        f"completion_cycles={completion_cycles}",
        f"validation_clean={yes_no(validation_clean)}",
        f"validation_mode={validation_mode}",
        f"full_workload={yes_no(full_workload)}",
        f"performance_profile_2k={yes_no(performance_profile)}",
        f"runtime_floor_violation={yes_no(runtime_floor_violation)}",
        f"short_runtime_only={yes_no(short_runtime_only)}",
        f"seed_warning={yes_no(seed_warning)}",
        f"errors_detected={yes_no(errors_detected)}",
        f"competition_reportable={yes_no(competition_reportable)}",
        f"strict_eembc_10s_compliant={yes_no(strict_eembc_10s)}",
        (
            "competition_report_line="
            f"CoreMark/MHz (host-parsed): {coremark_per_mhz:.6f} / "
            f"{compiler_version} / {memory_location}"
        ),
        (
            "note=Derived host-side from raw ticks because the HAS_FLOAT=0 "
            "portable path truncates in-program integer seconds."
        ),
        (
            "note_competition=Competition reports may use short reproducible "
            "runs; strict EEMBC validity still requires a >=10 second run."
        ),
    ]

    summary_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    # Preserve shell-friendly exit codes for the surrounding batch wrappers.
    raise SystemExit(main())
