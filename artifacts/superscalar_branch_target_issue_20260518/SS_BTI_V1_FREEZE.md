# SS-BTI-v1 Freeze Note

Date: 2026-05-18

## Optimization

SS-BTI-v1 adds a low-cost branch target issue folding path. When the redirect-target cache supplies the target instruction for a taken branch or jump, the core can decode the target instruction and issue it into ID/EX while flushing the branch itself from the normal decode path. The implementation keeps the EX-stage redirect/check path as the correctness backstop and blocks folding when the target instruction is control/trap/CSR or depends on an unresolved load.

This is a hardware-only optimization. The official CoreMark workload files remain unmodified; only the permitted port/build layer is used for target selection, timing, UART/logging, and compiler information.

## Performance Evidence

All CoreMark rows below use `DATA_SIZE=2000`, CRC `0xfcaf`, 10 iterations, host-parsed raw ticks, and a short-runtime mode. They are reproducible engineering scores, not strict EEMBC 10-second report rows.

| Version | Redirect Cache | Fold | CoreMark/MHz | Ticks | Completion Cycles | 2K Profile | CRC | Strict 10s |
|---|---:|---:|---:|---:|---:|---|---|---|
| Baseline | 1024, XOR | 0 | 3.876931 | 2579360 | 2619407 | yes | 0xfcaf | no |
| SS-BTI-v1 | 1024, XOR | 1 | 3.987347 | 2507933 | 2547990 | yes | 0xfcaf | no |
| Baseline exploration | 16384, XOR | 0 | 3.883825 | 2574781 | 2614698 | yes | 0xfcaf | no |
| SS-BTI-v1 exploration | 16384, XOR | 1 | 3.995148 | 2503036 | 2542950 | yes | 0xfcaf | no |

| Version | Dhrystone Runs | DMIPS/MHz | Dhrystones/s | Completion Cycles | Notes |
|---|---:|---:|---:|---:|---|
| Baseline | 2000 | 1.371423 | 240959 | 873680 | Dhrystone 2.2, host-parsed UART log |
| SS-BTI-v1 | 2000 | 1.371423 | 240959 | 873680 | No measurable effect on current Dhrystone path |

## Verification Evidence

| Check | Result |
|---|---|
| Branch target issue diagnostic | PASS, 25 cycles, 3 folds, `x2=4` |
| Redirect target cache diagnostic | PASS, 21 cycles, 2 redirects |
| XThead mempair diagnostic | PASS, 13 cycles |
| XThead MAC diagnostic | PASS, 25 cycles |
| CoreMark official-source guard | Core benchmark files restored clean before measurement |

## Resource Evidence

| Resource Run | Configuration | Result |
|---|---|---|
| PYNQ-Z2 synth, CoreMark 64KB ROM/RAM | SS-BTI-v1, 1024 redirect cache, CoreMark image | Failed during memory inference: 64KB DMem could not infer BRAM with current dual-write/pair-port style |
| PYNQ-Z2 synth, default demo memory | SS-BTI-v1, 1024 redirect cache | Timed out during timing optimization after 15 minutes; no utilization report produced |

## Next Hardware Tasks

1. Rework `YH_rv_dmem_ram` large-memory FPGA style so Method A CoreMark can infer BRAM instead of register memory.
2. Convert redirect-target cache storage away from reset-heavy register arrays so 1024+ entries can map to FPGA RAM resources.
3. Add a correctly tagged fold-next buffer or small prefetch queue before attempting broader superscalar fetch, because the first naive target+4 request skipped instructions under sync ROM timing.
4. Profile fold hit rate in CoreMark/Dhrystone and prioritize only paths that reduce real timed cycles without touching benchmark algorithms.
