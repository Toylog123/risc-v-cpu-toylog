# Next Steps After CPU25 Freeze

This task list starts from the frozen timing-closed CPU25 baseline:

- commit: `74bc557 Freeze timing-closed CPU25 baseline`
- tag: `freeze-timingclosed-cpu25-20260605`
- metrics: `6791 LUT / 4.501191 CoreMark/MHz / 1.205669 DMIPS/MHz`
- timing: post-route `WNS +0.291 ns / WHS +0.065 ns`
- bitstream: `artifacts/freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit`

## Pending Task Table

| ID | Task | Status | Priority | Completion Standard | Next Action |
|---|---|---|---|---|---|
| T01 | Push frozen commit and tag to remote | pending | P0 | Remote contains commit `74bc557` and tag `freeze-timingclosed-cpu25-20260605` | Run `git push origin codex/syncbram-h22-20260514` and `git push origin freeze-timingclosed-cpu25-20260605` after user approval |
| T02 | Board program this exact bitstream | pending | P0 | Vivado Hardware Manager reports PROGRAM_OK for `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit` | Connect PYNQ-Z2, open hardware target, program frozen bitstream |
| T03 | Capture UART output from frozen bitstream | pending | P0 | UART log shows expected CoreMark/Dhrystone or firmware completion output and matches the frozen 25 MHz build | Use the documented baud rate and save raw terminal log under the freeze package |
| T04 | Record board video evidence | pending | P0 | Video shows board, programming context, UART output, and identifies the frozen tag/bitstream | Record one continuous short clip after PROGRAM_OK and UART check |
| T05 | Add board evidence manifest | pending | P0 | Freeze package contains `BOARD_EVIDENCE.md` with PROGRAM_OK, UART log path, video path, date, board, cable, and bitstream checksum | Create `BOARD_EVIDENCE.md` after T02-T04 |
| T06 | Run strict 10-second CoreMark on frozen hardware or equivalent long simulation | pending | P1 | Evidence no longer carries short-runtime-only warning, or the document clearly separates competition short-run from strict EEMBC evidence | Prepare a long-run image/config and record runtime, CRC, and parsed score |
| T07 | Produce final comparison table against the old 6872 baseline | pending | P1 | Table lists 6872 timing-fail baseline and CPU25 timing-closed baseline with LUT, CoreMark/MHz, DMIPS/MHz, WNS, WHS, clock, and evidence path | Add comparison to project report or freeze README |
| T08 | Decide whether to keep optimizing 50 MHz timing as research-only | pending | P1 | Decision note says whether 50 MHz remains a future optimization branch or is out of scope for the submission baseline | Review cost/benefit after board evidence is complete |
| T09 | Prepare submission-facing technical narrative | pending | P1 | Narrative accurately states the timing-closed 25 MHz baseline and does not claim the 50 MHz 6872 line is closed | Draft concise Chinese technical section from frozen evidence |
| T10 | Clean local untracked/dirty experiment clutter policy | pending | P2 | A short cleanup policy identifies what can be ignored, archived, or later deleted; no unrelated files are staged | Keep `YH_rv_cpu/scripts/resolve_python.bat` out of commits unless explicitly requested |
| T11 | Optional power/temperature observation | pending | P2 | Record board-level observation or Vivado power estimate for the 25 MHz baseline | Run Vivado power estimate or collect simple board observation after programming |
| T12 | Optional 30 MHz/33 MHz exploratory margin check | pending | P2 | If explored, result is documented separately and does not replace CPU25 baseline unless it also closes timing and passes benchmarks | Only start after board evidence, and keep it on a new experiment branch or clearly separate artifact |

## Immediate Execution Batch

1. Push the frozen commit and tag after approval.
2. Program the frozen bitstream on PYNQ-Z2 and capture PROGRAM_OK plus UART output.
3. Add `BOARD_EVIDENCE.md` and attach checksums/log paths/video path to the freeze package.

## Guardrails

- Do not modify CoreMark core algorithm files.
- Do not use the Chinese-path frozen submission-materials directory for Vivado runs.
- Do not stage unrelated historical experiment files.
- Do not stage `YH_rv_cpu/scripts/resolve_python.bat` unless explicitly requested.
- Treat `freeze-timingclosed-cpu25-20260605` as the baseline for future comparisons.
