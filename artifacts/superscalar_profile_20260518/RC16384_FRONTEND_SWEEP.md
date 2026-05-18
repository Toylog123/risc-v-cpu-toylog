# Redirect Cache 16384 Sweep

Date: 2026-05-18

## Result

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Decision |
|---|---:|---:|---:|---|
| RC8192 + store fold | pending | 5.934774 | 1.371423 | retained baseline |
| RC16384 + store fold | pending | 5.936755 | not rerun | candidate, resource pending |

## Technical Note

Increasing the redirect cache from 8192 to 16384 entries slightly improved front-end delivery and reduced bubbles, but the score gain is small. This node should not replace the retained path until synthesis confirms the LUT and timing impact on the target PYNQ-Z2 configuration.

## Evidence

- `coremark_nt_store_fold_rc16384.summary.txt`: `coremark_per_mhz=5.936755`, `crcfinal=0xfcaf`
