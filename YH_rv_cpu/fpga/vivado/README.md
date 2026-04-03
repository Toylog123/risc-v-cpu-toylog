# YH_rv_cpu Nexys A7-100T FPGA Flow

This directory contains the frozen pre-board Vivado flow for `YH_rv_cpu`.
It keeps the port naming and timing scaffolding stable now, while leaving
the final board pinout to be filled in once the physical board arrives.

## Current Baseline

- The frozen bring-up target is `50 MHz`.
- `project` generates only the Vivado project skeleton under repo-root `project/`.
- `synth50` and `impl50` are the pre-board baseline modes.
- `synth100` and `impl100` are retained as 100 MHz reference modes for comparison.
- The Tcl flow now writes synthesis and implementation reports plus a final bitstream in `project/`.

## Supported Modes

From `YH_rv_cpu\scripts\build_vivado_project.bat`:

- `project` - create the Vivado project skeleton only.
- `synth` - run synthesis with the default clock override.
- `synth50` - run synthesis at 20.000 ns, the frozen 50 MHz baseline.
- `impl` - run implementation with the default clock override.
- `impl50` - run implementation at 20.000 ns, the frozen 50 MHz baseline.
- `synth100` - run synthesis at 10.000 ns, the 100 MHz reference.
- `impl100` - run implementation at 10.000 ns, the 100 MHz reference.

`open_vivado_project.bat` always opens the project skeleton. It will create
the skeleton first if the local `project/` directory does not exist.

## What Is Frozen

- Top-level port names are fixed by `YH_rv_cpu_fpga_top`.
- The clock scaffold is fixed at `CLK100MHZ` in the Tcl-generated clock constraint.
- The frozen XDC already carries the official Digilent pin map for
  `CLK100MHZ`, `cpu_resetn`, `uart_txd_in`, `uart_rxd_out`, and `led[3:0]`.
- The pre-board flow is intentionally centered on `synth50` and `impl50`.

## What Still Blocks Final Board Closure

- The actual Nexys A7-100T board must be available.
- UART wiring must be verified on the actual board.
- LED mapping must be verified on the actual board.
- A full serial boot log and LED evidence capture are still required.

## Generated Artifacts

Implementation mode writes these files into `project/`:

- `YH_rv_cpu_nexys_a7_100_<clock>.bit`
- `YH_rv_cpu_nexys_a7_100_<clock>_impl.dcp`
- `YH_rv_cpu_nexys_a7_100_<clock>_synth.dcp`
- `reports/clk_<clock>ns/*.rpt`

For the frozen 50 MHz baseline, `<clock>` is `20p000`.

## Quick Start

```bat
YH_rv_cpu\scripts\build_vivado_project.bat project
YH_rv_cpu\scripts\build_vivado_project.bat synth50
YH_rv_cpu\scripts\build_vivado_project.bat impl50
YH_rv_cpu\scripts\open_vivado_project.bat
```

## Bring-Up Expectation

Do not treat the flow as board-complete until the checklist in
`YH_rv_cpu\doc\fpga_bringup_checklist.md` is finished, including:

- bitstream generation
- serial console capture
- LED observation
- screenshot or video evidence

## Frozen Snapshot (2026-04-03)

- Retained FPGA-default top-level parameters in
  `src/YH_rv_cpu_fpga_top.v` are now `IMEM_OUTPUT_REG=0` and
  `DMEM_OUTPUT_REG=0`.
- Fresh `impl50` on this retained configuration reports:
  `2555 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS = +5.822ns`,
  `WHS = +0.057ns`.
- A fast FPGA-like CoreMark tuning entry now exists at
  `YH_rv_cpu\scripts\run_coremark_fpga.bat`.
- Its default no-extra-args probe corresponds to:
  `rv32 / 1 iteration / data_size=400 / timer_hz=100000000UL / max_cycles=20000000 / exec_mask=1`.
- Fresh quick-probe result on the retained configuration:
  `156442` completion cycles, `CoreMark/MHz = 7.728811`.
- Remaining closure gap is unchanged:
  final board I/O delay constraints, UART/LED evidence, and real board bring-up
  still depend on the physical Nexys A7-100T arriving.
