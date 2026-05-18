# DMem True Dual-Port BRAM Freeze Note

Date: 2026-05-18

## Change

`YH_rv_dmem_ram` synchronous RAM write/read logic was split into two port-oriented always blocks. This matches the FPGA true dual-port RAM template more closely than the previous single process with two write ports.

## Evidence

| Check | Result |
|---|---|
| XThead mempair diagnostic | PASS, 13 cycles |
| XThead MAC diagnostic | PASS, 25 cycles |
| Branch target issue diagnostic | PASS, 25 cycles, 3 folds, 3 fold-next issues |
| CoreMark 2K after DMem TDP rewrite | 4.129273 CoreMark/MHz, `0xfcaf`, same as SS-BTI-v2 |

## Vivado Evidence

The PYNQ-Z2 64KB Method A synthesis log progressed past the previous memory inference failure and reported:

| Item | Vivado Log Evidence |
|---|---|
| DMem RAM inference | Recognized as true dual-port RAM template |
| DMem BRAM mapping | `16 K x 32` port A and B, `16 RAMB36` preliminary/final RAM mapping inside synthesis |
| Full synthesis status | Still timed out in Technology Mapping before final utilization report |

## Current Performance/Resource Table

| Version | CoreMark/MHz | DMIPS/MHz | LUT | FF | BRAM | DSP | Timing |
|---|---:|---:|---:|---:|---:|---:|---|
| SS-BTI-v2 + DMem TDP | 4.129273 | 1.371423 | pending | pending | DMem maps to 16 RAMB36 in synth log | pending | full synth timeout |

## Next Resource Tasks

1. Reduce or re-template redirect-target cache so it does not synthesize as large reset-heavy register arrays.
2. Add a faster Vivado resource-only flow or lower-optimization synthesis mode for quick LUT tracking.
3. Separate ROM/DMem resource experiments from full CPU timing closure so resource regressions can be measured quickly.
