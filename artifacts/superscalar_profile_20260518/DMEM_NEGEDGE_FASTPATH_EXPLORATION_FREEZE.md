# DMem Negedge Fast-Path Exploration Freeze Note

Date: 2026-05-18

## Change

This is a parameter-only hardware exploration. CoreMark was re-run with `DMEM_NEGEDGE_READ=1`, which enables the existing synchronous DMem negedge read path and load-use fast-forward mode. No CoreMark algorithm file was modified.

## Performance/Resource Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark Ticks | Completion Cycles | LUT | FF | BRAM | DSP | Status |
|---|---:|---:|---:|---:|---:|---:|---|---:|---|
| SS-BTI-v2, posedge DMem | 4.129273 | 1.371423 | 2,421,734 | 2,460,859 | pending | pending | DMem TDP BRAM seen in synth log | pending | prior stable baseline |
| SS-BTI-v2, negedge DMem fast path | 5.709219 | 1.371423 | 1,751,553 | 1,785,028 | pending | pending | needs fresh PYNQ-Z2 synth check | pending | exploration candidate |

## CoreMark Evidence

| Item | Result |
|---|---|
| CoreMark data profile | 2K, full workload |
| CRC | `0xfcaf` |
| Total ticks | 1,751,553 |
| CoreMark/MHz | 5.709219 |
| Strict EEMBC 10-second compliance | no, engineering short-run comparison |
| CoreMark algorithm files | unchanged |

## Dhrystone Evidence

| Item | Result |
|---|---|
| Runs | 2,000 |
| Dhrystones/s | 240,959 |
| DMIPS/MHz | 1.371423 |
| Completion cycles | 873,680 |
| Interpretation | unchanged from the prior Dhrystone path; Dhrystone needs a separate hardware-hotspot pass |

## Event Snapshot

| Event | Posedge DMem | Negedge DMem Fast Path |
|---|---:|---:|
| Completion cycles | 2,460,859 | 1,785,028 |
| Stall decode cycles | 482,464 | 0 |
| Memory wait cycles | 521,399 | 0 |
| IF/ID load bubbles | 704,585 | 5,309 |
| Redirect events | 193,402 | 193,592 |
| Redirect-cache delivery | 189,652 | 189,833 |
| Fold-next delivery | 158,568 | 127,196 |

## Interpretation

The score gain comes from removing synchronous DMem load wait and load-use stalls, not from changing the CoreMark workload. This is a real hardware-path lever, but it must be treated as an exploration candidate until Vivado confirms that the negedge memory style maps and times cleanly on PYNQ-Z2.

## Required Follow-Up

1. Run fresh PYNQ-Z2 synthesis/implementation or a smaller synthesis proxy to verify resource and timing.
2. Add Dhrystone event profiling because the same memory fast path does not move DMIPS.
3. If negedge BRAM inference is not acceptable, re-implement the same load-use benefit with a safer dual-port/read-ahead or bypassed DMem wrapper.
