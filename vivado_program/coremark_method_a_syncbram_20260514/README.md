# Method A Sync BRAM PYNQ-Z2 Bitstream

Updated: `2026-05-14`

This directory is the English-path convenience package for manual Vivado
programming and video recording.

## Program This Bitstream

```text
vivado_program/coremark_method_a_syncbram_20260514/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit
```

Root quick-copy:

```text
vivado_program/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit
```

## Configuration

- Board: `Xilinx PYNQ-Z2`
- Part: `xc7z020clg400-1`
- CPU clock: `50 MHz`
- UART: Pmod B PL UART, `115200 8N1`
- Target: `rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller`
- CoreMark iterations: `10`
- CoreMark data size: `2000`

## Evidence

- Logs: `logs/`
- Vivado reports: `reports/`
- Firmware images: `firmware/`
- CoreMark/MHz for sync BRAM Method A simulation: `3.757530`
- CRC evidence: `seedcrc=0xe9f5`, `crcfinal=0xfcaf`
- Resources: `5963 LUT`, `2645 FF`, `32 BRAM`, `15 DSP`
- Timing: `WNS +0.120 ns`, `WHS +0.050 ns`
- Bitstream SHA256:
  `51691CD0074722C6ADF642584FB86A5BF066E3F44B4B499A639C57397DBF4B34`

This package is intended for the board-facing Method A demo. Higher historical
exploration scores should be kept separate from this frozen evidence path.
