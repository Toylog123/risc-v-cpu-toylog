# strict50 impl220 bitstream evidence 2026-07-02

This directory contains the board-facing bitstream generated from the frozen
`impl220` routed checkpoint.

Reportable status:

`impl220 bitstream generated from the frozen routed DCP; PROGRAM_OK, board UART, and video evidence are still pending.`

Key files:

- `YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit`
- `bitstream_manifest.md`
- `SHA256SUMS.txt`
- `vivado_write_bitstream_from_impl220.log`
- `vivado_write_bitstream_from_impl220.jou`
- `write_bitstream_stdout.log`
- `bitstream_from_dcp_drc.rpt`
- `bitstream_from_dcp_timing_summary.rpt`
- `bitstream_from_dcp_utilization.rpt`
- `bitstream_from_dcp_route_status.rpt`

Important values:

- Bitstream SHA256:
  `13DD28472DBEF194E57B9C4D217CD5E886F34234CE17746E4F47854401AE6DBD`
- Timing after reopening DCP:
  WNS +0.056 ns / WHS +0.121 ns.
- Utilization after reopening DCP:
  9965 LUT / 6520 FF / 32 BRAM Tile / 8 DSP.
- Bitgen log:
  `Bitgen Completed Successfully`; pre-bitstream DRC finished with 0 errors.

This evidence does not make `impl220` board-proven. Board proof still requires
PROGRAM_OK, raw board UART, and video evidence tied to this exact bitstream.
