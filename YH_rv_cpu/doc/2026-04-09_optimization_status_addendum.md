# 2026-04-09 Optimization Status Addendum

## What changed

- The `2026-04-09` split redirect profile confirmed that CoreMark redirect
  cost is branch-dominant.
- A follow-up `decode-stage early JAL redirect` trial was attempted as a
  narrow control-flow experiment.
- That trial failed the minimal `rv32 jal` guardrail and was rejected.

## Evidence

- Split profile log:
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-09.log`
- Rejected trial debug evidence:
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/jal_early_redirect_debug_2026-04-09.log`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_jal_early_redirect_debug_2026-04-09.txt`
- Restored-baseline guardrail:
  - `scripts\run_riscv_tests_subset.bat rv32 jal - 120000` -> `PASS`

## Current recommendation

- Do not reopen this jal-only shortcut.
- If optimization continues, start from branch-dominant redirect profiling and
  keep the work single-variable and fully documented.
