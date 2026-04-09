# YH_rv_cpu FQ-05C IF/ID Mem-Wait Preload Plan

**Goal:** Execute one conservative IF/ID preload trial with strict early-exit
guardrails.

## Task 1: Apply single-variable RTL change

**File:** `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [x] Relax only `if_id_data_write_en` to allow payload update during `mem_wait`.
- [x] Keep `if_id_write_en` unchanged.
- [x] Keep queue consume/request policy unchanged.

## Task 2: Run quick-screen matrix with early-fail gate

- [x] `scripts\run_memwait_overlap_diag.bat` -> PASS
- [x] `scripts\run_fetch_redirect_reuse_diag.bat` -> FAIL (timeout)
- [x] Stop remaining checks after first guardrail failure (policy-compliant)

## Task 3: Retain or reject

- [x] Reject immediately on guardrail failure.
- [x] Revert RTL in the same round.
- [x] Record the fail-fast result in logs/handoff.

## Execution Summary

FQ-05C failed the first redirect guardrail after passing memwait overlap
diagnostic. Trial was rejected and reverted immediately; no smoke/score or
strict variants were continued.
