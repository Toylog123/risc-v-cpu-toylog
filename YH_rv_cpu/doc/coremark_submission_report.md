# CoreMark Submission Report

## Scope

This document freezes the CoreMark reporting path used for the competition
submission package.

Two layers must be distinguished:

- frozen command-level baseline: the current competition-facing score flow
- active worktree validation: newer non-CoreMark tasks that do not change the
  frozen CoreMark numbers unless a fresh rerun is completed

As of `2026-04-08`, the CoreMark path itself is unchanged. Current active work
is focused on expanded `riscv-tests` coverage and documentation closure.

## Frozen Commands

### Smoke

```bat
scripts\run_coremark_smoke.bat rv32
```

Purpose:

- verify that CoreMark can build and complete on the current RTL
- keep runtime short enough for routine regression

### Short Score

```bat
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
```

Purpose:

- run the full workload with `EXEC_MASK=0`
- capture a reproducible raw log and parsed summary
- maintain the fast comparison path used during routine optimization work

### Strict `>=10s` Score

```bat
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
```

Purpose:

- produce the strict EEMBC-valid `>=10s` answer
- confirm that the retained baseline scales without changing workload semantics

## Frozen Short-Run Baseline

Project-wide references were refreshed on `2026-04-07`. The underlying short
run evidence remains:

- raw log: `build/sw/YH_rv_cpu_coremark_rv32_score.log`
- parsed summary: `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt`

Current result:

- `CoreMark Size = 666`
- `Total ticks = 10959245`
- `Iterations = 10`
- `Completion cycles = 11014885`
- `CoreMark/MHz (host-parsed) = 0.912472`
- `validation_mode = short_runtime_only`
- `competition_reportable = yes`
- `strict_eembc_10s_compliant = no`
- `compiler_version = GCC 15.2.0`
- `compiler_flags = -O2 -march=rv32i_zicsr -mabi=ilp32`
- `memory_location = SoC ROM/RAM`

Interpretation:

- this is the frozen fast comparison path
- it is suitable for competition-package reporting as the short path
- it is not the strict EEMBC-valid answer by itself

Validation note:

- In this port, CoreMark still prints `Errors detected` when runtime is under
  10 seconds. That line reflects the EEMBC runtime floor, not a CRC mismatch.
- The benchmark CRCs still match the expected `2K performance` values:
  `crclist=0xe714`, `crcmatrix=0x1fd7`, `crcstate=0x8e3a`.

## Strict EEMBC-Valid Long Run

The current authoritative strict evidence is:

- raw log: `build/sw/YH_rv_cpu_coremark_rv32_strict.log`
- parsed summary: `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt`

Current result:

- `CoreMark Size = 666`
- `Total ticks = 1095932534`
- `Total seconds = 10.959325`
- `Iterations = 1000`
- `Completion cycles = 1095991523`
- `CoreMark/MHz (host-parsed) = 0.912465`
- `validation_clean = yes`
- `validation_mode = eembc_validated`
- `competition_reportable = yes`
- `strict_eembc_10s_compliant = yes`
- `compiler_version = GCC 15.2.0`
- `compiler_flags = -O2 -march=rv32i_zicsr -mabi=ilp32`
- `memory_location = SoC ROM/RAM`

Interpretation:

- this is the authoritative strict-valid answer
- the short path remains useful for rapid comparison
- the strict path is the one to quote when a formal `>=10s` result is required

## FPGA-Like Probe

Command:

```bat
scripts\run_coremark_fpga.bat rv32 1 400 100000000UL 20000000 build\sw\fpga_probe_i0d0.summary.txt 1
```

Purpose:

- exercise the near-FPGA synchronous memory configuration
- verify the retained `IMEM_OUTPUT_REG=0 / DMEM_OUTPUT_REG=0` default
- keep the workload small enough for fast FPGA-path tuning

Result:

- `completion_cycles = 156442`
- `CoreMark/MHz (host-parsed) = 7.728811`
- `validation_clean = yes`
- `competition_reportable = no`

## 2026-04-08 Status Note

Fresh CoreMark reruns in this worktree now include:

- smoke rerun complete: `620530 cycles`
- short rerun complete: `0.912472 CoreMark/MHz`, `11014885 cycles`
- dated short summary: `build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt`
- strict rerun complete: `0.912465 CoreMark/MHz`, `1095991523 cycles`, `10.959325s`
- dated strict log: `build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.log`
- dated strict summary: `build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt`

Current active work also includes:

- expanded `riscv-tests` validation beyond the frozen baseline subsets
- documentation synchronization to the current true repo state
- closure of the `fence_i` ISA/march ambiguity in the general `rv32ui` matrix

Important boundary:

- no `fence` / `fence.i` opcode appears in the fresh short-run dump, so the
  current `fence_i` decode legalization is not part of the observed CoreMark
  hot path
- the fresh strict rerun completed on `2026-04-08` and matches the frozen
  strict-valid baseline numerically
- `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt` remains the frozen
  canonical strict reference, while the dated `2026-04-08` files provide fresh
  worktree-local evidence

## Notes

- `run_coremark_smoke.bat` intentionally uses a smaller workload and a lighter
  runtime budget.
- `run_coremark_score.bat` passes the real reporting clock (`100000000UL`) and
  relies on `report_coremark_result.py` to compute the final host-side score.
- The short run and strict run intentionally coexist:
  - short run = fast frozen comparison path
  - strict run = formal `>=10s` validation path
- `run_coremark_fpga.bat` is a separate tuning-only entry point and must not
  replace the frozen submission command above.
