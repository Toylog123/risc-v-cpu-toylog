# YH_rv_cpu Memwait Overlap Experiment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run one minimal `mem_wait overlap` RTL experiment on the frozen `YH_rv_cpu` baseline, retain it only if it produces a real short CoreMark gain with no regression.

**Architecture:** Reuse the existing `imem_req` path and add only enough gating to permit a single safe overlap-time fetch request during synchronous load wait. Keep decode/commit frozen during `mem_wait`, validate with the existing strict directed test, then run the short regression matrix before deciding retain vs revert.

**Tech Stack:** Verilog RTL, xsim batch flow, Vivado 2025.2, xPack RISC-V GCC, CoreMark, `riscv-tests`, Markdown docs, Windows batch scripts

---

### Task 1: Reconfirm The Red Baseline

**Files:**
- Test: `YH_rv_cpu/tb/YH_rv_cpu_memwait_overlap_tb.v`
- Test: `YH_rv_cpu/scripts/run_memwait_overlap_diag.bat`
- Test: `YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat`

- [ ] **Step 1: Re-run the strict failing test before touching RTL**

Run: `cmd /c YH_rv_cpu\scripts\run_memwait_overlap_diag.bat require_overlap`
Expected: FAIL because the frozen baseline still issues `0` overlap requests.

- [ ] **Step 2: Re-run the default green directed path**

Run: `cmd /c YH_rv_cpu\scripts\run_memwait_overlap_diag.bat`
Expected: PASS with `overlap_requests=0`.

- [ ] **Step 3: Re-run the redirect guardrail**

Run: `cmd /c YH_rv_cpu\scripts\run_fetch_redirect_reuse_diag.bat`
Expected: PASS.

- [ ] **Step 4: Commit**

No commit in this task. This task establishes the red/green starting point.

### Task 2: Implement The Minimal Overlap Gate

**Files:**
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [ ] **Step 1: Add a minimal safe-overlap predicate**

Introduce a small combinational predicate that is true only when:
- `mem_wait` is high
- `stall_decode` is low
- `ex_fetch_redirect_valid` is low
- `fetch_buffer_valid` is low
- no fetch response is already in flight

- [ ] **Step 2: Route the predicate through `imem_req`**

Update `imem_req` so the frozen path still works unchanged outside `mem_wait`,
but the new overlap predicate can issue one request during `mem_wait`.

- [ ] **Step 3: Keep all non-request behavior unchanged**

Do not modify:
- `pipeline_run`
- queue consumption
- redirect/drop logic
- IF/ID write rules

- [ ] **Step 4: Run syntax check**

Run: `cmd /c YH_rv_cpu\scripts\check_syntax.bat`
Expected: PASS.

- [ ] **Step 5: Run the strict directed test**

Run: `cmd /c YH_rv_cpu\scripts\run_memwait_overlap_diag.bat require_overlap`
Expected: PASS.

- [ ] **Step 6: Re-run the default directed path**

Run: `cmd /c YH_rv_cpu\scripts\run_memwait_overlap_diag.bat`
Expected: PASS with `overlap_requests>=1`.

- [ ] **Step 7: Re-run the redirect guardrail**

Run: `cmd /c YH_rv_cpu\scripts\run_fetch_redirect_reuse_diag.bat`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add YH_rv_cpu/rtl/YH_rv_cpu.v
git commit -m "perf: try memwait overlap fetch request"
```

### Task 3: Run The Short Regression Matrix

**Files:**
- Modify if needed: `YH_rv_cpu/doc/regression_test_log.md`
- Modify if needed: `YH_rv_cpu/doc/performance_experiment_log.md`

- [ ] **Step 1: Run CoreMark smoke**

Run: `cmd /c YH_rv_cpu\scripts\run_coremark_smoke.bat rv32`
Expected: PASS.

- [ ] **Step 2: Run short CoreMark score**

Run: `cmd /c YH_rv_cpu\scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
Expected: PASS with either an improved score or a clearly unchanged result.

- [ ] **Step 3: Run RV32 subset**

Run: `cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv32`
Expected: PASS `33/33`.

- [ ] **Step 4: Run RV64 subset**

Run: `cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv64`
Expected: PASS `21/21`.

- [ ] **Step 5: Decide retain vs revert**

Retain only if:
- short CoreMark improves
- RV32/RV64 remain green
- directed tests remain consistent

Otherwise revert the RTL commit and keep only the experiment record.

- [ ] **Step 6: Commit**

No commit in this task until retain/reject is decided.

### Task 4: Record Outcome And Close The Loop

**Files:**
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/regression_test_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify if retained: `YH_rv_cpu/README.md`
- Modify if retained: `YH_rv_cpu/doc/技术文档.md`

- [ ] **Step 1: Document the directed-test result**

Write the fresh `require_overlap` outcome and note whether the RTL was retained
or reverted.

- [ ] **Step 2: Document the short-score decision**

Record the exact short CoreMark result and whether it justified keeping the RTL.

- [ ] **Step 3: If retained, schedule heavier follow-up**

Only after a positive short-score result, run:
- `cmd /c YH_rv_cpu\scripts\build_vivado_project.bat impl50`
- `cmd /c YH_rv_cpu\scripts\run_coremark_fpga.bat rv32`

- [ ] **Step 4: Commit**

If rejected:

```bash
git add YH_rv_cpu/doc/performance_experiment_log.md YH_rv_cpu/doc/regression_test_log.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md YH_rv_cpu/doc/YH_rv_cpu_todo.md
git commit -m "docs: record rejected memwait overlap trial"
```

If retained:

```bash
git add YH_rv_cpu/README.md YH_rv_cpu/doc/技术文档.md YH_rv_cpu/doc/performance_experiment_log.md YH_rv_cpu/doc/regression_test_log.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md YH_rv_cpu/doc/YH_rv_cpu_todo.md
git commit -m "docs: record retained memwait overlap optimization"
```
