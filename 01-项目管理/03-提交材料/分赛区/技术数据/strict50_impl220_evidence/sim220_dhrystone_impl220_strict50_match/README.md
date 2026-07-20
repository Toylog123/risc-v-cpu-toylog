# Strict50 impl220 Dhrystone xsim evidence 2026-07-02

This directory archives same-configuration Dhrystone 2.2 xsim evidence for the
frozen strict50 `impl220` engineering candidate:

`impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`

## Reportable Result

| Item | Value |
|---|---:|
| Runs | 1000 |
| Clock used for Dhrystone timer | 50 MHz |
| Dhrystones/s | 219240 |
| DMIPS | 124.780876 |
| DMIPS/MHz | 2.495618 |
| Completion cycles | 271091 |
| Measurement mode | host-parsed from xsim UART log |

Reportable line:

`DMIPS/MHz (host-parsed): 2.495618 / Dhrystones/s 219240 / runs 1000`

This is simulation evidence only. It is not board UART evidence and does not
make `impl220` board-proven.

## Formal Evidence Files

| File | Purpose |
|---|---|
| `dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt` | Parsed formal result for reporting |
| `dhrystone_impl220_strict50_noautoinc_timer50_runs1000.log` | Raw xsim UART log consumed by the parser |
| `run_strict50_dhrystone_impl220_timer50_runs1000.stdout.log` | Full wrapper stdout, including compile timer Hz and xelab generics |
| `SHA256SUMS.txt` | SHA256 hashes for evidence, runner, parser, and timer audit scripts |

## Reproduction

From the worktree root:

```powershell
cmd /c YH_rv_cpu\scripts\run_strict50_dhrystone_impl220.bat 1000 200000000 artifacts\strict_50m_timing_opt_20260609\sim220_dhrystone_impl220_strict50_match\dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt
```

Audit commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_dhrystone_timer_clock_consistency.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_strict50_dhrystone_evidence.ps1
```

Expected status:

```text
dhrystone_timer_clock_consistency=PASS
strict50_dhrystone_audit_status=PASS
```

## Configuration Notes

- The runner uses `DHRYSTONE_CLOCK_HZ=50000000L`, matching the strict50 CPU
  clock used by the implementation evidence.
- The Dhrystone target is
  `rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_mac_noautoinc_idbr`.
- `ENABLE_XTHEAD_MEMPAIR_EXTENSION=0` and
  `ENABLE_XTHEAD_BASE_UPDATE_EXTENSION=0`, so the noautoinc target is required.
- The formal evidence uses the `timer50` file names. Earlier local scratch
  files without `timer50` in the name are superseded diagnostics and must not
  be used as the reportable `impl220` DMIPS result.
