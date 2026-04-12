# YH_rv_cpu BEQ/BNE Early Redirect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evaluate a decode-stage early redirect slice for taken `BEQ/BNE` that can reduce `fetch_queue_empty_cycles` without regressing the frozen `RV32/RV64` baseline.

**Architecture:** Keep the current mainline RTL as the authority baseline and introduce one single-variable trial only: taken `BEQ/BNE` may redirect earlier when ID-stage operands are ready and hazard-free. The trial must still preserve full wrong-path flush behavior and must be rejected in the same round if it fails guardrails or leaves short CoreMark unchanged.

**Tech Stack:** SystemVerilog RTL/TB, Vivado xsim batch scripts, PowerShell/batch tooling, markdown handoff docs.

---

### Task 1: Freeze the experiment contract

**Files:**
- Modify: `YH_rv_cpu/doc/CURRENT_STATUS.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Test: `docs/superpowers/plans/2026-04-12-yh-rv-cpu-beqbne-early-redirect-plan.md`

- [ ] **Step 1: Record the retained hypothesis**

Write the experiment target as: decode-stage early redirect for taken `BEQ/BNE` only, gated by operand readiness and hazard cleanliness.

- [ ] **Step 2: Record the explicit non-goals**

Write that this plan does not reopen `jal-only`, does not widen queue depth, does not change generic reuse bookkeeping, and does not bundle `JALR`.

- [ ] **Step 3: Record the retain/reject bar**

State that the slice is retained only if it lowers short CoreMark cycles below `11014885` and keeps `RV32/RV64` guardrails green.

- [ ] **Step 4: Commit**

```bash
git add YH_rv_cpu/doc/CURRENT_STATUS.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md YH_rv_cpu/doc/YH_rv_cpu_todo.md docs/superpowers/plans/2026-04-12-yh-rv-cpu-beqbne-early-redirect-plan.md
git commit -m "docs: plan beqbne early redirect trial"
```

### Task 2: Add a failing focused diagnostic

**Files:**
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v`
- Modify: `YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat`
- Test: `YH_rv_cpu/build/tests/branch-first/`

- [ ] **Step 1: Write the failing test behavior**

Add a focused branch-first mode that proves the frozen baseline cannot satisfy an early taken-branch redirect requirement when `BEQ/BNE` operands are available in ID.

- [ ] **Step 2: Run the diagnostic on frozen baseline and verify it fails**

Run:

```bat
scripts\run_fetch_redirect_reuse_diag.bat require_branch_reuse debug_trace
```

Expected: `FAIL` on frozen baseline for the new stricter branch-first requirement.

- [ ] **Step 3: Refine the diagnostic to isolate BEQ/BNE-only intent**

Keep the failing condition tied to taken `BEQ/BNE` overlap or queue-visible latency. Do not let `jal`, `jalr`, queue depth, or unrelated fetch bubbles satisfy the test.

- [ ] **Step 4: Re-run and verify the failure message is specific**

Expected: failure text identifies missing early branch redirect behavior rather than a generic timeout.

- [ ] **Step 5: Commit**

```bash
git add YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat
git commit -m "test: add failing beqbne early redirect diagnostic"
```

### Task 3: Implement the minimal RTL slice

**Files:**
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_id_stage.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_hazard_unit.v`
- Test: `YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v`

- [ ] **Step 1: Add explicit ID-stage eligibility signals**

Create the smallest internal signals needed to identify taken `BEQ/BNE` whose source operands are ready in ID and are not blocked by load-use or redirect hazards.

- [ ] **Step 2: Keep EX-stage redirect as correctness backstop**

Preserve the existing EX-stage authority so the experiment only adds an earlier safe fast-path rather than deleting the proven path.

- [ ] **Step 3: Implement minimal early redirect path**

Update the fetch-control path so the branch target can be selected one stage earlier for the eligible `BEQ/BNE` slice only.

- [ ] **Step 4: Implement full wrong-path flush handling**

Ensure younger wrong-path work is invalidated correctly when the early redirect fires; do not rely on reuse counters alone.

- [ ] **Step 5: Run the focused diagnostic and verify it passes**

Run:

```bat
scripts\run_fetch_redirect_reuse_diag.bat require_branch_reuse
```

Expected: `PASS`.

- [ ] **Step 6: Commit**

```bash
git add YH_rv_cpu/rtl/YH_rv_cpu.v YH_rv_cpu/rtl/YH_rv_cpu_id_stage.v YH_rv_cpu/rtl/YH_rv_cpu_hazard_unit.v YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v
git commit -m "feat: add beqbne early redirect trial"
```

### Task 4: Run the quick-screen guardrail matrix

**Files:**
- Test: `YH_rv_cpu/build/tests/branch-first/`
- Test: `YH_rv_cpu/build/sw/`
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`

- [ ] **Step 1: Run branch-focused diagnostics**

Run:

```bat
scripts\run_fetch_redirect_reuse_diag.bat
scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0
scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1
```

Expected: all `PASS`.

- [ ] **Step 2: Run minimum ISA guardrails**

Run:

```bat
scripts\run_riscv_tests_subset.bat rv32 beq - 120000
scripts\run_riscv_tests_subset.bat rv32 bne - 120000
scripts\run_riscv_tests_subset.bat rv64
```

Expected: `PASS`.

- [ ] **Step 3: Run CoreMark smoke and profile**

Run:

```bat
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_profile.bat rv32 10 2000 100000000UL 20000000
```

Expected: smoke `PASS`; profile should show a reduction in `fetch_queue_empty_cycles` relative to `1504970`.

- [ ] **Step 4: Run short CoreMark score**

Run:

```bat
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
```

Expected: retained candidate only if `completion_cycles < 11014885`.

- [ ] **Step 5: Record quick-screen result**

Append one row or section to `YH_rv_cpu/doc/performance_experiment_log.md` with the measured counters, score, and retain/reject decision.

- [ ] **Step 6: Commit**

```bash
git add YH_rv_cpu/doc/performance_experiment_log.md
git commit -m "docs: record beqbne early redirect quick-screen"
```

### Task 5: Retain or reject in the same round

**Files:**
- Modify: `YH_rv_cpu/doc/CURRENT_STATUS.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`

- [ ] **Step 1: Reject immediately if the score bar is missed**

If short CoreMark stays at `11014885` or worse, revert the experiment RTL in the same round and keep only useful diagnostics or documentation.

- [ ] **Step 2: Expand only if the score bar is beaten**

If short CoreMark improves, queue the larger matrix: `rv32 baseline`, `rv32 full-ui`, `rv64 baseline`, `rv64 full-ui`, strict CoreMark, and `impl50`.

- [ ] **Step 3: Sync handoff docs**

Update current status, handoff, change log, and todo so the next person sees the result without reading raw logs.

- [ ] **Step 4: Commit**

```bash
git add YH_rv_cpu/doc/CURRENT_STATUS.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md YH_rv_cpu/doc/YH_rv_cpu_change_log.md YH_rv_cpu/doc/YH_rv_cpu_todo.md
git commit -m "docs: sync beqbne early redirect decision"
```
