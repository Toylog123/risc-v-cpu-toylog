# CoreMark Method A Validation

Date: 2026-05-14

This artifact follows the Method A validation flow: compile a CoreMark firmware image, initialize the FPGA on-chip ROM/RAM image with that firmware, program the PYNQ-Z2 bitstream, and observe the CPU output through the PL UART.

## Artifact Paths

- Bitstream: `artifacts/coremark_method_a_fixed75_20260514/YH_rv_cpu_pynq_z2_method_a_fixed75_20260514.bit`
- Vivado-friendly copy: `vivado_program/YH_rv_cpu_pynq_z2_method_a_fixed75_20260514.bit`
- Firmware byte hex: `artifacts/coremark_method_a_fixed75_20260514/firmware/verify_coremark75_nozbc_zicond_cm10_corrected_20260510.hex`
- Firmware 32-bit memory hex: `artifacts/coremark_method_a_fixed75_20260514/firmware/verify_coremark75_nozbc_zicond_cm10_corrected_20260510.mem32.hex`
- Raw simulation log: `artifacts/coremark_method_a_fixed75_20260514/fixedhex_final_h13_method_a_image_cm10.log`
- Parsed simulation summary: `artifacts/coremark_method_a_fixed75_20260514/fixedhex_final_h13_method_a_image_cm10.summary.txt`
- Vivado reports: `artifacts/coremark_method_a_fixed75_20260514/reports/`

## Hardware Configuration

- Board: `Xilinx PYNQ-Z2`
- Part: `xc7z020clg400-1`
- CPU clock: `50 MHz`
- ISA configuration: `RV32I + Zmmul + Zba/Zbb/Zbs + XThead memidx/condmov`, with `Zbc/Zicond/Zbkb` disabled for the frozen Method A bitstream.
- Program memory: CoreMark image embedded in on-chip ROM through `ROM_INIT_HEX` / `ROM_INIT_MEM32_HEX`.
- RAM base: `0x00010000`
- UART: PL soft UART on Pmod B, `115200 8N1`

## Manual Demo Steps

Open two PowerShell terminals from the worktree root.

Terminal 1, start the UART monitor before programming:

```powershell
.\YH_rv_cpu\scripts\watch_uart_live.bat COM7
```

Terminal 2, program the Method A bitstream:

```powershell
.\YH_rv_cpu\scripts\program_pynq_z2_method_a_fixed75.bat
```

Expected Vivado console evidence:

```text
PROGRAM_OK: xc7z020_1 ...
PROGRAM_OK
```

Expected UART evidence:

```text
CoreMark Size    : 666
Total ticks      : ...
Correct operation validated.
```

The exact UART content depends on where the capture starts. For a complete boot banner, keep the UART monitor open before pressing Program Device or running the programming script.

## One-Command Capture

For repeatable evidence capture, use:

```powershell
.\YH_rv_cpu\scripts\demo_method_a_program_and_capture.bat COM7
```

This command opens a UART capture window first, waits two seconds, then programs the Method A bitstream. The capture log is written under:

```text
artifacts/coremark_method_a_fixed75_20260514/board_logs/
```

## Reporting Boundary

The fixed simulation image reports `7.502641 CoreMark/MHz` from raw ticks. This is a short reproducible run used for competition engineering evidence and board demonstration. It is not an official EEMBC-certified result because it does not meet the strict 10-second runtime rule.

This fixed image is also not a pure RTL-only CoreMark result. It comes from the historical ISA/software co-design path that uses custom CRC instructions and `YH_COREMARK_SKIP_ZERO_STATE_RERUN`. The rebuild audit is documented in `../coremark8_hw_20260512/H20_COREMARK_REBUILD_AUDIT.md`. Any formal use of this image must disclose that boundary.

The Method A bitstream proves that the same fixed firmware image can be embedded into the FPGA fabric and started from on-chip memory after configuration. Resource and timing evidence for this bitstream is:

- `5791 LUT`
- `2503 FF`
- `32 BRAM`
- `15 DSP`
- `WNS +0.095 ns`
- `WHS +0.038 ns`

## Current Host Board Attempt

`BOARD_ATTEMPT_20260514.md` records a local programming attempt where command-line Vivado did not see a JTAG hardware target and `COM7` was listed by Windows but not openable by .NET `SerialPort`. This is kept as environment evidence. It does not invalidate the prepared Method A bitstream or simulation/Vivado reports, but a fresh board-side `PROGRAM_OK` plus UART capture is still required for a final live demonstration recording.
