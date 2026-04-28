# Performance Experiment Log

## Frozen Baseline (2026-04-07)

Use this baseline before starting any competition-facing optimization work.

### CoreMark

| Item | Value |
|------|------|
| Command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Raw log | `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score.log` |
| Summary | `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt` |
| Result | `CoreMark/MHz = 0.912472` |
| Short completion cycles | `11014885` |
| Strict-valid companion | `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt` -> `0.912465`, `1095991523 cycles`, `10.959325s` |

### riscv-tests baseline

| Item | Value |
|------|------|
| RV32 baseline manifest | `scripts\riscv_tests_rv32_baseline.txt` |
| RV32 fresh result | `33/33` |
| RV64 baseline manifest | `scripts\riscv_tests_rv64_baseline.txt` |
| RV64 fresh result | `21/21` |

### FPGA impl50 / probe

| Item | Value |
|------|------|
| Command | `scripts\build_vivado_project.bat impl50` |
| Bitstream | `project/YH_rv_cpu_nexys_a7_100_20p000.bit` |
| Timing report | `project/reports/clk_20p000ns/impl_timing_summary.rpt` |
| Utilization report | `project/reports/clk_20p000ns/impl_utilization.rpt` |
| WNS / WHS | `+5.599ns / +0.025ns` |
| Slice LUTs / FF / BRAM / DSP | `2556 / 2170 / 4 / 0` |
| FPGA-like probe | `156442 cycles`, `7.728811 CoreMark/MHz` |

## Retained Optimizations

### O1 - Tighten synchronous load hazard stall

| Item | Value |
|------|------|
| Change | `stall_decode` stalls only on `load_use_hazard` |
| Files | `rtl/YH_rv_cpu_hazard_unit.v` |
| Before | `CoreMark/MHz = 0.888486` |
| After | `CoreMark/MHz = 0.912472` |
| Delta | `+0.023986` (`+2.70%`) |
| Keep? | `yes` |

### O2 - FPGA path defaults

| Item | Value |
|------|------|
| Change | Retain `IMEM_OUTPUT_REG=0` and `DMEM_OUTPUT_REG=0` on FPGA path |
| Files | `fpga/vivado/src/YH_rv_cpu_fpga_top.v`, `tb/YH_rv_cpu_coremark_fpga_tb.v` |
| Probe result | `156442 cycles`, `7.728811 CoreMark/MHz` |
| impl50 result | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS=+5.599ns`, `WHS=+0.025ns` |
| Keep? | `yes` |

Final retained state:

- `stall_decode = load_use_hazard`
- FPGA default `IMEM_OUTPUT_REG=0`
- FPGA default `DMEM_OUTPUT_REG=0`

## Closed / Rejected Optimization Directions

The following directions were fully executed and rejected because they produced
no retainable benefit or failed guardrails:

| Direction | Result | Reason |
|------|------|------|
| Simple `stall_decode` relaxation for fetch-side gain | closed | current fetch PC freezes under stall, so relaxing the gate is not a safe one-line optimization |
| O6 fetch-side prefetch / request cursor | rejected | directed behavior could be shown, but short CoreMark delta remained `0` |
| redirect `pipe-hit` recheck | rejected | strict diagnostics could pass, but short score stayed flat |
| redirect same-cycle request | rejected | functionally green, score delta `0` |
| FQ-01 queue-decouple | rejected | guardrails green, score delta `0` |
| FQ-02 queue/FIFO occupancy | rejected | guardrails green, score delta `0` |
| FQ-03 explicit 3-entry queue | rejected | guardrails green, score delta `0` |
| FQ-04 IF/ID redirect-hit bubble bypass | rejected | score regressed by one cycle |
| FQ-05A queue-consume/data-write align | rejected | score delta `0` |
| FQ-05B redirect-reuse next-line prefetch | rejected | score delta `0` |
| FQ-05C IF/ID mem-wait preload | rejected | redirect guardrail failed early |

## 2026-04-08 Validation-Led Pause Before Further Optimization

This round does not introduce a new retained optimization. Instead, it expands
the verification envelope before any higher-intrusion optimization work such as
`FQ-06`.

### Worktree changes under active validation

- `scripts\run_riscv_tests_subset.bat`
  - adds custom manifest, `march`, linker, `tohost_addr`, `max_cycles`, and
    non-fail-fast support
- `tb\YH_rv_cpu_riscv_tests_tb.v`
  - adds runtime-configurable `tohost_addr`
- `sw\riscv-tests-env\riscv_test.h`
  - adds misaligned load/store trap software compensation for `riscv-tests`
- new formal inputs:
  - `scripts\riscv_tests_rv32_ui_all.txt`
  - `scripts\riscv_tests_rv64_ui_all.txt`
  - `sw\linker\YH_rv_cpu_riscv_tests_large.ld`

### Fresh evidence from this round

| Item | Result |
|------|------|
| Command | `scripts\run_riscv_tests_subset.bat rv32 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv32_ui_all.txt rv32i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000` |
| Overall result | `42/42` |
| Summary | `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt` |
| RV64 full-ui | `54/54` via `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt` |
| Newly important pass | `ma_data` |
| `fence_i` handling | `PASS` under `rv32i_zicsr_zifencei` |
| Coverage statement | expanded UI coverage matrix now includes `zifencei`; frozen competition baseline remains `RV32I + Zicsr` |
| RV32 baseline fresh rerun | `33/33` via `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt` |
| RV64 baseline fresh rerun | `21/21` via `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt` |
| CoreMark smoke fresh rerun | `620530 cycles` |
| CoreMark short fresh rerun | `0.912472` via `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt` |
| CoreMark strict fresh rerun | `0.912465` via `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt` |

### Current decision gate

Pre-optimization closure is now complete. The next local batch is:

1. freeze the post-closure baseline table
2. start `FQ-06` as the next single-variable optimization candidate
3. keep docs and focused commits aligned with each retained/rejected experiment

## 2026-04-08 FQ-06 Launch Contract

This entry started the next optimization batch after strict closure and froze
the first active `FQ-06` slice plus its red/green gate.

| Item | Value |
|------|------|
| Active baseline | `2026-04-08` fresh closure set (`full-ui`, baseline, smoke, short, strict) |
| Performance target path | `IMEM_OUTPUT_REG=0` |
| Correctness-only guardrail path | `IMEM_OUTPUT_REG=1` |
| Selected change class | bounded request cursor / request-side decouple |
| Explicitly unchanged in first cut | IF/ID payload path, fetch buffer depth, competition ISA baseline |
| New red/green entry | strengthen `run_fetch_prefetch_diag.bat` so the frozen baseline fails a stricter stall-prefetch requirement |
| Must stay green before any CoreMark claim | `run_fetch_redirect_reuse_diag.bat` default + strict `imem_output_reg=0/1`, `run_memwait_overlap_diag.bat` |
| Quick-screen performance gate | `run_coremark_smoke.bat rv32`, `run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Expansion rule | only if short CoreMark strictly improves |

