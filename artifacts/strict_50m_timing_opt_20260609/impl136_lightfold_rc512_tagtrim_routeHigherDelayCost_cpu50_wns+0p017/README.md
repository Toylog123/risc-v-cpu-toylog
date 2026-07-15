# impl136 Light-Fold RC512 Tag-Trim Route HigherDelayCost Candidate

Status: accepted routed DCP candidate under the current strict gate. Bitstream
generation from the archived routed DCP completed on 2026-07-13. Matched
Dhrystone xsim evidence and supplemental strict 10-second CoreMark xsim
evidence are available. PROGRAM_OK, UART capture, and board video are still
pending.

Non-invasive hardware probing on 2026-07-13 launched local `hw_server`, but no
matching hardware target was visible on `localhost`; PROGRAM_OK was therefore
not collected in that run.

## Result

| Item | Value |
| --- | --- |
| Post-route Slice LUTs | 9895 |
| Post-route LUT as Logic | 8559 |
| Post-route Registers | 6230 |
| BRAM / DSP | 32 / 8 |
| CoreMark/MHz | 4.287448 |
| DMIPS/MHz | 1.178213 matched xsim |
| Completion cycles | 2373958 |
| CRC final | 0xfcaf |
| Acceptance | yes |
| Clock | 50 MHz |
| Post-route WNS/WHS | +0.017 ns / +0.155 ns |
| Route status | 0 routing errors |
| Bitstream | `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit` |
| Bitgen source | `dcp/cpu50_impl.dcp` |
| Bitgen DRC | write-bitstream precondition DRC finished with 0 errors; standalone report is warning-only |

## Optimization

`impl136` uses the same RTL, strict CoreMark ROM/RAM image, and synthesis DCP as
`impl134_lightfold_rc512_tagtrim_cpu50_wns+0p001`. The only implementation-flow
change is `route_design -directive HigherDelayCost`; opt, place, and phys-opt
remain on `Explore`.

This keeps the `impl134`/RC512 tag-trim CoreMark score while improving the
routed timing margin from `WNS +0.001 ns / WHS +0.119 ns` to
`WNS +0.017 ns / WHS +0.155 ns`. LUT increases by 3 versus `impl134`, still
under the 10000 LUT gate.

## Evidence Files

- `fast134/coremark50_fast_gate_iter10.summary.txt`
- `fast134/coremark50_fast_gate_iter10.log`
- `logs/vivado_pynq_z2_synth.log`
- `logs/vivado_impl_from_synth.log`
- `reports/cpu50/impl_timing_summary.rpt`
- `reports/cpu50/impl_timing_setup_top20.rpt`
- `reports/cpu50/impl_timing_hold_top20.rpt`
- `reports/cpu50/impl_utilization.rpt`
- `reports/cpu50/impl_route_status.rpt`
- `reports/cpu50/impl_methodology.rpt`
- `dcp/cpu50_synth.dcp`
- `dcp/cpu50_impl.dcp`
- `write_bitstream_from_impl136.tcl`
- `vivado_write_bitstream_impl136.log`
- `vivado_write_bitstream_impl136.jou`
- `bitstream_from_dcp_timing_summary.rpt`
- `bitstream_from_dcp_utilization.rpt`
- `bitstream_from_dcp_drc.rpt`
- `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit`
- `BOARD_EVIDENCE_TEMPLATE.md`
- `FREEZE_HANDOFF_IMPL136_20260715.md`
- `probe_hw_targets_impl136.tcl`
- `vivado_hw_probe_impl136.log`
- `vivado_hw_probe_impl136.jou`
- `hw_probe_impl136.status.txt`
- `program_impl136_if_single_xc7z020.tcl`
- `program_impl136.status.txt`
- `vivado_program_impl136.log`
- `vivado_program_impl136.jou`
- `capture_impl136_uart.ps1`
- `run_impl136_board_evidence.ps1`
- `board_evidence_run_impl136.status.txt`
- `refresh_impl136_sha256sums.ps1`
- `verify_impl136_evidence.ps1`
- `verify_impl136_evidence.status.txt`
- `verify_impl136_evidence_board_required.status.txt`
- `../strict10s_impl136_20260709/iter2150_cpu50timer/coremark50_fast_gate_iter2150_cpu50timer.summary.txt`
- `../strict10s_impl136_20260709/iter2150_cpu50timer/coremark50_fast_gate_iter2150_cpu50timer.log`
- `../sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/README.md`
- `../sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim_runs1000.summary.txt`
- `../sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim_runs1000.log`
- `../sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim.dump`

