# Strict 50 MHz CoreMark Freeze Audit

Date: 2026-06-08

This package records a fresh audit of the candidate that was being considered
for a strict 50 MHz freeze. The audit uses the CoreMark firmware image for the
PYNQ-Z2 implementation run instead of relying on the earlier demo-ROM timing
closure result.

## Decision

Do not freeze this version as the region-contest baseline.

The CoreMark short-run performance is still above the target, but the exact
50 MHz CoreMark-ROM implementation does not close timing.

| Gate | Result | Status |
| --- | --- | --- |
| CPU clock | 50 MHz | pass |
| CoreMark/MHz | 5.162186 | pass for engineering short-run |
| CoreMark core source files | external repo clean | pass |
| Strict EEMBC 10-second runtime | no | fail / board-long-run pending |
| PYNQ-Z2 post-route timing | WNS -5.800 ns / WHS +0.061 ns | fail |
| Freeze as main baseline | rejected | fail |

## CoreMark Simulation Recheck

Command run from:

`D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark5-dmips3-20260506`

```bat
YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 YH_rv_cpu\build\sw\coremark_freeze_candidate_50m_strictsync_20260608.summary.txt
```

Summary:

| Item | Value |
| --- | --- |
| CoreMark/MHz | 5.162186 |
| Iterations | 10 |
| Total ticks | 1937164 |
| Completion cycles | 1971888 |
| validation_clean | no |
| validation_mode | short_runtime_only |
| strict_eembc_10s_compliant | no |

The `validation_clean=no` result is caused by the runtime-floor failure. This
summary is valid as a reproducible short engineering run, but must not be
presented as a strict 10-second EEMBC CoreMark result.

## CoreMark-ROM Implementation Recheck

Command run from:

`D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508`

```bat
cmd /c YH_rv_cpu\scripts\build_pynq_z2_coremark5_dmips3_50m_coremark.bat impl
```

Implementation result:

| Metric | Result |
| --- | --- |
| Post-route LUT | 11182 |
| LUT as Logic | 8878 |
| LUT as Memory | 2304 |
| FF | 3439 |
| BRAM | 20 RAMB36E1 |
| DSP | 8 |
| WNS | -5.800 ns |
| TNS | -18015.188 ns |
| Setup failing endpoints | 3967 |
| WHS | +0.061 ns |

Worst setup path:

| Item | Value |
| --- | --- |
| Source | `u_soc/g_shared_sync_rom.u_sync_rom/imem_rdata_r_reg_5/CLKBWRCLK` |
| Destination | `u_soc/u_cpu/if_id_instruction_r_reg[8]/D` |
| Requirement | 20.000 ns |
| Data path delay | 25.589 ns |
| Logic levels | 32 |

The implementation still uses synchronous instruction/data memories
(`SYNC_IMEM=1`, `SYNC_DMEM=1`) and maps the program/data memories to BRAM. The
remaining distributed RAM is not evidence that the program memory is async; it
comes from other small architectural tables/caches. The failure is a real
post-route setup failure on the strict 50 MHz CoreMark-ROM build.

## Evidence Files

- `coremark_freeze_candidate_50m_strictsync_20260608.summary.txt`
- `vivado_impl_coremark50_20260608.log`
- `synth_utilization_coremark50.rpt`
- `synth_timing_summary_coremark50.rpt`
- `impl_utilization_coremark50_11182lut.rpt`
- `impl_timing_summary_coremark50_wns-5p800.rpt`
- `SHA256SUMS.txt`

## Reporting Rule

Do not report the earlier `5918 LUT / WNS +0.358 ns` demo-ROM implementation as
the strict CoreMark-ROM freeze evidence. It is useful historical information,
but it is not the exact audited freeze build.

The current strict 50 MHz CoreMark-ROM candidate should be reported as:

`11182 LUT / 5.162186 CoreMark/MHz short-run / 50 MHz / WNS -5.800 ns / rejected for freeze`
