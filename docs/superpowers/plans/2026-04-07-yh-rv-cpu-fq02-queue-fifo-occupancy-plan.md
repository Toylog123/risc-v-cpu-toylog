# YH_rv_cpu FQ-02 Queue FIFO Occupancy Plan

**Goal:** Implement and evaluate FQ-02 queue-structure trial, then close as retain/reject with evidence.

## Task 1 - RTL Trial

Files:

- `YH_rv_cpu/rtl/YH_rv_cpu.v`

Checklist:

- [ ] Replace shift-oriented queue behavior with explicit FIFO occupancy semantics.
- [ ] Keep request issue and redirect/drop semantics unchanged.
- [ ] Keep all edits inside fetch queue organization region.

## Task 2 - Quick Screen

- [ ] `scripts\run_fetch_redirect_reuse_diag.bat`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
- [ ] `scripts\run_coremark_smoke.bat rv32`
- [ ] `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`

Decision gate:

- [ ] If short score improves, continue to full matrix.
- [ ] If not improved, revert immediately and record rejection.

## Task 3 - Retain-Only Full Matrix

- [ ] `scripts\run_riscv_tests_subset.bat rv32`
- [ ] `scripts\run_riscv_tests_subset.bat rv64`
- [ ] `scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt`
- [ ] `scripts\build_vivado_project.bat impl50`

## Task 4 - Documentation Closure

- [ ] Update `YH_rv_cpu/doc/performance_experiment_log.md`.
- [ ] Update `YH_rv_cpu/doc/YH_rv_cpu_handoff.md` and `YH_rv_cpu/doc/YH_rv_cpu_todo.md`.
- [ ] Commit as focused retain/reject record.

