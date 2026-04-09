# YH_rv_cpu FQ-06 Fetch-Request FIFO Decouple Design

**Date:** 2026-04-07  
**Status:** Executed 2026-04-08, first slice rejected
**Owner:** Codex

## Goal

Start a higher-intrusion optimization direction after strict closure:
decouple fetch request issue from IF/ID consume timing using bounded
request-side state, while keeping redirect/drop-accounting correct under both
`IMEM_OUTPUT_REG` variants.

## Why This Direction

FQ-05 series completed with no retainable gain under single-variable
front-end micro-tuning. CoreMark profile counters still show meaningful
`ex_fetch_redirect_valid_cycles` and `fetch_queue_empty_cycles`, suggesting
remaining headroom likely needs structural decouple instead of gate tweaks.

## Scope

In scope:

- new request-side state to let sync IMEM keep requesting while decode is
  stalled and the fetch queue still has safe headroom
- explicit occupancy/inflight invariants for the request side
- clear redirect/drop-accounting interaction model under `IMEM_OUTPUT_REG=0/1`
- reuse of existing directed diagnostics as guardrails before any CoreMark
  claim

Out of scope for first entry:

- branch prediction
- multi-outstanding memory protocol beyond current interface
- mixed payload/request policy changes in one shot without diagnostics
- broadening the competition ISA baseline beyond `RV32I + Zicsr`
- treating `IMEM_OUTPUT_REG=1` as a performance target; in this round it is a
  correctness guardrail only

## Selected 2026-04-08 Entry

The selected first cut is not a full general-purpose request FIFO. It is a
bounded request cursor experiment for the active performance path
(`IMEM_OUTPUT_REG=0`) with these constraints:

- keep IF/ID payload movement unchanged in the first cut
- keep fetch buffer depth unchanged
- let request issue decouple from `stall_decode` only when the queue/inflight
  model says there is room
- preserve current redirect flush semantics and keep strict redirect/drop
  diagnostics green under both `IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`

This choice intentionally avoids repeating O6/O7/FQ-01~FQ-05:

- O6 only relaxed a gate and was structurally unsafe
- O7 proved single prefetch behavior but did not close redirect/drop coupling
- FQ-01~FQ-05 covered local queue and redirect micro-tweaks without retainable
  gain

The new hypothesis is narrower: a bounded request-side cursor may allow the
existing 2-entry payload queue to fill earlier during decode stalls without
re-opening the old redirect accounting hazards.

## Test-First Entry Criteria

Before RTL changes, this round must make a directed fetch-prefetch test fail on
the frozen baseline and pass only after the new request-side behavior exists.

The initial red/green contract is:

- baseline must fail a stronger stall-prefetch requirement
- existing redirect/drop-accounting diagnostics must remain green after the RTL
  change
- only then run CoreMark smoke and short quick-screen

## 2026-04-08 Outcome

The first slice of this design was executed as a bounded request-cursor trial on
`IMEM_OUTPUT_REG=0`.

- The directed prefetch guardrails went green.
- Redirect/drop-accounting diagnostics stayed green under both
  `IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`.
- CoreMark smoke remained `620530 cycles`.
- CoreMark short remained exactly `11014885 cycles`, `0.912472 CoreMark/MHz`.

Because the short score stayed flat, the RTL was rejected and reverted in the
same round. The retained outcome from this design is diagnostic infrastructure,
not a mainline fetch-path change.

## Risk Model

- Higher design intrusion than FQ-01~FQ-05.
- Must preserve accounting correctness under redirect and IMEM output register
  variants.
- Must add/extend directed diagnostics before performance claims.

## Retain Gate

Same policy remains:

1. guardrails must stay green,
2. short CoreMark must strictly improve,
3. only then expand to full matrix.
