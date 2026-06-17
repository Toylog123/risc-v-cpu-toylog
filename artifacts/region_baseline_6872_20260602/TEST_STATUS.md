# Test Status

## Completed Evidence

| Category | Status | Result | Evidence |
|---|---|---:|---|
| Demoted 6872 CoreMark reference | done / not baseline | `5.023480 CoreMark/MHz` | `evidence/coremark_summary_6872lut_5p023480.txt` |
| Demoted 6872 Dhrystone reference | done / not baseline | `1.275942 DMIPS/MHz` | `evidence/dhrystone_summary_6872lut_1p275942.txt` |
| Demoted 6872 synthesis utilization | done / not baseline | `6872 LUT / 3153 FF / 20 BRAM / 8 DSP` | `reports/synth_util_6872lut.rpt` |
| Synthesis hierarchy | done | recorded | `reports/synth_util_hier_6872lut.rpt` |
| Synthesis timing | done | quick-synth timing recorded | `reports/synth_timing_6872lut.rpt` |
| Full implementation attempt | done / timing failed | `7063 LUT / WNS -10.360 ns / WHS +0.028 ns` | `reports/impl_utilization_6872baseline_7063lut_wns-10p360.rpt`, `reports/impl_timing_6872baseline_7063lut_wns-10p360.rpt` |
| Strict 50 MHz CoreMark-ROM freeze audit | done / timing failed | `11182 LUT / 5.162186 CoreMark/MHz short-run / WNS -5.800 ns / WHS +0.061 ns` | `../strict_50m_coremark_freeze_audit_20260608/` |
| CPU25 timing-closed baseline | done | `6791 LUT / WNS +0.291 ns / WHS +0.065 ns` | `../freeze_timingclosed_cpu25_20260605/reports/impl_timing_summary_cpu25_wns+0p291.rpt` |
| CPU25 RC128 timing-closed candidate | done / board pending | `7076 LUT / 4.627215 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +0.514 ns / WHS +0.056 ns` | `../freeze_timingclosed_cpu25_20260605/experiments/CPU25_RC128_EXPERIMENT_20260605.md` |
| CPU25 performance demo xsim | done | `PERF_DEMO PASS checksum=0xe727358b total_cycles=0x00038add` | `../freeze_timingclosed_cpu25_20260605/evidence/perf_demo_summary_20260605.txt` |
| CPU25 performance demo bitstream | done | `6791 LUT / WNS +0.291 ns / WHS +0.065 ns` | `../freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit` |

## Pending Board-Facing Evidence

| Category | Status | Required Output |
|---|---|---|
| 6872 timing-closed full implementation | pending | post-route WNS >= 0 at the audited 50 MHz target |
| 50 MHz strict CoreMark-ROM timing-closed version | pending | exact benchmark ROM image closes post-route timing at 50 MHz and CoreMark/MHz remains >= 4.3 |
| Board-facing bitstream | done for CPU25 demo | generated `.bit` tied to a timing-closed baseline configuration |
| Board programming | pending | Vivado `PROGRAM_OK` log on PYNQ-Z2 |
| UART/application run | pending | runtime UART output from the CPU25 perf-demo FPGA image |
| Video evidence | pending | board run or demo clip using the CPU25 perf-demo bitstream |
| Strict CoreMark run | optional | 10-second compliant run if stricter benchmark reporting is required |

## Reporting Rule

When writing region-contest documents, report the accepted baseline as:

`6791 LUT / 4.501191 CoreMark/MHz / 1.205669 DMIPS/MHz / 25 MHz / WNS +0.291 ns / WHS +0.065 ns`

The best recorded timing-closed successor candidate is:

`7473 LUT / 4.741458 CoreMark/MHz / 1.205669 DMIPS/MHz / 25 MHz / WNS +1.348 ns / WHS +0.041 ns`

Do not call the successor board-proven until PROGRAM_OK, UART, and video
evidence are captured for its selected bitstream.

The old 6872 row may only be reported as a timing-failed engineering reference:

`6872 LUT / 5.023480 CoreMark/MHz / 1.275942 DMIPS/MHz`

Do not describe the 6872-LUT version as timing-closed or board-proven until full
implementation and board evidence are added for that exact configuration.

Do not describe the historical `5918 LUT / WNS +0.358 ns` 50 MHz run as the
strict CoreMark-ROM freeze baseline. The 2026-06-08 strict CoreMark-ROM audit
failed timing at `11182 LUT / WNS -5.800 ns`; use it as rejection evidence.

## Full Implementation Attempt Notes

The exact 6872 quick-synthesis baseline was run through Vivado implementation on
2026-06-02. Bitstream generation completed, but timing did not close. The worst
reported setup path is from `u_soc/u_cpu/ex_mem_mem_addr_r_reg[3]/C` to
`u_soc/u_cpu/pc_r_reg[30]/D`, with `41` logic levels and a data path delay of
`30.328 ns`. Treat this as diagnostic evidence only; do not use the generated
bitstream as the board-facing contest image until the timing path is fixed.
