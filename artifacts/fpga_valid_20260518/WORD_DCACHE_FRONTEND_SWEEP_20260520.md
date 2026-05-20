# Word D-cache Frontend Sweep - 2026-05-20

Scope: current strict sync-BRAM CoreMark path with RAM-only 4KB word D-cache enabled.

Fixed settings:

- `DCACHE_EN=1`, `DCACHE_SIZE_BYTES=4096`
- `DMEM_NEGEDGE_READ=0`
- `ID_BRANCH_FOLD=1`
- `ID_BRANCH_NOT_TAKEN_LOAD_FOLD=0`
- `ID_ALU_PAIR_FOLD=0`, `ID_ALU_DEP_FOLD=0`
- CoreMark core algorithm files unchanged.

Results:

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Conclusion |
| --- | ---: | ---: | ---: | --- |
| RC2048 + word D-cache | pending | 5.425097 | pending | retained baseline |
| RC4096 + word D-cache | pending | 5.425412 | pending | tiny gain |
| RC8192 + word D-cache | pending | 5.440883 | pending | retained candidate |
| RC8192 + fetch redirect reuse | pending | 5.440883 | pending | no extra gain |
| RC8192 + static branch mode 1 | pending | 5.440883 | pending | no extra gain |
| RC8192 + dynamic BHT512 | pending | 5.440676 | pending | rejected: slightly slower |
| RC16384 + word D-cache | pending | 5.442820 | pending | best simulated score; resource must be checked |

Technical optimization points:

| Technical point | Status | Note |
| --- | --- | --- |
| Larger redirect cache after D-cache | retained candidate | The D-cache removes most data stalls, making frontend misses more visible. |
| RC16384 | pending resource check | Best score, but resource cost may be too high for the low-power/LUT target. |
| Static branch mode 1 | rejected | Same result as RC8192 baseline under this workload. |
| Dynamic BHT512 | rejected | Adds prediction activity and is slightly slower in the current path. |
| Fetch redirect reuse | neutral | Same score as RC8192 baseline. |

Valid retained evidence:

- `coremark_syncbram_word_dcache_rc4096.summary.txt`
- `coremark_syncbram_word_dcache_rc8192.summary.txt`
- `coremark_syncbram_word_dcache_rc8192_static1.summary.txt`
- `coremark_syncbram_word_dcache_rc8192_reuse.summary.txt`
- `coremark_syncbram_word_dcache_rc8192_dyn512.summary.txt`
- `coremark_syncbram_word_dcache_rc16384.summary.txt`

All listed completed runs report `crcfinal=0xfcaf`, `acceptance_pass=yes`, and `strict_eembc_10s_compliant=no` because they are short engineering runs.