## 2026-04-08 FQ-06A Bounded Request-Cursor Trial (Rejected)

This round executed the first post-closure `FQ-06` slice in `rtl/YH_rv_cpu.v`:
add bounded request-side decoupling on the active `IMEM_OUTPUT_REG=0` path,
while keeping `IMEM_OUTPUT_REG=1` as a strict correctness guardrail only.

| Item | Value |
|------|------|
| Trial scope | `rtl/YH_rv_cpu.v` only, bounded request cursor / request-side decouple |
| Retained diagnostics | `scripts\run_fetch_prefetch_diag.bat` now accepts raw plusargs; `tb\YH_rv_cpu_fetch_prefetch_tb.v` adds `require_queue_fill` |
| New directed red/green | frozen baseline fails `run_fetch_prefetch_diag.bat require_prefetch` and `run_fetch_prefetch_diag.bat require_queue_fill`; trial RTL passes both |
| Redirect diag default | `scripts\run_fetch_redirect_reuse_diag.bat` -> `PASS` |
| Redirect accounting strict (`IMEM_OUTPUT_REG=0`) | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` -> `PASS` |
| Redirect accounting strict (`IMEM_OUTPUT_REG=1`) | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` -> `PASS` |
| Memwait guardrail | `scripts\run_memwait_overlap_diag.bat` -> `PASS` |
| CoreMark smoke on trial RTL | `620530 cycles` |
| CoreMark short on trial RTL | `11014885 cycles`, `0.912472 CoreMark/MHz` |
| Trial evidence archive | `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_fq06_request_cursor_2026-04-08.log`, `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_fq06_request_cursor_2026-04-08.summary.txt` |
| Keep? | `no` |

Notes:

- The bounded request cursor is functionally feasible under the current
  diagnostics and does create stall-time prefetch activity.
- Short CoreMark remains exactly unchanged, so the RTL does not meet the
  retention bar and was reverted in the same round.
- Keep the new `run_fetch_prefetch_diag.bat` plusarg normalization and the
  `require_queue_fill` guardrail in-tree; they are useful entry points for any
  future fetch/request experiment.

