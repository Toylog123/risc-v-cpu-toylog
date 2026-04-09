# YH_rv_cpu FQ-04 IF/ID Redirect-Hit Bubble Bypass Design

**Date:** 2026-04-07  
**Status:** Executed (Rejected)  
**Owner:** Codex

## Goal

Run one tightly scoped FQ-04 trial that tests a single fetch-path idea:
an `if_id` redirect-hit bubble bypass.

The purpose of this round is narrow by design. We want to answer one question
quickly:
does bypassing the redirect-hit bubble at the IF/ID boundary produce a visible
gain on the quick screen, without breaking the existing guardrails?

## Context

The FQ series is intentionally conservative:

- keep the fetch-path change isolated
- test with a small quick screen first
- reject immediately when the candidate has no measurable benefit

FQ-04 should follow the same discipline. The trial should stay small enough
that we can decide retain or reject without opening a broader tuning space.

## Hypothesis

If the redirect-hit bubble is bypassed only at the IF/ID boundary, then the
quick screen should show one of two outcomes:

- the candidate improves enough to justify keeping it, or
- the candidate shows no gain, which should trigger immediate rollback

There is no middle state worth carrying forward. Either the bypass is worth
retaining as-is, or it should be rejected immediately.

## Scope

In scope:

- one RTL trial under `YH_rv_cpu/rtl/YH_rv_cpu.v`
- one variable boundary only: `if_id` redirect-hit bubble bypass
- quick screen diagnostics and a short performance check

Out of scope:

- adding a second fetch-path knob in the same round
- changing unrelated redirect, queue, or drop-accounting behavior
- expanding to the full regression set unless the quick screen shows clear gain

## Single-Variable Boundary

The trial is valid only if exactly one change axis is active.

Allowed:

- bypassing the redirect-hit bubble at `if_id`

Not allowed:

- combining the bypass with any other fetch policy change
- "cleaning up" unrelated logic while testing this candidate
- holding a second hidden variable in reserve

If the candidate cannot be described as a single `if_id` redirect-hit bubble
bypass, the trial should be rejected before execution.

## Quick Screen Matrix

Required quick screen:

| Check | Command | Expected |
| --- | --- | --- |
| Directed guardrail | `scripts\run_fetch_redirect_reuse_diag.bat` | PASS |
| Guardrail, reg=0 | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` | PASS |
| Guardrail, reg=1 | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` | PASS |
| Smoke | `scripts\run_coremark_smoke.bat rv32` | PASS |
| Short score | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` | Improve vs current baseline |

Expansion gate:

- only run the full regression if the short score improves
- otherwise stop at the quick screen and roll back the RTL change immediately

## Retain Criteria

Retain only if all of the following are true:

- all quick screen commands pass
- the short CoreMark score is strictly better than the current baseline
- no new issue appears in the guardrail diagnostics

If those conditions are met, keep the RTL change and record the candidate as
retainable.

## Reject Criteria

Reject immediately if any of the following happens:

- the candidate needs a second variable to make progress
- any guardrail command fails
- the short score does not improve

Reject means:

- revert the RTL change in the same round
- record the result as a no-gain trial
- do not expand to the full matrix

## Execution Outcome

Executed on 2026-04-07 with the standard quick-screen gate.

Observed results:

- `scripts\run_fetch_redirect_reuse_diag.bat` -> PASS
- `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` -> PASS
- `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` -> PASS
- `scripts\run_coremark_smoke.bat rv32` -> PASS (`620531 cycles`)
- `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` -> PASS but `completion_cycles=11014886`

Decision: rejected and reverted in the same round because short CoreMark
did not improve versus the frozen baseline (`11014885 cycles`).
