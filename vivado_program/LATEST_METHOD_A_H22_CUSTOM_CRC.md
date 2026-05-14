# Latest Method A H22 Custom CRC Bitstream

Date: 2026-05-14

Use this English-path copy when selecting a bitstream manually in Vivado:

```text
vivado_program/YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit
```

Equivalent archived directory:

```text
vivado_program/coremark_method_a_h22_custom_crc_20260514/
```

This image embeds the H22 CoreMark firmware directly in FPGA Block RAM. It enables the custom CRC hardware instruction path and does not enable `YH_COREMARK_SKIP_ZERO_STATE_RERUN`.

Expected evidence for this artifact:

- CoreMark/MHz: `6.234161`
- Firmware summary: `artifacts/coremark8_hw_20260512/logs/h22_custom_crc_only_no_skip_20260514.summary.txt`
- FPGA implementation: `5830 LUT / 2503 FF / 32 BRAM / 15 DSP`
- Timing: `WNS +0.042 ns / WHS +0.040 ns`
- Board: `Xilinx PYNQ-Z2`, part `xc7z020clg400-1`, CPU clock `50 MHz`

Boundary: this is an ISA/hardware co-design result. It is cleaner than the historical fixed75 artifact because it does not skip benchmark work, but it is still not a pure RTL-only comparison against an unchanged benchmark image.
