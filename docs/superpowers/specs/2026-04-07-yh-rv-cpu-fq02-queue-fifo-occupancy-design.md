# YH_rv_cpu FQ-02 Queue FIFO Occupancy Design

**Date:** 2026-04-07  
**Status:** Draft for implementation  
**Owner:** Codex

## Goal

After FQ-01 (`no gain`), try one higher-intrusion single-variable candidate:
reorganize current 2-entry fetch queue into explicit FIFO-occupancy semantics.

The target is to reduce queue-empty exposure around redirect-heavy windows
without changing request issue policy.

## Context

Fresh profile baseline:

- `total_cycles = 12516421`
- `ex_fetch_redirect_valid_cycles = 1504970`
- `fetch_queue_empty_cycles = 1504970`

Rejected trials so far:

- request-side cursor
- redirect pipe-hit recheck
- redirect same-cycle request
- FQ-01 queue-decouple quick screen

All above were functionally green but short score remained unchanged.

## Hypothesis

Current shift-style `buf0/buf1` logic may still leave recoverable bubbles during
consume/enqueue edges. Explicit FIFO occupancy/head-tail style behavior can
reduce edge-case idle cycles even when request timing is unchanged.

## Scope

In scope:

- `YH_rv_cpu/rtl/YH_rv_cpu.v` fetch queue organization only

Out of scope:

- `imem_req` generation policy
- redirect/drop-accounting semantics
- CPU ISA or branch predictor behavior

## Single-Variable Guardrail

One variable only: queue structure semantics.

- No request-timing changes in same trial.
- No pipe-hit or redirect-gating changes in same trial.
- If second variable is required, reject and revert.

## Validation Matrix

Required quick screen:

- `scripts\run_fetch_redirect_reuse_diag.bat`
- `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
- `scripts\run_coremark_smoke.bat rv32`
- `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`

Retain-only expansion:

- `scripts\run_riscv_tests_subset.bat rv32`
- `scripts\run_riscv_tests_subset.bat rv64`
- `scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt`
- `scripts\build_vivado_project.bat impl50`

## Retain Criteria

All required:

- Quick-screen diagnostics all pass
- `CoreMark short` improves vs `11014885 cycles`
- No regressions in expanded matrix

Otherwise reject and revert in same round.

