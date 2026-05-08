# PYNQ-Z2 Bitstream Candidate: CoreMark7 / DMIPS5 Area no-Zbc

This directory keeps the English-path FPGA artifacts for the area-focused post-submission exploration candidate.

## Bitstream

- `YH_rv_cpu_pynq_z2_coremark7_dmips5_area_nozbc_xthead_noidbr_cpu50_20260508.bit`

## Build Configuration

- Board: Xilinx PYNQ-Z2
- Device: `xc7z020clg400-1`
- CPU clock: 50.0 MHz
- Enabled CPU features: Zmmul, Zba/Zbb/Zbs, XThead, XThead conditional move
- Disabled CPU features for this candidate: full M divide, Zbc, Zicond, Zbkb, ID branch EX-forward

## Implementation Result

- LUT: 5097
- FF: 2316
- BRAM: 4
- DSP: 15
- WNS: +0.546 ns
- WHS: +0.118 ns
- Default-activity power estimate: 0.279 W total, 0.170 W dynamic, 0.109 W static

Reports are in `reports/`, Vivado logs are in `logs/`, and the default-activity power report is in `power/`.

## Score Evidence

- CoreMark: 7.208501 CoreMark/MHz, log `artifacts/coremark7_dmips5_20260508/logs/lp_nozbc_xthead_coremark_cm10_20260508.summary.txt`
- Dhrystone reference without Zbc/XThead: 10.145310 DMIPS/MHz, log `artifacts/coremark7_dmips5_20260508/logs/lp_nozbc_noxthead_dhry_runs20_20260508.summary.txt`

This candidate is useful for LUT reduction. The lower-power recommended candidate remains `coremark7_dmips5_lowpower_noidbr_20260508` because its default-activity power estimate is lower.
