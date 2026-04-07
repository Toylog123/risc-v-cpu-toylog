# YH_rv_cpu Redirect Accounting Diagnostic Design

**Date:** 2026-04-07  
**Status:** Draft for review  
**Owner:** Codex

## Goal

Add a strict directed diagnostic that verifies the redirect/flush/drop
accounting contract under both `IMEM_OUTPUT_REG=0` and
`IMEM_OUTPUT_REG=1`. The diagnostic must prove two things:

1. After a redirect overlap, the target instruction is preserved in the
   fetch queue/buffers within 1–2 cycles.
2. When `IMEM_OUTPUT_REG=1`, the `fetch_drop_count_r` behavior drops the
   stale response and then returns to `0` as expected.

## Context

We previously rejected the `fetch_redirect_pipe_hit` RTL experiment because the
verification gap was not in the overlap signal itself but in the
redirect/flush/drop contract. The current directed TB only proves overlap; it
does not enforce that the queued instruction and drop-counter semantics are
correct after the redirect.

The critical state is in `rtl/YH_rv_cpu.v`:

- `fetch_drop_count_r` / `IMEM_DROP_COUNT`
- `fetch_queue_valid`, `fetch_queue_pc`
- `fetch_buf0_valid_r`, `fetch_buf1_valid_r`
- `fetch_rsp_valid`, `imem_rvalid`

## Scope

**In scope**

- Extend the existing directed fetch redirect TB to include strict assertions
  for queue preservation and drop-counting.
- Add a second runtime path that enables `IMEM_OUTPUT_REG=1` for the same
  scenario.
- Provide two strict plusargs so the default run stays green while strict runs
  enforce the contract.

**Out of scope**

- Any RTL optimization (`fetch_redirect_pipe_hit`, reuse logic, etc.)
- Any changes to `pipeline_run` or queue consumption semantics
- Any changes to `IMEM_DROP_COUNT` logic

## Options Considered

### Option A (Recommended): Extend existing TB

Add strict checks to `tb/YH_rv_cpu_fetch_redirect_reuse_tb.v` and extend the
script to run the test with both `IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`.

Pros:

- Minimal new files
- Keeps existing flow and diagnostics in one place

Cons:

- TB grows a bit larger

### Option B: New dedicated TB

Create a new `tb/YH_rv_cpu_redirect_accounting_tb.v` with only the strict checks.

Pros:

- Clean separation and readability

Cons:

- Adds new file and new script, more overhead

## Recommended Design

Use **Option A** and extend `YH_rv_cpu_fetch_redirect_reuse_tb.v`.

### Behavioral Requirements

The directed scenario must:

- Create a sync-fetch response that overlaps a redirect.
- Trigger the existing overlap detection.
- Then assert **strict checks**:
  - `fetch_queue_valid` becomes `1` and `fetch_queue_pc` equals the redirect
    target within 1–2 cycles after overlap.
  - When `IMEM_OUTPUT_REG=1`, `fetch_drop_count_r` must:
    1. become `IMEM_DROP_COUNT` after redirect flush,
    2. decrement on the next valid response,
    3. return to `0` before the queued target is consumed.

### Test Controls

Use plusargs to keep default runs permissive:

- `require_queue_preserve`
- `require_drop_accounting`
- `imem_output_reg=0|1` (or two TB variants if parameterization is simpler)

