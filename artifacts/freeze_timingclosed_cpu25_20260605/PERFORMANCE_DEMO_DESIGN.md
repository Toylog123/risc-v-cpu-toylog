# CPU25 Performance Demo Design

This demo is a board-facing application for the frozen CPU25 baseline. It is not a replacement for CoreMark or Dhrystone evidence. Its purpose is to make the CPU behavior visible in a contest/demo setting through deterministic UART output and workload-specific measurements.

## Scope

- Hardware base: `freeze-timingclosed-cpu25-20260605`
- Clock target: 25 MHz CPU clock
- Memory target: 64 KiB ROM image, 16 KiB RAM
- Interface: UART TX only, automatic run, no interactive RX dependency
- End condition: write MMIO DONE register, then idle

## UART Report

The program prints a compact report with:

- baseline tag and clock
- per-workload cycle count
- per-workload throughput numerator/denominator
- deterministic checksum
- per-workload `PASS` or `FAIL`
- final `PERF_DEMO PASS checksum=... total_cycles=...`

## Workloads

| Workload | Purpose | Evidence |
|---|---|---|
| CRC32 | bit/data-flow stress over a fixed byte buffer | cycles, bytes, checksum |
| Matrix multiply | integer multiply/add workload | cycles, operation count, checksum |
| Memory copy/fill | RAM bandwidth and store/load path | cycles, bytes, checksum |
| Branch/control | taken/not-taken control-flow stress | cycles, iterations, checksum |
| Load-use/DCache-style | dependent loads and pointer/stride pattern | cycles, iterations, checksum |

## Verification Flow

1. Build `YH_rv_cpu_perf_demo.elf/.hex/.mem32.hex`.
2. Run the dedicated SoC testbench.
3. The testbench captures UART and fails on trap, timeout, or missing `PERF_DEMO PASS`.
4. Save the UART log and summary as demo evidence.
5. For board demo, rebuild the PYNQ-Z2 CPU25 bitstream with this ROM image and rerun post-route timing before programming the board.

## Board Demo Claim

This demo can be used on board after the ROM-embedded CPU25 bitstream is regenerated and timing is still closed. Until that implementation report exists, it should be described as a verified demo firmware candidate, not as board evidence.