## 2026-04-08 Post-FQ-06A Profile Follow-up

After reverting the trial RTL, a fresh profile run was taken on the restored
baseline via `scripts\run_coremark_profile.bat rv32 10 2000 100000000UL 20000000`.
The log is archived at `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-08.log`.

| Counter | Value |
|------|------|
| `PROFILE: total_cycles` | `12516421` |
| `PROFILE: stall_decode_cycles` | `207474` |
| `PROFILE: mem_wait_cycles` | `553215` |
| `PROFILE: ex_fetch_redirect_valid_cycles` | `1504970` |
| `PROFILE: fetch_queue_empty_cycles` | `1504970` |

Conclusion:

- residual fetch starvation is aligned exactly with redirect windows
- request-side decouple is no longer the main missing piece on the restored baseline
- if optimization resumes, the next meaningful direction must attack control-flow redirect cost directly; repeating request/queue micro-tuning is likely redundant

## 2026-04-09 Redirect Breakdown Profile

To avoid restarting optimization from a vague "redirect cost" label, the
profile testbench was extended to split redirect windows by source class and
reuse outcome. A fresh run was taken via:

```bat
scripts\run_coremark_profile.bat rv32 10 2000 100000000UL 20000000
```

The log is archived at `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-09.log`.

| Counter | Value |
|------|------|
| `PROFILE: total_cycles` | `12516421` |
| `PROFILE: stall_decode_cycles` | `207474` |
| `PROFILE: mem_wait_cycles` | `553215` |
| `PROFILE: ex_trap_valid_cycles` | `0` |
| `PROFILE: ex_mret_valid_cycles` | `0` |
| `PROFILE: ex_branch_redirect_cycles` | `1235790` |
| `PROFILE: ex_jal_redirect_cycles` | `153354` |
| `PROFILE: ex_jalr_redirect_cycles` | `115826` |
| `PROFILE: ex_fetch_redirect_valid_cycles` | `1504970` |
| `PROFILE: fetch_queue_empty_cycles` | `1504970` |
| `PROFILE: fetch_redirect_reuse_cycles` | `0` |
| `PROFILE: fetch_redirect_reuse_miss_cycles` | `1504970` |
| `PROFILE: fetch_redirect_buf0_hit_cycles` | `0` |
| `PROFILE: fetch_redirect_buf1_hit_cycles` | `0` |

Conclusion:

- redirect windows are still the dominant fetch starvation source, but they are
  now clearly branch-heavy rather than trap-heavy or reuse-heavy
- taken branches account for `1235790 / 1504970` redirect cycles, so any
  jal-only or jalr-only change has a capped upside
- `fetch_redirect_reuse` is effectively dead on CoreMark (`0` hits), so
  repeating buffer-reuse/request-side experiments is not justified
- the next non-redundant optimization hypothesis should attack taken
  control-flow latency directly; the lowest-risk first slice is an earlier
  unconditional control redirect rather than another queue/reuse tweak

## 2026-04-09 Decode-Stage Early JAL Redirect Trial (Rejected Before CoreMark Re-run)

This round tested a narrower follow-up hypothesis after the split redirect
profile: allow `JAL` to redirect the fetch PC one stage earlier in decode
while leaving branch and `JALR` on the existing EX redirect path.

### Trial scope

| Item | Value |
|------|------|
| Goal | reduce unconditional redirect bubbles without reopening queue/reuse tuning |
| Intended change | decode-stage early fetch redirect for `JAL` only |
| First guardrail | `scripts\run_riscv_tests_subset.bat rv32 jal - 120000` |
| Failure evidence | `YH_rv_cpu/build/tests/riscv-tests/rv32/jal_early_redirect_debug_2026-04-09.log` |
| Debug summary | `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_jal_early_redirect_debug_2026-04-09.txt` |
| Keep? | `no` |

### Fresh evidence

- The first cut failed the minimal `rv32 jal` guardrail immediately and wrote
  `tohost=7`, which proved the change was not CoreMark-specific.
- A minimal follow-up restoration of EX-stage decode flush changed the failure
  from `tohost=7` to `tohost=5`, showing that missing wrong-path flush was one
  real issue but not the only issue.
- Additional debug trace showed that the trial was consuming an implicit
  control bubble and exposing deeper control/operand timing coupling in the
  existing pipeline.
- After reverting the trial RTL, a fresh rerun of
  `scripts\run_riscv_tests_subset.bat rv32 jal - 120000` returned to `PASS`.

### Conclusion

