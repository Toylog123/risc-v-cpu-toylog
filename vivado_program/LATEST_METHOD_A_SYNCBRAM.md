# Latest Method A Sync BRAM Bitstream

Updated: `2026-05-14`

Use this package for the board-oriented Method A demonstration where the
CoreMark program image is embedded into the FPGA bitstream.

```text
vivado_program/coremark_method_a_syncbram_20260514/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit
```

Root quick-copy:

```text
vivado_program/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit
```

Summary:

- `3.757530 CoreMark/MHz` on FPGA-like synchronous ROM/RAM simulation
- `CoreMark Size=666`, `Iterations=10`, `Total ticks=2661323`
- `seedcrc=0xe9f5`, `crcfinal=0xfcaf`, `acceptance_pass=yes`
- PYNQ-Z2 implementation: `5963 LUT`, `2645 FF`, `32 BRAM`, `15 DSP`
- Timing: `WNS +0.120 ns`, `WHS +0.050 ns`
- Bitstream SHA256:
  `51691CD0074722C6ADF642584FB86A5BF066E3F44B4B499A639C57397DBF4B34`

Detailed handoff:

```text
artifacts/coremark_method_a_20260514_172753/METHOD_A_FREEZE_HANDOFF.md
```
