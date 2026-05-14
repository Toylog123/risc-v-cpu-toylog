# PYNQ-Z2 CoreMark Method A Artifact

Date: 2026-05-14

This artifact follows Method A: the CoreMark program image is embedded in the FPGA bitstream through `ROM_INIT_HEX` / `ROM_INIT_MEM32_HEX`. After programming the bitstream, the CPU starts from on-chip ROM and prints the CoreMark banner, raw ticks, CRC lines, and completion status through the PL UART.

## Firmware Image

- Byte hex: `firmware/verify_coremark75_nozbc_zicond_cm10_corrected_20260510.hex`
- 32-bit hex: `firmware/verify_coremark75_nozbc_zicond_cm10_corrected_20260510.mem32.hex`
- Linker RAM origin: `0x00010000`
- FPGA `RAM_BASE` generic: `65536`
- ROM/RAM size generics: `65536` / `65536` bytes
- Fresh final-code simulation summary: `fixedhex_final_h13_method_a_image_cm10.summary.txt`
- Fresh final-code Dhrystone summary: `dhrystone_final_h13.summary.txt`

## FPGA Result

- Board: `Xilinx PYNQ-Z2`
- Part: `xc7z020clg400-1`
- CPU clock: `50 MHz`
- Bitstream: `YH_rv_cpu_pynq_z2_method_a_fixed75_20260514.bit`
- Implementation utilization: `5791 LUT / 2503 FF / 32 BRAM / 15 DSP`
- Implementation timing: `WNS +0.095 ns / WHS +0.038 ns`
- UART: Pmod B PL UART, `115200 8N1`

## Reporting Boundary

The simulation score for this exact fixed image is `7.502641 CoreMark/MHz`, derived from raw ticks in the UART log. It is a short reproducible run, not a strict 10-second EEMBC-certified run. The artifact is valid as a board reproducibility and competition demonstration evidence path because the bitstream contains the same fixed program image and Vivado reports show timing closure.

This image must also be disclosed as a historical ISA/software co-design image: it uses custom CRC hardware instructions and the `YH_COREMARK_SKIP_ZERO_STATE_RERUN` macro path. See `METHOD_A_VALIDATION.md` and `../coremark8_hw_20260512/H20_COREMARK_REBUILD_AUDIT.md` before using the score in any formal comparison.

## Rebuild This Fixed-Image Bitstream

Run:

```bat
YH_rv_cpu\scripts\build_pynq_z2_coremark_fixed75_method_a.bat
```

This script intentionally reuses the archived fixed firmware image. The separate `build_pynq_z2_coremark_method_a.bat` script recompiles CoreMark and is useful for clean software rebuild checks, but it is not the same firmware image as this `fixed75` artifact.

## Program and Capture on PYNQ-Z2

For manual video recording, open the UART monitor before programming:

```bat
YH_rv_cpu\scripts\watch_uart_live.bat COM7
```

Then program the bitstream from another terminal:

```bat
YH_rv_cpu\scripts\program_pynq_z2_method_a_fixed75.bat
```

For a single repeatable capture command:

```bat
YH_rv_cpu\scripts\demo_method_a_program_and_capture.bat COM7
```

Vivado-friendly copies are also available under `vivado_program/`:

- `vivado_program/YH_rv_cpu_pynq_z2_method_a_fixed75_20260514.bit`
- `vivado_program/coremark_method_a_fixed75_20260514/YH_rv_cpu_pynq_z2_method_a_fixed75_20260514.bit`
