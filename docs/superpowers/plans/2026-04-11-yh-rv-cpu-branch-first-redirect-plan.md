# YH_rv_cpu Branch-First Redirect Experiment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute one controlled post-profiling experiment that attacks branch-dominant redirect cost first, while keeping the frozen baseline easy to restore if the trial shows no real gain.

**Architecture:** Keep EX-stage redirect resolution and flush as the architectural source of truth in the first cut. The trial should only try to make the existing fetch redirect reuse path useful for branch-heavy control flow, preferably starting with `BEQ/BNE`, without reopening queue-depth tuning or a `jal-only` shortcut.

**Tech Stack:** Verilog/SystemVerilog RTL, xsim directed diagnostics, Windows batch scripts, CoreMark profile/smoke/score scripts, Markdown experiment docs

---

## File Structure

- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v`
- Modify: `YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat`
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify: `YH_rv_cpu/doc/CURRENT_STATUS.md`
- Inspect: `YH_rv_cpu/scripts/run_riscv_tests_subset.bat`
- Inspect: `YH_rv_cpu/scripts/run_coremark_profile.bat`

---

### Task 1: Freeze the one-variable contract before touching RTL

**Files:**
- Modify: `docs/superpowers/plans/2026-04-11-yh-rv-cpu-branch-first-redirect-plan.md`
- Modify: `YH_rv_cpu/doc/CURRENT_STATUS.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`

- [ ] **Step 1: State the active hypothesis explicitly**

Write down that the first cut is `branch-first redirect reuse`, not a general
fetch rewrite, not queue-depth tuning, and not a `jal-only` fast path.

- [ ] **Step 2: Freeze the first cut to `BEQ/BNE` if scope pressure appears**

If the RTL starts spreading into many control classes, stop and narrow the
experiment back to `BEQ/BNE` only.

- [ ] **Step 3: Freeze the keep/reject bar**

The candidate is retainable only if all correctness guardrails stay green,
`fetch_redirect_reuse_cycles` becomes meaningfully non-zero or
`fetch_queue_empty_cycles` drops below the frozen `1504970`, and short
CoreMark improves strictly over `11014885 cycles`.

### Task 2: Add the failing branch-first guardrail before implementation

**Files:**
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v`
- Modify: `YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat`

- [ ] **Step 1: Extend the existing redirect diagnostic with a branch-first mode**

Add one focused mode or plusarg that models a branch redirect scenario and
checks whether the target can be observed through the existing reuse/queue path.
Do not weaken the existing queue-preserve or drop-accounting checks.

- [ ] **Step 2: Confirm the frozen baseline does not falsely satisfy the new mode**

Run the new branch-first diagnostic on the unmodified baseline and confirm it
fails for the expected reason: branch redirect reuse still behaves like a miss.

- [ ] **Step 3: Keep the old redirect diagnostics intact**

Re-run the existing matrix and confirm the new test support does not change the
meaning of:

- [ ] `scripts\run_fetch_redirect_reuse_diag.bat`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`

### Task 3: Implement the minimal branch-first RTL slice

**Files:**
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [ ] **Step 1: Keep architectural redirect authority in EX**

Do not move trap, `mret`, `jal`, or `jalr` commit semantics in the first cut.
The experiment may pre-stage useful fetch data, but EX remains the point that
authorizes redirect/flush.

- [ ] **Step 2: Constrain edits to existing fetch redirect/reuse plumbing**

Touch only the logic around:

- [ ] `fetch_redirect_buf0_hit`
- [ ] `fetch_redirect_buf1_hit`
- [ ] `fetch_redirect_reuse_valid`
- [ ] fetch buffer next-state handling around redirect miss/hit paths

Do not widen the fetch queue, change IF/ID consume rules, or reopen request-side
cursor experiments in the same round.

- [ ] **Step 3: Gate the new behavior to branch traffic only**

Use the already-available branch classification signals (`id_ex_branch_funct3_r`,
`id_ex_jump_r`, `id_ex_jalr_r`, and the existing redirect path) so the first
trial can focus on taken branch redirects, preferably `BEQ/BNE`.

- [ ] **Step 4: Re-read the diff and reject accidental second variables**

If the trial also changes `jal`, `jalr`, trap/mret handling, queue sizing, or
general request timing, back it out and re-scope before testing.

### Task 4: Run the correctness-first quick screen

**Files:**
- Test: `YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat`
- Test: `YH_rv_cpu/scripts/run_riscv_tests_subset.bat`
- Test: `YH_rv_cpu/scripts/run_coremark_smoke.bat`
- Test: `YH_rv_cpu/scripts/run_coremark_profile.bat`
- Test: `YH_rv_cpu/scripts/run_coremark_score.bat`

- [ ] **Step 1: Run the new branch-first directed diagnostic**

Run the new focused branch-first mode added in Task 2.
Expected: PASS on the trial RTL.

- [ ] **Step 2: Re-run redirect accounting guardrails**

Run:

- [ ] `scripts\run_fetch_redirect_reuse_diag.bat`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`

Expected: PASS on all three.

- [ ] **Step 3: Re-run the smallest instruction-level branch guardrails**

Run:

- [ ] `scripts\run_riscv_tests_subset.bat rv32 beq - 120000`
- [ ] `scripts\run_riscv_tests_subset.bat rv32 bne - 120000`

Expected: PASS on both before any CoreMark retention claim.

- [ ] **Step 4: Re-run CoreMark smoke**

Run: `scripts\run_coremark_smoke.bat rv32`
Expected: PASS.

- [ ] **Step 5: Re-run CoreMark profile**

Run: `scripts\run_coremark_profile.bat rv32 10 2000 100000000UL 20000000`
Expected: collect updated redirect counters for retain/reject.

- [ ] **Step 6: Re-run short CoreMark**

Run: `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
Expected: strictly better than `11014885 cycles` before the trial may survive.

### Task 5: Retain or reject in the same round

**Files:**
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify: `YH_rv_cpu/doc/CURRENT_STATUS.md`

- [ ] **Step 1: Reject immediately on any guardrail failure**

If the new branch diagnostic, either redirect-accounting variant, `rv32 beq`,
or `rv32 bne` fails, reject and revert the RTL in the same round.

- [ ] **Step 2: Reject if the profile still shows no meaningful reuse**

If `fetch_redirect_reuse_cycles` stays at `0` and `fetch_queue_empty_cycles`
does not drop below `1504970`, do not spend more time on full-matrix expansion.

- [ ] **Step 3: Reject if short CoreMark is flat or worse**

If completion cycles are `>= 11014885`, revert the RTL and keep only any useful
diagnostic improvements.

- [ ] **Step 4: Expand only on a real win**

Only if the quick screen is fully green and short CoreMark improves should the
next batch run a broader matrix (`rv32`, `rv64`, strict CoreMark, `impl50`,
and FPGA-like probe).

- [ ] **Step 5: End with focused commits and synced docs**

Record the final decision, update the short status entry point, and keep the
round easy to hand off whether it was retained or rejected.

---

## Notes for the implementer

- Current evidence says redirect cost is branch-dominant, not queue-dominant.
- Current evidence also says `fetch_redirect_reuse_cycles = 0`, so the trial
  must prove that the reuse path becomes active on real workload traffic.
- Do not reopen the old `jal-only` early redirect line in this round.