- This is not a low-intrusion optimization anymore; keeping it would require
  structural work on control/forwarding timing rather than a single-variable
  tweak.
- Because the gain was still unproven and the first guardrail already failed,
  the trial was rejected before spending more time on CoreMark reruns.
- The next optimization entry should stay aligned with the `2026-04-09`
  split-profile conclusion: prioritize branch-dominant redirect cost analysis,
  not a jal-only speculative shortcut.

## 2026-04-11 Split Redirect Profile Re-Verification

The current worktree was re-run via:

```bat
scripts\run_coremark_profile.bat rv32 10 2000 100000000UL 20000000
```

The working log is `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile.log`.
It was diffed against the archived
`YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_branch_breakdown_2026-04-09.log`.
The only textual differences were the session timestamp and total simulation
runtime lines.

| Counter | Value |
|------|------|
| `PROFILE: ex_branch_redirect_cycles` | `1235790` |
| `PROFILE: ex_beq_redirect_cycles` | `329513` |
| `PROFILE: ex_bne_redirect_cycles` | `849894` |
| `PROFILE: ex_blt_redirect_cycles` | `3863` |
| `PROFILE: ex_bge_redirect_cycles` | `10573` |
| `PROFILE: ex_bltu_redirect_cycles` | `13963` |
| `PROFILE: ex_bgeu_redirect_cycles` | `27984` |
| `PROFILE: ex_jal_redirect_cycles` | `153354` |
| `PROFILE: ex_jalr_redirect_cycles` | `115826` |
| `PROFILE: fetch_redirect_reuse_cycles` | `0` |
| `PROFILE: fetch_redirect_reuse_miss_cycles` | `1504970` |

Conclusion:

- the current worktree still reproduces the same branch-dominant redirect
  profile seen on `2026-04-09`
- `BEQ/BNE` remain the overwhelming majority of taken-branch redirect cost
- no evidence suggests queue/reuse work has become newly useful on CoreMark

## 2026-04-11 Branch-First `BEQ/BNE` Pipe-Hit Trial (Rejected)

This round executed the first post-profile branch-first slice:
allow the active `IMEM_OUTPUT_REG=0` path to treat same-cycle redirect-target
responses as reusable only for taken `BEQ/BNE`, while leaving EX-stage
redirect/flush authority unchanged.

### Trial scope

| Item | Value |
|------|------|
| Goal | activate useful redirect reuse on the branch-dominant CoreMark path without reopening `jal-only` or queue-depth tuning |
| Intended RTL slice | `fetch_redirect_pipe_hit` gated to taken `BEQ/BNE` on `IMEM_OUTPUT_REG=0` |
| New red/green entry | `scripts\run_fetch_redirect_reuse_diag.bat require_branch_reuse timeout_cycles=80` |
| Baseline fail evidence | `YH_rv_cpu/build/tests/branch-first/branch_reuse_beqbne_baseline_fail_2026-04-11.log` |
| Trial pass evidence | `YH_rv_cpu/build/tests/branch-first/branch_reuse_beqbne_diag_2026-04-11.log` |
| `rv32 beq` guardrail | `YH_rv_cpu/build/tests/branch-first/summary_beq_branch_pipehit_beqbne_2026-04-11.txt` |
| `rv32 bne` guardrail | `YH_rv_cpu/build/tests/branch-first/summary_bne_branch_pipehit_beqbne_2026-04-11.txt` |
| Profile evidence | `YH_rv_cpu/build/tests/branch-first/YH_rv_cpu_coremark_rv32_profile_branch_pipehit_beqbne_2026-04-11.log` |
| Short-score evidence | `YH_rv_cpu/build/tests/branch-first/YH_rv_cpu_coremark_rv32_score_branch_pipehit_beqbne_2026-04-11.summary.txt` |
| Keep? | `no` |

### Quick-screen results

| Check | Result |
|------|------|
| branch-first diag | `PASS` on trial RTL, `FAIL` on reverted baseline |
| redirect diag default | `PASS` |
| redirect accounting strict (`IMEM_OUTPUT_REG=0`) | `PASS` |
| redirect accounting strict (`IMEM_OUTPUT_REG=1`) | `PASS` |
| `rv32 beq` | `PASS` |
| `rv32 bne` | `PASS` |
| CoreMark smoke | `620530 cycles` |
| CoreMark profile | `fetch_redirect_reuse_cycles = 305277`, `fetch_redirect_reuse_miss_cycles = 1199693` |
| CoreMark profile | `fetch_queue_empty_cycles = 1504970` |
| CoreMark short | `11014885 cycles`, `0.912472 CoreMark/MHz` |

