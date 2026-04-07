# YH_rv_cpu FQ-01 Queue-Decouple Design

**Date:** 2026-04-07  
**Status:** Ready for implementation  
**Owner:** Codex

## Goal

Run one new single-variable fetch candidate after rejected trials:

- request-side cursor (`no gain`)
- redirect `pipe-hit` recheck (`no gain`)
- redirect same-cycle request (`no gain`)

Candidate FQ-01 focuses on queue organization only:
keep request timing unchanged and decouple queue ingest/consume behavior.

## Why This Candidate

Current profile snapshot (fresh rerun):

- `total_cycles = 12516421`
- `ex_fetch_redirect_valid_cycles = 1504970`
- `fetch_queue_empty_cycles = 1504970`

This suggests fetch starvation around redirect windows is still a large cost.
FQ-01 targets the queue boundary directly, instead of adding a new request gate.

## Scope

In scope:

- `YH_rv_cpu/rtl/YH_rv_cpu.v` fetch queue/buffer organization around:
  - `fetch_queue_valid`
  - `fetch_queue_enqueue_data`
  - `fetch_buf0_*` / `fetch_buf1_*` state transitions
- Keep external interface and command flow unchanged.

Out of scope:

- Changing `imem_req` timing policy
- Re-enabling `fetch_redirect_pipe_hit`
- Changing `IMEM_DROP_COUNT` or drop-accounting contract
- Any branch predictor or ISA-level behavior

## Single-Variable Rule

Only one variable may change: queue organization semantics.

- Do not alter request issue policy in the same trial.
- Do not alter redirect/drop policy in the same trial.
- If a second variable is needed, reject trial and record why.

## Validation Matrix (Mandatory)

Directed guardrails:

- `scripts\run_fetch_redirect_reuse_diag.bat`
- `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`

Performance and regression:

- `scripts\run_coremark_smoke.bat rv32`
- `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
- `scripts\run_riscv_tests_subset.bat rv32`
- `scripts\run_riscv_tests_subset.bat rv64`

Full retain gate (only if short-score improves):

- `scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt`
- `scripts\build_vivado_project.bat impl50`

## Retain / Reject Criteria

Retain only if all are true:

- No directed/regression failures
- `CoreMark short` strictly better than `11014885 cycles`
- No clear implementation regression on `impl50`

Otherwise:

- Reject, revert RTL, and log in `doc/performance_experiment_log.md`

