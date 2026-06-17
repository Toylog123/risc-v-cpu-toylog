# Long-Term Optimization Plan After CPU25 Baseline

Baseline for all work in this plan:

- tag: `freeze-timingclosed-cpu25-20260605`
- metrics: `6791 post-route LUT / 4.501191 CoreMark/MHz / 1.205669 DMIPS/MHz`
- implementation timing: `WNS +0.291 ns / WHS +0.065 ns`
- board clock: 25 MHz PYNQ-Z2 CPU MMCM
- hard rule: do not modify CoreMark core algorithm files

## Optimization Principles

- Keep the CPU25 freeze as the board-facing fallback at all times.
- Every experiment must report `LUT | CoreMark/MHz | DMIPS/MHz | timing | technical change`.
- Do not promote a version unless it has CRC-clean benchmark evidence and reproducible Vivado reports.
- Prefer small, explainable RTL changes over benchmark-specific software edits.
- Treat 50 MHz timing recovery as a separate research line until it closes post-route timing.

## Roadmap Summary

| Phase | Goal | Priority | Success Metric | Promotion Rule |
|---|---|---|---|---|
| P0 | Make CPU25 baseline board-proven | P0 | PROGRAM_OK, UART log, video evidence | Required before any public/submission claim |
| P1 | Recover CoreMark/MHz while preserving timing closure | P1 | `CoreMark/MHz > 4.7`, LUT `< 8000`, post-route WNS `>= 0` | Promote only if board-facing evidence can be regenerated |
| P2 | Explore 30-40 MHz clock points | P1 | Highest closed CPU clock with current RTL family | Promote only if CoreMark/MHz remains `> 4.5` and WNS/WHS close |
| P3 | Structurally shorten DCache/front-end/PC path | P1 | Same or higher clock with less timing margin pressure | Promote after CoreMark/Dhrystone and full implementation |
| P4 | Reduce LUT/power around frozen performance | P2 | LUT below `6500` or lower power estimate without timing loss | Promote only if board evidence remains valid after rebuild |
| P5 | Build final reporting package | P1 | Reproducible tables, commands, checksums, evidence manifest | Required for handoff/submission |

## Detailed Task List

| ID | Task | Status | Priority | Completion Standard | Next Action |
|---|---|---|---|---|---|
| L01 | Push freeze commit, documentation commit, and tag | pending | P0 | Remote branch and tag resolve to the intended frozen baseline documentation | Push branch and `freeze-timingclosed-cpu25-20260605` after approval |
| L02 | Program CPU25 bitstream on PYNQ-Z2 | pending | P0 | Vivado Hardware Manager reports PROGRAM_OK for the frozen bitstream | Use `artifacts/freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit` |
| L03 | Capture UART evidence | pending | P0 | Raw UART log saved with date, board, baud rate, bitstream checksum | Run board image and store log under freeze package |
| L04 | Create `BOARD_EVIDENCE.md` | pending | P0 | Manifest links PROGRAM_OK, UART log, video, bitstream checksum, report paths | Add after board run |
| L05 | Run strict 10-second CoreMark evidence | pending | P1 | Long-run result has CRC-clean output and no short-runtime-only caveat | Prepare long-run simulation or hardware run |
| L06 | Check current RTL at 30 MHz | pending | P1 | Full implementation report for CPU30 with WNS/WHS and LUT | Add 30 MHz MMCM option or direct clock constraint experiment |
| L07 | Check current RTL at 33.333 MHz | pending | P1 | Full implementation report for CPU33 with WNS/WHS and LUT | Add a legal MMCM divider and run implementation |
| L08 | Check current RTL at 40 MHz | pending | P1 | Full implementation report shows whether current path has enough margin | Try only after CPU30/33 result is known |
| L09 | Revisit regular redirect-cache lookup timing | pending | P1 | Keep most regular-cache performance while removing DCache/tag-to-PC path | Prototype registered or staged regular lookup metadata |
| L10 | Pipeline redirect-cache PC skip decision | pending | P1 | PC update no longer depends on same-cycle DCache/load-use/cache-hit fan-in | Add a redirect accepted/advance register and verify no fetch semantic break |
| L11 | Split fold-target decoder from PC critical path | pending | P1 | Worst path no longer enters `u_fold_target_id_stage/u_decoder` before `pc_r` | Cache or predecode only the control bits needed for fold safety |
| L12 | Register selected frontend hazard classes | pending | P1 | Load-use/frontend hazards do not fan into `fetch_control_redirect_valid` and `pc_r` in one cycle | Add one-cycle conservative stalls for only path-sensitive cases |
| L13 | Re-evaluate EX operand frontend guard | pending | P1 | Determine if the guard is still needed after structural path cuts | Compare CoreMark, DMIPS, LUT, WNS with and without guard |
| L14 | Try 128-entry redirect cache under CPU25/30 | done | P2 | Improves CoreMark/MHz or DMIPS without exceeding 8000 LUT and timing | CPU25 RC128 validated at `7076 LUT / 4.627215 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +0.514`; promote only after board evidence is regenerated |
| L15 | Try selective NT-load fold recovery | pending | P2 | Recover performance without reintroducing DCache-to-PC critical path | Enable fold only for path-safe dependency classes |
| L16 | Add timing-report parser script | done | P2 | One command extracts LUT, FF, BRAM, DSP, WNS, WHS, worst path endpoints | Parser is `YH_rv_cpu/scripts/parse_vivado_reports.py` |
| L17 | Add experiment ledger table | done | P2 | All future runs recorded in a single CSV/Markdown table with evidence paths | Ledger is `OPTIMIZATION_LEDGER_20260605.md` |
| L18 | Power estimate for CPU25 baseline | pending | P2 | Vivado power or board observation recorded with clock and activity assumption | Run after board evidence or stable SAIF/VCD is available |
| L19 | Clean stale local artifacts policy | pending | P2 | Clearly identify ignored historical artifacts and current freeze artifacts | Document what should not be staged or pushed |
| L20 | Final technical narrative | pending | P1 | Chinese report text accurately distinguishes timing-closed CPU25 from 50 MHz timing-fail baselines | Draft after board evidence and long-run evidence are complete |
| L21 | Keep RC128 validation wrapper current | done | P1 | One command reruns the validated CPU25 RC128 CoreMark and Dhrystone simulation pair with matching hardware generics | Wrapper is `YH_rv_cpu/scripts/run_cpu25_rc128_validated.bat`; use before promoting RC128 to board-facing baseline |
| L22 | Restore BFNext and trim unused ZBKB hardware | done | P1 | Best CPU25 successor keeps CoreMark/MHz above 4.7, closes timing, and stays below 8000 LUT | Low-LUT candidate: `7374 LUT / 4.741458 CoreMark/MHz / WNS +0.282 / WHS +0.062`; wrapper is `YH_rv_cpu/scripts/build_pynq_z2_cpu25_rc128_bfnext_nozbkb_coremark.bat` |
| L23 | Rebuild BFNext/no-ZBKB with timing-driven synthesis | done | P1 | Improve setup margin without losing CoreMark or exceeding 8000 LUT | Current recommended timing-robust candidate: `7473 LUT / 4.741458 CoreMark/MHz / WNS +1.348 / WHS +0.041`; wrapper is `YH_rv_cpu/scripts/build_pynq_z2_cpu25_rc128_bfnext_nozbkb_timingdriven_coremark.bat` |

