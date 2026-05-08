# FPGA App Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a PYNQ-Z2 board demo firmware that runs visible application workloads on YH_rv_cpu and prints PASS/checksum evidence through the PL UART.

**Architecture:** Add a new bare-metal firmware target `fpga_app_demo` that exercises QuickSort, CRC/bit-mix, and matrix multiply. Add a SoC UART simulation test that watches for the expected banner and PASS markers before any board bitstream is generated. Keep the existing frozen bitstream intact and generate a separate app-demo bitstream for recording.

**Tech Stack:** RV32 bare-metal C/assembly, existing MMIO UART at `0x10000000`, Vivado/xsim, PYNQ-Z2 Vivado project scripts.

---

### Task 1: Test Harness

**Files:**
- Create: `源代码/CICC1003618_初赛_源代码/tb/YH_rv_cpu_soc_fpga_app_demo_tb.v`
- Create: `源代码/CICC1003618_初赛_源代码/scripts/run_soc_fpga_app_demo.bat`

- [x] **Step 1: Write failing simulation test**
  - The test loads `build/sw/YH_rv_cpu_fpga_app_demo.hex`.
  - It fails until the firmware target exists.
  - It watches UART bytes for `YH_rv_cpu FPGA APP DEMO`, `QuickSort PASS`, `CRC PASS`, `MatrixMul PASS`, and `APP_DEMO_DONE`.

- [x] **Step 2: Run the test and confirm RED**
  - Run: `cmd /c scripts\run_soc_fpga_app_demo.bat`
  - Expected: failure because `fpga_app_demo` build target or hex image is missing.

### Task 2: Firmware

**Files:**
- Create: `源代码/CICC1003618_初赛_源代码/sw/src/fpga_app_demo.S`
- Modify: `源代码/CICC1003618_初赛_源代码/scripts/build_firmware.bat`

- [x] **Step 1: Implement minimal UART helpers**
  - MMIO UART TX: `0x10000000`.
  - DONE register: `0x10000004`.
  - Print ASCII only, no libc dependency.

- [x] **Step 2: Implement application workloads**
  - Deterministic register sorting network with checksum.
  - CRC-like bit-mix loop to exercise shifts/xors/bit operations.
  - 2x2 matrix multiply checksum to exercise multiply-heavy paths.

- [x] **Step 3: Add build target**
  - `scripts/build_firmware.bat fpga_app_demo` builds `YH_rv_cpu_fpga_app_demo.hex` and `.mem32.hex`.

### Task 3: Verification

**Files:**
- Generated evidence under `build/` and later copied to submission evidence folders if retained.

- [x] **Step 1: Run app demo simulation**
  - Run: `cmd /c scripts\build_firmware.bat fpga_app_demo`
  - Run: `cmd /c scripts\run_soc_fpga_app_demo.bat`
  - Expected: PASS and UART log includes all app markers.

- [x] **Step 2: Re-run existing UART alive smoke**
  - Run: `cmd /c scripts\run_soc_uart_alive.bat`
  - Expected: PASS, proving the old demo path still works.

### Task 4: PYNQ-Z2 Bitstream

**Files:**
- Modify or create wrapper script under `源代码/CICC1003618_初赛_源代码/scripts/`
- Generate: `vivado_program/YH_rv_cpu_pynq_z2_fpga_app_demo_cpu50_20260507.bit`

- [x] **Step 1: Add app-demo build wrapper**
  - Build firmware first.
  - Set `ROM_INIT_HEX_OVERRIDE` and `ROM_INIT_MEM32_HEX_OVERRIDE` to the app-demo images.
  - Disable FPGA top diagnostic stream if CPU software UART output is stable.

- [x] **Step 2: Build implementation**
  - Run the wrapper with `impl`.
  - Expected: bitstream generated with timing reports.

### Task 5: User Recording Instructions

**Files:**
- Create: `FPGA原型系统/fpga_artifacts_pynq_z2/APP_DEMO_UART_RESULT_2026-05-07.md`

- [x] **Step 1: Write recording commands**
  - Vivado bit path.
  - Terminal command to watch UART.
  - Expected output snippets.
