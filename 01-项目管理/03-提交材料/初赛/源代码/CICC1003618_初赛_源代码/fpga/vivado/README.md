# YH_rv_cpu PYNQ-Z2 FPGA Flow

This directory contains the Vivado flow used for the PYNQ-Z2 FPGA prototype.

## Board Target

- Board: `Xilinx PYNQ-Z2`
- Device: `xc7z020clg400-1`
- PL input clock: `125 MHz`
- CPU clock: `50.0 MHz`
- Primary top: `fpga/vivado/src/YH_rv_cpu_fpga_top.v`
- Constraint template: `constraints/pynq_z2_template.xdc`

## Final Prototype Configuration

- ISA baseline: `RV32I`
- Enabled extensions: `Zmmul`, `Zba/Zbb/Zbs`
- Disabled for final bitstream: hardware division, Zbc, XThead, IDBR exploration path
- ROM size: `16384` bytes for the board demo image
- RAM size: `16384` bytes for stack and byte-spacing delay
- UART output: `uart_rxd_out` mapped to Pmod B `JB1 / Y14`

## Build Entry

From the source package root:

```bat
scripts\build_firmware.bat uart_alive
scripts\build_pynq_z2_uart_alive_print.bat
```

The print build enables the board-level UART diagnostic stream used for the submitted PYNQ-Z2 evidence.

## Board Evidence

The submitted FPGA artifact package records the following implementation result:

- `4961 LUT / 2367 FF / 6 BRAM / 15 DSP`
- `WNS = +0.338 ns`
- `WHS = +0.059 ns`
- Vivado Hardware Manager log contains `PROGRAM_OK: xc7z020_1`
- External CP2102 USB-UART log on `COM7 115200 8N1` shows continuous `YH_rv_cpu CoreMark/MHz=4.137461 DMIPS/MHz=2.908287 tick=XX pc=XXXXXXXX`

PYNQ-Z2 Micro-USB is used for JTAG download and device recognition. PL UART text output is captured through an external 3.3 V USB-UART connected to Pmod B; do not connect the USB-UART VCC pin.
