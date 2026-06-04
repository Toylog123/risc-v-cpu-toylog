# Freeze: Timing-Closed CPU25 Baseline 2026-06-05

This directory freezes the first board-facing baseline that satisfies the current project gate:

- timing closed,
- `CoreMark/MHz > 4.5`,
- `LUT < 8000`.

## Frozen Metrics

| LUT | CoreMark/MHz | DMIPS/MHz | Timing | Technical optimization point |
|---:|---:|---:|---|---|
| 6791 post-route | 4.501191 | 1.205669 | WNS +0.291 ns / WHS +0.065 ns | DCache512 + RC64, frontend/JALR/fold load-use timing cuts, EX operand frontend guard, PYNQ-Z2 CPU MMCM at 25 MHz |

## Version Identity

- Branch: `codex/syncbram-h22-20260514`
- Freeze tag target: `freeze-timingclosed-cpu25-20260605`
- PYNQ-Z2 CPU clock: 25 MHz
- FPGA top generic: `USE_CLK_MMCM_25M=1`
- CPU frequency generic: `CLK_FREQ_HZ=25000000`

## Frozen Evidence

- Bitstream: `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit`
- Implementation timing: `reports/impl_timing_summary_cpu25_wns+0p291.rpt`
- Implementation utilization: `reports/impl_utilization_cpu25_6791lut.rpt`
- Synthesis timing: `reports/synth_timing_summary_cpu25_wns+6p555.rpt`
- Synthesis utilization: `reports/synth_utilization_cpu25_6940lut.rpt`
- CoreMark summary: `evidence/coremark_summary_4p501191.txt`
- Dhrystone summary: `evidence/dhrystone_summary_1p205669.txt`
- Checksums: `SHA256SUMS.txt`
- Follow-up task list: `NEXT_STEPS.md`

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
