# Region Baseline 6872 LUT Package

This directory is the region-contest engineering baseline package for the
strict sync-BRAM optimization line.

## Selected Baseline

| Item | Value |
|---|---|
| Baseline tag | `freeze-region-baseline-dcache512-rc64-nonext-noexfwd-6872lut-coremark5p02-20260602` |
| Configuration | `DCache512 + RC64 + nonext + no Zicond + no ID-branch EX-forward` |
| Slice LUTs | `6872` |
| CoreMark/MHz | `5.023480` |
| DMIPS/MHz | `1.275942` |
| FF | `3153` |
| BRAM | `20` |
| DSP | `8` |

## Why This Baseline

This point is selected as the current region-contest baseline because it is the
lowest recorded LUT point that keeps CoreMark above 5 under the strict
sync-BRAM evidence. Larger points such as 7164 LUT and 7853 LUT remain useful
exploration references, but later low-resource work should report deltas
against this 6872-LUT baseline.

## Directory Layout

| Path | Purpose |
|---|---|
| `evidence/` | Benchmark summary files copied from the main experiment ledger. |
| `reports/` | Synthesis utilization, hierarchy, and timing reports. |
| `runbook/` | Commands and notes for reproducing and extending this baseline. |
| `TEST_STATUS.md` | What has been tested and what still needs board-facing evidence. |
| `NEXT_STEPS.md` | Follow-up task list based on this baseline. |

## Evidence Boundary

Available evidence covers CoreMark, Dhrystone/DMIPS, and quick synthesis
resource reports. Full implementation timing, generated bitstream, and
board/UART evidence are still required before this can be described as a final
board-facing package.

