# H22 Custom CRC Hardware ISA Path

Date: 2026-05-14

## Purpose

H20 showed that the historical `7.50 CoreMark/MHz` image mixes custom CRC acceleration with `YH_COREMARK_SKIP_ZERO_STATE_RERUN`. H22 keeps only the custom CRC hardware instruction path and does not enable the zero-state skip macro. This makes the result easier to defend as an ISA/hardware acceleration experiment.

## Command

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32
YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 10 2000 100000000UL 220000000 artifacts\coremark8_hw_20260512\logs\h22_custom_crc_only_no_skip_20260514.summary.txt
```

## Result

- CoreMark/MHz: `6.234161`
- Raw ticks: `1604065`
- Completion cycles: `1638280`
- Runtime mode: short reproducible run, not strict 10-second EEMBC
- Raw log: `logs/h22_custom_crc_only_no_skip_20260514.log`
- Summary: `logs/h22_custom_crc_only_no_skip_20260514.summary.txt`
- Firmware archive: `logs/h22_custom_crc_only_no_skip_20260514_firmware/`

## Interpretation

Compared with the ordinary zicond rebuild (`5.070698 CoreMark/MHz`), custom CRC hardware instructions improve the short-run score by about `22.95%`:

```text
(6.234161 - 5.070698) / 5.070698 = 22.95%
```

This is not a pure RTL-only comparison because the benchmark image is rebuilt to call the custom CRC instructions. It is a hardware ISA acceleration path and must be reported with that boundary. Unlike the historical 7.50 path, H22 does not use `YH_COREMARK_SKIP_ZERO_STATE_RERUN`.

## Next Work

- Method A bitstream has been generated under `../coremark_method_a_h22_custom_crc_20260514/`.
- Vivado-friendly English-path copy is under `../../vivado_program/coremark_method_a_h22_custom_crc_20260514/`.
- FPGA implementation result: `5830 LUT / 2503 FF / 32 BRAM / 15 DSP`, `WNS +0.042 ns / WHS +0.040 ns`.
- If pursuing higher scores, keep any additional benchmark-image changes separately labeled as ISA/software co-design, not hardware-only RTL.
