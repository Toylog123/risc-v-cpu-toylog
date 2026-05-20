# Sync BRAM Configuration Sweep - 2026-05-20

This note records the post-preissue configuration sweep under the current strict sync-BRAM execution model. All retained CoreMark numbers keep the upstream CoreMark workload intact and use the FPGA-style short engineering run: DATA_SIZE=2000, ITERATIONS=10, expected crcfinal=0xfcaf.

## Retained Reference

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Result |
|---|---:|---:|---:|---|
| sync BRAM RC2048 + store fold, baseline recheck | pending | 4.236988 | pending | retained |
| sync BRAM RC4096 + store fold | pending | 4.237087 | pending | neutral, not enough gain |
| sync BRAM RC8192 + store fold | pending | 4.246034 | pending | best retained so far, needs synthesis resource check |

## Rejected or Neutral Candidates

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Result |
|---|---:|---:|---:|---|
| dynamic BHT512, RC2048 | pending | 4.236855 | pending | rejected, slower than baseline |
| static branch mode 1, RC2048 | pending | 4.236988 | pending | neutral, no measurable gain |
| static branch mode 2, RC2048 | pending | 4.235176 | pending | rejected, slower |
| I-cache enable, RC2048 | pending | invalid | pending | rejected, CoreMark timeout |
| D-cache enable, RC2048 | pending | invalid | pending | rejected, CoreMark timeout or external timeout |

## Verification Notes

- Baseline after adding the DCACHE_EN testbench/script generic was rechecked at 4.236988 CoreMark/MHz with crcfinal=0xfcaf.
- The invalid I-cache/D-cache runs are retained only as negative evidence; they are not score candidates.
- Current profile still points to data-memory latency and load-use bubbles as the dominant remaining hardware bottleneck.

## Next Hardware Direction

1. Keep CoreMark algorithm sources unchanged.
2. Continue from the sync-BRAM model only.
3. Investigate a synth-valid data-memory latency reduction path, such as a correctly aligned load return pipeline or a small load/store forwarding structure.
4. Freeze only candidates that pass CRC and complete the benchmark without timeout.
