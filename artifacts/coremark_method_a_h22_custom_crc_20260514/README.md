# PYNQ-Z2 CoreMark Method A H22 Custom CRC Artifact

Date: 2026-05-14

This Method A bitstream embeds the H22 CoreMark image. H22 enables custom CRC hardware instructions but does not enable `YH_COREMARK_SKIP_ZERO_STATE_RERUN`.

## Firmware

- Source score summary: `artifacts/coremark8_hw_20260512/logs/h22_custom_crc_only_no_skip_20260514.summary.txt`
- Firmware: `firmware/h22_custom_crc_only_no_skip_20260514.mem32.hex`
- RAM base: `0x00010000`
- CoreMark/MHz: `6.234161`
- Raw ticks: `1604065`
- Completion cycles: `1638280`

## FPGA

- Board: `Xilinx PYNQ-Z2`
- Part: `xc7z020clg400-1`
- CPU clock: `50 MHz`
- ISA: `RV32I + Zmmul + Zba/Zbb/Zbs + Zicond + XThead custom CRC/memidx`
- Resources: `5830 LUT / 2503 FF / 32 BRAM / 15 DSP`
- Timing: `WNS +0.042 ns / WHS +0.040 ns`
- Bitstream: `YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit`

## Boundary

This is an ISA/hardware co-design artifact, not a pure RTL-only benchmark. It is cleaner than the historical fixed75 image because it does not skip the zero-state rerun path.

## Programming

Use the English-path copy when selecting the bitstream manually in Vivado:

```text
vivado_program/YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit
```

Or run the scripted flow from the worktree root:

```bat
YH_rv_cpu\scripts\demo_method_a_h22_custom_crc.bat COM7
```