### Conclusion

- the branch-only pipe-hit slice did activate redirect reuse on CoreMark, but
  it did not reduce the dominant fetch-empty window
- `fetch_queue_empty_cycles` remained exactly `1504970`, so the reuse activity
  did not translate into less starvation at the scoreboard level
- short CoreMark remained exactly unchanged, so the trial failed the retention
  bar even though the new counter moved
- the mainline RTL was reverted in the same round; the retained artifact from
  this batch is the stronger `require_branch_reuse` diagnostic path

## 2026-04-12 Taken `BEQ/BNE` Decode-Stage Early Redirect with Operand-Ready Gating (Retained in Worktree)

This round revisited the branch-dominant redirect problem after rejecting the
`pipe-hit-only` slice. The retained cut does not try to revive reuse. Instead,
it lets decode redirect taken `BEQ/BNE` one stage earlier, but only when both
branch operands are provably ready and not still pending in `ID/EX` or
`EX/MEM`.

### Trial scope

| Item | Value |
|------|------|
| Goal | shrink taken-branch redirect windows directly, without reopening queue/reuse tuning or the rejected `jal-only` path |
| Root-cause evidence | ungated decode-stage trial failed `rv32 beq` / `rv32 bne` immediately because decode was comparing stale regfile values |
| Early fail evidence | `YH_rv_cpu/build/tests/branch-first/rv32_beq_decode_redirect_2026-04-12.log`, `YH_rv_cpu/build/tests/branch-first/rv32_bne_decode_redirect_2026-04-12.log` |
| Retained RTL slice | `rtl/YH_rv_cpu.v`: decode-stage taken `BEQ/BNE` redirect with operand-ready gating; EX redirect path remains the authority for the rest of control flow |
| Directed TB support | `tb/YH_rv_cpu_fetch_redirect_reuse_tb.v`: add `require_branch_decode_kill` red/green and safer branch-kill program shape |
| Test harness support | `scripts/run_coremark_score.bat` now derives build/log artifact names from the summary path to avoid short/strict clobbering; `scripts/riscv_tests_*` manifests were normalized for the batch loader |
| Keep? | `yes` in the active worktree; frozen competition tables are not refreshed yet |

### Fresh evidence

| Item | Result |
|------|------|
| branch-kill baseline fail | `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_baseline_2026-04-12.log` |
| branch-kill trial pass | `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_trial_2026-04-12.log` |
| redirect diag default | `PASS` via `YH_rv_cpu/build/tests/branch-first/redirect_diag_default_trial_2026-04-12.log` |
| `rv32 baseline` | `33/33` via `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-12.txt` |
| `rv64 baseline` | `21/21` via `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-12.txt` |
| `rv32 full-ui` | `42/42` via `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-12.txt` |
| `rv64 full-ui` | `54/54` via `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-12.txt` |
| CoreMark short | `10862713 cycles`, `0.925186 CoreMark/MHz` via `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-12.summary.txt` |
| CoreMark short rerun | identical `10862713 cycles`, `0.925186 CoreMark/MHz` via `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_rerun_2026-04-12.summary.txt` |
| CoreMark profile | `12364249 cycles` via `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-12.log` |
| Fresh strict / impl / probe | deferred in this round; last archived long-run / implementation references remain the `2026-04-08` frozen set |

### Measured delta vs frozen baseline

| Metric | Frozen baseline | Retained worktree | Delta |
|------|------|------|------|
| CoreMark short cycles | `11014885` | `10862713` | `-152172` (`-1.3815%`) |
| CoreMark short score | `0.912472` | `0.925186` | `+0.012714` (`+1.3934%`) |
| Profile total cycles | `12516421` | `12364249` | `-152172` (`-1.2158%`) |
| `ex_branch_redirect_cycles` | `1235790` | `1081457` | `-154333` (`-12.4886%`) |
| `ex_beq_redirect_cycles` | `329513` | `317843` | `-11670` (`-3.5416%`) |
| `ex_bne_redirect_cycles` | `849894` | `707231` | `-142663` (`-16.7860%`) |
| `ex_fetch_redirect_valid_cycles` | `1504970` | `1350637` | `-154333` (`-10.2549%`) |
| `fetch_queue_empty_cycles` | `1504970` | `1504970` | `0` |
| `fetch_redirect_reuse_cycles` | `0` | `0` | `0` |

### Conclusion

- The retained gain is real and repeatable on the short CoreMark path.
- The profile improvement lines up with the design intent: fewer branch
  redirect window cycles, especially on `BNE`.
