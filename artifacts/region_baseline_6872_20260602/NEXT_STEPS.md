# Next Steps From 6872 LUT Baseline

| ID | Task | Priority | Completion Criteria |
|---|---|---|---|
| R01 | Run full implementation for the 6872 baseline | P0 | `impl_utilization.rpt` and `impl_timing_summary.rpt` copied into this package |
| R02 | If full implementation fails timing, reduce decode/control fan-in | P0 | New variant improves WNS or reduces failing endpoints without dropping below CoreMark 5 |
| R03 | Generate bitstream for the selected board-facing variant | P0 | `.bit` copied into this package with matching reports |
| R04 | Add board/UART evidence | P0 | `PROGRAM_OK` and UART output logs copied into this package |
| R05 | Update region-contest technical documents | P1 | Documents use the selected baseline and do not mix in larger exploration points |
| R06 | Optional strict benchmark run | P1 | >=10 second CoreMark evidence if needed for stricter public benchmark reporting |

## Optimization Direction

Use the 6872-LUT point as the comparison baseline for all later work. Useful
next RTL directions are:

- reduce MEM/address-to-ID/EX control fan-in,
- keep DCache512 unless a lower-cache variant can preserve CoreMark above 5,
- avoid coarse IMEM output-register insertion unless compensated by front-end
logic, because the measured CoreMark dropped below the target,
- keep CoreMark core algorithm files unchanged.

