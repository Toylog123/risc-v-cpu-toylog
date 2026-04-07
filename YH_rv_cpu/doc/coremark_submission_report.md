# CoreMark Submission Report

## Scope

This document freezes the CoreMark reporting path used for the competition
submission package.
Project-wide frozen baseline references were refreshed on `2026-04-07`; this
report remains the command-level authority for the CoreMark score flow.

- `scripts/run_coremark_smoke.bat` is the fast functional smoke test.
- `scripts/run_coremark_score.bat` is the reproducible submission score path.
- Host-side parsing is authoritative for `CoreMark/MHz` because the portable
  `HAS_FLOAT=0` build keeps the benchmark output integer-only.

## Frozen Commands

### Smoke

```bat
scripts\run_coremark_smoke.bat rv32
```

Expected purpose:

- verify that CoreMark can build and complete on the current RTL
- keep runtime short enough for routine regression

### Score

```bat
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
```

Expected purpose:

- run the full workload with `EXEC_MASK=0`
- capture a reproducible raw log and parsed summary
- mark whether the run is a competition-reportable short run or a strict
  EEMBC-valid `>=10s` run

## Frozen Short-Run Baseline (2026-04-03)

Raw log:

- `build/sw/YH_rv_cpu_coremark_rv32_score.log`

Parsed summary:

- `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt`

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

- The run is suitable for a reproducible competition submission report.
- The run is not a strict EEMBC-valid score because the benchmark does not run
  for 10 seconds in simulation at the frozen `10` iteration setting.

Validation note:

- In this port, CoreMark still prints `Errors detected` when the runtime is
  under 10 seconds. For the fresh frozen score above, the actual benchmark CRCs
  still match the expected `2K performance` values:
  `crclist=0xe714`, `crcmatrix=0x1fd7`, `crcstate=0x8e3a`.
- Treat the frozen score as `competition_reportable=yes` but
  `strict_eembc_10s_compliant=no`.

## Strict EEMBC-Valid Long Run (2026-04-04)

Command:

```bat
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
```

Raw log:

- `build/sw/YH_rv_cpu_coremark_rv32_strict.log`

Parsed summary:

- `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt`

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

- The project now has a fresh strict EEMBC-valid `>=10s` CoreMark run.
- The frozen short run remains useful as a fast reproducible reporting path.
- The strict long run is the authoritative answer when a strict-valid result is
  required.

## FPGA-Like Probe (2026-04-03)

Command:

```bat
scripts\run_coremark_fpga.bat rv32 1 400 100000000UL 20000000 build\sw\fpga_probe_i0d0.summary.txt 1
```

Purpose:

- exercise the near-FPGA synchronous memory configuration
- verify the retained `IMEM_OUTPUT_REG=0 / DMEM_OUTPUT_REG=0` default
- keep the workload small enough for quick turnaround during FPGA-path tuning

Result:

- `completion_cycles = 156442`
- `CoreMark/MHz (host-parsed) = 7.728811`
- `validation_clean = yes`
- `competition_reportable = no` because this is not the frozen full-workload
  score path

## Notes

- `run_coremark_smoke.bat` intentionally uses a smaller workload and keeps the
  default timer at `1000UL`.
- `run_coremark_score.bat` passes the real reporting clock (`100000000UL`) and
  relies on `report_coremark_result.py` to compute the final host-side score.
- The short run and strict run intentionally coexist:
  - short run = fast frozen comparison path
  - strict run = formal `>=10s` validation path
- `run_coremark_fpga.bat` is a separate tuning-only entry point and must not
  replace the frozen submission command above.
