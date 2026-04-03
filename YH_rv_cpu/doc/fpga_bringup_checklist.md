# FPGA Bring-Up Checklist

Scope: `YH_rv_cpu` Phase B pre-board closure on the frozen `50 MHz` path.

Use this checklist only for the Nexys A7-100T flow in
`fpga/vivado/README.md`. Do not mark the final board items complete until
the physical board is present and the real XDC has been applied.

## 1. Freeze Confirmation

- [ ] Confirm the working baseline is `impl50`, not `impl100`.
- [ ] Confirm the frozen clock override is `20.000 ns`.
- [ ] Confirm the project skeleton exists under repo-root `project/`.
- [ ] Confirm the frozen XDC pin map matches the official Digilent Master XDC
      for the used ports.
- [ ] Confirm the current XDC is still pre-board only: pin map is frozen, but
      board-grade I/O delay constraints are not complete.

## 2. Firmware Image Freeze

- [ ] Decide which ROM image the `impl50` bitstream should boot.
- [ ] If the target is the default boot-banner demo, run `YH_rv_cpu\scripts\build_firmware.bat`.
- [ ] If the target is the default boot-banner demo, copy:
      `YH_rv_cpu\build\sw\YH_rv_cpu_demo.hex` -> `YH_rv_cpu\build\tests\riscv-tests\current.hex`
- [ ] If the target is the default boot-banner demo, copy:
      `YH_rv_cpu\build\sw\YH_rv_cpu_demo.mem32.hex` -> `YH_rv_cpu\build\tests\riscv-tests\current.mem32.hex`
- [ ] If the target is not the demo image, record which command last staged
      `current.hex` / `current.mem32.hex`.

## 3. Bitstream Artifact

- [ ] Run `YH_rv_cpu\scripts\build_vivado_project.bat impl50`.
- [ ] Confirm Vivado finishes synthesis and implementation without errors.
- [ ] Confirm the bitstream is written to `project\YH_rv_cpu_nexys_a7_100_20p000.bit`.
- [ ] Confirm the implementation reports are written under `project\reports\clk_20p000ns\`.
- [ ] Confirm the frozen timing summary is `project\reports\clk_20p000ns\impl_timing_summary.rpt`.
- [ ] Confirm the frozen utilization summary is `project\reports\clk_20p000ns\impl_utilization.rpt`.
- [ ] Capture a screenshot of the final Vivado summary or reports window.

## 4. Serial Console

- [ ] Flash the `impl50` bitstream onto the board.
- [ ] Open the target serial port at `115200 8N1`.
- [ ] Confirm the boot banner appears on UART.
- [ ] Confirm the expected program output or smoke-test log appears on UART.
- [ ] Capture a screenshot or terminal log showing the full serial session.

## 5. LED Observation

- [ ] Confirm the LED mapping from the final board XDC.
- [ ] Verify the reset state drives the expected LED baseline.
- [ ] Verify the runtime toggles or status pattern on the LEDs.
- [ ] Capture a photo or video clip showing the LED behavior.

## 6. Evidence Package

- [ ] Save the bitstream path, synthesis report path, and implementation report path.
- [ ] Save all real-board evidence under `YH_rv_cpu\doc\fpga_bringup_evidence\<YYYY-MM-DD>\`.
- [ ] Save at least one screenshot of Vivado results.
- [ ] Save at least one screenshot of the serial console.
- [ ] Save at least one short video or photo sequence of the LEDs.
- [ ] Record the board serial number and board revision, if available.

## 7. Board-Not-Available Blockers

- [ ] The board is physically present.
- [ ] The frozen project XDC has been checked against the Digilent master XDC.
- [ ] UART pinout has been verified against the actual board.
- [ ] LED pinout has been verified against the actual board.
- [ ] End-to-end bring-up evidence has been collected from real hardware.

If any item in this section is unchecked, the bring-up is still blocked.
