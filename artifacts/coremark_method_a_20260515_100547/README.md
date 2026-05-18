# PYNQ-Z2 CoreMark Method A Artifact

Build timestamp: 20260515_100547

This artifact follows Method A: the CoreMark program image is compiled first, then embedded into the FPGA bitstream through ROM_INIT_HEX/ROM_INIT_MEM32_HEX generics.

## Firmware

- Target: `rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_o2sched_nocaller`
- Iterations: `10`
- Data size: `2000`
- Timer Hz macro: `50000000UL`
- RAM base generic: `65536` decimal, matching linker RAM origin `0x00010000`
- ROM/RAM bytes: `65536` / `65536`

## FPGA

- Board: `Xilinx PYNQ-Z2`
- Part: `xc7z020clg400-1`
- CPU clock: `50 MHz`
- UART: Pmod B PL UART, `115200 8N1`

## Reproduce

Run:

```bat
YH_rv_cpu\scripts\build_pynq_z2_coremark_method_a.bat
```
