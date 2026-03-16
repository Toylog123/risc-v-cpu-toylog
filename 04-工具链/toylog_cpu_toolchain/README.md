# toylog_cpu Toolchain Guide

## Purpose

This folder documents the competition-oriented toolchain baseline for `toylog_cpu`.

It serves two goals:

- keep the team on a consistent minimum environment
- map the competition recommendations to the actual project workflow

## Team Baseline

The current team baseline is:

- `Git`
- `Vivado 2025.2`
- `xsim`
- `iverilog`
- `riscv-none-elf-gcc`
- `riscv-none-elf-objdump`
- `riscv-none-elf-objcopy`

The detailed team-facing install note is:

- `04-工具链/toylog_cpu_toolchain/队伍安装清单.md`

## Competition Mapping

The competition topic recommends:

- RTL design with Verilog/VHDL
- TestBench-based simulation
- module and system verification
- `riscv-tests`
- FPGA implementation
- optional formal verification

This project maps that recommendation to:

- quick syntax check: `iverilog`
- main simulation path: `xsim`
- firmware build: `riscv-none-elf-*`
- FPGA flow: `Vivado`
- follow-up verification: `riscv-tests` and `CoreMark`

## Project Scripts

Use the scripts under:

- `toylog_cpu/scripts/check_toolchain.bat`
- `toylog_cpu/scripts/check_syntax.bat`
- `toylog_cpu/scripts/build_firmware.bat`

## Engineering Rules

- The project must not depend on a device-specific absolute path.
- Local scripts should resolve the project root from the script location.
- Tools should be taken from `PATH` first, then from known local installs when needed.
- Source code comments in `toylog_cpu` should default to Chinese.

## Workspace Policy

- Do not keep an unbuilt `riscv-gnu-toolchain` source tree in this workspace.
- Do not keep unrelated large reference repositories as part of the active flow.
- Keep this folder focused on toolchain notes and project-facing scripts only.

## 2026-03-16 Local Snapshot

- `iverilog`: installed
- `rg` (`ripgrep`): installed
- `Vivado 2025.2`: installed
- `xsim`: available
- `riscv-none-elf-gcc`: installed via `xPack`
- `riscv-none-elf-objdump`: available
- `riscv-none-elf-objcopy`: available
- `vsim`: not installed
