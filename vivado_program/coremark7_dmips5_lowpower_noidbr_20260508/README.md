# PYNQ-Z2 Bitstream Candidate: CoreMark7 / DMIPS5 Low-Power no-IDBR

This directory keeps the English-path FPGA artifacts for the lower-power post-submission exploration candidate.

## Bitstream

- `YH_rv_cpu_pynq_z2_coremark7_dmips5_lp_noidbr_cpu50_20260508.bit`

## Build Configuration

- Board: Xilinx PYNQ-Z2
- Device: `xc7z020clg400-1`
- CPU clock: 50.0 MHz
- Enabled CPU features: Zmmul, Zba/Zbb/Zbs, Zbc, XThead, XThead conditional move
- Disabled CPU features for this candidate: full M divide, Zicond, Zbkb, ID branch EX-forward, failed XSTATE exploration path

## Implementation Result

- LUT: 5601
- FF: 2317
- BRAM: 4
- DSP: 15
- WNS: +0.864 ns
- WHS: +0.111 ns
- Default-activity power estimate: 0.239 W total, 0.131 W dynamic, 0.108 W static

Reports are in `reports/`, Vivado logs are in `logs/`, and the default-activity power report is in `power/`.

## Score Evidence

- CoreMark: 7.208501 CoreMark/MHz, log `artifacts/coremark7_dmips5_20260508/logs/lp_noidbr_coremark_cm10_20260508.summary.txt`
- Dhrystone: 10.154360 DMIPS/MHz, log `artifacts/coremark7_dmips5_20260508/logs/lp_noidbr_dhry_runs20_20260508.summary.txt`
