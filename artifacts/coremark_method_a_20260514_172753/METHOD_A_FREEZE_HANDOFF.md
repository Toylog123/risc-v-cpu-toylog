# Method A Sync BRAM Freeze Handoff

Updated: `2026-05-14 17:45`

## Scope

This freeze captures the first clean Method A evidence path where the CoreMark
program is compiled into a ROM/RAM image and embedded into the PYNQ-Z2 bitstream.
The CPU then boots from FPGA Block RAM, matching the intended "program burned
into FPGA" validation style.

## Branch

- Worktree: `D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508`
- Branch: `opt/coremark8-hw-20260512`

## What Changed

- Fixed synchronous instruction memory redirect behavior by advancing `pc_r` to
  `redirect_target + 4` after issuing the redirect target request. This prevents
  the same redirected instruction from being fetched and executed twice.
- Added fetch epoch filtering for stale synchronous IMEM responses.
- Added conservative MEM/WB load-use hazard coverage when fast load-use
  forwarding is disabled.
- Hardened CoreMark result parsing with expected CoreMark size, iteration count,
  CRC fields, and explicit `acceptance_pass` status.
- Extended the FPGA-like CoreMark batch flow so target extension generics are
  passed into the testbench consistently.

## Frozen Evidence

### Simulation

- Command:

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32
YH_rv_cpu\scripts\run_coremark_fpga.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 10 2000 100000000UL 5000000 artifacts\coremark8_hw_20260512\logs\h54_fpga_sync_perf2k_full_cm10_scriptpass_20260514.summary.txt 0
```

- Summary:
  `artifacts/coremark8_hw_20260512/logs/h54_fpga_sync_perf2k_full_cm10_scriptpass_20260514.summary.txt`
- Log:
  `artifacts/coremark8_hw_20260512/logs/h54_fpga_sync_perf2k_full_cm10_scriptpass_20260514.log`

Key values:

| Item | Value |
|---|---:|
| CoreMark Size | `666` |
| Iterations | `10` |
| Total ticks | `2661323` |
| Completion cycles | `2711356` |
| seedcrc | `0xe9f5` |
| crcfinal | `0xfcaf` |
| acceptance_pass | `yes` |
| CoreMark/MHz | `3.757530` |

### Bitstream

- Build command:

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32
YH_rv_cpu\scripts\build_pynq_z2_coremark_method_a.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 10 2000 100000000UL
```

- Artifact directory:
  `artifacts/coremark_method_a_20260514_172753`
- Bitstream:
  `artifacts/coremark_method_a_20260514_172753/YH_rv_cpu_pynq_z2_method_a_coremark_20260514_172753.bit`
- Vivado convenience copy:
  `vivado_program/coremark_method_a_syncbram_20260514/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit`
- Bitstream SHA256:
  `51691CD0074722C6ADF642584FB86A5BF066E3F44B4B499A639C57397DBF4B34`

Implementation results:

| Item | Value |
|---|---:|
| Slice LUTs | `5963` |
| Slice Registers | `2645` |
| Block RAM Tile | `32` |
| DSPs | `15` |
| WNS | `+0.120 ns` |
| WHS | `+0.050 ns` |

Vivado reported `All user specified timing constraints are met`.

## Board Demo Notes

1. Open Vivado Hardware Manager.
2. Program `xc7z020_1` with:
   `vivado_program/coremark_method_a_syncbram_20260514/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit`.
3. Open UART at `115200 8N1`.
4. Expected text is the CoreMark report stream, including:
   `2K performance run parameters for coremark`, `CoreMark Size : 666`,
   `Total ticks : 2661323`, `seedcrc : 0xe9f5`, and `[0]crcfinal : 0xfcaf`.

## Honesty Boundary

- This synchronous Method A path is the board-oriented evidence path and scores
  `3.757530 CoreMark/MHz` in FPGA-like simulation.
- Earlier async/profile exploration artifacts reached higher CoreMark numbers,
  but those are not the same synchronous Block RAM Method A evidence path.
- The short FPGA-style run is useful for competition reproducibility. It is not
  a strict EEMBC-certified 10-second result.
