# ID ALU Dependent Fold No-Gain Node

Date: 2026-05-18

## Result

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Decision |
|---|---:|---:|---:|---|
| baseline default off after patch | pending | 5.892738 | 1.371423 | retained |
| ID ALU dependent fold enabled | pending | 5.892738 | not rerun | no gain, default off |

## Technical Note

The experiment fuses adjacent dependent simple ALU instructions when the second instruction consumes and overwrites the first instruction's destination register. The directed diagnostic passed and fired one fold event, but the CoreMark run only observed four valid folds, so it did not reduce total ticks.

CoreMark core algorithm files were not modified. The hardware feature is parameterized as `ENABLE_ID_ALU_DEP_FOLD` and remains disabled by default.

## Evidence

- `coremark_id_alu_dep_fold_rc8192.summary.txt`: `crcfinal=0xfcaf`, `coremark_per_mhz=5.892738`
- `coremark_defaultoff_after_dep_fold.summary.txt`: `crcfinal=0xfcaf`, `coremark_per_mhz=5.892738`
- Directed test: `run_id_alu_dep_fold_test.bat`
