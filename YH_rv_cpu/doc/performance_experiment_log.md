# Performance Experiment Log

## Frozen Baseline (2026-04-07)

Use this baseline before starting any competition-facing optimization work.

### CoreMark

| Item | Value |
|------|------|
| Command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Raw log | `build/sw/YH_rv_cpu_coremark_rv32_score.log` |
| Summary | `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt` |
| Result | `CoreMark/MHz = 0.912472` |
| Short completion cycles | `11014885` |
| Strict-valid companion | `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt` -> `0.912465`, `1095991523 cycles`, `10.959325s` |

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
| Summary | `build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt` |
| RV64 full-ui | `54/54` via `build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt` |
| Newly important pass | `ma_data` |
| `fence_i` handling | `PASS` under `rv32i_zicsr_zifencei` |
| Coverage statement | expanded UI coverage matrix now includes `zifencei`; frozen competition baseline remains `RV32I + Zicsr` |
| RV32 baseline fresh rerun | `33/33` via `build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt` |
| RV64 baseline fresh rerun | `21/21` via `build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt` |
| CoreMark smoke fresh rerun | `620530 cycles` |
| CoreMark short fresh rerun | `0.912472` via `build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt` |
| CoreMark strict fresh rerun | `0.912465` via `build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt` |

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
| Trial evidence archive | `build/sw/YH_rv_cpu_coremark_rv32_score_fq06_request_cursor_2026-04-08.log`, `build/sw/YH_rv_cpu_coremark_rv32_score_fq06_request_cursor_2026-04-08.summary.txt` |
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
The log is archived at `build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-08.log`.

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

The log is archived at `build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-09.log`.

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
