# Baseline Cleanup 2026-06-09

Purpose: remove misleading score records from the current baseline path. This
file does not delete historical artifacts from disk; it defines what may be
reported as the current project baseline.

## Current Baseline Decision

| Role | LUT | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Decision |
|---|---:|---:|---:|---:|---|---|
| Accepted baseline | 6791 post-route | 4.501191 | 1.205669 | 25 MHz | WNS +0.291 ns / WHS +0.065 ns | keep as current honest-reporting baseline |
| Best timing-closed successor candidate | 7473 post-route | 4.741458 | 1.205669 | 25 MHz | WNS +1.348 ns / WHS +0.041 ns | keep as candidate; not board-proven |

There is currently no accepted strict 50 MHz timing-closed CoreMark-ROM
baseline.

## Removed From Current-Baseline Claims

| Record | Previous-looking claim | Evidence problem | Allowed future wording |
|---|---|---|---|
| Historical 5918 line | `5918 LUT / 5.162186 CoreMark/MHz / 50 MHz / WNS +0.358 ns` | Timing closure was for demo/default ROM, not the exact CoreMark-ROM freeze build | historical demo-ROM timing only; not a strict CoreMark-ROM baseline |
| Strict 50 MHz CoreMark-ROM audit | `11182 LUT / 5.162186 CoreMark/MHz / 50 MHz` | Exact implementation failed timing at `WNS -5.800 ns` | rejected strict 50 MHz audit |
| 6872 low-resource line | `6872 LUT / 5.023480 CoreMark/MHz` | Full implementation failed at `7063 post-route LUT / WNS -10.360 ns` | timing-failed low-resource engineering reference |
| 7216/7316/7164/7853 quick-synth lines | under-8000 5+ candidates | Quick synthesis or timing-failed implementation; not exact timing-closed board builds | exploration only unless rerun as exact-ROM timing-closed implementation |
| 8983/9796 high-score references | `5.60+ CoreMark/MHz` strict sync-BRAM references | No accepted exact timing-closed board implementation in the current evidence path | historical high-score exploration only |
| Method A 7.50/6.23 lines | high CoreMark board/demo evidence | Different fixed-image demonstration path; not the current strict CoreMark-ROM baseline path | separate historical demo method only |

## Reporting Rules

- Baseline reports must include clock, exact post-route LUT, timing WNS/WHS, and
  benchmark evidence path.
- A score is not a baseline if its implementation timing failed.
- A score is not a strict CoreMark-ROM baseline if timing was closed with a
  different demo/default ROM image.
- Short CoreMark runs may be used for engineering comparison only. Do not call
  them strict EEMBC 10-second compliant unless the summary explicitly records
  that runtime condition.
- Historical artifact files should remain on disk as audit evidence, but region
  reports and handoff summaries must not promote them as current results.

## Files Updated By This Cleanup

- `YH_rv_cpu/doc/CURRENT_STATUS.md`
- `artifacts/region_baseline_6872_20260602/README.md`
- `artifacts/region_baseline_6872_20260602/TEST_STATUS.md`
- `artifacts/region_baseline_6872_20260602/HANDOFF_20260602.md`
- `artifacts/region_baseline_6872_20260602/NEXT_STEPS.md`
- `artifacts/region_baseline_6872_20260602/TIMING_OPT_20260603.md`
- `artifacts/region_baseline_6872_20260602/runbook/reproduce_6872_baseline.md`
- `artifacts/region_baseline_6872_20260602/REGION_REPORT_DRAFT_CLEAN_20260609.md`
- `artifacts/region_baseline_6872_20260602/BASELINE_CLEANUP_20260609.md`

The older untracked draft `artifacts/region_baseline_6872_20260602/REGION_REPORT_DRAFT_20260605.md`
was removed because it still used the pre-cleanup two-layer wording.