- `fetch_queue_empty_cycles` staying flat means this is not a queue/reuse win;
  it is a control-flow timing win.
- This retained slice supersedes the rejected `BEQ/BNE pipe-hit-only` idea.
  Do not reopen `pipe-hit-only` or `jal-only`.
- Before declaring a new frozen competition baseline, still rerun:
  - strict CoreMark long run
  - `impl50`
  - FPGA-like probe

## 2026-04-28 RV32IM CoreMark Score Path (Retained Short-Run Path)

This round attacked the largest software-visible gap in the CoreMark dump:
the `rv32i_zicsr` build was still calling software multiply/divide helpers
such as `__mulsi3` and `__divsi3`. The RTL already includes M-extension
decode and ALU support, so the lowest-intrusion candidate was to add an
explicit `rv32im` CoreMark build/score path and verify that it emits hardware
M instructions.

### Red / Green

| Item | Result |
|------|------|
| Red build | `scripts\build_coremark.bat rv32im 1 2000 100000000UL 0 YH_rv_cpu_coremark_rv32im_red` still used `MARCH=rv32i_zicsr` |
| Red dump check | no hardware `mul` / `div` / `rem` instructions were emitted |
| Green build | `scripts\build_coremark.bat rv32im 1 2000 100000000UL 0 YH_rv_cpu_coremark_rv32im_green` used `MARCH=rv32im_zicsr` and `MULTIDIR=rv32im\ilp32` |
| Green dump check | hardware `mul` instructions appeared in `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32im_green.dump` |

### Changes

| File | Change |
|------|------|
| `scripts/build_coremark.bat` | add `rv32im` and `rv64im` target mapping to `rv32im_zicsr` / `rv64im_zicsr` and matching GCC multilibs |
| `scripts/run_coremark_score.bat` | map `rv32im` onto the existing rv32 testbench ROM name, and `rv64im` onto the existing rv64 testbench ROM name |
| `sw/coremark_port/core_portme.h` | report `rv32im_zicsr` / `rv64im_zicsr` compiler flags when `__riscv_mul` is defined |
| `scripts/run_m_extension_test.bat` | make pass/fail parsing robust by using ASCII `11/11` and `[FAIL]` markers |

### Fresh Evidence

| Check | Result |
|------|------|
| `rv32im` CoreMark short | `4269236 completion cycles`, `2.365118 CoreMark/MHz` via `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32im_score.summary.txt` |
| `rv32im` compiler flags | `-O2 -march=rv32im_zicsr -mabi=ilp32` |
| CoreMark CRCs | `crclist=0xe714`, `crcmatrix=0x1fd7`, `crcstate=0x8e3a`, `crcfinal=0xfcaf` |
| M extension guardrail | `scripts\run_m_extension_test.bat` -> `PASS`, `11/11` |
| Legacy `rv32i` score after script change | `10862713 cycles`, `0.925186 CoreMark/MHz` via `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_after_rv32im.summary.txt` |

### Measured Delta

| Metric | Previous active short path | RV32IM short path | Delta |
|------|------|------|------|
| CoreMark short cycles | `10862713` | `4269236` | `-6593477` (`-60.70%`) |
| CoreMark/MHz | `0.925186` | `2.365118` | `+1.439932` (`+155.64%`) |

### Conclusion

- The `>1.5 CoreMark/MHz` target is exceeded on the short reportable path.
- The gain comes from replacing software multiply helpers with hardware
  M-extension instructions, not from a new RTL timing or fetch change.
- This path should be kept as the primary high-score candidate, while the
  older `rv32i_zicsr` path remains available as the conservative ISA baseline.
- Before calling this a frozen strict baseline, still run a strict `>=10s`
  long run with enough iterations for the faster rv32im path, plus `impl50`
  and FPGA-like probe.

## 2026-04-28 RV32IM Compiler Matrix Follow-up

After retaining the basic `rv32im` score path, two compiler variants were
tested using the same RTL and the same short CoreMark command shape.

| Target | Compiler flags | Completion cycles | CoreMark/MHz | Decision |
|------|------|------|------|------|
| `rv32im` | `-O2 -march=rv32im_zicsr -mabi=ilp32` | `4269236` | `2.365118` | retained baseline for M path |
| `rv32im_o3` | `-O3 -march=rv32im_zicsr -mabi=ilp32` | `4327580` | `2.331563` | rejected; slower than `-O2` |
| `rv32im_o3unroll` | `-O3 -funroll-loops -march=rv32im_zicsr -mabi=ilp32` | `4112023` | `2.455226` | retained as current short best |

