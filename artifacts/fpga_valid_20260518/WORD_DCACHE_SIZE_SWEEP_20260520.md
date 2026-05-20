# Word D-cache Size Sweep - 2026-05-20

Scope: current strict sync-BRAM CoreMark path only. CoreMark core algorithm files were not modified.

Fixed hardware configuration:

- Sync instruction ROM and sync data RAM.
- RAM-only write-through direct-mapped word D-cache enabled.
- MMIO, ROM, and XThead memory-pair accesses bypass the D-cache.
- Redirect cache: 2048 entries, XOR index enabled.
- ID branch fold enabled; dynamic branch prediction disabled.

Results:

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Conclusion |
| --- | ---: | ---: | ---: | --- |
| sync BRAM RC2048 + store fold baseline | pending | 4.236988 | pending | retained baseline |
| RAM-only word D-cache 2KB | pending | invalid | pending | rejected: simulation timeout at 5,000,001 cycles |
| RAM-only word D-cache 4KB | pending | 5.425097 | pending | retained |
| RAM-only word D-cache 8KB | pending | 5.425097 | pending | same score as 4KB; no CoreMark benefit |

Technical notes:

| Technical point | Status | Note |
| --- | --- | --- |
| RAM-only D-cache window | retained | Prevents timer/UART MMIO from being cached and preserves benchmark timing correctness. |
| XThead memory-pair bypass | retained | Keeps pair load/store correctness without adding pair support to the small word cache. |
| Store write-through address fix | retained | Uses the current CPU address for RAM writes; required for valid CRC. |
| 4KB capacity | retained | Matches 8KB score on the 2K CoreMark engineering workload. |
| 2KB capacity | rejected | Timeout indicates excessive conflict/slowdown under the current direct-mapped design. |

Valid retained CoreMark evidence:

- `coremark_syncbram_word_dcache_4k_param_rc2048.summary.txt`
- `coremark_syncbram_word_dcache_8k_rc2048.summary.txt`

Both retained runs report `crcfinal=0xfcaf`, `acceptance_pass=yes`, and `strict_eembc_10s_compliant=no` because they are short engineering runs.
