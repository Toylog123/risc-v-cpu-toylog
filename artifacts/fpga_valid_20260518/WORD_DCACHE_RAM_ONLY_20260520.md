# RAM-only word D-cache candidate - 2026-05-20

This node keeps the upstream CoreMark workload unchanged and optimizes only hardware. It adds a small write-through, direct-mapped word D-cache for RAM accesses. MMIO, ROM and XThead pair load/store operations bypass the D-cache and continue to use the existing sync-BRAM path.

## Performance

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Result |
|---|---:|---:|---:|---|
| sync BRAM RC2048 baseline | pending | 4.236988 | pending | previous valid baseline |
| RAM-only word D-cache, RC2048 | pending | 5.425097 | pending | retained CoreMark candidate |

## Technical optimization points

| Optimization | Status | Note |
|---|---|---|
| RAM-only word D-cache | retained | Cacheable window is RAM only; MMIO timer reads are not cached. |
| XThead pair bypass | retained | `th.lwd/th.swd` keep the original pair-memory path to preserve semantics. |
| Store write-through address fix | retained | Store writes now use the current CPU address instead of the previous miss address. |
| Optional `0x` CRC parser | retained | Engineering parser now accepts both `fcaf` and `0xfcaf`; CoreMark source is unchanged. |

## Evidence

- D-cache directed test: `YH_rv_cpu/scripts/run_dcache_word_tb.bat` passed.
- CoreMark log: `artifacts/fpga_valid_20260518/coremark_syncbram_word_dcache_ram_only_rc2048_5m.log`
- CoreMark summary: `artifacts/fpga_valid_20260518/coremark_syncbram_word_dcache_ram_only_rc2048_5m.summary.txt`
- CRC: `0xfcaf`
- Rejected intermediate logs document the bugs fixed during this node:
  - `coremark_syncbram_word_dcache_rc2048.log`
  - `coremark_syncbram_word_dcache_rc2048_5m.log`
  - `coremark_syncbram_word_dcache_storeaddr_fix_rc2048_5m.log`
  - `coremark_syncbram_word_dcache_pair_bypass_rc2048_5m.log`

## Remaining checks

- Run synthesis/implementation to obtain LUT and timing for the D-cache node.
- Run Dhrystone with the same RAM-only D-cache path after the Dhrystone testbench exposes the `DCACHE_EN` parameter.
