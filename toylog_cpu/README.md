# toylog_cpu

`toylog_cpu` is the formal project name for the Qixingwei competition implementation.

Current location: workspace root `toylog_cpu/`.

## Goal

- Original RISC-V CPU implementation for the Qixingwei topic
- English project structure and source names
- Starter RTL + toolchain scripts + preliminary design
- Direct path to a 5-stage RV32I competition core

## Competition Alignment

The current project layout is aligned with the topic requirements:

- RV32I first, then optional RV32M expansion
- 5-stage pipeline as the target microarchitecture
- Verilog modeling, testbench-based verification, and FPGA bring-up path
- Space reserved for two required optimization items
- Space reserved for test programs, build scripts, and documentation

## Important Note

This project is self-written and is not copied from `picorv32`, `rocket-chip`, or any other
open-source CPU RTL. Existing external repositories in the workspace are now treated only as
plain reference material, not as upstream-synced sub-repositories.

## Layout

- `rtl/toylog_cpu_defs.vh`: local constants
- `rtl/toylog_cpu_alu.v`: ALU
- `rtl/toylog_cpu_regfile.v`: 32 x 32 register file
- `rtl/toylog_cpu_decoder.v`: RV32I decoder
- `rtl/toylog_cpu_if_stage.v`: fetch stage
- `rtl/toylog_cpu_id_stage.v`: decode stage
- `rtl/toylog_cpu_ex_stage.v`: execute stage
- `rtl/toylog_cpu_mem_stage.v`: memory stage
- `rtl/toylog_cpu_wb_stage.v`: write-back stage
- `rtl/toylog_cpu_hazard_unit.v`: stall and forwarding control
- `rtl/toylog_cpu.v`: 5-stage top-level core
- `tb/toylog_cpu_tb.v`: smoke testbench
- `sw/src`: bare-metal demo sources
- `sw/linker`: linker script
- `doc/toylog_cpu_preliminary_design.md`: preliminary architecture
- `doc/toylog_cpu_handoff.md`: current handoff status
- `doc/toylog_cpu_change_log.md`: change record
- `doc/toylog_cpu_todo.md`: execution todo list
- `scripts/check_toolchain.bat`: toolchain probe
- `scripts/check_syntax.bat`: RTL syntax check
- `scripts/iverilog_sources.f`: syntax-check file list
- `scripts/build_firmware.bat`: firmware build starter
- `fpga/vivado/README.md`: FPGA-stage notes

## Current Status

- Working RV32I 5-stage baseline with separate IF / ID / EX / MEM / WB stage files
- Basic load-use stalling and EX/MEM, MEM/WB forwarding are present
- Separate instruction and data memory interfaces
- Path-independent scripts for Windows workspace roots
- Preliminary software and build flow in place
- Not yet the final competition-ready SoC or FPGA image

## Quick Start

Run these scripts from Windows Explorer or a terminal:

- `scripts\check_toolchain.bat`
- `scripts\check_syntax.bat`
- `scripts\build_firmware.bat`

Read these docs before handoff or new work:

- `doc\toylog_cpu_handoff.md`
- `doc\toylog_cpu_change_log.md`
- `doc\toylog_cpu_todo.md`

## Next Steps

1. Add CSR, trap, and timer support
2. Build a SoC wrapper with ROM, RAM, UART, and timer
3. Create a stable regression flow with `riscv-tests`
4. Add the first competition optimization item: stronger branch handling
5. Add the second competition optimization item: prefetch or lightweight prediction
6. Create a Vivado project for board bring-up and timing closure
