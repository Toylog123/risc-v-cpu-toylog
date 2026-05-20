# Area Tradeoff Notes - 2026-05-20

Scope: current strict sync-BRAM CoreMark path. CoreMark core algorithm files were not modified.

Results:

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Conclusion |
| --- | ---: | ---: | ---: | --- |
| MAC+mempair, RC8192, 4KB word D-cache | pending | 5.440883 | pending | retained simulated candidate |
| MAC+mempair, RC16384, 4KB word D-cache | pending | 5.442820 | pending | best simulated score; resource risk |
| no MAC/mempair target, RC2048, 4KB word D-cache | pending | 5.298996 | pending | lower area candidate, lower score |
| no MAC/mempair target, RC8192, 4KB word D-cache | pending | 5.312130 | pending | lower area candidate, lower score |
| store-allocate D-cache trial, RC2048 | pending | 5.424026 | pending | rejected: slower than baseline |
| store-allocate D-cache trial, RC8192 | pending | 5.438918 | pending | rejected: slower than RC8192 baseline |

Technical optimization points:

| Technical point | Status | Note |
| --- | --- | --- |
| XThead MAC | retained for performance path | The high-score binary emits `th.mula`/`th.mulah`, so removing this target loses CoreMark score. |
| XThead memidx/mempair | retained for performance path | The high-score binary emits indexed and pair memory operations. |
| D-cache store allocate | rejected | Correct CRC, but worse CoreMark/MHz than the non-allocating write-through word cache. |
| PYNQ-Z2 D-cache generics | added | FPGA top and Vivado scripts now expose `DCACHE_EN`, `DCACHE_SIZE_BYTES`, and `ICACHE_EN` for resource validation. |
| RC8192/RC16384 resource check | pending | Batch synth exceeded the local 30 minute guard before reports were produced; both need smaller-resource implementation or longer dedicated run. |

Evidence:

- `coremark_syncbram_word_dcache_nomac_rc2048.summary.txt`
- `coremark_syncbram_word_dcache_nomac_rc8192.summary.txt`
- `coremark_syncbram_word_dcache_storealloc_rc2048.summary.txt`
- `coremark_syncbram_word_dcache_storealloc_rc8192.summary.txt`

All listed runs completed with `crcfinal=0xfcaf`. The `storealloc` RTL change was reverted after measurement.
