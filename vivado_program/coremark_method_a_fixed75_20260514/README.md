# PYNQ-Z2 Method A CoreMark Bitstream

Date: 2026-05-14

This directory is an English-path copy for Vivado Hardware Manager. Use this bitstream when recording the Method A demonstration where the CoreMark firmware image is embedded into the FPGA bitstream.

## Files

- `YH_rv_cpu_pynq_z2_method_a_fixed75_20260514.bit`
- `reports/impl_utilization.rpt`
- `reports/impl_timing_summary.rpt`
- `reports/synth_utilization.rpt`
- `reports/synth_timing_summary.rpt`

## Vivado Manual Programming

1. Open Vivado Hardware Manager.
2. Open target and select `xc7z020_1`.
3. Program device with:

```text
vivado_program/coremark_method_a_fixed75_20260514/YH_rv_cpu_pynq_z2_method_a_fixed75_20260514.bit
```

4. Keep a serial terminal open on the PL UART before programming if the full boot banner needs to be recorded.

UART setting: `COM7 115200 8N1` by default. Adjust the COM port to match the CP2102 adapter on the host PC.

## Scripted Programming

From the worktree root:

```powershell
.\YH_rv_cpu\scripts\program_pynq_z2_method_a_fixed75.bat
```

For UART capture plus programming:

```powershell
.\YH_rv_cpu\scripts\demo_method_a_program_and_capture.bat COM7
```
