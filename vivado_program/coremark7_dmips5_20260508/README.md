# PYNQ-Z2 Bitstream Candidate: CoreMark7 / DMIPS5

This directory is the English-path FPGA artifact location for the post-submission exploration branch.

## Bitstream

- `YH_rv_cpu_pynq_z2_coremark7_dmips5_cpu50_20260508.bit`

## Build Configuration

- Board: Xilinx PYNQ-Z2
- Device: `xc7z020clg400-1`
- CPU clock: 50.0 MHz
- Enabled CPU features: Zmmul, Zba/Zbb/Zbs, Zbc, XThead, XThead conditional move, ID branch EX-forward
- Disabled CPU features for this candidate: full M divide, Zicond, Zbkb, failed XSTATE exploration path

## Implementation Result

- LUT: 5877
- FF: 2317
- BRAM: 4
- DSP: 15
- WNS: +0.173 ns
- WHS: +0.016 ns
- Default-activity power estimate: 0.276 W total, 0.168 W dynamic, 0.109 W static

Reports are in `reports/`, Vivado logs are in `logs/`, and the default-activity power report is in `power/`.
