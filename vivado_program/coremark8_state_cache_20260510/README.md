# CoreMark 8+ PYNQ-Z2 Bitstream - 2026-05-10

This directory archives the PYNQ-Z2 implementation for the CoreMark 8+ state-cache candidate.

## Bitstream

- `YH_rv_cpu_pynq_z2_coremark8_state_cache_cpu50_20260510.bit`
- Quick Vivado GUI copy: `vivado_program/YH_rv_cpu_pynq_z2_coremark8_state_cache_cpu50_20260510.bit`

## Configuration

- Board: Xilinx PYNQ-Z2
- Device: `xc7z020clg400-1`
- CPU clock: 50.0 MHz
- ROM/RAM: 64 KiB ROM, 64 KiB RAM
- ISA path: RV32I + Zmmul + Zba/Zbb/Zbs + Zicond + XThead memidx/cond-move + ID branch forwarding
- Zbc: disabled

## Results

- CoreMark reference: `9.099315 CoreMark/MHz` from `artifacts/coremark8_20260510/logs/state_cache_cm100.summary.txt`
- Resource: 5435 LUT / 2426 FF / 32 RAMB36 / 15 DSP
- Timing: WNS +0.147 ns / WHS +0.086 ns
- Power estimate: 0.296 W total / 0.186 W dynamic / 0.110 W static

## Evidence

- Reports: `reports/`
- Vivado implementation log: `logs/vivado_pynq_z2_coremark8_state_cache_impl_20260510.log`
- Power report: `power/impl_power_default_activity.rpt`
