# Board Evidence Template

Fill this file after programming the PYNQ-Z2 board. Do not mark the demo as board-proven until every required item is filled.

## Identity

| Item | Value |
|---|---|
| Date | `TODO` |
| Board | `PYNQ-Z2` |
| Git branch | `codex/syncbram-h22-20260514` |
| Baseline tag | `freeze-timingclosed-cpu25-20260605` |
| Bitstream | `../freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit` |
| Bitstream SHA256 | `474FB90B3A88EF0855569C6C21567E45CF963FDA36CC0A437288386D4BB88C6F` |
| CPU clock | `25 MHz` |
| Timing report | `../freeze_timingclosed_cpu25_20260605/reports/impl_timing_summary_cpu25_perf_demo_wns+0p291.rpt` |

## Required Evidence

| Evidence | Status | Path / Note |
|---|---|---|
| Vivado PROGRAM_OK | pending | `TODO` |
| UART raw log | pending | `TODO` |
| Video | pending | `TODO` |
| Photo/screenshot, optional | pending | `TODO` |

## Expected UART Markers

```text
CRC32 ... PASS
MATMUL8 ... PASS
MEMCPYFILL ... PASS
BRANCH ... PASS
LOADUSE ... PASS
PERF_DEMO PASS checksum=0xe727358b
```

## Final Board Claim

After all evidence is collected, the allowed claim is:

`CPU25 performance-demo bitstream is board-programmed and UART-verified on PYNQ-Z2.`

Do not claim the 6872-LUT performance reference is board-proven unless its exact configuration later closes timing and is separately programmed.
