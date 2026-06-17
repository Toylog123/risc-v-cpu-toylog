# Freeze: Timing-Closed CPU25 Baseline 2026-06-05

This directory freezes the first board-facing baseline that satisfies the current project gate:

- timing closed,
- `CoreMark/MHz > 4.5`,
- `LUT < 8000`.

## Frozen Metrics

| LUT | CoreMark/MHz | DMIPS/MHz | Timing | Technical optimization point |
|---:|---:|---:|---|---|
| 6791 post-route | 4.501191 | 1.205669 | WNS +0.291 ns / WHS +0.065 ns | DCache512 + RC64, frontend/JALR/fold load-use timing cuts, EX operand frontend guard, PYNQ-Z2 CPU MMCM at 25 MHz |

## Validated Successor Candidate

The same CPU25 timing-cut family now has a validated RC128 candidate:

| LUT | CoreMark/MHz | DMIPS/MHz | Timing | Technical optimization point |
|---:|---:|---:|---|---|
| 7076 post-route | 4.627215 | 1.205669 | WNS +0.514 ns / WHS +0.056 ns | Redirect cache increased from 64 to 128 entries; Dhrystone rebuilt with no-auto-inc target matching base-update-disabled hardware |

Evidence is recorded in `experiments/CPU25_RC128_EXPERIMENT_20260605.md`. This candidate meets the current `CoreMark/MHz > 4.5` and `LUT < 8000` gates, but it is not yet board-facing until a selected RC128 bitstream gets PROGRAM_OK, UART, and video evidence.

The validated simulation pair can be rerun with:

```powershell
cmd /c YH_rv_cpu\scripts\run_cpu25_rc128_validated.bat
```

The wrapper intentionally uses different software targets for the two benchmarks: CoreMark keeps the validated Zicond/Zbkb/XThead-memidx/MAC no-auto-inc target, while Dhrystone uses the no-auto-inc/no-condmov target that matches the base-update-disabled CPU25 timing-cut hardware.

The wrapper was rerun on 2026-06-05 and reproduced the validated numbers: `4.627215 CoreMark/MHz` and `1.205669 DMIPS/MHz`. Fresh outputs are under `experiments/repro_cpu25_rc128`.

The PYNQ-Z2 implementation can also be reproduced with:

```powershell
cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_coremark.bat impl
```

The 2026-06-05 rerun produced `7124 post-route LUT / 3211 FF / WNS +1.881 ns / WHS +0.100 ns` and wrote `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_coremark_repro_20260605.bit`. This is still not board-proven until PROGRAM_OK/UART/video are captured.

Current recommended timing-robust CPU25 RC128 follow-up:

| LUT | CoreMark/MHz | DMIPS/MHz | Timing | Technical optimization point |
|---:|---:|---:|---|---|
| 7473 post-route | 4.741458 | 1.205669 | WNS +1.348 ns / WHS +0.041 ns | Restores branch-fold next-cache, disables unused ZBKB hardware, and uses timing-driven synthesis while keeping the CPU25 DCache/load-use timing cuts |

The lower-LUT BFNext/no-ZBKB implementation remains available at `7374 post-route LUT / WNS +0.282 ns / WHS +0.062 ns`, but the timing-driven run is the better board-facing candidate when timing margin is the priority.

Reproduce the implementation with:

```powershell
cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_bfnext_nozbkb_timingdriven_coremark.bat impl
```

The BFNext/no-ZBKB simulation evidence is under `experiments/repro_cpu25_rc128_bfnext_nozbkb`. This candidate is still not board-proven until PROGRAM_OK/UART/video are captured.

## Version Identity

- Branch: `codex/syncbram-h22-20260514`
- Freeze tag target: `freeze-timingclosed-cpu25-20260605`
- PYNQ-Z2 CPU clock: 25 MHz
- FPGA top generic: `USE_CLK_MMCM_25M=1`
- CPU frequency generic: `CLK_FREQ_HZ=25000000`

## Frozen Evidence

