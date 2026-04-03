# FPGA Bring-Up Checklist

Scope: `YH_rv_cpu` Phase B pre-board closure on the frozen `50 MHz` path.

Use this checklist only for the Nexys A7-100T flow in
`fpga/vivado/README.md`. Do not mark the final board items complete until
the physical board is present and the real XDC has been applied.

## 1. Freeze Confirmation

- [ ] Confirm the working baseline is `impl50`, not `impl100`.
- [ ] Confirm the frozen clock override is `20.000 ns`.
- [ ] Confirm the project skeleton exists under repo-root `project/`.
- [ ] Confirm the frozen XDC matches the official Digilent Master XDC for the
      used ports.

## 2. Bitstream Artifact

- [ ] Run `YH_rv_cpu\scripts\build_vivado_project.bat impl50`.
- [ ] Confirm Vivado finishes synthesis and implementation without errors.
- [ ] Confirm the bitstream is written to `project\YH_rv_cpu_nexys_a7_100_20p000.bit`.
- [ ] Confirm the implementation reports are written under `project\reports\clk_20p000ns\`.
- [ ] Capture a screenshot of the final Vivado summary or reports window.

## 3. Serial Console

- [ ] Flash the `impl50` bitstream onto the board.
- [ ] Open the target serial port at the agreed baud rate.
- [ ] Confirm the boot banner appears on UART.
- [ ] Confirm the expected program output or smoke-test log appears on UART.
- [ ] Capture a screenshot or terminal log showing the full serial session.

## 4. LED Observation

- [ ] Confirm the LED mapping from the final board XDC.
- [ ] Verify the reset state drives the expected LED baseline.
- [ ] Verify the runtime toggles or status pattern on the LEDs.
- [ ] Capture a photo or video clip showing the LED behavior.

## 5. Evidence Package

- [ ] Save the bitstream path, synthesis report path, and implementation report path.
- [ ] Save at least one screenshot of Vivado results.
- [ ] Save at least one screenshot of the serial console.
- [ ] Save at least one short video or photo sequence of the LEDs.
- [ ] Record the board serial number and board revision, if available.

## 6. Board-Not-Available Blockers

- [ ] The board is physically present.
- [ ] The frozen project XDC has been checked against the Digilent master XDC.
- [ ] UART pinout has been verified against the actual board.
- [ ] LED pinout has been verified against the actual board.
- [ ] End-to-end bring-up evidence has been collected from real hardware.

If any item in this section is unchecked, the bring-up is still blocked.
