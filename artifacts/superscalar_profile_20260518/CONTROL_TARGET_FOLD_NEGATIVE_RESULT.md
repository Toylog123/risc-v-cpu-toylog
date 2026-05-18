# Control-Target Fold Negative Result

Date: 2026-05-18

## Scope

This experiment temporarily allowed branch-target issue folding when the cached target instruction was itself a branch or jump. A directed diagnostic verified that a branch-to-`JAL x0` target could be folded correctly.

## Performance/Resource Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark Ticks | Completion Cycles | LUT | FF | BRAM | DSP | Decision |
|---|---:|---:|---:|---:|---:|---:|---|---:|---|
| RC4096 + negedge DMem baseline | 5.718962 | 1.371423 | 1,748,569 | 1,781,838 | pending | pending | needs fresh synth | pending | keep as best current candidate |
| Control-target fold + RC4096 + negedge DMem | 5.713789 | not rerun | 1,750,152 | 1,782,895 | pending | pending | needs fresh synth | pending | reject, slower |

## Evidence

| Check | Result |
|---|---|
| Control-target directed test before RTL change | RED, control target was not folded |
| Control-target directed test after RTL change | PASS, 3 control folds |
| Normal branch-target issue test after RTL change | PASS |
| CoreMark 2K after RTL change | PASS, CRC `0xfcaf`, but slower |

## Interpretation

Although the folded control target is functionally correct, CoreMark does not benefit. EX redirect events increased from 1,937 to 5,612 and decode flush cycles increased from 2,034 to 5,709, so the additional speculative control fold creates more downstream correction traffic than useful issue bandwidth.

## Decision

Do not retain the RTL behavior in the main candidate. Keep the result as a documented negative experiment and continue from the RC4096 + DMem negedge fast-path candidate.
