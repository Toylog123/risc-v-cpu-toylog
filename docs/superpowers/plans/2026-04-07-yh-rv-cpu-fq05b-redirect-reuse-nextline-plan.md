# YH_rv_cpu FQ-05B Redirect-Reuse Next-Line Prefetch Plan

**Goal:** Execute one single-variable redirect-reuse next-line prefetch trial,
and retain only if short score improves.

## Task 1: Apply trial RTL change

**File:** `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [x] Add redirect-reuse-gated prefetch request enable.
- [x] Add redirect-reuse-gated request PC selection to `redirect_pc + 4`.
- [x] Keep non-redirect fetch path unchanged.

## Task 2: Run quick-screen matrix

- [x] `scripts\run_fetch_redirect_reuse_diag.bat` -> PASS
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` -> PASS
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` -> PASS
- [x] `scripts\run_coremark_smoke.bat rv32` -> PASS (`620530 cycles`)
- [x] `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` -> PASS (`11014885 cycles`)

## Task 3: Retain or reject

- [x] Compare short score against frozen baseline `11014885`.
- [x] Reject when no gain appears.
- [x] Revert RTL and record result in experiment/handoff docs.

## Execution Summary

FQ-05B completed on 2026-04-07. Diagnostics and smoke passed, but short score
remained unchanged. Trial rejected and RTL reverted in the same round.
