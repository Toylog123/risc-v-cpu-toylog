# YH_rv_cpu FQ-03 Single-Variable Boundary Design

**Date:** 2026-04-07  
**Status:** Executed and rejected  
**Owner:** Codex

## Goal

Run one tightly scoped FQ-03 trial that tests the current fetch-path idea
against a strict single-variable boundary.

The purpose of this round is not to expand the design space. It is to answer
one question quickly and safely:
does the candidate produce a measurable gain on the quick screen, with no
regression in the guardrail checks?

## Context

The recent FQ sequence has already established a pattern:

- keep the fetch-path change isolated
- use a small quick screen first
- reject immediately when the candidate has no visible benefit

FQ-03 should follow that same discipline. The doc is intentionally narrow so
the implementation and decision can be completed in one pass.

## Hypothesis

If the candidate change stays inside one variable boundary, then the quick
screen should be able to detect either:

- a real improvement worth expanding, or
- no benefit, which should trigger immediate revert

The important outcome is not a partial win. The important outcome is whether
this exact single-variable idea is worth keeping at all.

## Scope

In scope:

- one fetch-path trial under `YH_rv_cpu/rtl/YH_rv_cpu.v`
- one variable boundary only
- quick screen diagnostics and a short performance check

Out of scope:

- adding a second tuning knob in the same round
- changing unrelated fetch, redirect, or drop-accounting behavior
- full regression expansion unless the quick screen shows clear gain

## Single-Variable Boundary

The trial is valid only if one and only one change axis is active.

Allowed:

- one RTL behavior change in the fetch path

Not allowed:

- combining queue, request, and redirect policy changes in the same round
- "fixing" unrelated cleanup while testing the candidate
- keeping a second hidden variable in reserve

If the candidate cannot be described as one variable, the trial should be
rejected before execution.

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

- only run full regression if the short score improves
- otherwise stop at the quick screen and revert

## Retain Criteria

Retain only if all of the following are true:

- all quick screen commands pass
- the short CoreMark score is strictly better than the current baseline
- no new issue appears in the guardrail diagnostics

If any of those fail, do not keep the RTL change.

## Reject Criteria

Reject immediately if any of the following happens:

- the candidate needs a second variable to make progress
- the quick screen passes but the short score does not improve
- any guardrail command fails

Reject means:

- revert the RTL change in the same round
- record the result as a no-gain trial
- do not expand to the full matrix

## Execution Outcome

Result: `rejected`

- Redirect diagnostics: `PASS`
- CoreMark smoke: `PASS` (`620530 cycles`)
- CoreMark short: unchanged (`11014885 cycles`, `0.912472 CoreMark/MHz`)
- RTL retained: `no` (reverted)
