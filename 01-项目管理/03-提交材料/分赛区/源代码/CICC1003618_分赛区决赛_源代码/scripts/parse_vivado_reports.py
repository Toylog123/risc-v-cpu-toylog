#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path


def read_text(path):
    if not path or not Path(path).exists():
        return ""
    return Path(path).read_text(encoding="utf-8", errors="ignore")


def first_match(pattern, text, flags=0):
    match = re.search(pattern, text, flags)
    return match.group(1) if match else None


def parse_utilization(text):
    metrics = {}

    patterns = {
        "lut": r"\|\s*Slice LUTs\s*\|\s*([0-9]+)\s*\|",
        "ff": r"\|\s*Slice Registers\s*\|\s*([0-9]+)\s*\|",
        "bram_tile": r"\|\s*Block RAM Tile\s*\|\s*([0-9]+)\s*\|",
        "dsp": r"\|\s*DSPs\s*\|\s*([0-9]+)\s*\|",
    }

    for key, pattern in patterns.items():
        value = first_match(pattern, text)
        if value is not None:
            metrics[key] = int(value)

    return metrics


def parse_timing(text):
    metrics = {}

    summary = re.search(
        r"\n\s*([-+]?[0-9]*\.?[0-9]+)\s+[-+]?[0-9]*\.?[0-9]+\s+\d+\s+\d+\s+"
        r"([-+]?[0-9]*\.?[0-9]+)\s+[-+]?[0-9]*\.?[0-9]+\s+\d+\s+\d+",
        text,
    )
    if summary:
        metrics["wns_ns"] = float(summary.group(1))
        metrics["whs_ns"] = float(summary.group(2))

    if "All user specified timing constraints are met." in text:
        metrics["timing_met"] = True
    elif "Timing constraints are not met." in text:
        metrics["timing_met"] = False

    setup_source = first_match(r"Source:\s+([^\r\n]+)", text)
    setup_dest = first_match(r"Destination:\s+([^\r\n]+)", text)
    if setup_source:
        metrics["worst_setup_source"] = setup_source.strip()
    if setup_dest:
        metrics["worst_setup_destination"] = setup_dest.strip()

    logic_levels = first_match(r"Logic Levels:\s+([0-9]+)", text)
    if logic_levels is not None:
        metrics["worst_setup_logic_levels"] = int(logic_levels)

    data_delay = first_match(r"Data Path Delay:\s+([-+]?[0-9]*\.?[0-9]+)ns", text)
    if data_delay is not None:
        metrics["worst_setup_data_delay_ns"] = float(data_delay)

    return metrics


def format_value(value):
    if value is None:
        return ""
    if isinstance(value, float):
        return f"{value:.3f}"
    if isinstance(value, bool):
        return "yes" if value else "no"
    return str(value)


def main():
    parser = argparse.ArgumentParser(description="Parse Vivado utilization and timing reports.")
    parser.add_argument("--util", help="Vivado utilization report")
    parser.add_argument("--timing", help="Vivado timing summary report")
    parser.add_argument("--name", default="", help="Experiment name")
    parser.add_argument("--coremark", default="", help="CoreMark/MHz value")
    parser.add_argument("--dmips", default="", help="DMIPS/MHz value")
    parser.add_argument("--tech", default="", help="Short technical change description")
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    args = parser.parse_args()

    result = {
        "name": args.name,
        "coremark_per_mhz": args.coremark,
        "dmips_per_mhz": args.dmips,
        "tech": args.tech,
    }
    result.update(parse_utilization(read_text(args.util)))
    result.update(parse_timing(read_text(args.timing)))

    if args.format == "json":
        print(json.dumps(result, indent=2, sort_keys=True))
        return

    columns = [
        "name",
        "lut",
        "ff",
        "bram_tile",
        "dsp",
        "coremark_per_mhz",
        "dmips_per_mhz",
        "wns_ns",
        "whs_ns",
        "timing_met",
        "tech",
    ]
    print("| " + " | ".join(columns) + " |")
    print("|" + "|".join(["---"] * len(columns)) + "|")
    print("| " + " | ".join(format_value(result.get(column)) for column in columns) + " |")


if __name__ == "__main__":
    main()
