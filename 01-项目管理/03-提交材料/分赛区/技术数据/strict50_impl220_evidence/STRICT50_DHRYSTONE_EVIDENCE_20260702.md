# strict50 impl220 Dhrystone evidence 2026-07-02

This document records the same-configuration Dhrystone 2.2 xsim evidence for
the frozen strict50 `impl220` engineering candidate.

## Result

| Item | Value |
|---|---:|
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Clock | 50 MHz |
| Runs | 1000 |
| Dhrystones/s | 219240 |
| DMIPS | 124.780876 |
| DMIPS/MHz | 2.495618 |
| Completion cycles | 271091 |
| Evidence level | xsim, host-parsed from UART log |

Reportable line:

`DMIPS/MHz (host-parsed): 2.495618 / Dhrystones/s 219240 / runs 1000`

This is not board evidence. Board-proven wording still requires bitstream,
PROGRAM_OK, raw board UART, video, and bitstream SHA256 evidence.

## Evidence Paths

| File | Purpose |
|---|---|
| `sim220_dhrystone_impl220_strict50_match/README.md` | Evidence directory index |
| `sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt` | Parsed formal result |
| `sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.log` | Raw xsim UART log |
| `sim220_dhrystone_impl220_strict50_match/run_strict50_dhrystone_impl220_timer50_runs1000.stdout.log` | Full wrapper stdout with compile timer Hz and xelab generics |
| `sim220_dhrystone_impl220_strict50_match/SHA256SUMS.txt` | SHA256 hashes |
| `YH_rv_cpu/scripts/run_strict50_dhrystone_impl220.bat` | Reproduction wrapper |
| `audit_dhrystone_timer_clock_consistency.ps1` | Timer macro/clock consistency audit |
| `audit_strict50_dhrystone_evidence.ps1` | Dhrystone evidence audit |

## Reproduction

```powershell
cmd /c YH_rv_cpu\scripts\run_strict50_dhrystone_impl220.bat 1000 200000000 artifacts\strict_50m_timing_opt_20260609\sim220_dhrystone_impl220_strict50_match\dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt
```

The wrapper fixes:

- `DHRYSTONE_CLOCK_HZ=50000000L`
- target `rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_mac_noautoinc_idbr`
- `ENABLE_XTHEAD_MEMPAIR_EXTENSION=0`
- `ENABLE_XTHEAD_BASE_UPDATE_EXTENSION=0`
- `ENABLE_BRANCH_BHT_ID_UPDATE=0`
- `DCACHE_EN=1`, `DCACHE_SIZE_BYTES=512`
- `REDIRECT_CACHE_ENTRIES=512`

## Audit

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_dhrystone_timer_clock_consistency.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_strict50_dhrystone_evidence.ps1
```

Observed status:

```text
dhrystone_timer_clock_consistency=PASS
strict50_dhrystone_audit_status=PASS
```

## Superseded Diagnostic Files

Some local worktrees may still contain earlier diagnostic Dhrystone files
without `timer50` in their names. Those files were produced before the build
script passed the 50 MHz timer macro into `build_dhrystone.bat`; they are
superseded scratch history only and are not part of the formal reportable
evidence set.
