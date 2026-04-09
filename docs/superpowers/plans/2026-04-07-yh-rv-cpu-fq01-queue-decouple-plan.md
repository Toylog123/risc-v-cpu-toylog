# YH_rv_cpu FQ-01 Queue-Decouple Implementation Plan

**Goal:** Execute one single-variable queue-decouple trial (FQ-01), decide retain/reject by fresh evidence, and sync docs.

## Task 1 - Implement FQ-01 RTL Trial

Files:

- `YH_rv_cpu/rtl/YH_rv_cpu.v`

Steps:

- [ ] Modify only queue organization logic in fetch path.
- [ ] Keep request timing, redirect drop-accounting, and external interfaces unchanged.
- [ ] Build and run directed diagnostics first.

## Task 2 - Run Validation Matrix

Steps:

- [ ] `scripts\run_fetch_redirect_reuse_diag.bat`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
- [ ] `scripts\run_coremark_smoke.bat rv32`
- [ ] `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
- [ ] `scripts\run_riscv_tests_subset.bat rv32`
- [ ] `scripts\run_riscv_tests_subset.bat rv64`

Conditional steps (only when short-score improves):

- [ ] `scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt`
- [ ] `scripts\build_vivado_project.bat impl50`

## Task 3 - Close Trial

Steps:

- [ ] If no gain or any regression: revert RTL trial and document rejection.
- [ ] If gain and no regression: keep RTL and document retain evidence.
- [ ] Update `YH_rv_cpu/doc/performance_experiment_log.md`.
- [ ] Update `YH_rv_cpu/doc/regression_test_log.md` (if baseline matrix rerun is affected).
- [ ] Update `YH_rv_cpu/doc/YH_rv_cpu_todo.md`.

