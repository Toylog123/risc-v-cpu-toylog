# Vivado-Friendly Method A H22 Custom CRC Artifact

Date: 2026-05-14

This directory is an English-path copy for manual Vivado programming. It mirrors the archived artifact under:

```text
artifacts/coremark_method_a_h22_custom_crc_20260514/
```

## Bitstream

```text
YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit
```

The bitstream contains the CPU hardware and the H22 CoreMark firmware initialized into FPGA Block RAM. After programming, the CPU starts from the embedded image and prints through the PL soft UART when the Pmod UART wiring is present.

## Measurement

- CoreMark/MHz: `6.234161`
- Raw ticks: `1604065`
- Completion cycles: `1638280`
- Score summary: `artifacts/coremark8_hw_20260512/logs/h22_custom_crc_only_no_skip_20260514.summary.txt`

## FPGA Reports

Reports copied here:

```text
reports/
```

Implementation summary:

- Board: `Xilinx PYNQ-Z2`
- Part: `xc7z020clg400-1`
- CPU clock: `50 MHz`
- Resources: `5830 LUT / 2503 FF / 32 BRAM / 15 DSP`
- Timing: `WNS +0.042 ns / WHS +0.040 ns`

## Boundary

This is an ISA/hardware co-design artifact using custom CRC hardware instructions. It does not use `YH_COREMARK_SKIP_ZERO_STATE_RERUN`. For a pure RTL-only comparison, use the fixed ordinary benchmark image and compare only RTL changes.
