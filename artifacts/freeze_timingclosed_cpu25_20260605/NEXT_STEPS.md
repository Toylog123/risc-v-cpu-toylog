# Next Steps After CPU25 Freeze

This task list starts from the frozen timing-closed CPU25 baseline:

- commit: `74bc557 Freeze timing-closed CPU25 baseline`
- tag: `freeze-timingclosed-cpu25-20260605`
- metrics: `6791 LUT / 4.501191 CoreMark/MHz / 1.205669 DMIPS/MHz`
- timing: post-route `WNS +0.291 ns / WHS +0.065 ns`
- bitstream: `artifacts/freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit`
- long-term roadmap: `LONG_TERM_OPTIMIZATION_PLAN.md`

Validated successor candidate:

- `CPU25 RC128`: `7076 LUT / 4.627215 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +0.514 ns / WHS +0.056 ns`.
- Reproduced implementation: `7124 LUT / 3211 FF / WNS +1.881 ns / WHS +0.100 ns`, bitstream `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_coremark_repro_20260605.bit`.
- Current recommended timing-robust follow-up: `CPU25 RC128 BFNext/no-ZBKB timing-driven`: `7473 LUT / 4.741458 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +1.348 ns / WHS +0.041 ns`.
- Low-LUT alternative in the same family: `7374 LUT / 4.741458 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +0.282 ns / WHS +0.062 ns`.
- Evidence: `experiments/CPU25_RC128_EXPERIMENT_20260605.md`.
- Status: simulation and implementation evidence pass; board evidence still pending if this candidate replaces the RC64 fallback.
- Reproduction wrapper: `cmd /c YH_rv_cpu\scripts\run_cpu25_rc128_validated.bat`.
- Implementation wrapper: `cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_coremark.bat impl`.
- BFNext implementation wrapper: `cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_bfnext_coremark.bat impl`.
- BFNext/no-ZBKB implementation wrapper: `cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_bfnext_nozbkb_coremark.bat impl`.
- BFNext/no-ZBKB timing-driven implementation wrapper: `cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_bfnext_nozbkb_timingdriven_coremark.bat impl`.

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
| T13 | Build and simulate performance demo firmware | done | P0 | `run_perf_demo.bat` completes and UART contains `PERF_DEMO PASS checksum=0xe727358b` | Evidence saved in `evidence/perf_demo_summary_20260605.txt` and `evidence/perf_demo_xsim_uart_20260605.log` |
| T14 | Generate CPU25 performance-demo bitstream | done | P0 | PYNQ-Z2 implementation uses `YH_rv_cpu_perf_demo.hex/.mem32.hex`, `RAM_BASE=0x00010000`, CPU25 generics, and closes timing | Bitstream saved as `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit`; timing is `WNS +0.291 ns / WHS +0.065 ns` |
| T15 | Board-run performance demo | pending | P0 | UART on PYNQ-Z2 prints all five workload PASS lines plus final `PERF_DEMO PASS`; PROGRAM_OK and video are captured | Run only after T14 timing is closed |
| T16 | Decide whether RC128 replaces RC64 fallback | pending | P1 | Decision note selects RC64 freeze or RC128 successor as the next board-facing bitstream | RC128 now passes CoreMark, Dhrystone, LUT, and timing gates; board evidence is still required |
| T17 | Regenerate RC128 board evidence if selected | pending | P1 | RC128 bitstream checksum, PROGRAM_OK, UART log, and video are captured | Use `experiments/CPU25_RC128_EXPERIMENT_20260605.md` as the reproduction anchor |
| T18 | Re-run RC128 simulation wrapper before promotion | done | P1 | Fresh CoreMark and Dhrystone summaries match the validated RC128 metrics within expected deterministic simulation variance | Completed 2026-06-05; summaries saved under `experiments/repro_cpu25_rc128` |
| T19 | Re-run RC128 PYNQ-Z2 implementation wrapper | done | P1 | Fresh implementation closes timing and remains below 8000 LUT | Completed 2026-06-05: `7124 LUT / WNS +1.881 / WHS +0.100`; bitstream archived in freeze package |
| T20 | Test RC128 BFNext follow-up | done | P1 | CoreMark remains above 4.5, LUT remains below 8000, and implementation closes timing | Completed 2026-06-06: `7505 LUT / 4.741458 CoreMark/MHz / WNS +1.138 / WHS +0.100` |
| T21 | Trim unused ZBKB hardware from BFNext | done | P1 | CoreMark remains above 4.5, LUT remains below 8000, and implementation closes timing | Completed 2026-06-06: `7374 LUT / 4.741458 CoreMark/MHz / WNS +0.282 / WHS +0.062`; bitstream archived in freeze package |
| T22 | Rebuild BFNext/no-ZBKB with timing-driven synthesis | done | P1 | Timing margin improves while CoreMark remains above 4.5 and LUT remains below 8000 | Completed 2026-06-06: `7473 LUT / 4.741458 CoreMark/MHz / WNS +1.348 / WHS +0.041`; current recommended timing-robust candidate |
| T23 | Check CPU30 timing on BFNext/no-ZBKB timing-driven | pending | P1 | Full implementation report records whether the selected family closes at 30 MHz | Add/use CPU30 MMCM/constraint wrapper only after preserving CPU25 evidence |
| T24 | Check CPU33 timing on BFNext/no-ZBKB timing-driven | pending | P1 | Full implementation report records whether the selected family closes at 33.333 MHz | Run only after CPU30 result is known |

## Immediate Execution Batch

1. Preserve the CPU25 BFNext/no-ZBKB timing-driven evidence and use it as the selected optimization family for further tests.
2. Before board programming, check CPU30 and then CPU33 timing on this same family to see whether a higher-clock successor is realistic.
3. Keep the performance-demo firmware aligned with the selected family so the board demo can show workload behavior, not only benchmark numbers.
4. After the clock/resource choice is stable, program the selected timing-closed bitstream on PYNQ-Z2, capture PROGRAM_OK/UART/video, and add `BOARD_EVIDENCE.md`.

## Guardrails

- Do not modify CoreMark core algorithm files.
- Do not use the Chinese-path frozen submission-materials directory for Vivado runs.
- Do not stage unrelated historical experiment files.
- Do not stage `YH_rv_cpu/scripts/resolve_python.bat` unless explicitly requested.
- Treat `freeze-timingclosed-cpu25-20260605` as the baseline for future comparisons.
