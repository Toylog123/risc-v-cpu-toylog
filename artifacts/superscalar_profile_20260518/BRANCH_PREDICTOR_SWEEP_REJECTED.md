# Branch Predictor Sweep

Date: 2026-05-18

## Result Table

| Version | LUT | CoreMark/MHz | DMIPS/MHz | Decision |
|---|---:|---:|---:|---|
| RC8192 + DMem negedge + non-memory not-taken fold | pending | 5.892738 | 1.371423 | retained |
| Dynamic BHT512 | pending | 5.892738 | not rerun | no gain |
| Static mode 1 | pending | 5.892738 | not rerun | no gain |
| Static always-taken | pending | 5.624911 | not rerun | rejected, slower |
| Dynamic BHT512 strong-only | pending | 5.892738 | not rerun | no gain |

## Optimization Notes

| Optimization | Status | Note |
|---|---|---|
| Dynamic BHT512 | rejected | Correct CRC but no CoreMark gain in the current RC8192 redirect-cache path. |
| Static mode 1 | rejected | Correct CRC but no CoreMark gain. |
| Static always-taken | rejected | Correct CRC but more decode flushes and lower score. |
| Dynamic BHT512 strong-only | rejected | Correct CRC but no CoreMark gain. |

## Decision

Keep the existing static/ID redirect plus RC8192 redirect-cache path.  Do not
enable dynamic BHT for the retained CoreMark/DMIPS candidate unless future
hardware changes create a new unresolved-branch bottleneck.