## Suggested Experiment Order

1. Keep `cpu25_rc128_bfnext_nozbkb_timingdriven_20260606` as the selected optimization family unless a later experiment beats it on all gates.
2. Run CPU30 and CPU33 implementation on this selected family, because this is the fastest way to find the available clock ceiling without changing software.
3. If CPU30/33 fails, prioritize structural cuts around regular redirect-cache lookup and PC skip, then rerun CoreMark/Dhrystone before full implementation.
4. If CPU30/33 passes, rerun CoreMark/Dhrystone evidence at the selected clock and decide whether to freeze a higher-clock successor.
5. Regenerate board evidence only after the clock/resource/performance choice is stable: bitstream checksum, PROGRAM_OK, UART log, and video.

## Tooling Added

- Report parser: `YH_rv_cpu/scripts/parse_vivado_reports.py`.
- RC128 validation wrapper: `YH_rv_cpu/scripts/run_cpu25_rc128_validated.bat`.
- Current recommended BFNext/no-ZBKB timing-driven implementation wrapper: `YH_rv_cpu/scripts/build_pynq_z2_cpu25_rc128_bfnext_nozbkb_timingdriven_coremark.bat`.
- Experiment ledger: `artifacts/freeze_timingclosed_cpu25_20260605/OPTIMIZATION_LEDGER_20260605.md`.
- Use the parser output as the canonical row format for future optimization reports.

## Promotion Gates

| Gate | Requirement |
|---|---|
| Functional | CoreMark CRC and Dhrystone completion pass with matching RTL generics |
| Performance | CoreMark/MHz `> 4.5`; preferred next target `> 4.7` |
| Area | Post-route LUT `< 8000`; preferred next target `< 7200` |
| Timing | Post-route WNS `>= 0`, WHS `>= 0` |
| Evidence | Reports, logs, bitstream checksum, reproduction command, and status document update |
| Board | PROGRAM_OK and UART evidence for any board-facing replacement baseline |

## Do Not Do

- Do not edit `core_list_join.c`, `core_matrix.c`, `core_state.c`, `core_util.c`, or `core_main.c`.
- Do not call a bitstream board-facing if post-route timing is negative.
- Do not replace the CPU25 freeze with a simulation-only result.
- Do not bulk stage historical untracked experiment files.
- Do not run Vivado from the Chinese submission-materials path.
