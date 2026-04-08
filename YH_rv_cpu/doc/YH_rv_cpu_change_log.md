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
- Legalized `MISC_MEM` decode for `fence` / `fence.i` as non-trapping
  instructions under the current no-I-cache synchronous-memory baseline
- Fresh active result:
  - `rv32 full-ui = 42/42`
  - `rv64 full-ui = 54/54`
  - `rv32 baseline = 33/33`
  - `rv64 baseline = 21/21`
  - fresh CoreMark smoke = `620530 cycles`
  - fresh CoreMark short = `11014885 cycles`, `0.912472 CoreMark/MHz`
- `fence_i` is no longer open in the expanded UI matrix:
  - expanded validation now uses `rv32i_zicsr_zifencei` / `rv64i_zicsr_zifencei`
  - frozen competition ISA baseline still remains `RV32I + Zicsr`
- Synced the main docs so they now distinguish:
  - frozen baseline
  - active 2026-04-08 validation worktree
  - live handoff status during strict CoreMark closure
- Focused commits created during this round:
  - `1f6767f` `test(env): add misaligned load/store trap compensation for riscv-tests`
  - `8e8719d` `test(infra): enable full rv32ui/rv64ui runs with custom manifest/linker/tohost`
  - `e8b22eb` `rtl: legalize misc-mem fence and fence.i decode`
  - `2897dea` `docs: sync fresh baseline and live handoff before strict closure`
- Remaining local closure item:
  - fresh strict `>=10s` CoreMark rerun is in progress; until it finishes,
    `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt` remains the current
    authoritative strict-valid evidence
