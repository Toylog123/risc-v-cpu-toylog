# Freeze: best strict 50 MHz CoreMark candidate

Date: 2026-06-25

Updated: 2026-07-09 with target-frequency strict 10-second xsim evidence for
the frozen `impl136` candidate. The freeze decision and routed timing evidence
are unchanged.

Updated: 2026-07-13 with bitstream evidence generated from the frozen routed
DCP. Board evidence remains pending.

Freeze decision:

- Freeze `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017` as the current best strict 50 MHz exact-CoreMark-ROM routed candidate.
- Keep `impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004` only as the latest current-RTL routed pass, not as the best score candidate.
- Do not promote `impl179_impl173_routeNoTimingRelaxation_postExplore_cpu50`; it has no final timing summary and is an interrupted/incomplete implementation experiment.

Frozen candidate metrics:

| Candidate | LUT | FF | BRAM Tile | DSP | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017` | 9895 | 6230 | 32 | 8 | 4.287448 | 1.178213 matched xsim | 50 MHz | WNS +0.017 ns / WHS +0.155 ns | frozen best strict routed candidate; bitstream generated; board evidence pending |

Evidence paths:

- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_route_status.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/fast134/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/strict10s_impl136_20260709/sanity_iter10/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/strict10s_impl136_20260709/iter2150_cpu50timer/coremark50_fast_gate_iter2150_cpu50timer.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/strict10s_impl136_20260709/iter2150_cpu50timer/coremark50_fast_gate_iter2150_cpu50timer.log`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/write_bitstream_from_impl136.tcl`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/vivado_write_bitstream_impl136.log`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/bitstream_from_dcp_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/bitstream_from_dcp_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/bitstream_from_dcp_drc.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/BOARD_EVIDENCE_TEMPLATE.md`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/probe_hw_targets_impl136.tcl`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/vivado_hw_probe_impl136.log`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/hw_probe_impl136.status.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/program_impl136_if_single_xc7z020.tcl`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/program_impl136.status.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/vivado_program_impl136.log`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/capture_impl136_uart.ps1`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/run_impl136_board_evidence.ps1`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/board_evidence_run_impl136.status.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/verify_impl136_evidence.ps1`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/verify_impl136_evidence.status.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/verify_impl136_evidence_board_required.status.txt`
- `artifacts/strict_50m_timing_opt_20260609/sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim_runs1000.summary.txt`

Fresh verification performed on 2026-07-13:

- Vivado 2025.2 batch command completed with exit code 0 using `write_bitstream_from_impl136.tcl`.
- `vivado_write_bitstream_impl136.log` reports `DRC finished with 0 Errors`, `Bitgen Completed Successfully`, and `write_bitstream completed successfully`.
- `bitstream_from_dcp_timing_summary.rpt` reports `All user specified timing constraints are met`, WNS `+0.017 ns`, TNS `0.000 ns`, WHS `+0.155 ns`, THS `0.000 ns`.
- `bitstream_from_dcp_utilization.rpt` reports `9895` Slice LUTs, `8559` LUT as Logic, `6230` Slice Registers, `32` Block RAM Tile, and `8` DSPs.
- Non-invasive Vivado hardware probing launched local `hw_server`, but the
  latest `hw_probe_impl136.status.txt` records
  `HW_PROBE_RESULT=connect_hw_server_failed`; `cs_server` did not come up on
  `localhost:9315`, so no PROGRAM_OK evidence was collected in this run.
- `program_impl136_if_single_xc7z020.tcl` is prepared for the board run and
  refuses to program unless exactly one `xc7z020` hardware device is detected.
- A safe program attempt was run after the probe and stopped at
  `PROGRAM_RESULT=get_hw_targets_failed`; it did not reach `program_hw_devices`.
- `run_impl136_board_evidence.ps1 -SkipProgram -SkipUart` was run as a dry-run;
  it enumerated visible serial ports (`COM4`, `COM6`, `COM11`, `COM10`, `COM5`,
  `COM3`), recorded `BOARD_EVIDENCE_RESULT=incomplete`, and reached
  `SHA256SUMS_REFRESH_ATTEMPT=before_exit`.
- `verify_impl136_evidence.ps1` reports `VERIFY_RESULT=pass` for offline
  evidence checks covering SHA256 sums, bitstream identity, Vivado bitgen
  markers, timing markers, strict 10-second xsim summary values, and the
  board-runner SHA256 refresh hook. It also checks the SHA refresh helper's
  check-only/optional-artifact contract, the single-`xc7z020`
  programming-helper guard, and UART capture marker contract.
- `verify_impl136_evidence.ps1 -RequireBoardEvidence` reports
  `VERIFY_RESULT=fail`, with `board_evidence` and `program_status_boundary`
  failing as expected until PROGRAM_OK, UART evidence, and board video are
  archived.

Fresh verification performed on 2026-07-09:

- `impl136` strict 10-second xsim summary reports `clock_hz=50000000`, `iterations=2150`, `total_seconds=10.029656`, `coremark_per_mhz=4.287286`, `crcfinal=0xea58`, `completion_cycles=501526636`, `validation_clean=yes`, `strict_eembc_10s_compliant=yes`, `acceptance_pass=yes`.
- `impl136` strict 10-second xsim log reports `Correct operation validated` and `PASS: coremark completed at PC=00003d34 in 501526636 cycles`.
- `impl136` short sanity xsim rerun reports `clock_hz=100000000`, `iterations=10`, `coremark_per_mhz=4.287448`, `crcfinal=0xfcaf`, `completion_cycles=2373958`, `acceptance_pass=yes`.

Fresh verification performed on 2026-06-25:

- `git status --short --branch --untracked-files=no` confirmed branch `codex/syncbram-h22-20260514`, ahead of origin by 7 commits before this freeze commit.
- `impl136` timing summary reports `All user specified timing constraints are met`.
- `impl136` timing summary reports WNS `+0.017 ns`, TNS `0.000 ns`, WHS `+0.155 ns`, THS `0.000 ns`.
- `impl136` CoreMark summary reports `coremark_per_mhz=4.287448`, `crcfinal=0xfcaf`, `acceptance_pass=yes`.
- `sim136` Dhrystone summary reports `dmips_per_mhz=1.178213`.

Validity notes:

- No CoreMark core algorithm source is part of this freeze change.
- This is a strict exact-ROM routed and bitstream-backed candidate, not a board-proven result.
- PROGRAM_OK, UART capture, and board video evidence remain pending.
- The historical 10-iteration CoreMark evidence is a short reproducible full-workload engineering gate and records `strict_eembc_10s_compliant=no`; use it for engineering comparison against older freeze records.
- The 2026-07-09 `iter2150_cpu50timer` CoreMark xsim evidence is a target-frequency strict 10-second run and records `strict_eembc_10s_compliant=yes`; use `4.287286 CoreMark/MHz` when strict 10-second runtime compliance is required.
- Do not describe this freeze as board-proven until PROGRAM_OK, UART capture, and board video evidence are collected for the generated bitstream.

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

1. Connect/power the PYNQ-Z2 JTAG target and rerun `probe_hw_targets_impl136.tcl`.
2. If exactly one `xc7z020` target is detected, run `run_impl136_board_evidence.ps1 -PortName COMx`, then record board video and fill `BOARD_EVIDENCE_TEMPLATE.md`.
3. Keep `impl104` only as previous bitstream-backed fallback evidence until `impl136` board evidence is captured.
4. For further optimization, start from `impl136` for score-oriented work and avoid broad forced fanout/replication on the current high-fanout set.