The `rv32im_o3unroll` profile was captured via:

```bat
scripts\run_coremark_profile.bat rv32im_o3unroll 10 2000 100000000UL 30000000 0
```

| Counter | Value |
|------|------|
| `PROFILE: total_cycles` | `4422172` |
| `PROFILE: stall_decode_cycles` | `204495` |
| `PROFILE: mem_wait_cycles` | `578409` |
| `PROFILE: ex_branch_redirect_cycles` | `149208` |
| `PROFILE: ex_jal_redirect_cycles` | `53053` |
| `PROFILE: ex_jalr_redirect_cycles` | `13814` |
| `PROFILE: ex_fetch_redirect_valid_cycles` | `216075` |
| `PROFILE: fetch_queue_empty_cycles` | `314532` |

Conclusion:

- The compiler matrix produced a small but real new short-run best.
- The next RTL target should no longer be branch-first; branch redirect is now
  much smaller than the memory-side counters.
- The existing memwait-overlap diagnostic is again relevant on the new best
  path because `mem_wait_cycles` and `fetch_queue_empty_cycles` remain visible.

## 2026-04-28 Memwait Overlap Fetch Request Trial (Rejected)

This round tested the planned low-intrusion RTL slice for the new
`rv32im_o3unroll` best path: allow a single instruction fetch request during a
data-side `mem_wait` window when there is no stall, redirect, queued fetch data,
or unresolved future fetch response.

| Check | Result |
|------|------|
| Baseline red | `scripts\run_memwait_overlap_diag.bat require_overlap` -> `FAIL`, `overlap_requests=0` |
| Trial syntax | `scripts\check_syntax.bat` -> PASS |
| Trial strict directed | `scripts\run_memwait_overlap_diag.bat require_overlap` -> PASS, `overlap_requests=1` |
| Trial default directed | `scripts\run_memwait_overlap_diag.bat` -> PASS, `overlap_requests=1` |
| Redirect guardrail | `scripts\run_fetch_redirect_reuse_diag.bat` -> PASS |
| CoreMark smoke | `scripts\run_coremark_smoke.bat rv32im_o3unroll` -> PASS, `591345 cycles` |
| CoreMark short score | `scripts\run_coremark_score.bat rv32im_o3unroll 10 2000 100000000UL 30000000 build\sw\YH_rv_cpu_coremark_rv32im_o3unroll_memwait_score.summary.txt` -> `4112023 cycles`, `2.455226 CoreMark/MHz` |
| Keep? | `no`; RTL reverted because short CoreMark was exactly unchanged |

Conclusion:

- The directed harness proved the overlap request is functionally feasible.
- It does not reduce the current CoreMark short cycle count on
  `rv32im_o3unroll`; the score and cycles are identical to the previous best.
- Do not repeat this exact request-only memwait overlap slice unless the memory
  subsystem or CoreMark workload shape changes.
- The next optimization should target a larger measured bucket than this
  one-cycle overlap opportunity, or change the software/code-generation path
  again.

## 2026-04-28 RV32IM Extended Compiler Matrix (No New Best)

After rejecting the request-only memwait RTL slice, another compiler-side
screen was run before moving to higher-intrusion RTL work. This batch also
fixed the Windows LTO build path by forcing GCC temporary files into the
project-local `_tmp\gcc_tmp` directory, avoiding non-ASCII user-profile temp
paths during `-flto` links.

| Target | Compiler flags | Completion cycles | CoreMark/MHz | Decision |
|------|------|------|------|------|
| `rv32im_o2unroll` | `-O2 -funroll-loops -march=rv32im_zicsr -mabi=ilp32` | `4138703` | `2.439546` | rejected |
| `rv32im_ofast` | `-Ofast -march=rv32im_zicsr -mabi=ilp32` | `4327646` | `2.331563` | rejected |
| `rv32im_ofast_unroll` | `-Ofast -funroll-loops -march=rv32im_zicsr -mabi=ilp32` | `4112080` | `2.455226` | rejected; score ties but cycles are slightly worse |
| `rv32im_o3lto` | `-O3 -flto -march=rv32im_zicsr -mabi=ilp32` | `4238630` | `2.381280` | rejected |
| `rv32im_o3unroll_lto` | `-O3 -funroll-loops -flto -march=rv32im_zicsr -mabi=ilp32` | `4168008` | `2.422267` | rejected |

Conclusion:

- Current short best remains `rv32im_o3unroll`: `4112023 cycles`,
  `2.455226 CoreMark/MHz`.
