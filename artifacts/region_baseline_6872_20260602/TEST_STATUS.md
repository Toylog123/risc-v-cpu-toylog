# Test Status

## Completed Evidence

| Category | Status | Result | Evidence |
|---|---|---:|---|
| CoreMark | done | `5.023480 CoreMark/MHz` | `evidence/coremark_summary_6872lut_5p023480.txt` |
| Dhrystone | done | `1.275942 DMIPS/MHz` | `evidence/dhrystone_summary_6872lut_1p275942.txt` |
| Synthesis utilization | done | `6872 LUT / 3153 FF / 20 BRAM / 8 DSP` | `reports/synth_util_6872lut.rpt` |
| Synthesis hierarchy | done | recorded | `reports/synth_util_hier_6872lut.rpt` |
| Synthesis timing | done | quick-synth timing recorded | `reports/synth_timing_6872lut.rpt` |

## Pending Board-Facing Evidence

| Category | Status | Required Output |
|---|---|---|
| Full implementation | pending | post-route LUT, WNS, WHS, and timing report at 50 MHz |
| Bitstream | pending | generated `.bit` tied to this baseline configuration |
| Board programming | pending | Vivado `PROGRAM_OK` log on PYNQ-Z2 |
| UART/application run | pending | runtime UART output from the FPGA image |
| Video evidence | pending | board run or demo clip using the selected baseline |
| Strict CoreMark run | optional | 10-second compliant run if stricter benchmark reporting is required |

## Reporting Rule

When writing region-contest documents, report this baseline as:

`6872 LUT / 5.023480 CoreMark/MHz / 1.275942 DMIPS/MHz`

Do not describe it as timing-closed or board-proven until full implementation
and board evidence are added to this package.

