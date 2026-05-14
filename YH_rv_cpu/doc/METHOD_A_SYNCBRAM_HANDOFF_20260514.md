# Method A Sync BRAM Handoff

Updated: `2026-05-14`

## Current Freeze

- Worktree: `D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508`
- Branch: `opt/coremark8-hw-20260512`
- Main artifact: `artifacts/coremark_method_a_20260514_172753`
- Vivado programming package: `vivado_program/coremark_method_a_syncbram_20260514`

This freeze is the board-oriented Method A path: CoreMark is compiled into a
ROM/RAM image, the image is embedded into the bitstream, and the CPU boots from
FPGA Block RAM.

## Results To Cite

| Item | Value |
|---|---:|
| CoreMark/MHz | `3.757530` |
| CoreMark Size | `666` |
| Iterations | `10` |
| Total ticks | `2661323` |
| Completion cycles | `2711356` |
| seedcrc | `0xe9f5` |
| crcfinal | `0xfcaf` |
| LUT | `5963` |
| FF | `2645` |
| BRAM | `32` |
| DSP | `15` |
| WNS | `+0.120 ns` |
| WHS | `+0.050 ns` |

The run is competition-reproducible short evidence, not a strict EEMBC
10-second certification run.

## Key Files

- Bitstream:
  `vivado_program/coremark_method_a_syncbram_20260514/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit`
- Root quick-copy:
  `vivado_program/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit`
- Simulation summary:
  `artifacts/coremark8_hw_20260512/logs/h54_fpga_sync_perf2k_full_cm10_scriptpass_20260514.summary.txt`
- Simulation log:
  `artifacts/coremark8_hw_20260512/logs/h54_fpga_sync_perf2k_full_cm10_scriptpass_20260514.log`
- FPGA reports:
  `vivado_program/coremark_method_a_syncbram_20260514/reports/`

## Next Work

1. If the goal is a higher board-facing score, optimize the synchronous
   ROM/RAM Method A path directly instead of citing async/profile scores.
2. Keep the Method A parser gate enabled: expected CoreMark size, iterations,
   CRC fields, and `acceptance_pass=yes`.
3. If a new bitstream is generated, create a new dated English package instead
   of overwriting this freeze.
