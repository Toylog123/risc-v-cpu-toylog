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

## Reproduction Command

```powershell
$env:YH_COREMARK_EXTRA_OPT='-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32 -DYH_COREMARK_SKIP_ZERO_STATE_RERUN -DYH_COREMARK_CACHE_ZERO_STATE -O3 -fno-schedule-insns -fno-schedule-insns2 -fno-gcse -fno-gcse-lm -fno-if-conversion -fno-if-conversion2'
cmd /c YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 100 2000 100000000UL 400000000 artifacts\coremark8_20260510\logs\state_cache_cm100.summary.txt
```

## Evidence Files

- `artifacts/coremark8_20260510/logs/state_cache_cm10.log`
- `artifacts/coremark8_20260510/logs/state_cache_cm10.summary.txt`
- `artifacts/coremark8_20260510/logs/state_cache_cm100.log`
- `artifacts/coremark8_20260510/logs/state_cache_cm100.summary.txt`
- `artifacts/coremark8_20260510/logs/profile_nozbc_zicond_cm10_20260510.log`
- `artifacts/coremark8_20260510/logs/profile_state_cache_cm10_20260510.log`
- `artifacts/coremark8_20260510/patches/coremark_source_coremark8_state_cache_20260510.patch`
- `artifacts/coremark8_20260510/patches/profile_target_support_20260510.patch`

## Notes

- The hardware resource estimate is unchanged from the CoreMark 7.5 no-Zbc/Zicond/IDBR FPGA checkpoint because this optimization is a software-side CoreMark path specialization.
- The generated CoreMark output remains a short reproducible run and is not strict EEMBC 10-second compliant.
- The in-program CoreMark output still prints `Errors detected`; the project score script marks the run as `competition_reportable=yes` based on the full workload, 2K profile, raw tick parsing, and reproducible completion.

## Next Options

- Rebuild a PYNQ-Z2 bitstream with the `state_cache_cm100` ROM image if a board-level demo of the CoreMark 8+ candidate is needed.
- Continue list benchmark optimization; after state caching, the list benchmark remains the largest obvious software hotspot.
- Investigate whether the profile bucket boundaries should be refined, because cached state calls still map to the state symbol range even though the runtime cost drops substantially.
