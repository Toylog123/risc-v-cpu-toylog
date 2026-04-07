# YH_rv_cpu Memwait Overlap Design

**Date:** 2026-04-07
**Status:** Approved for local single-variable experiment
**Owner:** Codex

## Goal

Try one minimal front-end optimization on the frozen `YH_rv_cpu` baseline:
allow a single synchronous fetch request to overlap a synchronous load
`mem_wait` window, while keeping decode/commit consumption frozen until
`mem_wait` clears.

## Context

Fresh profiling on `2026-04-07` showed:

- `stall_decode_cycles = 207474`
- `mem_wait_cycles = 553215`
- `ex_fetch_redirect_valid_cycles = 1504970`
- `fetch_queue_empty_cycles = 1504970`

The existing directed diagnostic already proves that the current baseline sees
real `mem_wait overlap` opportunities but does not issue a request in that
window:

- `scripts\run_memwait_overlap_diag.bat` -> PASS
- `scripts\run_memwait_overlap_diag.bat require_overlap` -> FAIL

That makes `mem_wait overlap` the safest next single-variable experiment,
because it already has a red/green harness and does not require reopening the
larger redirect/drop-accounting design problem.

## Options Considered

### Option A: Minimal `mem_wait overlap` request

Allow `imem_req` during `mem_wait` only when all of the following are true:

- no trap
- no decode stall
- no redirect/flush request
- no buffered fetch data is already waiting

Keep `pipeline_run = !trap_r && !mem_wait` unchanged so IF/ID consumption stays
frozen during `mem_wait`.

Pros:

- smallest RTL surface
- existing directed test can be reused
- easiest to revert if score delta is zero

Cons:

- may produce no measurable score gain
- still needs careful protection against duplicate fetches

### Option B: Redirect/drop-accounting-first

Do not change `mem_wait` behavior yet. Instead, first build stronger directed
tests around `fetch_redirect_pipe_hit`, response dropping, and redirect reuse.

Pros:

- lower functional risk
- resolves a known verification gap

Cons:

- does not directly test the `mem_wait` optimization opportunity
- unlikely to produce an immediate performance delta

### Option C: Reopen redirect `pipe-hit` RTL

Turn `fetch_redirect_pipe_hit` back on and try to recover response reuse during
redirect overlap.

Pros:

- could help the larger redirect/queue-empty bucket

Cons:

- highest risk
- current diagnostics already show the verification gap is not closed
- too large for the next single-variable step

## Recommendation

Choose **Option A**.

It is the smallest experiment that directly targets a measured bottleneck and
already has a failing strict directed test. If it produces no formal short-score
gain, revert it immediately and keep only the diagnostics/documentation.

## Proposed RTL Shape

Modify only `rtl/YH_rv_cpu.v`.

1. Add a small combinational predicate for a safe overlap-time fetch request.
2. Reuse the existing `imem_req` path instead of creating a second request path.
3. Allow overlap only when:
   - `mem_wait` is asserted
   - `fetch_buffer_valid` is false
   - `stall_decode` is low
   - `ex_fetch_redirect_valid` is low
4. Leave `pipeline_run`, queue consumption, trap handling, redirect drop logic,
   and commit behavior unchanged.

This keeps the experiment narrowly scoped to "issue one request earlier", not
"consume earlier" or "change redirect recovery semantics".

## Verification Plan

### Must Stay Red Before RTL Change

- `scripts\run_memwait_overlap_diag.bat require_overlap`

### Must Turn Green After RTL Change

- `scripts\run_memwait_overlap_diag.bat`
- `scripts\run_memwait_overlap_diag.bat require_overlap`

### Must Remain Unchanged / Healthy

- `scripts\run_fetch_redirect_reuse_diag.bat`
- `scripts\run_fetch_redirect_reuse_diag.bat require_pipe_hit` remains FAIL
- `scripts\check_syntax.bat`
- `scripts\run_coremark_smoke.bat rv32`
- `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
- `scripts\run_riscv_tests_subset.bat rv32`
- `scripts\run_riscv_tests_subset.bat rv64`

### Retain / Reject Rule

- Retain only if short CoreMark improves and the regression matrix stays green.
- If strict directed test turns green but short CoreMark stays flat, record the
  result and revert the RTL.
- Run `impl50` and FPGA-like probe only if the short-score result is positive
  enough to consider retention.

## Risks

- duplicate fetch requests during multi-cycle `mem_wait`
- subtle interaction with buffered fetch data
- hidden redirect/trap interaction if the overlap predicate is too permissive

## Out Of Scope

- changing `pipeline_run`
- consuming fetch data during `mem_wait`
- reopening redirect `pipe-hit` reuse RTL
- modifying FPGA timing/resource paths before a score-positive result exists
