# Performance Experiment Log

## Frozen Baseline (2026-04-07)

Use this baseline before starting any competition-facing optimization work.

### CoreMark

| Item | Value |
|------|------|
| Command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Raw log | `build/sw/YH_rv_cpu_coremark_rv32_score.log` |
| Summary | `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt` |
| Result | `CoreMark/MHz = 0.912472` |
| Short completion cycles | `11014885` |
| Strict-valid companion | `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt` -> `0.912465`, `1095991523 cycles`, `10.959325s` |

### riscv-tests baseline

| Item | Value |
|------|------|
| RV32 baseline manifest | `scripts\riscv_tests_rv32_baseline.txt` |
| RV32 fresh result | `33/33` |
| RV64 baseline manifest | `scripts\riscv_tests_rv64_baseline.txt` |
| RV64 fresh result | `21/21` |

### FPGA impl50 / probe

| Item | Value |
|------|------|
| Command | `scripts\build_vivado_project.bat impl50` |
| Bitstream | `project/YH_rv_cpu_nexys_a7_100_20p000.bit` |
| Timing report | `project/reports/clk_20p000ns/impl_timing_summary.rpt` |
| Utilization report | `project/reports/clk_20p000ns/impl_utilization.rpt` |
| WNS / WHS | `+5.599ns / +0.025ns` |
| Slice LUTs / FF / BRAM / DSP | `2556 / 2170 / 4 / 0` |
| FPGA-like probe | `156442 cycles`, `7.728811 CoreMark/MHz` |

## Retained Optimizations

### O1 - Tighten synchronous load hazard stall

| Item | Value |
|------|------|
| Change | `stall_decode` stalls only on `load_use_hazard` |
| Files | `rtl/YH_rv_cpu_hazard_unit.v` |
| Before | `CoreMark/MHz = 0.888486` |
| After | `CoreMark/MHz = 0.912472` |
| Delta | `+0.023986` (`+2.70%`) |
| Keep? | `yes` |

### O2 - FPGA path defaults

| Item | Value |
|------|------|
| Change | Retain `IMEM_OUTPUT_REG=0` and `DMEM_OUTPUT_REG=0` on FPGA path |
| Files | `fpga/vivado/src/YH_rv_cpu_fpga_top.v`, `tb/YH_rv_cpu_coremark_fpga_tb.v` |
| Probe result | `156442 cycles`, `7.728811 CoreMark/MHz` |
| impl50 result | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS=+5.599ns`, `WHS=+0.025ns` |
| Keep? | `yes` |

Final retained state:

- `stall_decode = load_use_hazard`
- FPGA default `IMEM_OUTPUT_REG=0`
- FPGA default `DMEM_OUTPUT_REG=0`

## Closed / Rejected Optimization Directions

The following directions were fully executed and rejected because they produced
no retainable benefit or failed guardrails:

| Direction | Result | Reason |
|------|------|------|
| Simple `stall_decode` relaxation for fetch-side gain | closed | current fetch PC freezes under stall, so relaxing the gate is not a safe one-line optimization |
| O6 fetch-side prefetch / request cursor | rejected | directed behavior could be shown, but short CoreMark delta remained `0` |
| redirect `pipe-hit` recheck | rejected | strict diagnostics could pass, but short score stayed flat |
| redirect same-cycle request | rejected | functionally green, score delta `0` |
| FQ-01 queue-decouple | rejected | guardrails green, score delta `0` |
| FQ-02 queue/FIFO occupancy | rejected | guardrails green, score delta `0` |
| FQ-03 explicit 3-entry queue | rejected | guardrails green, score delta `0` |
| FQ-04 IF/ID redirect-hit bubble bypass | rejected | score regressed by one cycle |
| FQ-05A queue-consume/data-write align | rejected | score delta `0` |
| FQ-05B redirect-reuse next-line prefetch | rejected | score delta `0` |
| FQ-05C IF/ID mem-wait preload | rejected | redirect guardrail failed early |

## 2026-04-08 Validation-Led Pause Before Further Optimization

This round does not introduce a new retained optimization. Instead, it expands
the verification envelope before any higher-intrusion optimization work such as
`FQ-06`.

### Worktree changes under active validation

- `scripts\run_riscv_tests_subset.bat`
  - adds custom manifest, `march`, linker, `tohost_addr`, `max_cycles`, and
    non-fail-fast support
- `tb\YH_rv_cpu_riscv_tests_tb.v`
  - adds runtime-configurable `tohost_addr`
- `sw\riscv-tests-env\riscv_test.h`
  - adds misaligned load/store trap software compensation for `riscv-tests`
- new formal inputs:
  - `scripts\riscv_tests_rv32_ui_all.txt`
  - `scripts\riscv_tests_rv64_ui_all.txt`
  - `sw\linker\YH_rv_cpu_riscv_tests_large.ld`

### Fresh evidence from this round

| Item | Result |
|------|------|
| Command | `scripts\run_riscv_tests_subset.bat rv32 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv32_ui_all.txt rv32i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000` |
| Overall result | `42/42` |
| Summary | `build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt` |
| RV64 full-ui | `54/54` via `build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt` |
| Newly important pass | `ma_data` |
| `fence_i` handling | `PASS` under `rv32i_zicsr_zifencei` |
| Coverage statement | expanded UI coverage matrix now includes `zifencei`; frozen competition baseline remains `RV32I + Zicsr` |
| RV32 baseline fresh rerun | `33/33` via `build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt` |
| RV64 baseline fresh rerun | `21/21` via `build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt` |
| CoreMark smoke fresh rerun | `620530 cycles` |
| CoreMark short fresh rerun | `0.912472` via `build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt` |
| CoreMark strict fresh rerun | `in progress` on `2026-04-08`; until completion keep `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt` as authoritative strict evidence |

### Current decision gate

Before optimization work resumes, the following must be closed:

1. wait for the fresh strict CoreMark rerun to complete and archive dated log/summary
2. sync the final strict result into all status docs
3. commit verification assets, RTL closure, and docs closure with focused boundaries

Until those items are complete, `FQ-06` remains queued but not active.
