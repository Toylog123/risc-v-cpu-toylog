# YH_rv_cpu Nexys A7-100T FPGA Flow

This directory contains the frozen pre-board Vivado flow for `YH_rv_cpu`.

Current status (`2026-04-08`):

- the pre-board flow is frozen and still authoritative
- real-board closure is still externally blocked by board availability
- board tasks are intentionally not the active priority until non-board
  verification and documentation closure are finished

## Current Baseline

- The frozen bring-up target is `50 MHz`
- Always invoke `YH_rv_cpu\scripts\build_vivado_project.bat impl50` explicitly
  for the competition-facing baseline
- `project` generates the Vivado project skeleton under repo-root `project/`
- `synth50` and `impl50` are the frozen pre-board modes
- `synth100` and `impl100` remain only as `100 MHz` reference modes
- The Tcl flow writes synthesis reports, implementation reports, and the final
  bitstream into `project/`

## Supported Modes

From `YH_rv_cpu\scripts\build_vivado_project.bat`:

- `project` - create the Vivado project skeleton only
- `synth` - run synthesis with the default clock override
- `synth50` - run synthesis at `20.000 ns`
- `impl` - run implementation with the default clock override
- `impl50` - run implementation at `20.000 ns`
- `synth100` - run synthesis at `10.000 ns`
- `impl100` - run implementation at `10.000 ns`

`open_vivado_project.bat` always opens the project skeleton and creates it
first if the local `project/` directory does not yet exist.

## What Is Frozen

- Top-level port names are fixed by `YH_rv_cpu_fpga_top`
- The clock scaffold is fixed at `CLK100MHZ`
- The current XDC already freezes the Digilent pin map for:
  - `CLK100MHZ`
  - `cpu_resetn`
  - `uart_txd_in`
  - `uart_rxd_out`
  - `led[3:0]`
- The current XDC is a pin-map freeze, not a board-grade signoff freeze
- The pre-board flow is intentionally centered on `synth50` and `impl50`

## Frozen Snapshot

- Retained FPGA-default top-level parameters are:
  - `IMEM_OUTPUT_REG=0`
  - `DMEM_OUTPUT_REG=0`
- Fresh `impl50` reports:
  - `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`
  - `WNS = +5.599ns`
  - `WHS = +0.025ns`
- Fast FPGA-like CoreMark probe:
  - command family: `YH_rv_cpu\scripts\run_coremark_fpga.bat`
  - latest retained result: `156442 cycles`, `7.728811 CoreMark/MHz`
- `impl50` now boots the frozen `YH_rv_cpu_demo` payload by default instead of
  inheriting the last staged `current.hex`

## Generated Artifacts

Implementation mode writes these files into `project/`:

- `YH_rv_cpu_nexys_a7_100_<clock>.bit`
- `YH_rv_cpu_nexys_a7_100_<clock>_impl.dcp`
- `YH_rv_cpu_nexys_a7_100_<clock>_synth.dcp`
- `reports/clk_<clock>ns/*.rpt`

For the frozen `50 MHz` baseline, `<clock>` is `20p000`.

## Firmware Image Staging

`impl50` freezes the default board-demo payload automatically. The build script
uses the following priority when choosing ROM init files:

1. caller-supplied `ROM_INIT_HEX_OVERRIDE` / `ROM_INIT_MEM32_HEX_OVERRIDE`
2. `YH_rv_cpu\build\sw\YH_rv_cpu_demo.hex`
3. `YH_rv_cpu\build\sw\YH_rv_cpu_demo.mem32.hex`
4. fallback to staged `build\tests\riscv-tests\current.*`
5. fallback to `build\tests\riscv-tests\rv32\simple.*`

If the frozen demo artifacts are missing, `build_vivado_project.bat` will call
`build_firmware.bat` automatically before invoking Vivado.

## Quick Start

```bat
YH_rv_cpu\scripts\build_vivado_project.bat project
YH_rv_cpu\scripts\build_vivado_project.bat synth50
YH_rv_cpu\scripts\build_vivado_project.bat impl50
YH_rv_cpu\scripts\open_vivado_project.bat
```

## Board Closure Status

Do not describe the FPGA flow as board-complete until all of the following are
true:

- the checklist in `YH_rv_cpu\doc\fpga_bringup_checklist.md` has been executed
- the physical Nexys A7-100T is present
- UART evidence exists at `115200 8N1`
- LED behavior has been captured
- final board-grade I/O delay constraints have been applied

Until then, the current FPGA state is accurately described as:

- pre-board flow frozen
- bitstream path frozen
- report paths frozen
- real-board closure externally blocked
