# PYNQ-Z2 CoreMark Method A Artifact

Build timestamp: `20260514_172753`

This artifact follows Method A: the CoreMark program image is compiled first,
then embedded into the FPGA bitstream through `ROM_INIT_HEX` /
`ROM_INIT_MEM32_HEX` generics. The path uses synchronous ROM/RAM so that the
simulation evidence matches the FPGA Block RAM execution model.

## Firmware

- Target: `rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller`
- Iterations: `10`
- Data size: `2000`
- Timer Hz macro: `100000000UL`
- RAM base generic: `65536` decimal, matching linker RAM origin `0x00010000`
- ROM/RAM bytes: `65536` / `65536`

## FPGA

- Board: `Xilinx PYNQ-Z2`
- Part: `xc7z020clg400-1`
- CPU clock: `50 MHz`
- UART: Pmod B PL UART, `115200 8N1`
- Bitstream: `YH_rv_cpu_pynq_z2_method_a_coremark_20260514_172753.bit`
- Timing: `WNS +0.120 ns`, `WHS +0.050 ns`, all specified timing constraints met
- Resources: `5963 LUT`, `2645 FF`, `32 BRAM`, `15 DSP`

## Verification Snapshot

- Simulation log:
  `artifacts/coremark8_hw_20260512/logs/h54_fpga_sync_perf2k_full_cm10_scriptpass_20260514.log`
- Parsed summary:
  `artifacts/coremark8_hw_20260512/logs/h54_fpga_sync_perf2k_full_cm10_scriptpass_20260514.summary.txt`
- Full 2K workload evidence:
  `CoreMark Size=666`, `Iterations=10`, `Total ticks=2661323`,
  `seedcrc=0xe9f5`, `crcfinal=0xfcaf`
- Host-parsed score for this synchronous Method A path:
  `3.757530 CoreMark/MHz`
- The run is competition-reproducible short evidence. It is not an EEMBC
  certified strict 10-second run because the FPGA-style simulation completes in
  less than 10 seconds of target time.

## Reproduce

Run:

```bat
YH_rv_cpu\scripts\build_pynq_z2_coremark_method_a.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 10 2000 100000000UL
```

For Vivado manual programming, a convenience copy is also kept under:

```text
vivado_program/coremark_method_a_syncbram_20260514/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit
```
