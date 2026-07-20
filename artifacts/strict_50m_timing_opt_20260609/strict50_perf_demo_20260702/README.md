# Strict50 perf demo xsim evidence 2026-07-02

This directory archives the strict50 application-demo xsim result for the
current `impl220` engineering candidate.

## Files

| File | Purpose |
|---|---|
| `YH_rv_cpu_strict50_perf_demo_xsim_20260702.log` | Raw xsim output for the strict50 perf demo |
| `SHA256SUMS.txt` | SHA256 hashes for the log and the source/testbench/runner used |

## Status

The demo passed xsim with:

```text
baseline=strict50 impl220 cpu_clk=50MHz
PERF_DEMO PASS checksum=0xe727358b total_cycles=0x0002c891
PASS: strict50 perf demo completed at PC=00000000 in 198587 cycles, UART bytes=542
```

This is not board evidence. Use `audit_strict50_board_evidence.ps1` before
changing any board-proven wording.
