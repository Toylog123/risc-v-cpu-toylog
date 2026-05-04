# Performance Experiment Log

> Updated: `2026-04-30`

## Current Leaderboard

| Candidate | Result | Decision |
|---|---:|---|
| `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect`, PYNQ-Z2 50.0MHz | `5.162186 CoreMark/MHz`, `4634 LUT`, `WNS=+0.608 ns` | current frozen preliminary submission path |
| Same path without JAL early redirect | `5.155952 CoreMark/MHz`, `4665 LUT`, `WNS=+0.275 ns` | superseded by current path |
| `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov`, no-IDBR, PYNQ-Z2 50.0MHz | `5.133707 CoreMark/MHz`, `4474 LUT`, `WNS=+0.559 ns` | superseded by timing-safe IDBR paths |
| Fast `Zba/Zbb/Zbs` subset, PYNQ-Z2 50.0MHz | `4.133456 CoreMark/MHz`, `3646 LUT` | area reference |
| Fast `Zba/Zbb/Zbs` subset, PYNQ-Z2 62.5MHz | `4.133456 CoreMark/MHz`, `3792 LUT`, `WNS=-0.029 ns` | rejected for formal timing |

## What Worked

- `Zbc` and selected XThead memory-index / conditional-move instructions lifted the score above the earlier `4.133456` fast bitmanip path.
- Timing-safe `IDBR cmp-cheapALU` gave a small but real CoreMark gain while staying under the `5000 LUT` hard limit.
- `JAL early redirect` removed a remaining cheap redirect cost and unexpectedly improved both score and LUT after implementation: `5.162186 CoreMark/MHz`, `4634 LUT`, `WNS=+0.608 ns`.
- Keeping full M division disabled remains important for area/timing; the conservative Dhrystone binary is built without hard `div/rem`.

## Rejected Or Superseded Experiments

| Experiment | Result | Decision |
|---|---:|---|
| Full IDBR broad EX-forward | `5.155979 CoreMark/MHz`, `5004 LUT`, `WNS=-3.017 ns` | rejected by LUT/timing gate |
| IDBR-lite EQ+signed with full EX-result fanout | `5.149765 CoreMark/MHz`, `5048 LUT`, `WNS=-3.026 ns` | rejected by LUT/timing gate |
| IDBR-lite BNE-only | `5.134659 CoreMark/MHz` | too small to promote |
| IDBR-lite EQ-only | `5.141626 CoreMark/MHz` | superseded |
| IDBR-lite EQ+unsigned | `5.147820 CoreMark/MHz` | superseded |
| All-backward branch prediction | `5.125708 CoreMark/MHz` | worse than baseline; reverted |
| BEQ+BNE pending-backward branch prediction | `5.133707 CoreMark/MHz`, `1982979` cycles | tied baseline; no useful gain |
| `fetch_redirect_pipe_hit` reuse candidate | `5.133707 CoreMark/MHz` | diagnostic found no useful EX-level redirect overlap |
| Compiler sweep batch 1 | best `5.133707 CoreMark/MHz` | no improvement; `-fauto-inc-dec` failed and was rejected |
| Compiler sweep batch 2 | best `5.133707 CoreMark/MHz` | IPA/modulo/peel/unswitch/schedule-pressure only tied or failed |
| `Zbkb` single extension | `5.133707 CoreMark/MHz` | no score gain |
| `Zicond` / `Zicond+Zbkb` | worse or timed out | rejected |
| M-extension score probes | tied or no gain | not worth area/timing cost |
| Layout/alignment sweep | best `5.133707 CoreMark/MHz` | no tick gain despite tiny completion-cycle changes |
| `-mtune` sweep | best `5.133707 CoreMark/MHz` | no meaningful gain |

## Current Hotspot Clues

- Latest formal run: `total_cycles=1971888`, `ticks=1937164`.
- Remaining EX redirect cycles are small: `BEQ=1864`, `JALR=26`, `JAL=0`.
- ID-stage branch decode redirect count is still high (`141100`), but this is mostly redirect classification rather than proven removable CPI.
- Since JAL redirect is gone and conditional EX redirect is under two thousand cycles, the next large gain likely needs a new view of load-use stalls, memory/fetch bubbles, instruction selection, or CoreMark code layout.

## Next Optimization Plan Toward 6+

1. Add measurement-only counters for load-use stalls, memory response waits, branch class mix, and top-level retired instruction buckets.
2. Rerun CoreMark once per counter build and compare against the `5.162186` reference to avoid optimizing blind.
3. Try low-risk software layout and compiler scheduling variants on the current formal RTL before adding hardware.
4. Explore a tiny fetch/predecode or load-use bypass improvement only if counters show a meaningful ceiling and the area estimate stays below `5000 LUT`.
5. Promote only candidates that pass functional regression, CoreMark CRC, PYNQ-Z2 implementation, timing, resource, and material-refresh gates.

## Evidence Pointers

- CoreMark formal summary: `build/sw/YH_rv_cpu_coremark_idbr_cmp_jal_predict_score_20260430_rerun.summary.txt`
- Dhrystone formal summary: `build/sw/YH_rv_cpu_dhrystone_idbr_cmp_jal_predict.summary.txt`
- FPGA implementation reports: `project/reports/pynq_z2/`
- Bitstream: `project/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit`
