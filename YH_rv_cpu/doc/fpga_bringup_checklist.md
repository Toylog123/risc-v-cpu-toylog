# FPGA Bring-Up Checklist

Scope: `YH_rv_cpu` pre-board closure on the frozen `50 MHz` path.

Status note (`2026-04-08`):

- pre-board flow is frozen and can still be cited
- real-board closure is still externally blocked by board availability
- current execution priority is non-board verification and document closure
- do not mark the board-only sections complete until the physical board is
  present and the real XDC constraints are ready

## 1. Freeze Confirmation

- [ ] Confirm the working baseline is `impl50`, not `impl100`
- [ ] Confirm the frozen clock override is `20.000 ns`
- [ ] Confirm the project skeleton exists under repo-root `project/`
- [ ] Confirm the frozen XDC pin map still matches the official Digilent Master XDC for the used ports
- [ ] Confirm the current XDC is still pre-board only: pin map frozen, board-grade I/O delay constraints not complete
- [ ] Confirm the frozen implementation result still references:
  - `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`
  - `WNS = +5.599ns`
  - `WHS = +0.025ns`

## 2. Firmware Image Freeze

- [ ] Confirm the default `impl50` payload remains the boot-banner demo
- [ ] Confirm `YH_rv_cpu\scripts\build_vivado_project.bat impl50` reports `YH_rv_cpu_demo.hex` / `YH_rv_cpu_demo.mem32.hex` as the ROM init files
- [ ] If the demo artifacts are missing, run `YH_rv_cpu\scripts\build_firmware.bat`
- [ ] If the target is not the demo image, set explicit `ROM_INIT_HEX_OVERRIDE` and `ROM_INIT_MEM32_HEX_OVERRIDE`

## 3. Bitstream And Report Artifacts

- [ ] Run `YH_rv_cpu\scripts\build_vivado_project.bat impl50`
- [ ] Confirm Vivado finishes synthesis and implementation without errors
- [ ] Confirm the bitstream is written to `project\YH_rv_cpu_nexys_a7_100_20p000.bit`
- [ ] Confirm the implementation reports are written under `project\reports\clk_20p000ns\`
- [ ] Confirm the frozen timing summary is `project\reports\clk_20p000ns\impl_timing_summary.rpt`
- [ ] Confirm the frozen utilization summary is `project\reports\clk_20p000ns\impl_utilization.rpt`
- [ ] Capture a screenshot of the final Vivado summary or reports window if a new pre-board refresh is performed

## 4. Real-Board Tasks (Blocked / Deferred)

- [ ] Flash the `impl50` bitstream onto the board
- [ ] Open the target serial port at `115200 8N1`
- [ ] Confirm the boot banner appears on UART
- [ ] Confirm the expected program output or smoke-test log appears on UART
- [ ] Confirm the LED mapping from the final board XDC
- [ ] Verify runtime LED behavior

Do not spend active closure effort here until the board is physically present
and the non-board validation line is closed.

## 5. Evidence Package (Board-Arrival Phase)

- [ ] Save the bitstream path, synthesis report path, and implementation report path
- [ ] Save all real-board evidence under `YH_rv_cpu\doc\fpga_bringup_evidence\<YYYY-MM-DD>\`
- [ ] Save at least one screenshot of Vivado results
- [ ] Save at least one screenshot of the serial console
- [ ] Save at least one short video or photo sequence of the LEDs
- [ ] Record the board serial number and board revision, if available

## 6. Board-Not-Available Blockers

- [ ] The board is physically present
- [ ] UART pinout has been verified against the actual board
- [ ] LED pinout has been verified against the actual board
- [ ] Final board-grade I/O delay constraints have been applied
- [ ] End-to-end bring-up evidence has been collected from real hardware

If any item in this section is unchecked, the bring-up is still blocked and
must not be described as complete.
