# CoreMark Event Profile Freeze Note

Date: 2026-05-18

## Change

Added simulation-only event counters to `YH_rv_cpu_coremark_fpga_tb`. The counters report front-end redirects, redirect-cache delivery, branch target issue folding, fold-next delivery, stalls, memory waits, and fetch requests at benchmark completion. CPU RTL and CoreMark algorithm files are unchanged by this profiling step.

## Performance/Resource Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark Ticks | Completion Cycles | LUT | FF | BRAM | DSP | Scope |
|---|---:|---:|---:|---:|---:|---:|---|---:|---|
| SS-BTI-v2 + event profile TB | 4.129273 | 1.371423 | 2,421,734 | 2,460,859 | pending | pending | unchanged from prior RTL | pending | TestBench-only instrumentation |

## CoreMark Event Snapshot

| Event | Count |
|---|---:|
| Total cycles | 2,460,859 |
| IF/ID valid cycles | 2,455,210 |
| ID/EX valid cycles | 2,079,861 |
| Stall decode cycles | 482,464 |
| Memory wait cycles | 521,399 |
| Decode flush cycles | 44 |
| IF/ID load bubble cycles | 704,585 |
| Redirect events | 193,402 |
| EX redirect events | 44 |
| ID redirect events | 190,883 |
| JAL predict redirect events | 2,475 |
| Redirect-cache deliver events | 189,652 |
| Regular-cache deliver events | 1,506,903 |
| Branch-fold candidates | 165,258 |
| Branch-fold valid events | 158,641 |
| Fold-next deliver events | 158,568 |
| Fetch requests | 55,157 |
| Redirect-target fetch requests | 3,750 |
| Regular fetch requests | 51,407 |
| Fetch data issue cycles | 1,751,712 |

## Interpretation

The current superscalar front-end path is already heavily cache-fed: most redirects hit the redirect-target cache, and nearly all valid branch folds also deliver `target+4` through fold-next. The next high-value path is therefore not another simple redirect predictor. The profile points to memory-related pressure and load-use bubbles as the larger remaining cycle cost.

## Next Hardware Directions

1. Investigate load-use and memory-wait reduction under synchronous BRAM semantics.
2. Add focused Dhrystone event profiling because the current front-end fold path does not improve DMIPS.
3. Keep front-end parallelism experiments resource-aware; the profile suggests diminishing returns from simply adding wider redirect lookup hardware.
