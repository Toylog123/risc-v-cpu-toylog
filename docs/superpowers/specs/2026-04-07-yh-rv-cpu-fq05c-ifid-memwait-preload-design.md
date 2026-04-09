# YH_rv_cpu FQ-05C IF/ID Mem-Wait Preload Design

**Date:** 2026-04-07  
**Status:** Executed (Rejected)  
**Owner:** Codex

## Goal

Test one conservative single-variable candidate in `rtl/YH_rv_cpu.v`:
allow IF/ID payload preload during `mem_wait` by relaxing only
`if_id_data_write_en`.

## Hypothesis

If IF/ID payload can be preloaded during memory-wait windows without changing
valid/consume policy, post-wait bubbles might be reduced with lower risk than
changing queue consume or IF/ID valid policy.

## Single-Variable Boundary

Allowed change:

- gate expression of `if_id_data_write_en` only

Not allowed:

- `if_id_write_en` policy change
- queue consume/enqueue policy change
- request timing policy change

## Quick Screen Gate

| Check | Command |
| --- | --- |
| Memwait guardrail | `scripts\run_memwait_overlap_diag.bat` |
| Redirect guardrail | `scripts\run_fetch_redirect_reuse_diag.bat` |
| Redirect strict reg=0 | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` |
| Redirect strict reg=1 | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` |
| Smoke | `scripts\run_coremark_smoke.bat rv32` |
| Short score | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |

## Execution Outcome

- `run_memwait_overlap_diag.bat` -> PASS
- `run_fetch_redirect_reuse_diag.bat` -> FAIL (timeout at `PC=00000064`, `cycle=241`)

Decision: rejected and reverted immediately. Remaining quick-screen items were
skipped by policy after early guardrail failure.
