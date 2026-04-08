# YH_rv_cpu Change Log

## Scope

This file keeps only the milestones that still matter for understanding the
current project baseline. Older one-off debug notes should be read from git
history instead of being treated as the current engineering truth.

## 2026-04-03 - Retain O1 Load-Use Stall Tightening

- Retained `stall_decode = load_use_hazard`
- Short CoreMark improved from `0.888486` to `0.912472 CoreMark/MHz`
- Current competition baseline still inherits this retained change

## 2026-04-04 - Close Strict CoreMark Validation

- Added the strict `>=10s` CoreMark path
- Current strict-valid result:
  - `0.912465 CoreMark/MHz`
  - `1095991523 cycles`
  - `10.959325s`
- The project now has both:
  - short reproducible comparison path
  - strict EEMBC-valid reporting path

## 2026-04-07 - Freeze Competition Baseline

- Refreshed the frozen competition-facing baseline
- Current retained baseline:
  - CoreMark short: `11014885 cycles`, `0.912472 CoreMark/MHz`
  - RV32 baseline: `33/33`
  - RV64 baseline: `21/21`
  - impl50: `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS=+5.599ns`, `WHS=+0.025ns`
  - FPGA-like probe: `156442 cycles`, `7.728811 CoreMark/MHz`
- Closed and rejected the single-variable front-end quick-screen rounds through
  `FQ-05`
- Froze the FPGA pre-board flow and the default `impl50` demo payload

## 2026-04-08 - Expand General `riscv-tests` Coverage And Sync Docs

- Added full-ui manifests:
  - `scripts/riscv_tests_rv32_ui_all.txt`
  - `scripts/riscv_tests_rv64_ui_all.txt`
- Added large linker for broader `riscv-tests` coverage:
  - `sw/linker/YH_rv_cpu_riscv_tests_large.ld`
- Extended `run_riscv_tests_subset.bat` with:
  - custom manifest support
  - custom `march`
  - custom linker
  - custom `tohost_addr`
  - non-fail-fast summary mode
- Added misaligned load/store trap software compensation in
  `sw/riscv-tests-env/riscv_test.h`
- Fresh active result:
  - `rv32 full-ui = 41/42`
  - `ma_data = PASS`
  - only current open item is `fence_i`
- Current root cause for `fence_i` is not timeout or trap looping. It is the
  current compile ISA scope: `-march=rv32i_zicsr` does not include `zifencei`
- Synced the main docs so they now distinguish:
  - frozen baseline
  - active 2026-04-08 validation worktree
