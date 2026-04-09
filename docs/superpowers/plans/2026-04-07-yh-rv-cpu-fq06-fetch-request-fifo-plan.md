# FQ-06 Fetch-Request FIFO Decouple Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute one controlled post-closure `FQ-06` round that adds bounded request-side decoupling on the sync-fetch path without breaking redirect/drop-accounting correctness.

**Architecture:** Keep the existing IF/ID payload path and 2-entry fetch buffer, but add request-side state so the sync IMEM path can continue filling safe queue headroom during decode stalls. Treat `IMEM_OUTPUT_REG=0` as the active performance target and `IMEM_OUTPUT_REG=1` as a strict correctness guardrail.

**Tech Stack:** Verilog/SystemVerilog RTL, xsim directed diagnostics, CoreMark quick-screen scripts, Markdown experiment logs

---

### Task 1: Sync docs and freeze the experiment contract

**Files:**
- Modify: `docs/superpowers/specs/2026-04-07-yh-rv-cpu-fq06-fetch-request-fifo-design.md`
- Modify: `docs/superpowers/plans/2026-04-07-yh-rv-cpu-fq06-fetch-request-fifo-plan.md`
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify: `YH_rv_cpu/README.md`

- [x] Record that pre-optimization closure is complete and `FQ-06` is now the active local batch.
- [x] Record the selected entry scope: bounded request cursor on `IMEM_OUTPUT_REG=0`, strict correctness-only coverage on `IMEM_OUTPUT_REG=1`.
- [x] Record the quick-screen gate: new directed red/green test, redirect/drop diagnostics, CoreMark smoke, CoreMark short.

### Task 2: Add the failing directed test first

**Files:**
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_fetch_prefetch_tb.v`
- Inspect: `YH_rv_cpu/scripts/run_fetch_prefetch_diag.bat`

- [x] Add one stricter plusarg-driven condition that the frozen baseline cannot satisfy.
- [x] Run the directed diagnostic on the frozen baseline and confirm it fails for the expected reason.
- [x] Keep the new test focused on request-side behavior, not on redirect accounting.

### Task 3: Implement the minimal request-side RTL slice

**Files:**
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [x] Add bounded request-side state for sync fetch issue.
- [x] Keep IF/ID payload movement unchanged in the first cut.
- [x] Limit the new behavior to safe queue headroom and the active `IMEM_OUTPUT_REG=0` performance path.
- [x] Preserve redirect/drop-accounting behavior across both accounting variants.

### Task 4: Close the red/green loop and quick-screen the candidate

**Files:**
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`

- [x] `scripts\run_fetch_prefetch_diag.bat require_queue_fill`
- [x] `scripts\run_fetch_redirect_reuse_diag.bat`
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
- [x] `scripts\run_memwait_overlap_diag.bat`
- [x] `scripts\run_coremark_smoke.bat rv32`
- [x] `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
- [x] Sync the result and decision into the experiment log before moving on.

### Task 5: Expand only on a real gain

**Files:**
- Modify: `YH_rv_cpu/doc/regression_test_log.md`
- Modify: `YH_rv_cpu/doc/coremark_submission_report.md`
- Modify: `YH_rv_cpu/README.md`

- [ ] If short score improves, run the expanded matrix (`rv32`, `rv64`, strict `>=10s`, `impl50`, `fpga` probe).
- [x] If no gain or any guardrail fails, reject and document the round in the same batch.
- [ ] End the round in a handoff-ready state with focused commits only.
