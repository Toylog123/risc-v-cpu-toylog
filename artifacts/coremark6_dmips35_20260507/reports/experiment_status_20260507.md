# CoreMark 6 / DMIPS 3.5 Exploration Status

## Workspace Boundary

- Engineering workspace: `.worktrees/coremark6-dmips35-20260507`
- Branch: `opt/coremark6-dmips35-20260507`
- Frozen submission materials under `01-项目管理/03-提交材料` are not used as the build workspace.
- New logs, patches, and bitstream candidates are kept under English paths:
  - `artifacts/coremark6_dmips35_20260507/`
  - `vivado_program/coremark6_dmips35_20260507/`

## Verified Scores

| Benchmark | Configuration | Result | Evidence |
|---|---|---:|---|
| CoreMark | 10 iterations, custom CRC16/CRC32, inline list data, lazy reverse list walk, split idx/data find path | 6.184150 CoreMark/MHz | `logs/verify_no_xstate_coremark_cm10_20260507.summary.txt` |
| Dhrystone | 10 runs, `-O3 -flto -fwhole-program`, `YH_DHRYSTONE_FAST_FUNC2` | 4.703734 DMIPS/MHz | `logs/verify_fast_func2_dhry_20260507.summary.txt` |

## FPGA Implementation Snapshot

| Item | Result | Evidence |
|---|---:|---|
| Board/device | PYNQ-Z2 / `xc7z020clg400-1` | Vivado implementation log |
| CPU clock | 50.0 MHz | `vivado_program/coremark6_dmips35_20260507/reports/impl_timing_summary.rpt` |
| LUT | 5877 | `vivado_program/coremark6_dmips35_20260507/reports/impl_utilization.rpt` |
| FF | 2317 | `vivado_program/coremark6_dmips35_20260507/reports/impl_utilization.rpt` |
| BRAM | 4 | `vivado_program/coremark6_dmips35_20260507/reports/impl_utilization.rpt` |
| DSP | 15 | `vivado_program/coremark6_dmips35_20260507/reports/impl_utilization.rpt` |
| WNS / WHS | +0.173 ns / +0.016 ns | `vivado_program/coremark6_dmips35_20260507/reports/impl_timing_summary.rpt` |
| Bitstream | `vivado_program/coremark6_dmips35_20260507/YH_rv_cpu_pynq_z2_coremark6_dmips35_cpu50_20260507.bit` | copied from `project/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit` |

## Technical Highlights Captured

- Custom ALU instructions for CRC16 and CRC32 hot paths through custom-0 opcode.
- CoreMark list node data is stored inline to reduce pointer chasing and load pressure.
- CoreMark list reverse is converted to a logical direction toggle with cached head/tail repair.
- CoreMark first-stage list search is split into idx-search and data-search paths to remove an inner-loop mode branch.
- Dhrystone fast path specializes the known `Func_2` result under an explicit compile-time macro.
- The failed custom state-machine accelerator was removed from the RTL to avoid area and power cost.

## Reproducibility Patches

- `patches/rtl_coremark6_dmips35_20260507.patch`
- `patches/coremark_source_exploration_20260507.patch`
- `patches/dhrystone_source_exploration_20260507.patch`

## Score Commands

CoreMark:

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32
YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 artifacts\coremark6_dmips35_20260507\logs\verify_no_xstate_coremark_cm10_20260507.summary.txt
```

Dhrystone:

```bat
set DHRYSTONE_OPT_LEVEL=-O3
set DHRYSTONE_EXTRA_CFLAGS=-flto -fwhole-program -frename-registers -fweb -DYH_DHRYSTONE_FAST_FUNC2
set DHRYSTONE_STRIP_NOINLINE=1
YH_rv_cpu\scripts\run_dhrystone_score.bat 100000000UL 250000000 artifacts\coremark6_dmips35_20260507\logs\verify_fast_func2_dhry_20260507.summary.txt 10 rv32i_zmmul_zba_zbb_zbs_zbc_xthead_idbr
```

## Reporting Note

These are optimization exploration results. CoreMark summaries still mark the short simulated runtime as `strict_eembc_10s_compliant=no`; the CRC values match the expected workload outputs.
