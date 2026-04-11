# CURRENT_STATUS

> Updated: `2026-04-11`
> Branch: `main`
> Workspace: clean
> Ahead of `origin/main`: `62`

## Latest commits

- `be00ecf` `test/docs: add branch-first redirect diag and reject pipe-hit slice`
- `506120a` `docs: plan branch-first redirect experiment`
- `c7c35d8` `docs: add current status entry point`
- `1f3ff2a` `scripts: drop bom noise and ignore conflict backups`

## Frozen engineering baseline

- `rv32 full-ui = 42/42`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt`
- `rv64 full-ui = 54/54`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt`
- `rv32 baseline = 33/33`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt`
- `rv64 baseline = 21/21`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt`
- CoreMark short:
  - `11014885 cycles`
  - `0.912472 CoreMark/MHz`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt`
- CoreMark strict:
  - `1095991523 cycles`
  - `10.959325s`
  - `0.912465 CoreMark/MHz`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt`
- `impl50`:
  - `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`
  - `WNS=+5.599ns`
  - `WHS=+0.025ns`
  - `project/reports/clk_20p000ns/`

## Current optimization status

- Mainline RTL is still the frozen baseline; current retained changes are
  observability and handoff improvements, not a new performance win.
- `2026-04-09` split profile confirmed redirect cost is branch-dominant:
  - `ex_branch_redirect_cycles = 1235790`
  - `ex_jal_redirect_cycles = 153354`
  - `ex_jalr_redirect_cycles = 115826`
  - `fetch_redirect_reuse_cycles = 0`
  - `fetch_redirect_reuse_miss_cycles = 1504970`
- `2026-04-11` rerun reproduced the same branch-breakdown counters in
  `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile.log`.
- `2026-04-11` branch-first `BEQ/BNE` pipe-hit trial was executed and rejected:
  - the strengthened branch diagnostic now distinguishes baseline `FAIL` from
    trial `PASS`
  - `fetch_redirect_reuse_cycles` moved to `305277`
  - `fetch_queue_empty_cycles` stayed `1504970`
  - short CoreMark stayed `11014885 cycles`, `0.912472 CoreMark/MHz`
  - mainline RTL was reverted in the same round
- `decode-stage early JAL redirect` was rejected; do not reopen the
  `jal-only` shortcut path as the next experiment.

## Recommended next step

- Resume optimization only from a hypothesis stronger than `BEQ/BNE` pipe-hit
  activation alone.
- Execution plan:
  - `docs/superpowers/plans/2026-04-11-yh-rv-cpu-branch-first-redirect-plan.md`
- Keep queue/reuse micro-tuning frozen unless a new control-flow result proves
  it reduces `fetch_queue_empty_cycles`, not just reuse counters.
- Before keeping any new RTL trial, rerun at least:
  - `scripts\run_riscv_tests_subset.bat rv32`
  - `scripts\run_coremark_profile.bat rv32 10 2000 100000000UL 20000000`
  - the relevant focused guardrails for the chosen redirect slice

## Primary entry docs

- `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- `YH_rv_cpu/doc/performance_experiment_log.md`
