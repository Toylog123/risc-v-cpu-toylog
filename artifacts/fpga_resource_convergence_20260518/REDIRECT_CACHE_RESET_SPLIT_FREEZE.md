# Redirect Cache Reset/Data Split Freeze Note

Date: 2026-05-18

## Change

The redirect-target cache valid bits remain resettable, while the cached PC and instruction arrays are written in a separate non-reset synchronous block. This keeps the architectural behavior unchanged and removes reset semantics from the cache payload arrays, which is friendlier to FPGA memory inference and synthesis convergence.

## Evidence

| Check | Result |
|---|---|
| Branch target issue diagnostic | PASS, 25 cycles, 3 folds, 3 fold-next issues |
| Redirect target cache diagnostic | PASS, 21 cycles, 2 redirects |
| XThead mempair diagnostic | PASS, 13 cycles |
| CoreMark 2K after redirect-cache reset/data split | 4.129273 CoreMark/MHz, `0xfcaf`, unchanged from SS-BTI-v2 |
| CoreMark source policy | Official CoreMark algorithm files remain outside the hardware diff path |

## Performance/Resource Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark Ticks | Dhrystone Cycles | LUT | FF | BRAM | DSP | Timing |
|---|---:|---:|---:|---:|---:|---:|---|---:|---|
| SS-BTI-v2 + DMem TDP + redirect-cache split | 4.129273 | 1.371423 | 2,421,734 | 873,680 | pending | pending | DMem maps to 16 RAMB36 in synth log | pending | full synth pending |

## Benchmark Scope

The CoreMark run uses the clean 2K data profile and reports CRC `0xfcaf`. It is an engineering comparison run with 10 iterations, not a strict EEMBC 10-second submission run. The hardware optimization does not modify CoreMark core algorithm files.

## Next Tasks

1. Add hardware-side profiling counters to quantify CoreMark fold and fold-next hit rates.
2. Use the profiling data to decide whether a small fetch queue, multi-entry target stream buffer, or another low-cost front-end parallelism block has enough return under the PYNQ-Z2 resource envelope.
3. Re-run Vivado resource synthesis after cache payload inference changes and record LUT/FF/BRAM/DSP only from fresh reports.
