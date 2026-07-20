# Strict 50 MHz Board Evidence Template

Fill this file only after the exact `impl220` bitstream is generated and
programmed on PYNQ-Z2. Do not mark the candidate as board-proven until every
required evidence item is filled.

## Identity

| Item | Value |
|---|---|
| Date | `TODO` |
| Board | `PYNQ-Z2` |
| Git branch | `codex/strict50-impl136-opt-20260625` |
| Freeze tag | `freeze-strict50-impl220-20260701` |
| Freeze commit | `See tag target` |
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Bitstream | `artifacts/strict_50m_timing_opt_20260609/board_impl220_bitstream_20260702/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit` |
| Bitstream SHA256 | `13DD28472DBEF194E57B9C4D217CD5E886F34234CE17746E4F47854401AE6DBD` |
| CPU clock | `50 MHz` |
| Timing report | `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_timing_summary.rpt` |
| Utilization report | `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_utilization.rpt` |

## Required Evidence

| Evidence | Status | Path / Note |
|---|---|---|
| Vivado PROGRAM_OK | pending | `TODO` |
| UART raw log | pending | `TODO` |
| Board video | pending | `TODO` |
| Screenshot/photo, optional | pending | `TODO` |
| Bitstream SHA256 record | complete | `board_impl220_bitstream_20260702/SHA256SUMS.txt` and `bitstream_manifest.md` |

## Expected Claim After Completion

After all required evidence is collected, the allowed claim is:

`The strict 50 MHz impl220 bitstream is programmed and UART-verified on PYNQ-Z2.`

Until then, the allowed claim remains:

`impl220 is a strict 50 MHz post-route timing-closed engineering candidate; board evidence is pending.`

## Evidence Consistency Checklist

| Check | Status | Note |
|---|---|---|
| Bitstream comes from the frozen `impl220` configuration | complete | Generated from frozen routed DCP; see `board_impl220_bitstream_20260702/bitstream_manifest.md` |
| Timing report and bitstream use the same RTL/configuration | complete | Timing after reopening DCP remains WNS +0.056 ns / WHS +0.121 ns |
| UART output corresponds to the selected ROM/demo workload | pending | `TODO` |
| Video shows the same board and programming context | pending | `TODO` |
| No CoreMark core algorithm file is modified | pending | `TODO` |