- Plain LTO and `Ofast` do not help this in-order core on the current workload.
- Further progress is more likely from reducing the global synchronous-load
  wait policy than from more generic GCC flag combinations.

## 2026-04-28 RV32IM Branch-Cost / Scheduler Compiler Follow-up (Retained)

After the RTL-side load/branch work lifted the `rv32im_o3unroll` path to
`3.140284 CoreMark/MHz`, a fresh profile showed the remaining score was no
longer dominated by stalls:

| Counter | Value |
|------|------|
| `PROFILE: total_cycles` | `3216462` |
| `PROFILE: stall_decode_cycles` | `0` |
| `PROFILE: mem_wait_cycles` | `0` |
| `PROFILE: id_ex_valid_cycles` | `2596163` |
| `PROFILE: ex_fetch_redirect_valid_cycles` | `71972` |
| Top dynamic regions | matrix `745741`, list `716795`, state `695000`, crc `394942` |

The next screen stayed within `rv32im_zicsr` and did not modify CoreMark
algorithm sources.

| Variant | Extra flags | Total ticks | CoreMark/MHz | Decision |
|------|------|------|------|------|
| baseline | none beyond `-O3 -funroll-loops` | `3184425` | `3.140284` | previous best |
| `rocket` | `-mtune=rocket` | `3184425` | `3.140284` | rejected; identical |
| `sifive-e31` | `-mtune=sifive-e31` | `3184425` | `3.140284` | rejected; identical |
| `branch0` | `-mbranch-cost=0` | `3184425` | `3.140284` | rejected; identical |
| `branch1` | `-mbranch-cost=1` | `3101076` | `3.224687` | improved |
| `branch2` | `-mbranch-cost=2` | `3184955` | `3.139762` | rejected |
| `branch1_sched` | `branch1` + modulo scheduling / rename flags | `3101096` | `3.224666` | rejected; tie/slightly worse |
| `branch1_peel` | `branch1` + peel/unswitch/tracer | `3101053` | `3.224711` | rejected; tiny gain but not best |
| `branch1_noifcvt` | `branch1` + `-fno-if-conversion*` | `3101116` | `3.224646` | rejected |
| `rv32im_o3_branch1_nosched` | no `-funroll-loops` | `3299219` | `3.031020` | rejected |
| `rv32im_o3unroll_b1nosched` | `-mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2` | `3090115` | `3.236126` | retained |
| `branch1_nosched_peel` | retained flags + peel/unswitch/tracer | `3090890` | `3.235314` | rejected |

### Retained Changes

| File | Change |
|------|------|
| `scripts/build_coremark.bat` | add `rv32im_o3unroll_b1nosched`; allow `YH_COREMARK_EXTRA_OPT` for temporary compiler screens |
| `sw/coremark_port/core_portme.h` | report the exact retained compiler flags in the CoreMark banner |
| `tb/YH_rv_cpu_coremark_profile_tb.v` | add dynamic instruction mix, function-region, and static PC Top-40 counters |
| `scripts/run_coremark_profile.bat` | print all `PROFILE:` counters so new profile fields are not silently hidden |

### Fresh Retained Evidence

| Check | Result |
|------|------|
| Score command | `scripts\run_coremark_score.bat rv32im_o3unroll_b1nosched 10 2000 100000000UL 30000000 build\sw\YH_rv_cpu_coremark_rv32im_o3unroll_b1nosched_score.summary.txt` |
| Score | `total_ticks=3090115`, `CoreMark/MHz=3.236126`, `competition_reportable=yes` |
| Compiler flags | `-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -march=rv32im_zicsr -mabi=ilp32` |
| Profile command | `scripts\run_coremark_profile.bat rv32im_o3unroll_b1nosched 10 2000 100000000UL 30000000 0` |
| Profile | `id_ex_valid_cycles=2544066`, `stall_decode_cycles=0`, `mem_wait_cycles=0`, `ex_fetch_redirect_valid_cycles=90227` |

### Conclusion

- The retained compiler target is a real short-run improvement over
  `rv32im_o3unroll_idjalr`: `3.236126` vs `3.140284 CoreMark/MHz`.
- The score gain comes from lower dynamic instruction count and code shape,
  not from reducing redirect cycles.
- The profile now shows no decode or memory wait stalls, so the remaining path
  to `>5 CoreMark/MHz` likely needs much larger instruction-count reduction or
  higher-throughput microarchitecture work; repeating memwait overlap, static
  backward prediction, or branch-only redirect tweaks is unlikely to close the
  remaining gap.
