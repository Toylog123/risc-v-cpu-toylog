# Test Status

## Completed Evidence

| Category | Status | Result | Evidence |
|---|---|---:|---|
| CoreMark | done | `5.023480 CoreMark/MHz` | `evidence/coremark_summary_6872lut_5p023480.txt` |
| Dhrystone | done | `1.275942 DMIPS/MHz` | `evidence/dhrystone_summary_6872lut_1p275942.txt` |
| Synthesis utilization | done | `6872 LUT / 3153 FF / 20 BRAM / 8 DSP` | `reports/synth_util_6872lut.rpt` |
| Synthesis hierarchy | done | recorded | `reports/synth_util_hier_6872lut.rpt` |
| Synthesis timing | done | quick-synth timing recorded | `reports/synth_timing_6872lut.rpt` |
| Full implementation attempt | done / timing failed | `7063 LUT / WNS -10.360 ns / WHS +0.028 ns` | `reports/impl_utilization_6872baseline_7063lut_wns-10p360.rpt`, `reports/impl_timing_6872baseline_7063lut_wns-10p360.rpt` |

## Pending Board-Facing Evidence

| Category | Status | Required Output |
|---|---|---|
| Timing-closed full implementation | pending | post-route WNS >= 0 at 50 MHz |
| Board-facing bitstream | pending | generated `.bit` tied to a timing-closed baseline configuration |
| Board programming | pending | Vivado `PROGRAM_OK` log on PYNQ-Z2 |
| UART/application run | pending | runtime UART output from the FPGA image |
| Video evidence | pending | board run or demo clip using the selected baseline |
| Strict CoreMark run | optional | 10-second compliant run if stricter benchmark reporting is required |

## Reporting Rule

When writing region-contest documents, report this baseline as:

`6872 LUT / 5.023480 CoreMark/MHz / 1.275942 DMIPS/MHz`

Do not describe it as timing-closed or board-proven until full implementation
and board evidence are added to this package.

## Full Implementation Attempt Notes

The exact 6872 quick-synthesis baseline was run through Vivado implementation on
2026-06-02. Bitstream generation completed, but timing did not close. The worst
reported setup path is from `u_soc/u_cpu/ex_mem_mem_addr_r_reg[3]/C` to
`u_soc/u_cpu/pc_r_reg[30]/D`, with `41` logic levels and a data path delay of
`30.328 ns`. Treat this as diagnostic evidence only; do not use the generated
bitstream as the board-facing contest image until the timing path is fixed.
