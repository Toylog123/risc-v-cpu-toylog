# Freeze: strict 50 MHz impl220 engineering candidate

Date: 2026-07-01

Freeze decision:

- Freeze `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`
  as the current strict 50 MHz post-route timing-closed engineering candidate.
- This supersedes `impl136` for current strict 50 MHz implementation-evidence
  reporting, but does not make a board-proven claim.
- Keep `impl136` as the prior explicit freeze record for historical comparison.
- Do not promote `impl223`; it closes timing but has weaker setup slack and
  higher LUT than `impl220`.
- Do not promote `synth224` or `fast201`; the fast score is not routeable in
  the current same-cycle form.

## Frozen Candidate Metrics

| Candidate | LUT | FF | BRAM Tile | DSP | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | 9965 | 6520 | 32 | 8 | 4.287521 | 2.495618 xsim | 50 MHz | WNS +0.056 ns / WHS +0.121 ns | frozen strict routed engineering candidate; bitstream generated, PROGRAM_OK/UART/video pending |

## Evidence Paths

- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/README.md`
- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_route_status.rpt`
- `artifacts/strict_50m_timing_opt_20260609/fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/STRICT50_DHRYSTONE_EVIDENCE_20260702.md`
- `artifacts/strict_50m_timing_opt_20260609/sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/REGION_STRICT50_UPDATE_20260701.md`
- `artifacts/strict_50m_timing_opt_20260609/REGION_REPORT_STRICT50_SECTION_20260701.md`

## Validity Notes

- No CoreMark core algorithm source file is modified in this freeze.
- The CoreMark score is an engineering short-gate result with CRC `0xfcaf`;
  do not describe it as official EEMBC 10-second compliance.
- This freeze is a post-route implementation evidence freeze, not a board
  evidence freeze.
- Dhrystone/DMIPS for the exact `impl220` configuration is available as xsim
  evidence: `2.495618 DMIPS/MHz`, host-parsed from the Dhrystone UART log.
- The Dhrystone formal result uses the `timer50` evidence files; earlier
  non-`timer50` Dhrystone diagnostics are superseded and must not be reported.
- Bitstream generation and SHA256 archival are complete; PROGRAM_OK, UART capture, and board video evidence are pending.

## Rejected Nearby Results

| Candidate | Reason |
|---|---|
| `impl223_impl200_optExploreArea_routeHigherDelayCost_postAggressive_cpu50` | Valid strict routed pass, but worse than `impl220`: 9968 LUT and WNS +0.003 ns. |
| `impl222_impl200_optExploreArea_placeExtraPost_routeAdvancedSkewModeling_postAggressive_cpu50` | Valid strict routed pass, but only saves 1 LUT and drops WNS to +0.006 ns. |
| `synth224_defaultfast_foldnext0_cpu50` | Rejected at synthesis: WNS -11.786 ns, 1088 setup failing endpoints. |
| `fast201_impl200_foldnext0_iter10` | High fast score only; cannot be reported because the corresponding strict 50 MHz synthesis fails. |

## Next Work

| ID | Task | Completion standard |
|---|---|---|
| F01 | Generate or select exact `impl220` bitstream | done: `board_impl220_bitstream_20260702/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit`, SHA256 recorded |
| F02 | PROGRAM_OK evidence | Vivado Hardware Manager log/screenshot identifies the exact bitstream |
| F03 | UART evidence | Raw UART log matches the selected ROM/demo workload |
| F04 | Board-level Dhrystone rerun, if needed | UART raw log and summary are tied to the exact `impl220` bitstream |
| F05 | Board video | Video shows board, programming context, and UART output |
