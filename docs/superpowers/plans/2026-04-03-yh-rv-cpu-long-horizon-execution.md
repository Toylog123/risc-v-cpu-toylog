# YH_rv_cpu Long-Horizon Execution Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `YH_rv_cpu` into a submission-grade, reproducible, regression-backed, board-ready baseline, then keep executing all locally-completable long-horizon tasks until only external blockers remain.

**Architecture:** Treat commit `72f9c2f` as the frozen starting point, but do not trust docs blindly. First re-establish the real repo state, then execute in six phases: strict CoreMark closure, FPGA pre-board closure, untracked-file governance, single-variable performance work, documentation unification, and final fresh regression/cleanup. Every retained change must ship with fresh evidence and a focused git commit.

**Tech Stack:** Verilog RTL, xsim batch flow, Vivado 2025.2, xPack RISC-V GCC, CoreMark, `riscv-tests`, Markdown docs, Windows batch/PowerShell helpers

---

## Real-State Baseline

- Read first:
  - `YH_rv_cpu/README.md`
  - `YH_rv_cpu/doc/coremark_submission_report.md`
  - `YH_rv_cpu/doc/performance_experiment_log.md`
  - `YH_rv_cpu/doc/regression_test_log.md`
  - `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
  - `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
  - `YH_rv_cpu/doc/fpga_bringup_checklist.md`
  - `docs/superpowers/plans/2026-04-02-yh-rv-cpu-competition-closure.md`
- Audit before edits:
  - current branch / HEAD
  - tracked vs untracked changes
  - latest reproducible CoreMark, regression, FPGA reports
  - whether docs already match `72f9c2f`
- Do not overwrite unrelated user changes.

## Phase Boundaries

### Task 1: Strict CoreMark Closure

**Files:**
- Modify: `YH_rv_cpu/scripts/run_coremark_score.bat`
- Modify or create only if justified by evidence: `YH_rv_cpu/scripts/run_coremark_long.bat`, `YH_rv_cpu/scripts/run_coremark_ultra.bat`
- Modify: `YH_rv_cpu/scripts/report_coremark_result.py`
- Modify: `YH_rv_cpu/doc/coremark_submission_report.md`
- Modify: `YH_rv_cpu/doc/regression_test_log.md`
- Modify: `YH_rv_cpu/README.md`

- [ ] Reconfirm the frozen short-run score with fresh evidence.
- [ ] Prove why the frozen score is below strict EEMBC `>=10s` using log data, not inference.
- [ ] Try the least-risk strict route first:
  - keep `timer_hz=100000000UL`
  - keep full workload semantics
  - increase run budget and workload only through benchmark parameters
- [ ] If strict run succeeds, emit a dedicated raw log and summary that clearly mark `strict_eembc_10s_compliant=yes`.
- [ ] If strict run is not practical locally, capture the exact attempted commands, runtime/cycle evidence, and bounded reason in docs, and only allow the phase to stop if the remaining gap is explicitly classified as an external blocker or a machine-capability blocker with evidence.
- [ ] Commit only the strict-CoreMark-related code/docs.

### Task 2: FPGA Pre-Board / Board-Ready Closure

**Files:**
- Modify: `YH_rv_cpu/fpga/vivado/README.md`
- Modify: `YH_rv_cpu/doc/fpga_bringup_checklist.md`
- Modify: `YH_rv_cpu/scripts/build_vivado_project.bat`
- Modify: `YH_rv_cpu/scripts/open_vivado_project.bat`
- Modify: `YH_rv_cpu/fpga/vivado/scripts/build_nexys_a7_100_project.tcl`
- Modify if needed: `YH_rv_cpu/fpga/vivado/constraints/nexys_a7_100_template.xdc`

- [ ] Verify bitstream, report, and XDC paths are consistent across scripts/docs.
- [ ] Close all board-independent SOP/document gaps.
- [ ] Separate true external blockers from fixable pre-board inconsistencies.
- [ ] Commit only FPGA closure files.

### Task 3: Untracked File Governance

**Files:**
- Modify as needed: `.gitignore`
- Add only justified tools/assets under `YH_rv_cpu/`
- Remove only confirmed temp/noise files

- [ ] Classify every untracked file as mainline asset, useful debug tool, temporary draft, or noise.
- [ ] Keep files that support repeatable verification or future debugging.
- [ ] Exclude or remove one-off scraps.
- [ ] Commit any retained assets with documentation of purpose.

### Task 4: Second-Round Performance Work

**Files:**
- Modify only one optimization dimension per attempt
- Always update: `YH_rv_cpu/doc/performance_experiment_log.md`

- [ ] Freeze the optimization pre-state after Phase 1-3 cleanup.
- [ ] Focus first on fetch/request/queue decoupling experiments only if there is a bounded, reviewable implementation.
- [ ] After every retained optimization, rerun:
  - `CoreMark score`
  - `CoreMark smoke`
  - `riscv-tests rv32`
  - `riscv-tests rv64`
  - `impl50`
  - FPGA-like probe when FPGA path changes
- [ ] Reject speculative or regression-prone changes quickly and document why.
- [ ] Commit each retained optimization separately.

### Task 5: Full Documentation Unification

**Files:**
- Modify: `YH_rv_cpu/README.md`
- Modify: `YH_rv_cpu/doc/coremark_submission_report.md`
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/regression_test_log.md`
- Modify: `YH_rv_cpu/doc/技术文档.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify: `YH_rv_cpu/doc/项目结构说明.md`
- Modify: `YH_rv_cpu/fpga/vivado/README.md`
- Modify report materials under `06-汇报材料/` when they are still in scope

- [ ] Remove stale scores, timing numbers, smoke counts, and contradictory claims.
- [ ] Ensure README, report, handoff, todo, regression log, and FPGA docs all cite the same current baseline.
- [ ] Commit the doc-only sync separately from RTL/script work.

### Task 6: Final Fresh Regression And Cleanup

**Files:**
- Modify only files needed to finalize logs/docs/cleanup

- [ ] Run a final fresh matrix:
  - `scripts/check_syntax.bat`
  - `scripts/run_coremark_smoke.bat rv32`
  - `scripts/run_coremark_score.bat rv32 ...`
  - `scripts/run_riscv_tests_subset.bat rv32`
  - `scripts/run_riscv_tests_subset.bat rv64`
  - `scripts/build_vivado_project.bat impl50`
  - `scripts/run_coremark_fpga.bat rv32` when FPGA path is still relevant
- [ ] Audit git status and working-tree leftovers.
- [ ] Leave only intentional retained files and true external blockers.
- [ ] Produce the final blocker list and stop only when all remaining items are externally blocked.

## Commit Rules

- One focused commit per phase or retained optimization.
- Check `git diff --staged` before every commit.
- Do not mix noise cleanup into functional commits unless the cleanup is phase-local and justified.

## Hard Verification Rules

- Never claim `done`, `pass`, `frozen`, or `reportable` without fresh evidence from this machine.
- If a required check cannot be run immediately, record:
  - the missing command
  - why it was skipped
  - when it will be backfilled
  - the residual risk
