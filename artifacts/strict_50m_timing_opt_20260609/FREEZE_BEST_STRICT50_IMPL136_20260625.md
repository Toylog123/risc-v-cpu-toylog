# Freeze: best strict 50 MHz CoreMark candidate

Date: 2026-06-25

Freeze decision:

- Freeze `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017` as the current best strict 50 MHz exact-CoreMark-ROM routed candidate.
- Keep `impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004` only as the latest current-RTL routed pass, not as the best score candidate.
- Do not promote `impl179_impl173_routeNoTimingRelaxation_postExplore_cpu50`; it has no final timing summary and is an interrupted/incomplete implementation experiment.

Frozen candidate metrics:

| Candidate | LUT | FF | BRAM Tile | DSP | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017` | 9895 | 6230 | 32 | 8 | 4.287448 | 1.178213 matched xsim | 50 MHz | WNS +0.017 ns / WHS +0.155 ns | frozen best strict routed candidate; bitstream pending |

Evidence paths:

- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_route_status.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/fast134/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim_runs1000.summary.txt`

Fresh verification performed on 2026-06-25:

- `git status --short --branch --untracked-files=no` confirmed branch `codex/syncbram-h22-20260514`, ahead of origin by 7 commits before this freeze commit.
- `impl136` timing summary reports `All user specified timing constraints are met`.
- `impl136` timing summary reports WNS `+0.017 ns`, TNS `0.000 ns`, WHS `+0.155 ns`, THS `0.000 ns`.
- `impl136` CoreMark summary reports `coremark_per_mhz=4.287448`, `crcfinal=0xfcaf`, `acceptance_pass=yes`.
- `sim136` Dhrystone summary reports `dmips_per_mhz=1.178213`.

Validity notes:

- No CoreMark core algorithm source is part of this freeze change.
- This is a strict exact-ROM routed candidate, not a board-proven result.
- Bitstream, PROGRAM_OK, UART capture, and board video evidence remain pending.
- CoreMark evidence is a short reproducible full-workload engineering gate and records `strict_eembc_10s_compliant=no`; do not describe it as an official EEMBC 10-second run.

Rejected or non-promoted nearby results:

| Candidate | Reason |
| --- | --- |
| `impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004` | Valid latest current-RTL pass, but lower score: 4.207950 CoreMark/MHz and tighter WNS +0.004 ns. |
| `impl174_impl173_postAggressiveExplore_cpu50` | Valid no-op; unchanged from `impl173`. |
| `impl175_impl173_routeHigherDelayCost_postAggressive_cpu50` | Valid reproduction; unchanged from `impl173`. |
| `impl176_aborted_forcefanout64_nomatch` | Aborted; target nets did not match. |
| `impl177_aborted_force_repl_option_conflict` | Aborted; Vivado option conflict. |
| `impl178_impl173_force_repl_nodirective_cpu50` | Rejected; forced replication worsened pre-route WNS to -1.075 ns and introduced route intermediate hold failure. |
| `impl179_impl173_routeNoTimingRelaxation_postExplore_cpu50` | Incomplete/interrupted; no final timing summary, no routed candidate. |

Recommended next work after freeze:

1. Generate `impl136` bitstream from the archived routed DCP.
2. Collect PROGRAM_OK, UART output, and board video evidence.
3. For further optimization, start from `impl136` for score-oriented work and avoid broad forced fanout/replication on the current high-fanout set.
