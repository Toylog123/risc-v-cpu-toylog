# YH_rv_cpu FQ-05B Redirect-Reuse Next-Line Prefetch Design

**Date:** 2026-04-07  
**Status:** Executed (Rejected)  
**Owner:** Codex

## Goal

Test one single-variable candidate in `rtl/YH_rv_cpu.v`:
when redirect reuse is detected, issue an IMEM request in redirect cycle for
`redirect_pc + 4`.

## Hypothesis

If redirect target instruction is already reusable from queue/buffer, a
same-cycle request for the next sequential instruction might reduce recovery
bubbles and improve short CoreMark score.

## Single-Variable Boundary

Allowed change:

- request enable policy for redirect-reuse hit
- request PC selection for that same case

Not allowed:

- queue depth changes
- drop-accounting policy changes
- non-redirect request behavior changes

## Quick Screen Gate

| Check | Command |
| --- | --- |
| Directed guardrail | `scripts\run_fetch_redirect_reuse_diag.bat` |
| Guardrail strict reg=0 | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` |
| Guardrail strict reg=1 | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` |
| Smoke | `scripts\run_coremark_smoke.bat rv32` |
| Short score | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |

## Execution Outcome

- Guardrails: PASS (default + strict reg=0 + strict reg=1)
- Smoke: PASS (`620530 cycles`)
- Short score: PASS but unchanged (`11014885 cycles`, `0.912472 CoreMark/MHz`)

Decision: rejected and reverted in the same round because no short-score gain
was observed.
