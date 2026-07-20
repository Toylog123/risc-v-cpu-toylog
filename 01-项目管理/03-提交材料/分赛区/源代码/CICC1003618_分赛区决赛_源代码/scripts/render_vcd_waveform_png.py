#!/usr/bin/env python3
import argparse
import math
import re
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.colors import to_rgba
from vcdvcd import VCDVCD


def parse_args():
    parser = argparse.ArgumentParser(description="Render selected VCD signals to a PNG timing diagram.")
    parser.add_argument("--vcd", required=True, help="Input VCD path")
    parser.add_argument("--out", required=True, help="Output PNG path")
    parser.add_argument("--title", default="", help="Figure title")
    parser.add_argument("--signal", action="append", required=True,
                        help="Signal mapping in LABEL=hier.signal form; can be specified multiple times")
    parser.add_argument("--start-ns", type=float, default=None, help="Optional start time in ns")
    parser.add_argument("--end-ns", type=float, default=None, help="Optional end time in ns")
    return parser.parse_args()


def parse_signal_specs(items):
    specs = []
    for item in items:
        if "=" not in item:
            raise ValueError(f"Bad --signal spec: {item}")
        label, path = item.split("=", 1)
        specs.append((label.strip(), path.strip()))
    return specs


def value_to_int(value):
    if value is None:
        return None
    value = value.lower()
    if any(ch in value for ch in "xzuwlh-"):
        return None
    if value.startswith("b"):
        value = value[1:]
    return int(value, 2)


def value_to_label(value):
    if value is None:
        return "x"
    raw = value.lower()
    if raw.startswith("b"):
        raw = raw[1:]
    if any(ch in raw for ch in "xzuwlh-"):
        return raw
    width = len(raw)
    intval = int(raw, 2)
    hex_digits = max(1, math.ceil(width / 4))
    return f"0x{intval:0{hex_digits}x}"


def signal_is_scalar(path):
    return not re.search(r"\[\d+:\d+\]$", path)


def iter_segments(tvs, end_time_ps, start_ns=None, end_ns=None):
    if not tvs:
        return []
    segments = []
    for idx, (t0, value) in enumerate(tvs):
        t1 = tvs[idx + 1][0] if idx + 1 < len(tvs) else end_time_ps
        if t1 < t0:
            continue
        x0 = t0 / 1000.0
        x1 = t1 / 1000.0
        if start_ns is not None and x1 < start_ns:
            continue
        if end_ns is not None and x0 > end_ns:
            continue
        if start_ns is not None:
            x0 = max(x0, start_ns)
        if end_ns is not None:
            x1 = min(x1, end_ns)
        segments.append((x0, x1, value))
    return segments


def plot_scalar(ax, row_base, segments, color):
    xs = []
    ys = []
    low = row_base + 0.20
    high = row_base + 0.80
    for idx, (x0, x1, value) in enumerate(segments):
        intval = value_to_int(value)
        level = high if intval == 1 else low
        if idx == 0:
            xs.append(x0)
            ys.append(level)
        xs.extend([x0, x1])
        ys.extend([level, level])
    ax.step(xs, ys, where="post", color=color, linewidth=1.8)


def plot_bus(ax, row_base, segments, color):
    top = row_base + 0.82
    bottom = row_base + 0.18
    mid = row_base + 0.50
    for x0, x1, value in segments:
        width = max(0.0, x1 - x0)
        if width <= 0.0:
            continue
        ax.fill_between([x0, x1], bottom, top, color=to_rgba(color, 0.06), linewidth=0)
        ax.vlines([x0, x1], bottom, top, colors=color, linewidth=0.8, alpha=0.65)
        label = value_to_label(value)
        if width >= 8.0:
            ax.text((x0 + x1) / 2.0, mid, label, ha="center", va="center",
                    fontsize=8.5, family="monospace", color=color)


def main():
    args = parse_args()
    specs = parse_signal_specs(args.signal)
    vcd = VCDVCD(args.vcd, store_tvs=True)

    end_time_ps = 0
    prepared = []
    for label, path in specs:
        sig = vcd[path]
        tvs = sig.tv
        if tvs:
            end_time_ps = max(end_time_ps, tvs[-1][0])
        prepared.append((label, path, tvs))

    fig_height = max(3.8, 0.95 * len(prepared) + 1.5)
    fig, ax = plt.subplots(figsize=(14, fig_height))
    colors = ["#2457c5", "#c0392b", "#1e8449", "#7d3c98", "#b9770e", "#148f77", "#566573", "#d35400"]

    for idx, (label, path, tvs) in enumerate(prepared):
        row = len(prepared) - idx - 1
        segments = iter_segments(tvs, end_time_ps, args.start_ns, args.end_ns)
        color = colors[idx % len(colors)]
        if signal_is_scalar(path):
            plot_scalar(ax, row, segments, color)
        else:
            plot_bus(ax, row, segments, color)

    ax.set_xlim(args.start_ns if args.start_ns is not None else 0.0,
                args.end_ns if args.end_ns is not None else (end_time_ps / 1000.0))
    ax.set_ylim(-0.2, len(prepared) + 0.2)
    ax.set_yticks([len(prepared) - idx - 1 + 0.5 for idx in range(len(prepared))])
    ax.set_yticklabels([label for label, _, _ in prepared], fontsize=10)
    ax.set_xlabel("Time (ns)")
    ax.grid(axis="x", linestyle="--", alpha=0.35)
    ax.set_title(args.title)
    ax.set_facecolor("white")
    fig.patch.set_facecolor("white")
    plt.tight_layout()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=180, bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    main()
