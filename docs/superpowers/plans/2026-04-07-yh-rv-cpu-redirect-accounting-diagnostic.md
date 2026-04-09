# YH_rv_cpu Redirect Accounting Diagnostic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a strict directed diagnostic that validates redirect/flush/drop accounting under both `IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`, enforcing queue preservation and stale-response drop behavior.

**Architecture:** Extend the existing directed fetch-redirect TB with strict assertions and add a script path that compiles two parameter variants. Keep default paths permissive; strict plusargs enforce the contract.

**Tech Stack:** Verilog TB/RTL, xsim batch flow, Windows batch scripts

---

## File Structure

- Modify: `YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v`
- Modify: `YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat`
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md` (record diagnostic availability)
- Modify: `YH_rv_cpu/doc/regression_test_log.md` (record strict diagnostic results)

---

### Task 1: Extend TB With Strict Contract Checks

**Files:**
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v`

- [x] **Step 1: Add strict plusargs and internal latches**
  - Add `require_queue_preserve` and `require_drop_accounting`.
  - Track an `overlap_cycle` (the cycle when the overlap event occurs).
  - Track `queue_target_seen`, `queue_instr_match_seen`, and `drop_count_sequence_ok`.

- [x] **Step 2: Define overlap event and bounded window**
  - Overlap event = existing overlap condition.
  - Bounded window = next 1–2 cycles after overlap event.

- [x] **Step 3: Queue preservation assertions**
  - When `require_queue_preserve` is set:
    - `fetch_queue_valid` must assert within the bounded window.
    - `fetch_queue_pc` must equal the redirect target PC.
    - `fetch_queue_instruction` (or `if_id_next_instruction` at consume) must
      match expected target payload.

- [x] **Step 4: Drop-accounting assertions**
  - When `require_drop_accounting` and `IMEM_OUTPUT_REG=1`:
    - `fetch_drop_count_r` must become `IMEM_DROP_COUNT` after redirect flush.
    - It must decrement on the next valid response.
    - It must return to `0` before the queued target is consumed.
    - While `fetch_drop_response` is asserted, `fetch_pipe_valid` must remain low
      and stale response must not enter the queue.

- [x] **Step 5: Run strict checks**
  - Run:
    - `cmd /c YH_rv_cpu\scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
    - `cmd /c YH_rv_cpu\scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
  - Result: PASS on both variants after script support landed.

- [x] **Step 6: Commit**

```bash
git add YH_rv_cpu/tb/YH_rv_cpu_fetch_redirect_reuse_tb.v
git commit -m "test: add strict redirect accounting checks"
```

---

### Task 2: Add Dual-Variant Script Support

**Files:**
- Modify: `YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat`

- [x] **Step 1: Add a mode switch**
  - Add a param such as `imem_output_reg=0|1` that maps to compile-time
    parameter override, not runtime.

- [x] **Step 2: Compile two variants**
  - For `IMEM_OUTPUT_REG=0`, keep current behavior.
  - For `IMEM_OUTPUT_REG=1`, pass the parameter override via `xvlog`/`xelab`
    (or instantiate a small wrapper module in TB if needed).

- [x] **Step 3: Re-run strict checks**
  - Run `IMEM_OUTPUT_REG=0` strict path: expect PASS.
  - Run `IMEM_OUTPUT_REG=1` strict path: expect PASS only if drop accounting
    contract is satisfied.

- [x] **Step 4: Commit**

```bash
git add YH_rv_cpu/scripts/run_fetch_redirect_reuse_diag.bat
git commit -m "test: add imem_output_reg variants for redirect diag"
```

---

### Task 3: Record Diagnostic Results

**Files:**
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/regression_test_log.md`

- [x] **Step 1: Record new strict diagnostic**
  - Add the new strict contract checks and their PASS/FAIL status for both
    `IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`.

- [x] **Step 2: Commit**

```bash
git add YH_rv_cpu/doc/performance_experiment_log.md YH_rv_cpu/doc/regression_test_log.md
git commit -m "docs: record redirect accounting diagnostic results"
```

---

## Execution Handoff

Plan completed and executed via subagent-driven flow, then closed with inline script/doc synchronization.

Execution commits:

1. `2f991bc` - `test: add strict redirect accounting checks`
2. `5ea8006` - `docs: record redirect accounting diagnostic results` (initial placeholder entry)
3. `b46afad` - `test: support dual IMEM variants in redirect diag script`
4. `48c7847` - `docs: record strict IMEM0/1 redirect diagnostic passes`
