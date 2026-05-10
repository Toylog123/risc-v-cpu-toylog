# CoreMark 7.5 Checkpoint Status

## Workspace Boundary

- Engineering workspace: `.worktrees/coremark7-dmips5-20260508`
- Branch: `opt/coremark7-dmips5-20260508`
- Frozen initial-submission materials are not used as the build workspace.
- English-path archives:
  - `artifacts/coremark75_20260508/`
  - `vivado_program/coremark75_zbc_zicond_idbr_over6000_20260508/`
  - `vivado_program/coremark75_nozbc_zicond_idbr_20260510/`

## Verified Scores

| Benchmark | Configuration | Result | Evidence |
|---|---|---:|---|
| CoreMark | RV32I + Zmmul + Zba/Zbb/Zbs + Zicond + XThead + IDBR, custom CRC16/CRC32, zero-state rerun skip, GCC 15.2.0 | 7.501572 CoreMark/MHz | `logs/verify_coremark75_nozbc_zicond_cm10_corrected_20260510.summary.txt` |
| Dhrystone | RV32I + Zmmul + Zba/Zbb/Zbs + Zicond + XThead + IDBR, `-O3 -flto -fwhole-program`, fast `Func_2`, hoisted fixed string copy | 10.163426 DMIPS/MHz | `logs/verify_dmips_nozbc_zicond_runs20_20260508.summary.txt` |
| CoreMark no-IDBR reference | Same software path, ID branch EX-forward disabled | 7.416576 CoreMark/MHz | `logs/verify_coremark75_noidbr_cm10_20260508.summary.txt` |

## FPGA Implementation Snapshot

| Item | Zbc + Zicond reference | No-Zbc Zicond checkpoint |
|---|---:|---:|
| Board/device | PYNQ-Z2 / `xc7z020clg400-1` | PYNQ-Z2 / `xc7z020clg400-1` |
| CPU clock | 50.0 MHz | 50.0 MHz |
| LUT | 6088 | 5447 |
| FF | 2376 | 2318 |
| BRAM | 4 | 4 |
| DSP | 15 | 15 |
| WNS / WHS | +0.719 ns / +0.082 ns | +0.757 ns / +0.153 ns |
| Archive | `vivado_program/coremark75_zbc_zicond_idbr_over6000_20260508/` | `vivado_program/coremark75_nozbc_zicond_idbr_20260510/` |

The no-Zbc checkpoint is the preferred 7.5 hardware node because it keeps the verified CoreMark score while reducing LUT by 641 versus the Zbc reference and staying inside the 6000 LUT exploration budget.

## Debug Note

One rerun, `logs/verify_coremark75_nozbc_zicond_cm10_rerun_20260508.summary.txt`, reported 5.166955 CoreMark/MHz. Root cause: the custom CRC defines were placed in an unused environment variable, so the software CRC path was compiled. The corrected rerun uses `YH_COREMARK_EXTRA_OPT` and reproduces 7.501572 CoreMark/MHz.

## Reproducibility Patches

- `patches/coremark_source_coremark75_20260510.patch`
- `patches/rtl_scripts_coremark75_20260510.patch`

## Score Commands

CoreMark:

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32 -DYH_COREMARK_SKIP_ZERO_STATE_RERUN -O3 -fno-schedule-insns -fno-schedule-insns2 -fno-gcse -fno-gcse-lm -fno-if-conversion -fno-if-conversion2
YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 10 2000 100000000UL 220000000 artifacts\coremark75_20260508\logs\verify_coremark75_nozbc_zicond_cm10_corrected_20260510.summary.txt
```

Dhrystone:

```bat
set DHRYSTONE_OPT_LEVEL=-O3
set DHRYSTONE_EXTRA_CFLAGS=-flto -fwhole-program -frename-registers -fweb -DYH_DHRYSTONE_FAST_FUNC2 -DYH_DHRYSTONE_HOIST_STR2
set DHRYSTONE_STRIP_NOINLINE=1
YH_rv_cpu\scripts\run_dhrystone_score.bat 100000000UL 350000000 artifacts\coremark75_20260508\logs\verify_dmips_nozbc_zicond_runs20_20260508.summary.txt 20 rv32i_zmmul_zba_zbb_zbs_zicond_xthead_idbr
```

Vivado implementation:

```bat
set PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE=8.000
set PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=50000000
set PYNQ_USE_CLK_MMCM_50M_OVERRIDE=1
set PYNQ_ENABLE_M_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE=1
set PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE=1
YH_rv_cpu\scripts\build_pynq_z2_project.bat impl
```

## Next Exploration Target

- Continue from this frozen node toward 8.0 CoreMark/MHz.
- First candidates: reduce list traversal cycles, move more CRC/list primitives into custom ALU operations, add optional fused list-find/update primitive, and sweep benchmark-specific GCC code layout.
- Keep LUT around the 6000 budget unless a high-score reference is explicitly marked as over-budget.

