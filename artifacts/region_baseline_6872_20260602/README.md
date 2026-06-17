# Region Baseline 6872 LUT Package

This directory is the region-contest engineering baseline package for the
strict sync-BRAM optimization line.

## Current Authoritative Baseline

This package has been cleaned up to avoid promoting exploratory or timing-failed
scores as baselines. The current accepted reporting baseline is the timing-closed
CPU25 board-facing fallback. The project currently has no accepted strict
50 MHz timing-closed CoreMark-ROM baseline.

### Accepted Timing-Closed Baseline

| Item | Value |
|---|---|
| Baseline tag | `freeze-timingclosed-cpu25-20260605` |
| Configuration | `DCache512 + RC64 + CPU25 timing cuts + PYNQ-Z2 25 MHz MMCM` |
| Post-route LUTs | `6791` |
| CoreMark/MHz | `4.501191` |
| DMIPS/MHz | `1.205669` |
| Timing | `WNS +0.291 ns / WHS +0.065 ns` |
| Demo bitstream | `../freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit` |
| Demo xsim result | `PERF_DEMO PASS checksum=0xe727358b total_cycles=0x00038add` |

### Best Timing-Closed Successor Candidate

| Item | Value |
|---|---|
| Candidate | `CPU25 RC128 BFNext/no-ZBKB timing-driven` |
| Configuration | `DCache512 + RC128 + branch-fold next-cache + no ZBKB + CPU25 timing cuts` |
| Post-route LUTs | `7473` |
| CoreMark/MHz | `4.741458` |
| DMIPS/MHz | `1.205669` |
| Timing | `WNS +1.348 ns / WHS +0.041 ns` |
| Status | candidate only; not board-proven |

### Demoted Low-Resource Reference

| Item | Value |
|---|---|
| Historical tag | `freeze-region-baseline-dcache512-rc64-nonext-noexfwd-6872lut-coremark5p02-20260602` |
| Configuration | `DCache512 + RC64 + nonext + no Zicond + no ID-branch EX-forward` |
| Quick-synth LUTs | `6872` |
| CoreMark/MHz | `5.023480` |
| DMIPS/MHz | `1.275942` |
| Post-route audit | `7063 LUT / WNS -10.360 ns / WHS +0.028 ns` |
| Status | engineering reference only; not timing-closed, not board-facing |

## Why This Baseline

The CPU25 line is the current accepted baseline because it is the only frozen
line that satisfies the current honest-reporting gates: exact implementation
timing is closed, benchmark evidence is recorded, and the bitstream identity is
known. The 7473-LUT CPU25 RC128 BFNext/no-ZBKB result is a better timing-closed
successor candidate, but it has not replaced the fallback baseline until the
project explicitly regenerates and captures its board evidence.

The 2026-06-08 strict 50 MHz CoreMark-ROM freeze audit also failed timing:

`11182 LUT / 5.162186 CoreMark/MHz short-run / WNS -5.800 ns / WHS +0.061 ns`

This means the earlier `5918 LUT / WNS +0.358 ns` historical 50 MHz result must
not be used as the strict CoreMark-ROM freeze baseline. It remains historical
demo-ROM timing evidence only.

## Directory Layout

| Path | Purpose |
|---|---|
| `evidence/` | Benchmark summary files copied from the main experiment ledger. |
| `reports/` | Synthesis utilization, hierarchy, and timing reports. |
| `runbook/` | Commands and notes for reproducing and extending this baseline. |
| `TEST_STATUS.md` | What has been tested and what still needs board-facing evidence. |
| `NEXT_STEPS.md` | Follow-up task list based on this baseline. |
| `REGION_SUBMISSION_STATUS_20260605.md` | Current region-contest wording, evidence matrix, and board-demo task list. |
| `REGION_REPORT_DRAFT_CLEAN_20260609.md` | Clean Chinese narrative draft for the region report or defense slides. |
| `BOARD_EVIDENCE_TEMPLATE.md` | Fill-in template for PROGRAM_OK, UART, and video evidence. |

## Evidence Boundary

Available evidence covers CoreMark, Dhrystone/DMIPS, quick synthesis resource
reports, and one diagnostic full-implementation attempt. The 2026-06-02
implementation attempt reached `7063 LUT / WNS -10.360 ns`, so timing closure,
a board-facing bitstream, and board/UART evidence are still required before
the 6872-LUT version can be described as a final board-facing package.

The CPU25 perf-demo image has a timing-closed bitstream and UART simulation
evidence, but still needs PYNQ-Z2 PROGRAM_OK, UART capture, and video evidence.

The current project has no accepted strict 50 MHz timing-closed freeze baseline.
The next freeze candidate must close post-route timing on the exact benchmark or
application ROM image that will be reported.
