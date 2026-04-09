# YH_rv_cpu FQ-05A Queue-Consume/Data-Write Align Plan

**Goal:** Execute one single-variable handshake-alignment trial, keep only
evidence-backed changes, and revert immediately if short score does not
improve.

## Task 1: Apply single-variable RTL change

**File:** `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [x] Change `fetch_live_to_ifid` gate from `if_id_write_en` to `if_id_data_write_en`.
- [x] Change `fetch_queue_consume` gate from `if_id_write_en` to `if_id_data_write_en`.
- [x] Keep all other fetch/request/queue behavior unchanged.

## Task 2: Run quick-screen matrix

- [x] `scripts\run_fetch_redirect_reuse_diag.bat` -> PASS
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` -> PASS
- [x] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` -> PASS
- [x] `scripts\run_coremark_smoke.bat rv32` -> PASS (`620530 cycles`)
- [x] `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` -> PASS (`11014885 cycles`)

## Task 3: Retain or reject

- [x] Compare short score versus frozen baseline `11014885`.
- [x] Reject and revert RTL when no improvement is observed.
- [x] Record result in experiment logs and handoff docs.

## Execution Summary

FQ-05A completed on 2026-04-07. Guardrails remained green, smoke remained
green, and short score was unchanged. Trial rejected and RTL reverted in the
same round.
