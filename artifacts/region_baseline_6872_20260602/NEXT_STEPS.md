# Next Steps After Baseline Cleanup

| ID | Task | Priority | Completion Criteria |
|---|---|---|---|
| R01 | Keep CPU25 accepted baseline clean | P0 | Reports consistently state `6791 LUT / 4.501191 CoreMark/MHz / 25 MHz / WNS +0.291 ns` as the accepted baseline |
| R02 | Reduce MEM/DCache-to-PC control fan-in for a future 50 MHz exact-ROM candidate | P0 | New exact-ROM implementation improves WNS and keeps CoreMark/MHz >= 4.3 |
| R03 | Generate bitstream for the selected board-facing variant | done | CPU25 perf-demo `.bit` exists and timing closes at `WNS +0.291 ns / WHS +0.065 ns` |
| R04 | Add board/UART evidence | P0 | `PROGRAM_OK` and UART output logs copied into this package or linked from `BOARD_EVIDENCE.md` |
| R05 | Update region-contest technical documents | in progress | Documents use CPU25 as accepted baseline and demote 6872/5918/11182 records |
| R06 | Optional strict benchmark run | P1 | >=10 second CoreMark evidence if needed for stricter public benchmark reporting |
| R07 | Add board evidence manifest | P0 | `BOARD_EVIDENCE.md` lists bitstream checksum, PROGRAM_OK, UART log, video path, board, date, and baud rate |
| R08 | Draft final Chinese region narrative | done | `REGION_REPORT_DRAFT_CLEAN_20260609.md` uses the cleaned claim boundary and cites evidence paths |
| R09 | Convert report draft into final submission format | P1 | Use `REGION_REPORT_DRAFT_CLEAN_20260609.md` as source and adapt it into Word/PPT/LaTeX without overstating board evidence |

## Optimization Direction

Use CPU25 as the accepted reporting baseline. The 6872-LUT point is now only a
timing-failed engineering reference. Useful next RTL directions are:

- reduce the worst post-route path from `ex_mem_mem_addr_r` to `pc_r`,
- reduce MEM/address-to-PC/redirect control fan-in,
- keep DCache512 unless a lower-cache variant can preserve CoreMark/MHz >= 4.3,
- avoid coarse IMEM output-register insertion unless compensated by front-end
logic, because the measured CoreMark dropped below the target,
- keep CoreMark core algorithm files unchanged.

## Region Demonstration Direction

Use the timing-closed CPU25 perf-demo bitstream for the first board video. It is
the current accepted baseline because it satisfies the current honest-reporting
gate: `CoreMark/MHz > 4.5`, `LUT < 8000`, and post-route timing closure.

The best current timing-closed successor candidate is CPU25 RC128 BFNext/no-ZBKB
timing-driven:
`7473 LUT / 4.741458 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +1.348 ns`.
It can replace the RC64 demo path only after the user selects it and board
PROGRAM_OK/UART/video evidence is regenerated for the selected successor bitstream.

Immediate board-demo sequence:

1. Program `../freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit`.
2. Capture Vivado PROGRAM_OK evidence.
3. Capture UART output containing `PERF_DEMO PASS checksum=0xe727358b`.
4. Record a short video tying board, bitstream, UART output, and date together.
5. Add `BOARD_EVIDENCE.md` before making board-proven claims.
