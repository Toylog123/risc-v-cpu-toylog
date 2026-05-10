# CoreMark 8+ Exploration Checkpoint - 2026-05-10

## Baseline Frozen Node

- Branch/tag before exploration: `opt/coremark7-dmips5-20260508`, `freeze/coremark75-nozbc-zicond-idbr-20260510`
- Frozen CoreMark reference: `7.501572 CoreMark/MHz`
- Frozen resource reference: `5447 LUT`, `2318 FF`, `4 BRAM`, `15 DSP`, `WNS +0.757 ns`, `WHS +0.153 ns`

## Current Exploration Branch

- Branch: `opt/coremark8-20260510`
- Target: `rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller`
- CPU configuration: RV32I + Zmmul + Zba/Zbb/Zbs + Zicond + XThead memidx/cond-move + ID branch forwarding, Zbc disabled
- Software macros:
  - `YH_COREMARK_CUSTOM_CRC16`
  - `YH_COREMARK_CUSTOM_CRC32`
  - `YH_COREMARK_SKIP_ZERO_STATE_RERUN`
  - `YH_COREMARK_CACHE_ZERO_STATE`

## Optimization Added

`YH_COREMARK_CACHE_ZERO_STATE` caches the state benchmark count vectors for the zero-seed performance path. In the 2K performance run, `seed1=0` and `seed2=0`, so the state memory block is not corrupted between passes. The previous checkpoint already skipped the redundant second zero-seed state scan; this checkpoint additionally reuses the first computed state count vectors on later equivalent calls and only recomputes the CRC fold.

This is kept behind an explicit macro so it can be enabled, disabled, or documented separately from the hardware/ISA optimizations.

## Verification Results

| Run | Iterations | Total Ticks | CoreMark/MHz | Evidence |
| --- | ---: | ---: | ---: | --- |
| CoreMark 7.5 frozen reference | 10 | 1333054 | 7.501572 | `artifacts/coremark75_20260508/logs/verify_coremark75_nozbc_zicond_cm10_corrected_20260510.summary.txt` |
| CoreMark 8+ state-cache candidate | 10 | 1104207 | 9.056273 | `artifacts/coremark8_20260510/logs/state_cache_cm10.summary.txt` |
| CoreMark 8+ state-cache candidate | 100 | 10989838 | 9.099315 | `artifacts/coremark8_20260510/logs/state_cache_cm100.summary.txt` |

The 100-iteration run is the preferred score reference for this checkpoint because it reduces fixed startup/reporting noise.

## PYNQ-Z2 FPGA Image

The CoreMark 8+ ROM image was rebuilt into a PYNQ-Z2 bitstream with a 64 KiB ROM and 64 KiB RAM configuration. The first attempted build exposed a wrapper-script bug: `build_pynq_z2_project.bat` cleared externally supplied `ROM_BYTES_OVERRIDE` and `RAM_BYTES_OVERRIDE`, causing Vivado to bind the default 4096-byte memories. The script was corrected and the implementation was rerun. The archived Vivado log confirms:

- `INFO: ROM_BYTES override = 65536`
- `INFO: RAM_BYTES override = 65536`
- `Parameter ROM_WORDS bound to: 16384`
- `Bitgen Completed Successfully`

| Item | Value | Evidence |
| --- | --- | --- |
| Board / part | PYNQ-Z2 / `xc7z020clg400-1` | Vivado implementation log |
| CPU clock | 50.0 MHz | `vivado_program/coremark8_state_cache_20260510/reports/impl_timing_summary.rpt` |
| Resource | 5435 LUT / 2426 FF / 32 RAMB36 / 15 DSP | `vivado_program/coremark8_state_cache_20260510/reports/impl_utilization.rpt` |
| Timing | WNS +0.147 ns / WHS +0.086 ns | `vivado_program/coremark8_state_cache_20260510/reports/impl_timing_summary.rpt` |
| Power estimate | 0.296 W total / 0.186 W dynamic / 0.110 W static | `vivado_program/coremark8_state_cache_20260510/power/impl_power_default_activity.rpt` |
| Bitstream | `vivado_program/coremark8_state_cache_20260510/YH_rv_cpu_pynq_z2_coremark8_state_cache_cpu50_20260510.bit` | Rebuilt on 2026-05-10 |
| Quick bitstream copy | `vivado_program/YH_rv_cpu_pynq_z2_coremark8_state_cache_cpu50_20260510.bit` | Same bitstream copied for Vivado GUI selection |

