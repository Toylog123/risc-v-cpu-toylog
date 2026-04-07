# YH_rv_cpu FQ-06 Fetch-Request FIFO Decouple Design

**Date:** 2026-04-07  
**Status:** Draft (Pending Execution)  
**Owner:** Codex

## Goal

Start a higher-intrusion optimization direction after FQ-05 closure:
decouple fetch request issue from IF/ID consume timing using an explicit
request FIFO and outstanding-request tracking.

## Why This Direction

FQ-05 series completed with no retainable gain under single-variable
front-end micro-tuning. CoreMark profile counters still show meaningful
`ex_fetch_redirect_valid_cycles` and `fetch_queue_empty_cycles`, suggesting
remaining headroom likely needs structural decouple instead of gate tweaks.

## Scope

In scope:

- new request-side state to track outstanding fetch requests
- request FIFO boundaries and invariants
- clear redirect/drop-accounting interaction model under `IMEM_OUTPUT_REG=0/1`

Out of scope for first entry:

- branch prediction
- multi-outstanding memory protocol beyond current interface
- mixed payload/request policy changes in one shot without diagnostics

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
