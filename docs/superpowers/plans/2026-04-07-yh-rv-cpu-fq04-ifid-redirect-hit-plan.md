# YH_rv_cpu FQ-04 IF/ID Redirect-Hit Bubble Bypass Implementation Plan

**Goal:** Execute the FQ-04 single-variable trial, keep only evidence-backed
changes, and roll back immediately if the bypass shows no gain.

**Architecture:** Make one isolated RTL change in
`YH_rv_cpu/rtl/YH_rv_cpu.v`, limited to the `if_id` redirect-hit bubble
bypass. Evaluate it with a small guardrail matrix first. Treat the quick screen
as the decision point: if the candidate does not improve the short score,
revert immediately and stop. Only if the quick screen is clean and improving
should the longer validation matrix run.

**Tech Stack:** SystemVerilog RTL, Windows batch scripts, CoreMark smoke and
score scripts, fetch redirect diagnostics.

---

### Task 1: Define the one-variable trial

**Files:**
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [x] **Step 1: Make exactly one RTL change**

Keep the edit constrained to the `if_id` redirect-hit bubble bypass.

- [x] **Step 2: Confirm no second variable slipped in**

Review the diff and verify the candidate does not also alter request policy,
queue behavior, or drop-accounting behavior.

- [x] **Step 3: Freeze the scope for testing**

Do not broaden the change surface before the quick screen completes.

### Task 2: Run the quick screen

**Files:**
- Test: `scripts\run_fetch_redirect_reuse_diag.bat`
- Test: `scripts\run_coremark_smoke.bat`
- Test: `scripts\run_coremark_score.bat`

- [x] **Step 1: Run the directed guardrail**

Run: `scripts\run_fetch_redirect_reuse_diag.bat`
Expected: PASS

- [x] **Step 2: Run the guardrail with queue-preserve and drop-accounting checks**

Run: `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
Expected: PASS

- [x] **Step 3: Run the alternate guardrail variant**

Run: `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
Expected: PASS

- [x] **Step 4: Run the smoke test**

Run: `scripts\run_coremark_smoke.bat rv32`
Expected: PASS

- [x] **Step 5: Run the short score**

Run: `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
Expected: strictly better than the current baseline

### Task 3: Decide retain or reject

- [x] **Step 1: If the short score does not improve, stop immediately**

Revert the RTL change in the same round and do not run the full matrix.

- [x] **Step 2: If the short score improves, expand validation (N/A this round: no short-score gain)**

Only then consider the longer regression set.

- [x] **Step 3: Record the decision**

Write the result as retain or reject based on the quick screen evidence.

Execution summary:

- Quick screen diagnostics passed under default, `IMEM_OUTPUT_REG=0`, and
  `IMEM_OUTPUT_REG=1` accounting guardrails.
- `run_coremark_smoke.bat rv32` passed with `620531 cycles`.
- `run_coremark_score.bat rv32 10 2000 100000000UL 20000000` passed but
  returned `completion_cycles=11014886` (no improvement vs baseline
  `11014885`).
- Final decision: rejected; RTL reverted in the same round; no full-matrix
  expansion.