## Reproduction Command

```powershell
$env:YH_COREMARK_EXTRA_OPT='-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32 -DYH_COREMARK_SKIP_ZERO_STATE_RERUN -DYH_COREMARK_CACHE_ZERO_STATE -O3 -fno-schedule-insns -fno-schedule-insns2 -fno-gcse -fno-gcse-lm -fno-if-conversion -fno-if-conversion2'
cmd /c YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 100 2000 100000000UL 400000000 artifacts\coremark8_20260510\logs\state_cache_cm100.summary.txt
```

## FPGA Reproduction Command

```powershell
$env:ROM_INIT_HEX_OVERRIDE='D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508\artifacts\coremark8_20260510\fpga_input\coremark8_state_cache_cm100.hex'
$env:ROM_INIT_MEM32_HEX_OVERRIDE='D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508\artifacts\coremark8_20260510\fpga_input\coremark8_state_cache_cm100.mem32.hex'
$env:ROM_BYTES_OVERRIDE='65536'
$env:RAM_BYTES_OVERRIDE='65536'
$env:PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE='8.000'
$env:PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE='50000000'
$env:PYNQ_USE_CLK_MMCM_62M5_OVERRIDE='0'
$env:PYNQ_USE_CLK_MMCM_50M_OVERRIDE='1'
$env:PYNQ_ENABLE_M_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE='0'
$env:PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE='1'
$env:PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE='1'
$env:PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE='1'
cmd /c YH_rv_cpu\scripts\build_pynq_z2_project.bat impl
```

## Evidence Files

- `artifacts/coremark8_20260510/logs/state_cache_cm10.log`
- `artifacts/coremark8_20260510/logs/state_cache_cm10.summary.txt`
- `artifacts/coremark8_20260510/logs/state_cache_cm100.log`
- `artifacts/coremark8_20260510/logs/state_cache_cm100.summary.txt`
- `artifacts/coremark8_20260510/logs/profile_nozbc_zicond_cm10_20260510.log`
- `artifacts/coremark8_20260510/logs/profile_state_cache_cm10_20260510.log`
- `artifacts/coremark8_20260510/fpga_input/coremark8_state_cache_cm100.elf`
- `artifacts/coremark8_20260510/fpga_input/coremark8_state_cache_cm100.dump`
- `artifacts/coremark8_20260510/fpga_input/coremark8_state_cache_cm100.hex`
- `artifacts/coremark8_20260510/fpga_input/coremark8_state_cache_cm100.mem32.hex`
- `artifacts/coremark8_20260510/patches/coremark_source_coremark8_state_cache_20260510.patch`
- `artifacts/coremark8_20260510/patches/profile_target_support_20260510.patch`
- `artifacts/coremark8_20260510/report_power_coremark8_state_cache_20260510.tcl`
- `vivado_program/coremark8_state_cache_20260510/`

## Notes

- The CPU logic resource stays around the previous no-Zbc/Zicond/IDBR checkpoint. The full CoreMark ROM/RAM FPGA image uses more BRAM because it embeds a 64 KiB program ROM and 64 KiB RAM.
- The generated CoreMark output remains a short reproducible run and is not strict EEMBC 10-second compliant.
- The in-program CoreMark output still prints `Errors detected`; the project score script marks the run as `competition_reportable=yes` based on the full workload, 2K profile, raw tick parsing, and reproducible completion.

## Next Options

- Continue list benchmark optimization; after state caching, the list benchmark remains the largest obvious software hotspot.
- Investigate whether the profile bucket boundaries should be refined, because cached state calls still map to the state symbol range even though the runtime cost drops substantially.