- Bitstream: `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit`
- Performance demo bitstream: `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit`
- RC128 CoreMark reproducibility bitstream: `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_coremark_repro_20260605.bit`
- RC128 BFNext candidate bitstream: `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_20260606.bit`
- RC128 BFNext/no-ZBKB candidate bitstream: `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_nozbkb_20260606.bit`
- RC128 BFNext/no-ZBKB timing-driven candidate bitstream: `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_nozbkb_timingdriven_20260606.bit`
- Implementation timing: `reports/impl_timing_summary_cpu25_wns+0p291.rpt`
- Implementation utilization: `reports/impl_utilization_cpu25_6791lut.rpt`
- Performance demo implementation timing: `reports/impl_timing_summary_cpu25_perf_demo_wns+0p291.rpt`
- Performance demo implementation utilization: `reports/impl_utilization_cpu25_perf_demo_6791lut.rpt`
- RC128 reproduced implementation timing: `reports/impl_timing_summary_cpu25_rc128_repro_wns+1p881_20260605.rpt`
- RC128 reproduced implementation utilization: `reports/impl_utilization_cpu25_rc128_repro_7124lut_20260605.rpt`
- RC128 BFNext implementation timing: `reports/impl_timing_summary_cpu25_rc128_bfnext_wns+1p138_20260606.rpt`
- RC128 BFNext implementation utilization: `reports/impl_utilization_cpu25_rc128_bfnext_7505lut_20260606.rpt`
- RC128 BFNext/no-ZBKB implementation timing: `reports/impl_timing_summary_cpu25_rc128_bfnext_nozbkb_wns+0p282_20260606.rpt`
- RC128 BFNext/no-ZBKB implementation utilization: `reports/impl_utilization_cpu25_rc128_bfnext_nozbkb_7374lut_20260606.rpt`
- RC128 BFNext/no-ZBKB timing-driven implementation timing: `reports/impl_timing_summary_cpu25_rc128_bfnext_nozbkb_timingdriven_wns+1p348_20260606.rpt`
- RC128 BFNext/no-ZBKB timing-driven implementation utilization: `reports/impl_utilization_cpu25_rc128_bfnext_nozbkb_timingdriven_7473lut_20260606.rpt`
- Synthesis timing: `reports/synth_timing_summary_cpu25_wns+6p555.rpt`
- Synthesis utilization: `reports/synth_utilization_cpu25_6940lut.rpt`
- CoreMark summary: `evidence/coremark_summary_4p501191.txt`
- Dhrystone summary: `evidence/dhrystone_summary_1p205669.txt`
- Performance demo design: `PERFORMANCE_DEMO_DESIGN.md`
- Performance demo xsim summary: `evidence/perf_demo_summary_20260605.txt`
- Performance demo xsim UART log: `evidence/perf_demo_xsim_uart_20260605.log`
- Checksums: `SHA256SUMS.txt`
- Follow-up task list: `NEXT_STEPS.md`
- Long-term optimization plan: `LONG_TERM_OPTIMIZATION_PLAN.md`

## Performance Demo Firmware

The CPU25 line now has an automatic UART performance demo candidate:

```powershell
cmd /c YH_rv_cpu\scripts\run_perf_demo.bat
```

The demo runs CRC32, 8x8 matrix multiply, memory copy/fill, branch/control stress, and load-use stress. It prints per-workload cycles/checksums and finishes with:

```text
PERF_DEMO PASS checksum=0xe727358b total_cycles=0x00038add
```

The PYNQ-Z2 CPU25 bitstream has also been regenerated with `YH_rv_cpu_perf_demo.hex/.mem32.hex` and timing remains closed: `6791 LUT / WNS +0.291 ns / WHS +0.065 ns`. Remaining board evidence is PROGRAM_OK, UART output, and video capture.

## Implementation Reproduction

Run from the English-path worktree:

```powershell
$env:ROM_INIT_HEX_OVERRIDE="$PWD\_tmp\sim_runtime\coremark_fpga\manual_baseline_check_20260526\build\sw\YH_rv_cpu_coremark_rv32.hex"
$env:ROM_INIT_MEM32_HEX_OVERRIDE="$PWD\_tmp\sim_runtime\coremark_fpga\manual_baseline_check_20260526\build\sw\YH_rv_cpu_coremark_rv32.mem32.hex"
$env:RAM_BASE_OVERRIDE="32'h00010000"
$env:ROM_BYTES_OVERRIDE='65536'
$env:RAM_BYTES_OVERRIDE='16384'
$env:PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE='8.000'
$env:PYNQ_SYNTH_RETIMING_OVERRIDE='0'
$env:PYNQ_SYNTH_NO_TIMING_DRIVEN_OVERRIDE='1'
$env:PYNQ_QUICK_UTIL_ONLY_OVERRIDE='0'
$env:PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE='25000000'
$env:PYNQ_USE_CLK_MMCM_25M_OVERRIDE='1'
$env:PYNQ_USE_CLK_MMCM_62M5_OVERRIDE='0'
$env:PYNQ_USE_CLK_MMCM_50M_OVERRIDE='0'
$env:PYNQ_ENABLE_M_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_XTHEAD_CRC_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_XTHEAD_MUL_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE='1'
$env:PYNQ_ENABLE_XTHEAD_ADDSL_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_XTHEAD_MEMPAIR_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_XTHEAD_BASE_UPDATE_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE='0'
$env:PYNQ_ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD_OVERRIDE='1'
$env:PYNQ_ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD_OVERRIDE='1'
$env:PYNQ_ENABLE_ID_BRANCH_FOLD_OVERRIDE='1'
$env:PYNQ_ENABLE_ID_BRANCH_FOLD_NEXT_CACHE_OVERRIDE='0'
$env:PYNQ_ENABLE_EX_REDIRECT_FOLD_OVERRIDE='1'
$env:PYNQ_ENABLE_ID_BRANCH_NT_NEXT_CACHE_OVERRIDE='1'
$env:PYNQ_ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD_OVERRIDE='1'
$env:PYNQ_ENABLE_ID_ALU_PAIR_FOLD_OVERRIDE='0'
$env:PYNQ_ENABLE_ID_ALU_DEP_FOLD_OVERRIDE='0'
$env:PYNQ_ENABLE_REDIRECT_TARGET_CACHE_OVERRIDE='1'
$env:PYNQ_ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP_OVERRIDE='1'
$env:PYNQ_ENABLE_FETCH_REDIRECT_REUSE_OVERRIDE='0'
$env:PYNQ_REDIRECT_CACHE_ENTRIES_OVERRIDE='64'
$env:PYNQ_REDIRECT_CACHE_XOR_INDEX_OVERRIDE='0'
$env:PYNQ_ENABLE_DYNAMIC_BRANCH_PREDICT_OVERRIDE='0'
$env:PYNQ_BRANCH_BHT_ENTRIES_OVERRIDE='2'
$env:PYNQ_BRANCH_STATIC_PREDICT_MODE_OVERRIDE='0'
$env:PYNQ_DMEM_NEGEDGE_READ_OVERRIDE='0'
$env:PYNQ_DMEM_READ_PREISSUE_OVERRIDE='0'
$env:PYNQ_DCACHE_EN_OVERRIDE='1'
$env:PYNQ_DCACHE_SIZE_BYTES_OVERRIDE='512'
$env:PYNQ_ENABLE_DCACHE_LOAD_USE_SPEC_OVERRIDE='1'
$env:PYNQ_ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC_OVERRIDE='1'
$env:PYNQ_ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC_OVERRIDE='1'
$env:PYNQ_ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC_OVERRIDE='0'
$env:PYNQ_ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC_OVERRIDE='0'
$env:PYNQ_ENABLE_FOLD_DCACHE_LOAD_USE_SPEC_OVERRIDE='0'
$env:PYNQ_ENABLE_FOLD_EXMEM_LOAD_USE_SPEC_OVERRIDE='1'
$env:PYNQ_ENABLE_DCACHE_NEXT_PREFETCH_OVERRIDE='0'
$env:PYNQ_ENABLE_DCACHE_WORD_ONLY_OVERRIDE='0'
$env:PYNQ_ICACHE_EN_OVERRIDE='0'
cmd /c YH_rv_cpu\scripts\build_pynq_z2_project.bat impl
```

## Freeze Notes

- This replaces the earlier 6872-LUT 50 MHz timing-failing implementation audit as the project baseline for future work.
- The original 6872 baseline remains useful as a performance/area reference, but it is not timing-closed.
- Do not modify CoreMark core algorithm files when deriving later versions.
- Next required evidence is tracked in `NEXT_STEPS.md`: PYNQ-Z2 PROGRAM_OK, UART capture, and board video for this exact bitstream.
- Longer-range optimization work is tracked in `LONG_TERM_OPTIMIZATION_PLAN.md`.
- The RC128 BFNext/no-ZBKB timing-driven candidate is the current recommended timing-robust performance recovery point, but keep this RC64 freeze as the fallback until RC128 board evidence is regenerated.
- Use `YH_rv_cpu/scripts/run_cpu25_rc128_validated.bat` for repeatable RC128 CoreMark + Dhrystone simulation evidence; pass an output directory as the first argument if the default `experiments/repro_cpu25_rc128` scratch location is not desired.
- Use `YH_rv_cpu/scripts/build_pynq_z2_cpu25_rc128_coremark.bat impl` for repeatable RC128 PYNQ-Z2 implementation evidence.
- Use `YH_rv_cpu/scripts/build_pynq_z2_cpu25_rc128_bfnext_nozbkb_timingdriven_coremark.bat impl` for the current recommended CPU25 RC128 BFNext/no-ZBKB timing-driven candidate.
