# SS-BTI-v2 Freeze Note

Date: 2026-05-18

## Optimization

SS-BTI-v2 extends SS-BTI-v1 with a second cache lookup for the sequential instruction after the folded branch target. If the redirect-target cache contains both the branch target and `target + 4`, the CPU issues the branch target into ID/EX and places `target + 4` into IF/ID in the same cycle. The PC is advanced to `target + 8`, so the next normal fetch continues after both issued instructions.

The optimization remains hardware-only and keeps the official CoreMark workload files untouched.

## Performance Evidence

All CoreMark rows use `DATA_SIZE=2000`, CRC `0xfcaf`, 10 iterations, host-parsed raw ticks, and short-runtime mode.

| Version | Redirect Cache | Fold Next | CoreMark/MHz | Ticks | Completion Cycles | 2K Profile | CRC | Strict 10s |
|---|---:|---:|---:|---:|---:|---|---|---|
| Baseline | 1024, XOR | 0 | 3.876931 | 2579360 | 2619407 | yes | 0xfcaf | no |
| SS-BTI-v1 | 1024, XOR | 0 | 3.987347 | 2507933 | 2547990 | yes | 0xfcaf | no |
| SS-BTI-v2 | 1024, XOR | 1 | 4.129273 | 2421734 | 2460859 | yes | 0xfcaf | no |

| Version | Dhrystone Runs | DMIPS/MHz | Dhrystones/s | Completion Cycles | Notes |
|---|---:|---:|---:|---:|---|
| Baseline | 2000 | 1.371423 | 240959 | 873680 | Dhrystone 2.2, host-parsed UART log |
| SS-BTI-v1 | 2000 | 1.371423 | 240959 | 873680 | No measurable change |
| SS-BTI-v2 | 2000 | 1.371423 | 240959 | 873680 | No measurable change |

## Verification Evidence

| Check | Result |
|---|---|
| Branch target issue diagnostic | PASS, 25 cycles, 3 folds, 3 fold-next issues |
| Redirect target cache diagnostic | PASS, 21 cycles, 2 redirects |
| XThead mempair diagnostic | PASS, 13 cycles |
| XThead MAC diagnostic | PASS, 25 cycles |

## Resource Evidence

PYNQ-Z2 synthesis has not produced a clean utilization report for this version. The failed/timeout synthesis runs show two resource-convergence tasks before this can be called an FPGA-ready CoreMark Method A design:

1. Large 64KB DMem cannot infer BRAM with the current dual-write/pair-port RAM style.
2. The 1024-entry redirect-target cache is still a reset-heavy register-array style and makes synthesis/timing optimization slow.

These are engineering blockers for board-level CoreMark, not benchmark correctness issues.
