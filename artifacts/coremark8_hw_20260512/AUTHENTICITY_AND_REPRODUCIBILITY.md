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

## What Is Not Allowed as a Final Claim

1. Quoting a score without the raw log and command path.
2. Mixing a high-score exploratory image with a different resource/timing configuration.
3. Treating a short-run or host-parsed diagnostic as an official benchmark result without disclosure.
4. Editing benchmark source only to remove work or bypass correctness checks.
5. Reporting a candidate as board-ready before implementation timing and bitstream evidence exist.

## Current Reporting Boundary

`H13` is a hardware resource/power reduction candidate on the no-Zbc/no-Zicond path. It preserves the current audited fixed-image CoreMark score and Dhrystone score, and it has synthesis evidence under `reports/h13_no_zbc_no_zicond_synth_20260514/`. It is not yet a board-grade final result because implementation timing and bitstream evidence still need to be generated.

The older high CoreMark fixed-image records and the `verify75` records are kept as separate evidence paths. They must not be merged into one claim unless the same RTL parameters, benchmark image, raw log, and FPGA report are all aligned.
