# Board Attempt Log

Date: 2026-05-14

This note records the local host state when attempting to program and observe the Method A bitstream.

## Vivado Programming Attempt

Command:

```powershell
.\YH_rv_cpu\scripts\program_pynq_z2_method_a_fixed75.bat
```

Result: not programmed in this attempt. Vivado started `hw_server` and `cs_server`, but no hardware target was visible to command-line Hardware Manager after five refresh attempts.

Evidence:

- `board_logs/program_method_a_fixed75.log`
- `board_logs/program_method_a_fixed75.jou`

Key log line:

```text
ERROR: no hardware targets detected
```

## UART Probe

Command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\YH_rv_cpu\scripts\capture_uart.ps1 -Port COM7 -Seconds 3
```

Result: UART capture did not start. Windows listed the CP2102 adapter as `Unknown Silicon Labs CP210x USB to UART Bridge (COM7)`, and .NET `SerialPort.Open()` reported that `COM7` did not exist as an openable serial port.

Evidence:

- `board_logs/uart_port_list_20260514.txt`
- `board_logs/uart_probe_COM7_20260514.console.txt`

## Interpretation

The Method A bitstream and scripts are prepared, but this host-side board attempt did not reach `PROGRAM_OK` because the current USB/JTAG and CP2102 devices were not enumerated as usable targets by the command-line tools. This is an environment/connection state, not a benchmark result.

When the board is physically ready again, use:

```powershell
.\YH_rv_cpu\scripts\watch_uart_live.bat COM7
.\YH_rv_cpu\scripts\program_pynq_z2_method_a_fixed75.bat
```

or:

```powershell
.\YH_rv_cpu\scripts\demo_method_a_program_and_capture.bat COM7
```
