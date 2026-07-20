# strict50 board evidence audit 2026-07-02

This file records the board-evidence state for the frozen strict 50 MHz `impl220` candidate. It is intentionally conservative: missing board evidence is treated as pending evidence, not as a failed implementation result.

## Candidate

| Item | Value |
|---|---|
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Freeze tag | `freeze-strict50-impl220-20260701` |
| Freeze commit | `ae648ca` |
| CPU clock | 50 MHz |
| Implementation timing | WNS +0.056 ns / WHS +0.121 ns |
| Utilization | 9965 LUT / 6520 FF / 32 BRAM Tile / 8 DSP |
| CoreMark/MHz | 4.287521 |
| DMIPS/MHz | 2.495618 xsim, same-configuration `timer50` Dhrystone evidence |
| Bitstream | generated and archived |
| Board evidence state | incomplete |
| Submission evidence state | incomplete |

## Audit Command

```powershell
powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/audit_strict50_board_evidence.ps1
```

For a hard CI-style gate after board evidence is collected:

```powershell
powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/audit_strict50_board_evidence.ps1 -RequireComplete
```

## Current Result

The current archive contains implementation evidence, same-configuration Dhrystone/DMIPS xsim evidence, and the `impl220` bitstream with SHA256. It still does not contain PROGRAM_OK, raw board UART, or board video evidence. Therefore the candidate must still be described as:

`impl220 is a strict 50 MHz post-route timing-closed engineering candidate; board evidence is pending.`

Current audit summary after bitstream archive and before board bring-up:

```text
board_dir_count=1
bitstream_count=1
ltx_count=0
program_ok_count=0
uart_log_count=0
video_count=0
video_manifest_count=0
bitstream_sha256_count=2
impl220_dmips_count=5
board_evidence_complete=False
submission_evidence_complete=False
board_missing_count=3
board_missing=program_ok
board_missing=uart_raw_log
board_missing=board_video
submission_missing_count=3
submission_missing=program_ok
submission_missing=uart_raw_log
submission_missing=board_video
impl220_dmips_evidence=sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.log
impl220_dmips_evidence=sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt
impl220_dmips_evidence=sim220_dhrystone_impl220_strict50_match/README.md
impl220_dmips_evidence=sim220_dhrystone_impl220_strict50_match/run_strict50_dhrystone_impl220_timer50_runs1000.stdout.log
impl220_dmips_evidence=STRICT50_DHRYSTONE_EVIDENCE_20260702.md
```

## Evidence Completion Standard

| Evidence item | Current status | Completion standard |
|---|---|---|
| `impl220` bitstream | complete | `.bit` generated from the frozen `impl220` configuration and archived under `board_impl220_bitstream_20260702/` |
| Bitstream SHA256 | complete | `13DD28472DBEF194E57B9C4D217CD5E886F34234CE17746E4F47854401AE6DBD` stored in `SHA256SUMS.txt` and `bitstream_manifest.md` |
| PROGRAM_OK | pending | Vivado Hardware Manager log or screenshot identifies successful programming |
| UART raw log | pending | Raw serial output archived for the selected ROM/demo workload |
| Board video | pending | PYNQ-Z2, programming context, and UART/demo output visible |
| `impl220` DMIPS/MHz | complete for xsim | Same-configuration `timer50` Dhrystone/DMIPS run archived under `sim220_dhrystone_impl220_strict50_match/` |

PROGRAM_OK, UART raw log, and board video define the remaining board-evidence gap. All rows together define `submission_evidence_complete`.

## Boundary

- This audit does not weaken the existing timing claim.
- This audit does not convert bitstream generation into PROGRAM_OK or UART/video board evidence.
- It must not be used to report `impl220` as board-proven until all required evidence items pass.
