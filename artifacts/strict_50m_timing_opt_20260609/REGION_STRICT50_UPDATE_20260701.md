# Region Strict 50 MHz Update 2026-07-01

This file is the current region-contest wording update for the strict 50 MHz
optimization line. It supersedes older statements that said no strict 50 MHz
CoreMark-ROM timing-closed candidate existed.

## Current Reportable Engineering Candidate

| Candidate | LUT | FF | CoreMark/MHz | Clock | Timing | Evidence status |
|---|---:|---:|---:|---:|---|---|
| `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | 9965 | 6520 | 4.287521 | 50 MHz | WNS +0.056 ns / WHS +0.121 ns | strict routed pass; not board-proven yet |

Allowed wording:

`The current strict 50 MHz routed engineering candidate is 9965 LUT / 4.287521 CoreMark/MHz / 50 MHz / WNS +0.056 ns / WHS +0.121 ns on PYNQ-Z2 implementation reports. It does not modify the CoreMark core algorithm files. Board PROGRAM_OK, UART capture, and video evidence are still pending.`

Do not call this a board-proven result until the board evidence package is
collected. Do not call the CoreMark short engineering gate an official EEMBC
10-second compliant run.

## Evidence Paths

- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/README.md`
- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/reports_cpu50/impl_route_status.rpt`
- `artifacts/strict_50m_timing_opt_20260609/fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt`

## Nearby Audit Results

| Candidate | Result | Decision |
|---|---|---|
| `impl218_impl200_optExploreArea_routeNoTimingRelaxation_postAggressive_cpu50` | 9963 LUT / WNS +0.006 ns / WHS +0.109 ns / same 4.287521 CoreMark/MHz line | valid lower-LUT companion, but much thinner setup margin |
| `impl223_impl200_optExploreArea_routeHigherDelayCost_postAggressive_cpu50` | 9968 LUT / WNS +0.003 ns / WHS +0.067 ns / same 4.287521 CoreMark/MHz line | valid routed pass, not promoted |
| `synth224_defaultfast_foldnext0_cpu50` | 4.569338 CoreMark/MHz fast gate, but synth WNS -11.786 ns | rejected; do not route or report as candidate |

## Region Narrative

The design now has a strict 50 MHz post-route timing-closed engineering
candidate above the current minimum performance target. The optimization was
done in hardware configuration and RTL/control-path switches, not by changing
the CoreMark workload. The main technical tradeoff is that the higher-score
same-cycle speculation features still create long DCache/MEM-to-front-end
decode paths, so the selected candidate uses a safer configuration with a
smaller performance score but closes timing at 50 MHz.

For a contest report, keep the claim bounded to implementation evidence until
the board package is complete:

- report `impl220` as the current strict 50 MHz routed engineering candidate;
- use `FREEZE_STRICT50_IMPL220_20260701.md` as the current implementation
  freeze decision once the corresponding commit/tag is present;
- keep `impl136` as the prior explicit freeze record for historical comparison;
- keep old CPU25 material as historical fallback and demo-program evidence;
- mark `fast201`/`synth224` and other high-score timing-failed rows as rejected
  audit history.

## Board Evidence Still Needed

| ID | Task | Completion standard |
|---|---|---|
| B01 | Generate or select the exact `impl220` bitstream | Bitstream path and SHA256 recorded |
| B02 | Program PYNQ-Z2 | Vivado Hardware Manager log or screenshot shows PROGRAM_OK |
| B03 | Capture UART output | Raw UART log shows expected benchmark/demo markers |
| B04 | Record short video | Video shows board, programming context, and UART PASS output |
| B05 | Write board evidence file | Links bitstream checksum, timing report, PROGRAM_OK, UART log, and video |
