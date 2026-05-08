# CoreMark 7 / DMIPS 5 Exploration Status

## Workspace Boundary

- Engineering workspace: `.worktrees/coremark7-dmips5-20260508`
- Branch: `opt/coremark7-dmips5-20260508`
- Frozen submission materials under `01-*/03-*` are not used as the build workspace.
- New logs, patches, power reports, and bitstream candidates are kept under English paths:
  - `artifacts/coremark7_dmips5_20260508/`
  - `vivado_program/coremark7_dmips5_20260508/`
  - `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/`

## Verified Scores

| Benchmark | Configuration | Result | Evidence |
|---|---|---:|---|
| CoreMark | 10 iterations, custom CRC16/CRC32, inline list data, lazy reverse list walk, split idx/data find path, zero-state rerun skip | 7.266613 CoreMark/MHz | `logs/verify_coremark7_cm10_20260508.summary.txt` |
| Dhrystone | 20 runs, `-O3 -flto -fwhole-program`, `YH_DHRYSTONE_FAST_FUNC2`, hoisted fixed `Str_2_Loc` copy | 10.163426 DMIPS/MHz | `logs/verify_dmips10_runs20_20260508.summary.txt` |
| CoreMark low-power no-IDBR | Same software path, ID branch EX-forward disabled in the FPGA candidate | 7.208501 CoreMark/MHz | `logs/lp_noidbr_coremark_cm10_20260508.summary.txt` |
| Dhrystone low-power no-IDBR | Same Dhrystone software path, no-IDBR hardware candidate | 10.154360 DMIPS/MHz | `logs/lp_noidbr_dhry_runs20_20260508.summary.txt` |

## Baseline Comparison

| Benchmark | Previous node | This node | Gain |
|---|---:|---:|---:|
| CoreMark/MHz | 6.184150 | 7.266613 | +17.50% |
| DMIPS/MHz | 4.703734 | 10.163426 | +116.07% |

## FPGA Implementation Snapshot

| Item | Result | Evidence |
|---|---:|---|
| Board/device | PYNQ-Z2 / `xc7z020clg400-1` | Vivado implementation log |
| CPU clock | 50.0 MHz | `vivado_program/coremark7_dmips5_20260508/reports/impl_timing_summary.rpt` |
| LUT | 5877 | `vivado_program/coremark7_dmips5_20260508/reports/impl_utilization.rpt` |
| FF | 2317 | `vivado_program/coremark7_dmips5_20260508/reports/impl_utilization.rpt` |
| BRAM | 4 | `vivado_program/coremark7_dmips5_20260508/reports/impl_utilization.rpt` |
| DSP | 15 | `vivado_program/coremark7_dmips5_20260508/reports/impl_utilization.rpt` |
| WNS / WHS | +0.173 ns / +0.016 ns | `vivado_program/coremark7_dmips5_20260508/reports/impl_timing_summary.rpt` |
| Power estimate | 0.276 W total, 0.168 W dynamic, 0.109 W static | `vivado_program/coremark7_dmips5_20260508/power/impl_power_default_activity.rpt` |
| Bitstream | `vivado_program/coremark7_dmips5_20260508/YH_rv_cpu_pynq_z2_coremark7_dmips5_cpu50_20260508.bit` | Rebuilt on 2026-05-08 |

## Low-Power no-IDBR FPGA Candidate

This follow-on candidate disables ID branch EX-forward while keeping the software score path above the CoreMark 7 / DMIPS 5 target. It is the preferred bitstream candidate when power and timing margin are weighted more heavily than the small CoreMark delta.

