# strict50 impl220 bitstream manifest 2026-07-02

This directory records the bitstream generated from the frozen strict50
`impl220` routed checkpoint. It is board-facing bitstream evidence only; it does
not prove PROGRAM_OK, board UART, or video evidence.

## Identity

| Item | Value |
|---|---|
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Freeze tag | `freeze-strict50-impl220-20260701` |
| Source routed DCP | `../impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/dcp/cpu50_impl.dcp` |
| Source DCP SHA256 | `abd1a9b81c42e1f868d3ab0352c4c1feca54606163cdd250681d1f2ee2cfc243` |
| Bitstream | `YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit` |
| Bitstream SHA256 | `13DD28472DBEF194E57B9C4D217CD5E886F34234CE17746E4F47854401AE6DBD` |
| Vivado | 2025.2 |
| Generated at | 2026-07-02 19:39:30 Asia/Shanghai |

## Result

| Check | Result |
|---|---|
| Bitgen | `Bitgen Completed Successfully` |
| Pre-bitstream DRC | `DRC finished with 0 Errors` |
| DRC report | warnings present, no bitgen-blocking errors |
| Timing after reopening DCP | WNS +0.056 ns / WHS +0.121 ns |
| Timing status | `All user specified timing constraints are met.` |
| Utilization after reopening DCP | 9965 LUT / 6520 FF / 32 BRAM Tile / 8 DSP |
| Route status | 0 routing errors |

## Files

| File | Purpose |
|---|---|
| `YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit` | Board-facing bitstream |
| `write_bitstream_from_impl220.tcl` | Reproduction script from routed DCP |
| `vivado_write_bitstream_from_impl220.log` | Vivado batch log |
| `vivado_write_bitstream_from_impl220.jou` | Vivado batch journal |
| `write_bitstream_stdout.log` | Captured stdout |
| `bitstream_from_dcp_drc.rpt` | DRC report |
| `bitstream_from_dcp_timing_summary.rpt` | Timing summary after reopening DCP |
| `bitstream_from_dcp_utilization.rpt` | Utilization after reopening DCP |
| `bitstream_from_dcp_route_status.rpt` | Route status after reopening DCP |
| `SHA256SUMS.txt` | Checksums |

## Boundary

- This is not PROGRAM_OK evidence.
- This is not board UART evidence.
- This is not board video evidence.
- The candidate must still not be described as board-proven until those
  evidence items are collected and audited.
