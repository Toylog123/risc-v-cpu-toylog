# CoreMark RC4096 Profile Freeze Note

Date: 2026-05-18

## Scope

This profile uses the current best exploration candidate: redirect cache 4096 entries, XOR index, branch target issue folding enabled, and DMem negedge fast path enabled. CoreMark source files are unchanged.

## Performance/Resource Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark Ticks | Completion Cycles | LUT | FF | BRAM | DSP | Scope |
|---|---:|---:|---:|---:|---:|---:|---|---:|---|
| RC4096 + negedge DMem | 5.718962 | 1.371423 | 1,748,569 | 1,781,838 | pending | pending | needs fresh synth | pending | best current candidate |
| RC4096 + negedge DMem + static always-taken | 5.466022 | not rerun | 1,829,484 | 1,862,866 | pending | pending | needs fresh synth | pending | rejected |

## Profile Highlights

| Item | Count |
|---|---:|
| Timed cycles | 1,748,569 |
| Timed ID/EX valid cycles | 1,743,641 |
| Timed non-ID/EX cycles | 4,928 |
| Timed branch decode candidate cycles | 466,749 |
| Timed branch decode pending cycles | 114,071 |
| Timed branch decode redirects | 134,042 |
| Timed not-taken branch fold queue candidates | 2,957 |
| Timed load-branch fuse candidates | 211 |
| Timed branch target fold candidates with next instruction | 135,732 |
| Timed ID/EX branch cycles | 339,307 |
| Timed ID/EX load cycles | 516,888 |

## Interpretation

The remaining gap to 6 CoreMark/MHz is no longer dominated by memory wait or fetch request latency. The profile shows that simple not-taken branch folding and load-branch fusion have too few opportunities to provide a large gain. Static always-taken prediction is harmful because it increases wrong-path flushes.

## Next Direction

The next useful hardware direction should be a more targeted macro-operation or execution optimization around the hottest PC ranges in list/state code, rather than broader prediction-table growth.
