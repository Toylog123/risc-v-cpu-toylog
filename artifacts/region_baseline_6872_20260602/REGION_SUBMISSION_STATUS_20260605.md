# Region Submission Status 2026-06-05

## Recommended Region-Contest Wording

Use a single accepted-baseline statement for the current submission package:

`6791 post-route LUT / 4.501191 CoreMark/MHz / 1.205669 DMIPS/MHz / 25 MHz / WNS +0.291 ns / WHS +0.065 ns`.

The CPU25 version is the current accepted baseline because Vivado implementation
closes timing and bitstream generation succeeds. The old 6872-LUT version is now
only a timing-failed low-resource engineering reference. Do not present it as a
current baseline.

## Evidence Matrix

| Version | Role | LUT | CoreMark/MHz | DMIPS/MHz | Timing | Evidence |
|---|---|---:|---:|---:|---|---|
| CPU25 baseline | accepted timing-closed baseline | 6791 post-route | 4.501191 | 1.205669 | WNS +0.291 ns / WHS +0.065 ns | `../freeze_timingclosed_cpu25_20260605/README.md` |
| CPU25 RC128 BFNext/no-ZBKB | timing-closed successor candidate | 7473 post-route | 4.741458 | 1.205669 | WNS +1.348 ns / WHS +0.041 ns | `../freeze_timingclosed_cpu25_20260605/README.md` |
| CPU25 perf demo | contest demonstration image | 6791 post-route | benchmark baseline unchanged | benchmark baseline unchanged | WNS +0.291 ns / WHS +0.065 ns | `../freeze_timingclosed_cpu25_20260605/evidence/perf_demo_summary_20260605.txt` |
| 6872 old reference | demoted timing-failed engineering reference | 6872 quick synth, 7063 post-route | 5.023480 | 1.275942 | WNS -10.360 ns / WHS +0.028 ns | `reports/impl_timing_6872baseline_7063lut_wns-10p360.rpt` |

## Demo Program

The current demonstration program is an automatic UART report, not an interactive menu. This matches the current PL UART TX-only path and avoids adding unverified UART RX RTL.

Workloads:

- CRC32 over a fixed byte buffer
- 8x8 integer matrix multiply
- memory fill/copy bandwidth loop
- branch/control-flow stress loop
- load-use dependent memory stress loop

Verified xsim final line:

```text
PERF_DEMO PASS checksum=0xe727358b total_cycles=0x00038add
```

The PYNQ-Z2 demo bitstream has been generated with the CPU25 timing-closed configuration:

`../freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit`

## What Can Be Claimed Now

- A timing-closed CPU25 version exists and is the accepted reporting baseline: CoreMark/MHz above 4.5, LUT below 8000, post-route timing closed.
- A stronger CPU25 timing-closed successor candidate exists at `7473 LUT / 4.741458 CoreMark/MHz / WNS +1.348 ns`.
- A contest demo application has been added, simulated, and embedded into a timing-closed PYNQ-Z2 bitstream.

## What Still Cannot Be Claimed

- Do not claim the 6872-LUT 5.023480 CoreMark/MHz version is the current baseline or timing-closed.
- Do not claim any strict 50 MHz CoreMark-ROM baseline exists yet.
- Do not claim the 7473-LUT successor is board-proven until its selected bitstream has PROGRAM_OK, UART, and video evidence.
- Do not claim board evidence until PROGRAM_OK, UART capture, and video are collected for the CPU25 perf-demo bitstream.
- Do not claim strict 10-second EEMBC CoreMark compliance until a >=10 second run is captured and documented.

## Immediate Region Package Tasks

| ID | Task | Status | Completion Standard |
|---|---|---|---|
| S01 | Finalize board-facing bitstream identity | done | CPU25 perf-demo bitstream generated and timing closed |
| S02 | Capture PROGRAM_OK | pending | Vivado Hardware Manager log or screenshot identifies the demo bitstream |
| S03 | Capture UART demo output | pending | Raw UART log contains all workload PASS lines and final `PERF_DEMO PASS` |
| S04 | Record short video | pending | Video shows board, programming context, and UART PASS output |
| S05 | Write `BOARD_EVIDENCE.md` | pending | Links bitstream checksum, PROGRAM_OK, UART log, and video path |
| S06 | Prepare cleaned Chinese region narrative draft | done | `REGION_REPORT_DRAFT_CLEAN_20260609.md` uses the single accepted CPU25 baseline wording |
