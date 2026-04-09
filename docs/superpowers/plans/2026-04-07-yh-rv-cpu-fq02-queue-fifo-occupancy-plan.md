# YH_rv_cpu FQ-02 Queue FIFO Occupancy Plan

**Goal:** Implement and evaluate FQ-02 queue-structure trial, then close as retain/reject with evidence.

## Task 1 - RTL Trial

Files:

- `YH_rv_cpu/rtl/YH_rv_cpu.v`

Checklist:

- [x] Replace shift-oriented queue behavior with explicit FIFO occupancy semantics.
- [x] Keep request issue and redirect/drop semantics unchanged.
- [x] Keep all edits inside fetch queue organization region.

## Task 2 - Quick Screen

- [x] `scripts\run_fetch_redirect_reuse_diag.bat`
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
- [x] `scripts\run_coremark_smoke.bat rv32`
- [x] `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`

Decision gate:

- [ ] If short score improves, continue to full matrix.
- [x] If not improved, revert immediately and record rejection.

## Task 3 - Retain-Only Full Matrix

- [ ] `scripts\run_riscv_tests_subset.bat rv32`
- [ ] `scripts\run_riscv_tests_subset.bat rv64`
- [ ] `scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt`
- [ ] `scripts\build_vivado_project.bat impl50`

## Task 4 - Documentation Closure

- [x] Update `YH_rv_cpu/doc/performance_experiment_log.md`.
- [x] Update `YH_rv_cpu/doc/YH_rv_cpu_handoff.md` and `YH_rv_cpu/doc/YH_rv_cpu_todo.md`.
- [ ] Commit as focused retain/reject record.

Execution summary:

- FQ-02 quick screen is green but short score is unchanged.
- Decision: reject and revert RTL.
