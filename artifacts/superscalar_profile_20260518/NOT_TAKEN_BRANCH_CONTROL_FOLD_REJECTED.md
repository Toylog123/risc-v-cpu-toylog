# Not-Taken Branch Control Fold Rejected

Date: 2026-05-18

## Result

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Decision |
|---|---:|---:|---:|---|
| retained store fold | pending | 5.934774 | 1.371423 | retained |
| branch-after-branch fold | pending | 5.915508 | not rerun | rejected |

## Technical Note

Allowing a branch instruction after a resolved not-taken branch to enter the folded path increased the number of EX redirects and decode flushes. The run completed with CRC `0xfcaf`, but the score regressed below the retained store-fold node.

The control-fold RTL change was reverted. This negative result is kept as an optimization boundary: folding a second control instruction needs a stronger front-end prediction/recovery scheme before it is worth retaining.

## Evidence

- `coremark_nt_branch_fold_rc8192.summary.txt`: `coremark_per_mhz=5.915508`, `crcfinal=0xfcaf`
