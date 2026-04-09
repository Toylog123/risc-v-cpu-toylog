# YH_rv_cpu FQ-05A Queue-Consume/Data-Write Align Design

**Date:** 2026-04-07  
**Status:** Executed (Rejected)  
**Owner:** Codex

## Goal

Test one single-variable candidate in `rtl/YH_rv_cpu.v`:
align fetch queue consume/live-to-ifid handshake with `if_id_data_write_en`
instead of `if_id_write_en`.

## Hypothesis

If queue consume is aligned with real IF/ID data write cycles, redirect-related
stall windows may avoid wasting buffered fetch entries and could reduce bubbles.

## Single-Variable Boundary

Allowed change:

- `fetch_live_to_ifid`: gate by `if_id_data_write_en`
- `fetch_queue_consume`: gate by `if_id_data_write_en`

Not allowed:

- request issue policy changes
- redirect/drop-accounting policy changes
- queue depth or queue structure changes

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

Decision: rejected and reverted in the same round because retention gate
requires a strict short-score improvement.