## Validity Notes

- CoreMark algorithm source files are unchanged.
- The historical 10-iteration CoreMark evidence is a short reproducible
  full-workload fast gate. Strict 10-second xsim evidence is available under
  `../strict10s_impl136_20260709/iter2150_cpu50timer`.
- This archive is bitstream-backed as of 2026-07-13, but not board-proven.
- The standalone DRC report contains warnings only. The bitstream generation log
  records `DRC finished with 0 Errors` and `Bitgen Completed Successfully`.
- Latest hardware probe status is `HW_PROBE_RESULT=connect_hw_server_failed`;
  `cs_server` did not come up on `localhost:9315`, so no PROGRAM_OK evidence is
  present yet.
- Program attempt status is `PROGRAM_RESULT=get_hw_targets_failed`; the script
  did not reach `program_hw_devices`.
- The programming helper refuses to program unless exactly one `xc7z020` device
  is detected.
- The board-evidence runner dry-run status is
  `BOARD_EVIDENCE_RESULT=incomplete`; it enumerated serial ports and reran the
  non-invasive hardware probe, but skipped programming and UART capture. The
  dry-run reached `SHA256SUMS_REFRESH_ATTEMPT=before_exit`, validating the
  runner finalizer path.
- The offline verifier status is `VERIFY_RESULT=pass` when board evidence is
  not required. The board-required verifier status is `VERIFY_RESULT=fail`
  because PROGRAM_OK, UART evidence, and board video are still missing.
- The Dhrystone result is matched simulation evidence only; do not describe it
  as board UART evidence.

## Evidence Verifier

Run the offline evidence verifier from this directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_impl136_evidence.ps1
```

This checks SHA256 sums, bitstream identity, Vivado bitgen markers, timing
markers, strict 10-second xsim summary values, and the board-runner
`SHA256SUMS.txt` refresh hook. It also checks that the SHA refresh helper keeps
check-only mode and optional UART/video artifact coverage, that the programming
helper keeps the single-`xc7z020` guard, and that the UART capture helper uses
the verifier's CoreMark marker contract. It intentionally treats board evidence
as pending.

The verifier rewrites its local status snapshot. After any verifier invocation,
especially on a different host or checkout path, refresh the manifest again and
confirm it is synchronized:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1 -CheckOnly
```

After board evidence is collected, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_impl136_evidence.ps1 -RequireBoardEvidence
powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1 -CheckOnly
```

This mode must fail until PROGRAM_OK, UART marker/raw-log evidence, and board
video are archived and covered by `SHA256SUMS.txt`.

## Board Evidence Runner

After connecting and powering the PYNQ-Z2 board, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_impl136_board_evidence.ps1 -PortName COMx
```

The runner probes hardware targets, programs only through the single-`xc7z020`
guard in `program_impl136_if_single_xc7z020.tcl`, and then captures UART
markers through `capture_impl136_uart.ps1`. Before exiting, it writes the final
`BOARD_EVIDENCE_RESULT` and runs `refresh_impl136_sha256sums.ps1`, covering the
generated status/UART files and any already-present `board_video_impl136.*`
file. If the board video is added after the runner exits, rerun
`refresh_impl136_sha256sums.ps1` before the board-required verifier.
