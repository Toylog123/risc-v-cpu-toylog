# Authenticity and Reproducibility Notes

Date: 2026-05-14

This directory records hardware optimization candidates for `YH_rv_cpu`. The goal is to improve CoreMark and Dhrystone/DMIPS through CPU microarchitecture, ISA hardware support, and FPGA-oriented resource/timing work. A result is not treated as reportable unless the evidence below is available.

## Evidence Required for a Reportable Result

1. Raw simulator log, including benchmark banner, iteration count, timing parameters, CRC/checksum output when available, and pass/fail status.
2. Summary file generated from the raw log, including completion cycles and normalized score.
3. Fixed benchmark image path or build target, so the run can be reproduced without silently changing the workload.
4. RTL/testbench configuration, including enabled ISA extensions and relevant parameters.
5. FPGA synthesis or implementation reports when the result is presented as a board candidate.
6. Clear label for short exploratory runs versus standard-compliant benchmark runs.
7. For Dhrystone, a run count large enough to avoid timer quantization artifacts, plus a scoring expression that does not overflow 32-bit arithmetic.

## What Is Not Allowed as a Final Claim

1. Quoting a score without the raw log and command path.
2. Mixing a high-score exploratory image with a different resource/timing configuration.
3. Treating a short-run or host-parsed diagnostic as an official benchmark result without disclosure.
4. Editing benchmark source only to remove work or bypass correctness checks.
5. Reporting a candidate as board-ready before implementation timing and bitstream evidence exist.
6. Reporting Dhrystone 10-run diagnostic scores as final DMIPS/MHz evidence; the UART output can quantize to `0` or `4` microseconds per run and is too coarse for final reporting.

## Current Reporting Boundary

`H13` is a hardware resource/power reduction candidate on the no-Zbc/no-Zicond path. It preserves the current audited fixed-image CoreMark score and Dhrystone score, and it has synthesis evidence under `reports/h13_no_zbc_no_zicond_synth_20260514/`.

Two board-grade FPGA evidence paths now exist and must be reported separately:

1. `reports/h14_h13_impl50_20260514/` plus `YH_rv_cpu_pynq_z2_h13_nozbc_nozicond_cpu50_20260514.bit` use the compact demo payload. This path is useful for CPU resource/timing reporting because it uses `4 BRAM`.
2. `../coremark_method_a_fixed75_20260514/` embeds the fixed CoreMark program image directly into the bitstream. This follows Method A and is useful for on-board CoreMark demonstration. It uses `32 BRAM` because the CoreMark ROM/RAM image is much larger.
3. `../coremark_method_a_h22_custom_crc_20260514/` embeds the cleaner H22 CoreMark image. It reports `6.234161 CoreMark/MHz`, uses custom CRC hardware instructions, does not use `YH_COREMARK_SKIP_ZERO_STATE_RERUN`, and implements at `5830 LUT / 2503 FF / 32 BRAM / 15 DSP` with `WNS +0.042 ns / WHS +0.040 ns`.

The older high CoreMark fixed-image records and the `verify75` records are kept as separate evidence paths. They must not be merged into one claim unless the same RTL parameters, benchmark image, raw log, and FPGA report are all aligned.

Freshly rebuilding the current no-Zicond CoreMark target on 2026-05-14 produced `5.052988 CoreMark/MHz` (`method_a_coremark_preflight_20260514.summary.txt`), while the archived fixed `verify75` image reproduced `7.502641 CoreMark/MHz` on the final code state (`fixedhex_final_h13_method_a_image_cm10.summary.txt`). These are different firmware images and must not be presented as the same measurement.

The Method A demonstration flow is documented in `../coremark_method_a_fixed75_20260514/METHOD_A_VALIDATION.md`. The worktree scripts `YH_rv_cpu/scripts/program_pynq_z2_method_a_fixed75.bat`, `watch_uart_live.bat`, `capture_uart.ps1`, and `demo_method_a_program_and_capture.bat` provide the board programming and UART capture path without relying on Chinese project-management directories.

H20 resolves the rebuild mismatch: `logs/h20_rebuild_with_extraopt_verify75_20260514.summary.txt` reproduces `7.502641 CoreMark/MHz` only when the historical `YH_COREMARK_EXTRA_OPT` macro set is injected. That path includes custom CRC hardware instructions and `YH_COREMARK_SKIP_ZERO_STATE_RERUN`. It must be disclosed as an ISA/software co-design artifact, not reported as a pure RTL-only improvement. The audit is recorded in `H20_COREMARK_REBUILD_AUDIT.md`.

H22 keeps only the custom CRC hardware instruction path and avoids the zero-state skip macro. It is still an ISA/hardware co-design result, but it is the cleaner Method A CoreMark demonstration candidate. The audit is recorded in `H22_CUSTOM_CRC_ONLY.md`.

## Dhrystone Measurement Boundary

The earlier Dhrystone 10-run logs are useful only as quick pass/fail diagnostics. They are not precise enough for final DMIPS reporting because the benchmark prints integer microseconds per run. During the 2026-05-14 audit, the 1000-run Dhrystone profile also exposed a separate upstream scoring issue: `HZ * Number_Of_Runs` is evaluated in 32-bit `long` arithmetic on RV32 and overflows at the 100 MHz / 1000-run setting.

The build flow now generates patched Dhrystone sources under `build/sw/generated_dhrystone/`. The patch preserves the upstream benchmark body and changes only the score calculation to use 64-bit intermediate arithmetic. The corrected long-run evidence is `logs/dhrystone_i64score_h13_runs1000.summary.txt`, reporting `1.371394 DMIPS/MHz`, `240954 Dhrystones/s`, and `458670` completion cycles for 1000 runs. This is the current truthful DMIPS baseline for the H13/H15 hardware path.

## Negative Evidence Kept Intentionally

The 2026-05-14 full-`M` division experiment found a measured Dhrystone hotspot and improved corrected long-run Dhrystone from `1.371394` to `1.466824 DMIPS/MHz`, but the current implementation uses a combinational divider. Vivado synthesis with full M plus bitmanip/XThead stalled in technology mapping and was terminated after the log stopped updating. Logs are kept under `logs/h17_full_m_synth_timeout_20260514/`.

This is not a failure to hide; it is evidence that the next DMIPS attempt should use a timing/resource-aware divider or a different reusable hardware feature, not a large single-cycle divider.
