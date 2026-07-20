# Strict 50 MHz Timing Optimization Archive

This directory contains the strict 50 MHz optimization evidence for the
YH_rv_cpu PYNQ-Z2 line.

## Current Best Candidate

| Candidate | LUT | FF | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
|---|---:|---:|---:|---:|---:|---|---|
| `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | 9965 | 6520 | 4.287521 | 2.495618 xsim | 50 MHz | WNS +0.056 ns / WHS +0.121 ns | current routed engineering candidate; board evidence pending |

This is an implementation-evidence result. It must not be described as
board-proven until PROGRAM_OK, UART capture, and video evidence are collected. The `impl220` bitstream itself is now archived under `board_impl220_bitstream_20260702/` with SHA256.
The CoreMark core algorithm source files are not modified by this optimization
line.

## Key Index Files

| File | Purpose |
|---|---|
| `REGION_STRICT50_UPDATE_20260701.md` | Region-contest wording for the current strict 50 MHz candidate |
| `REGION_REPORT_STRICT50_SECTION_20260701.md` | Chinese report/defense section for region-contest materials |
| `REGION_DELIVERY_INDEX_20260702.md` | Strict50 region package entry point and deliverable index |
| `REGION_REQUIREMENT_MATRIX_20260702.md` | Contest requirement-to-evidence matrix |
| `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md` | Machine-checkable metric-to-evidence trace for the current candidate |
| `verify_strict50_impl220_metrics.ps1` | Parses archived reports and verifies the current metric line |
| `REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md` | Strict verification gates for PPT/report/package/board-evidence wording |
| `REGION_DEFENSE_QA_STRICT50_20260702.md` | Strict50-specific defense Q&A wording |
| `REGION_DEFENSE_SPEAKER_SCRIPT_STRICT50_20260702.md` | 3-minute/1-minute defense speaker script and rapid answers |
| `REGION_SUBMISSION_WORKPLAN_20260702.md` | Region submission, PPT, evidence, and board-proof workplan |
| `REGION_REPORT_OUTLINE_STRICT50_20260702.md` | Technical report outline for the strict50 candidate |
| `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` | Report/PPT-ready Mermaid diagrams for pipeline, timing hotspot, optimization flow, and evidence chain |
| `REGION_WORK_INTRO_AND_PPT_MASTER_STRICT50_20260706.md` | Detailed work introduction and PPT content master for the strict50 candidate |
| `REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md` | Full Chinese technical report draft for the strict50 candidate |
| `REGION_FINAL_PACKAGE_MANIFEST_20260702.md` | Final submission package checklist and packaging boundary |
| `CICC_STRICT50_PACKAGE_RUNBOOK_20260702.md` | Dry-run/build instructions for the CICC strict50 submission package |
| `CICC_STRICT50_PACKAGE_DRYRUN_20260702.md` | Latest dry-run result for the whitelist package script |
| `CICC_STRICT50_PACKAGE_DRYRUN_20260702.tsv` | Machine-readable dry-run package file list |
| `make_cicc_strict50_package.ps1` | Whitelist package manifest/build script; excludes DCP and forbidden paths |
| `STRICT50_BOARD_EVIDENCE_AUDIT_20260702.md` | Current board-evidence gap audit for `impl220` |
| `audit_strict50_board_evidence.ps1` | Machine-checkable board evidence audit script |
| `STRICT50_APP_DEMO_EVIDENCE_20260702.md` | Strict50 application-demo xsim evidence and reporting boundary |
| `audit_strict50_demo_evidence.ps1` | Checks strict50 demo identity and `impl220`-matched testbench parameters |
| `STRICT50_DHRYSTONE_EVIDENCE_20260702.md` | Same-configuration Dhrystone/DMIPS xsim evidence for `impl220` |
| `audit_dhrystone_timer_clock_consistency.ps1` | Checks Dhrystone timer macro and 50 MHz clock consistency |
| `audit_strict50_dhrystone_evidence.ps1` | Checks formal `impl220` Dhrystone evidence files and key hardware parameters |
| `REGION_PPT_STORYBOARD_STRICT50_20260702.md` | Defense PPT storyboard and speaker notes |
| `REGION_PPT_DRAFT_MANIFEST_20260702.md` | PPTX draft identity, SHA256, slide map, and QA result |
| `CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx` | Editable region-defense PPT draft for the current strict50 candidate |
| `FREEZE_STRICT50_IMPL220_20260701.md` | Freeze decision for the current strict 50 MHz engineering candidate |
| `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` | Fill-in template for PROGRAM_OK, UART, bitstream SHA256, and video evidence |
| `STRICT50_BOARD_DEMO_RUNBOOK_20260702.md` | Board and application-demo evidence runbook |
| `RESULTS_20260611.md` | Chronological optimization and reject/accept ledger |
| `HANDOFF_20260617.md` | Current handoff notes and next technical targets |
| `FREEZE_BEST_STRICT50_IMPL136_20260625.md` | Last explicit strict 50 MHz freeze before post-freeze optimization |

## Reporting Boundary

Application-demo xsim evidence is now available under
`strict50_perf_demo_20260702/`. It verifies that the strict50 `impl220`-matched
SoC configuration runs the bundled performance-demo workload and prints
`PERF_DEMO PASS`. This is still simulation evidence only; board-proven wording
requires the separate PROGRAM_OK, board UART, and video evidence chain.

Same-configuration Dhrystone xsim evidence is available under
`sim220_dhrystone_impl220_strict50_match/`. The formal reportable simulation
line is `DMIPS/MHz (host-parsed): 2.495618 / Dhrystones/s 219240 / runs 1000`.

Allowed current wording:

`9965 LUT / 4.287521 CoreMark/MHz / 2.495618 DMIPS/MHz xsim / 50 MHz / WNS +0.056 ns / WHS +0.121 ns`

Do not promote these rows as reportable candidates:

- `synth224_defaultfast_foldnext0_cpu50`: high fast-gate score but synthesis
  timing fails at WNS -11.786 ns.
- `impl223_impl200_optExploreArea_routeHigherDelayCost_postAggressive_cpu50`:
  valid routed pass, but worse area and setup slack than `impl220`.
- historical high-score timing-failed or demo-ROM rows.

## Next Evidence Needed

| ID | Task | Completion standard |
|---|---|---|
| E01 | Select or generate exact `impl220` bitstream | done: `board_impl220_bitstream_20260702/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit`, SHA256 recorded |
| E02 | Program board | PROGRAM_OK evidence identifies the bitstream |
| E03 | Capture UART | Raw log matches the selected ROM/demo workload |
| E04 | Record video | Board, programming context, and UART output visible |
| E05 | Freeze if promoted | Commit/tag explicitly names the new frozen baseline |

Run `audit_strict50_board_evidence.ps1` before changing the board-evidence
claim. The current expected state is `board_evidence_complete=False` and
`submission_evidence_complete=False`; DMIPS is now present as xsim evidence, but
board-side PROGRAM_OK, UART, and video evidence are still missing; the `impl220` bitstream and SHA256 are archived.
