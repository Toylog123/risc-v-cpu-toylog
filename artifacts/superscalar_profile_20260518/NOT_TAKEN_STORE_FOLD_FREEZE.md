# Not-Taken Branch Store Fold Freeze

Date: 2026-05-18

## Result

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Decision |
|---|---:|---:|---:|---|
| RC8192 + DMem negedge + non-memory not-taken fold | pending | 5.892738 | 1.371423 | superseded |
| not-taken branch store fold | pending | 5.934774 | 1.371423 | retained |

## Technical Optimization

| Optimization | Status | Note |
|---|---|---|
| Store after not-taken branch fold | retained | Allows a store instruction immediately after a resolved not-taken branch to enter the folded issue path. |
| CoreMark core source integrity | verified | Core algorithm files unchanged; CRC remains `0xfcaf`. |

## Evidence

- CoreMark: `coremark_nt_store_fold_rc8192.summary.txt`, `coremark_per_mhz=5.934774`, `crcfinal=0xfcaf`
- Dhrystone: `dhrystone_nt_store_fold.summary.txt`, `dmips_per_mhz=1.371423`
- Directed test: `run_branch_not_taken_store_fold_test.bat`
