# FPGA Bring-Up Notes

This folder is reserved for the Vivado project of `toylog_cpu`.

## Current Status

- No final FPGA top-level wrapper yet
- No board-specific XDC yet
- No block design yet

## Planned Contents

- board-specific top wrapper
- XDC constraints
- memory initialization flow
- UART bring-up
- timer interrupt bring-up
- performance measurement counters

## Expected Target

The first FPGA target should follow the Qixingwei recommendation:

- Xilinx Zynq-7000 or Artix-7 class board
- stable board frequency at or above `50MHz`
- UART-based demonstration path
- later CoreMark measurement path
