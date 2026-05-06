# CoreMark 5+ / DMIPS 3+ Candidate Artifact

This directory freezes the 2026-05-07 exploration candidate for local review and later board bring-up.

## Result Summary

| Item | Result |
| --- | --- |
| Branch | `opt/coremark5-dmips3-20260506` |
| Commit | `8c0585b` |
| CPU config | `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect` |
| CPU clock | `50 MHz` on PYNQ-Z2 |
| CoreMark/MHz | `5.162186` |
| DMIPS/MHz | `3.134092` |
| LUT / FF | `5918 LUT / 2382 FF` |
| BRAM / DSP | `4 BRAM / 15 DSP` |
| Timing | `WNS +0.358 ns / WHS +0.126 ns` |

## Files

- `YH_rv_cpu_pynq_z2_coremark5_dmips3_20260507.bit`: PYNQ-Z2 bitstream generated from this candidate.
- `logs/coremark5_after_lwib_20260507.summary.txt`: CoreMark score summary.
- `logs/coremark5_after_lwib_20260507.log`: CoreMark simulation log.
- `logs/dhrystone_zbc_xthead_idbr_o3_lto_recheck_20260506.summary.txt`: Dhrystone score summary.
- `logs/YH_rv_cpu_dhrystone_zmmul_zbc_xthead_idbr.log`: Dhrystone simulation log.
- `reports/impl_utilization.rpt`: implemented utilization report.
- `reports/impl_timing_summary.rpt`: implemented timing report.
- `reports/synth_utilization.rpt`: synthesis utilization report.
- `reports/synth_timing_summary.rpt`: synthesis timing report.

## Build Command

```bat
set PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE=8.000
set PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=50000000
set PYNQ_USE_CLK_MMCM_62M5_OVERRIDE=0
set PYNQ_USE_CLK_MMCM_50M_OVERRIDE=1
set PYNQ_ENABLE_M_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE=1
set PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE=1
YH_rv_cpu\scripts\build_pynq_z2_project.bat impl
```
