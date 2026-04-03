# Performance Experiment Log

## Frozen Baseline (2026-04-02)

Use this baseline before starting any competition-facing optimization work.

### CoreMark

| Item | Value |
|------|------|
| Command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Raw log | `build/sw/YH_rv_cpu_coremark_rv32_score.log` |
| Summary | `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt` |
| Result | `CoreMark/MHz = 0.888486` |
| Validation mode | `short_runtime_only` |

### riscv-tests

| Item | Value |
|------|------|
| RV32 baseline | `scripts\riscv_tests_rv32_baseline.txt` |
| RV32 fresh result | `33/33` |
| RV64 baseline | `scripts\riscv_tests_rv64_baseline.txt` |
| RV64 fresh result | `21/21` |

### FPGA impl50

| Item | Value |
|------|------|
| Command | `scripts\build_vivado_project.bat impl50` |
| Bitstream | `project/YH_rv_cpu_nexys_a7_100_20p000.bit` |
| Timing report | `project/reports/clk_20p000ns/impl_timing_summary.rpt` |
| Utilization report | `project/reports/clk_20p000ns/impl_utilization.rpt` |
| WNS | `+5.085ns` |
| WHS | `+0.058ns` |
| Slice LUTs | `2545` |
| Slice Registers | `2240` |
| BRAM | `4` |

## Experiment Rules

- Change only one optimization dimension at a time.
- Re-run `CoreMark score`, `riscv-tests rv32`, `riscv-tests rv64`, and `impl50` after every retained optimization.
- Do not replace this baseline with speculative or stale results.

## 2026-04-03 Retained Optimizations

### O1 - Tighten synchronous load hazard stall

| Item | Value |
|------|------|
| Change | `stall_decode` now stalls only on `load_use_hazard` |
| Files | `rtl/YH_rv_cpu_hazard_unit.v` |
| Before | `CoreMark/MHz = 0.888486` |
| After | `CoreMark/MHz = 0.912472` |
| Delta | `+0.023986` (`+2.70%`) |
| Formal command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Raw log | `build/sw/YH_rv_cpu_coremark_rv32_score.log` |
| Summary | `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt` |
| Validation | `validation_mode=short_runtime_only`, `competition_reportable=yes` |
| RV32 regression | `scripts\run_riscv_tests_subset.bat rv32` -> `33/33` |
| RV64 regression | `scripts\run_riscv_tests_subset.bat rv64` -> `21/21` |
| Keep? | `yes` |

Notes:

- The printed `Errors detected` line in this score run comes from the CoreMark
  `>=10s` runtime floor, not from CRC mismatch.
- The per-benchmark CRCs remain correct: `crclist=0xe714`,
  `crcmatrix=0x1fd7`, `crcstate=0x8e3a`.

## 2026-04-04 Formal CoreMark Validation Closure

This entry does not introduce a new retained optimization. It closes the formal
CoreMark validation gap on top of the already-retained baseline.

| Item | Value |
|------|------|
| Short command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Short result | `CoreMark/MHz = 0.912472` |
| Short completion cycles | `11014885` |
| Short validation | `competition_reportable=yes`, `strict_eembc_10s_compliant=no` |
| Strict command | `scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt` |
| Strict result | `CoreMark/MHz = 0.912465` |
| Strict completion cycles | `1095991523` |
| Strict runtime | `10.959325s` (`Total ticks = 1095932534`) |
| Strict validation | `validation_clean=yes`, `strict_eembc_10s_compliant=yes` |

Notes:

- The strict run confirms that the retained optimized baseline scales to a
  valid `>=10s` CoreMark result without changing workload semantics.
- The short run remains useful as a fast reproducible comparison path during
  future optimization work.

### O3 - FPGA path `DMEM_OUTPUT_REG: 1 -> 0`

| Item | Value |
|------|------|
| Change | Remove the extra synchronous DMEM output register on the FPGA path |
| Files | `fpga/vivado/src/YH_rv_cpu_fpga_top.v`, `tb/YH_rv_cpu_coremark_fpga_tb.v` |
| FPGA probe command | `scripts\run_coremark_fpga.bat rv32 1 400 100000000UL 20000000 build\sw\fpga_probe_dmem0.summary.txt 1` |
| FPGA probe result | `timeout` at `20,000,000` cycles |
| impl50 WNS | `+6.113ns` |
| impl50 WHS | `+0.042ns` |
| impl50 LUT / FF / BRAM | `2555 / 2170 / 4` |
| Keep? | `yes, as intermediate step to O4` |

### O4 - FPGA path `IMEM_OUTPUT_REG: 1 -> 0` on top of O3

| Item | Value |
|------|------|
| Change | Remove the extra synchronous IMEM output register on the FPGA path |
| Files | `fpga/vivado/src/YH_rv_cpu_fpga_top.v`, `tb/YH_rv_cpu_coremark_fpga_tb.v` |
| FPGA probe command | `scripts\run_coremark_fpga.bat rv32 1 400 100000000UL 20000000 build\sw\fpga_probe_i0d0.summary.txt 1` |
| FPGA probe result | `PASS`, `completion_cycles=156442`, `CoreMark/MHz=7.728811` |
| FPGA probe validation | `validation_clean=yes`, reduced workload so `competition_reportable=no` |
| impl50 WNS | `+5.822ns` |
| impl50 WHS | `+0.057ns` |
| impl50 LUT / FF / BRAM | `2555 / 2170 / 4` |
| Keep? | `yes` |

Final retained FPGA-default state:

- `IMEM_OUTPUT_REG=0`
- `DMEM_OUTPUT_REG=0`
- Bitstream target remains `project/YH_rv_cpu_nexys_a7_100_20p000.bit`

### O6 - Evaluate fetch-side prefetch during decode stall

| Item | Value |
|------|------|
| Change | Investigate whether `imem_req` / fetch queue can keep advancing when `stall_decode=1` |
| Files reviewed | `rtl/YH_rv_cpu.v`, `rtl/YH_rv_cpu_hazard_unit.v` |
| Result | `not retained` |
| Reason | Current fetch PC (`pc_r`) is frozen when `stall_decode=1`, so simply relaxing the `!stall_decode` gate would re-request the same PC instead of safely prefetching future instructions |
| Risk | A real fetch-side gain would require a deeper decoupling of fetch PC advance, IF/ID hold, and redirect/drop accounting rather than a one-line gate removal |

Notes:

- The retained `+2.70%` gain comes from O1, not from fetch-side speculation.
- Keep O6 closed unless a dedicated fetch queue refactor is planned and regression budget is available.