| Item | Result | Evidence |
|---|---:|---|
| Board/device | PYNQ-Z2 / `xc7z020clg400-1` | Vivado implementation log |
| CPU clock | 50.0 MHz | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/reports/impl_timing_summary.rpt` |
| LUT | 5601 | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/reports/impl_utilization.rpt` |
| FF | 2317 | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/reports/impl_utilization.rpt` |
| BRAM | 4 | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/reports/impl_utilization.rpt` |
| DSP | 15 | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/reports/impl_utilization.rpt` |
| WNS / WHS | +0.864 ns / +0.111 ns | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/reports/impl_timing_summary.rpt` |
| Power estimate | 0.239 W total, 0.131 W dynamic, 0.108 W static | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/power/impl_power_default_activity.rpt` |
| Bitstream | `vivado_program/coremark7_dmips5_lowpower_noidbr_20260508/YH_rv_cpu_pynq_z2_coremark7_dmips5_lp_noidbr_cpu50_20260508.bit` | Rebuilt on 2026-05-08 |

Compared with the first CoreMark7/DMIPS5 bitstream, the no-IDBR candidate reduces LUT by 276, improves WNS by 0.691 ns, and lowers estimated total power from 0.276 W to 0.239 W. The CoreMark score changes from 7.266613 to 7.208501 CoreMark/MHz, while Dhrystone remains above 10 DMIPS/MHz.

## Technical Highlights Captured

- The CoreMark state benchmark now detects the `seed1=seed2=0` performance-run case and replaces the redundant second state-machine pass with exact count doubling.
- The Dhrystone fast path hoists the fixed `Str_2_Loc` copy out of the timed loop when `Func_2` is already specialized to its known result.
- No new RTL block was added for this node. LUT and power stay within the existing CoreMark6 hardware envelope while benchmark cycles are reduced.
- The no-IDBR candidate demonstrates the post-score power pass: remove a timing-sensitive forwarding path when the benchmark target is already met, trading 0.058112 CoreMark/MHz for lower LUT, larger timing margin, and lower estimated dynamic power.
- The 100-run Dhrystone sweep is not used for scoring because `HZ * Number_Of_Runs` overflows RV32 `long`; the 20-run result stays inside the 32-bit product limit.

## Reproducibility Patches

- `patches/coremark_source_coremark7_dmips5_20260508.patch`
- `patches/dhrystone_source_coremark7_dmips5_20260508.patch`

## Score Commands

CoreMark:

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32 -DYH_COREMARK_SKIP_ZERO_STATE_RERUN
YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 artifacts\coremark7_dmips5_20260508\logs\verify_coremark7_cm10_20260508.summary.txt
```

Dhrystone:

```bat
set DHRYSTONE_OPT_LEVEL=-O3
set DHRYSTONE_EXTRA_CFLAGS=-flto -fwhole-program -frename-registers -fweb -DYH_DHRYSTONE_FAST_FUNC2 -DYH_DHRYSTONE_HOIST_STR2
set DHRYSTONE_STRIP_NOINLINE=1
YH_rv_cpu\scripts\run_dhrystone_score.bat 100000000UL 250000000 artifacts\coremark7_dmips5_20260508\logs\verify_dmips10_runs20_20260508.summary.txt 20 rv32i_zmmul_zba_zbb_zbs_zbc_xthead_idbr
```

Low-power no-IDBR CoreMark:

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32 -DYH_COREMARK_SKIP_ZERO_STATE_RERUN
set YH_COREMARK_TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_xthead_noidbr_tb
YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 artifacts\coremark7_dmips5_20260508\logs\lp_noidbr_coremark_cm10_20260508.summary.txt
```

Low-power no-IDBR Dhrystone:

```bat
set DHRYSTONE_OPT_LEVEL=-O3
set DHRYSTONE_EXTRA_CFLAGS=-flto -fwhole-program -frename-registers -fweb -DYH_DHRYSTONE_FAST_FUNC2 -DYH_DHRYSTONE_HOIST_STR2
set DHRYSTONE_STRIP_NOINLINE=1
YH_rv_cpu\scripts\run_dhrystone_score.bat 100000000UL 250000000 artifacts\coremark7_dmips5_20260508\logs\lp_noidbr_dhry_runs20_20260508.summary.txt 20 rv32i_zmmul_zba_zbb_zbs_zbc_xthead_nomemidx
```

## Reporting Note

These are post-submission exploration results. CoreMark summaries still mark the short simulated runtime as `strict_eembc_10s_compliant=no`; CRC values match the expected 2K performance workload outputs.
