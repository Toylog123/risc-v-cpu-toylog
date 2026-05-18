# Control-Flow Cache Sweep Freeze Note

Date: 2026-05-18

## Scope

This sweep keeps the CoreMark workload and CPU RTL unchanged and explores parameter-level control-flow hardware options on top of the DMem negedge fast-path candidate.

## Performance/Resource Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark Ticks | Completion Cycles | LUT | FF | BRAM | DSP | Result |
|---|---:|---:|---:|---:|---:|---:|---|---:|---|
| RC1024 + negedge DMem | 5.709219 | 1.371423 | 1,751,553 | 1,785,028 | pending | pending | needs fresh synth | pending | current fast-path baseline |
| RC1024 + BHT256 + negedge DMem | 5.709219 | not rerun | 1,751,553 | 1,785,028 | pending | pending | needs fresh synth | pending | no measurable gain |
| RC2048 + negedge DMem | 5.718717 | not rerun | 1,748,644 | 1,782,090 | pending | pending | needs fresh synth | pending | small gain |
| RC4096 + negedge DMem | 5.718962 | not rerun | 1,748,569 | 1,781,838 | pending | pending | needs fresh synth | pending | marginal gain over RC2048 |

## Event Notes

| Version | Fetch Requests | Redirect-Target Fetch Requests | Regular Fetch Requests | Redirect-Cache Delivery | Regular-Cache Delivery |
|---|---:|---:|---:|---:|---:|
| RC1024 + negedge DMem | 54,863 | 3,759 | 51,104 | 189,833 | 1,540,332 |
| RC2048 + negedge DMem | 35,388 | 2,274 | 33,114 | 191,330 | 1,555,372 |
| RC4096 + negedge DMem | 33,496 | 2,118 | 31,378 | 191,486 | 1,556,856 |

## Interpretation

Increasing the redirect/regular instruction cache reduces fetch requests, but the performance gain quickly saturates. BHT256 does not improve this workload because the existing static/ID redirect plus redirect cache already handles most repeating control-flow targets.

## Next Direction

Further CoreMark gain is unlikely to come from larger control-flow tables alone. The next experiments should target a lower-cost way to reduce remaining front-end bubbles or expose additional same-cycle issue opportunities without greatly increasing LUT count.
