# Hardware-Only Benchmark Rule

Date: 2026-05-14

This exploration branch evaluates hardware changes only. The benchmark software image, compiler options and simulator harness must be kept fixed when comparing two RTL candidates.

## Scope

Allowed changes:

- RTL microarchitecture changes in fetch, decode, execute, memory, writeback, hazard control and forwarding.
- Parameterized hardware ISA extensions implemented in decoder, execute datapath and directed tests.
- FPGA integration changes needed for timing, resource, UART evidence and board bring-up.
- Testbench or reporting changes that improve observability without changing the executed benchmark program.

Not allowed for hardware-only scoring:

- CoreMark or Dhrystone algorithm rewrites.
- Benchmark-specific result caches or precomputed data paths.
- Compiler flag changes used as the only reason for a score comparison.
- Rebuilding a different software image and comparing it against an old RTL score without labeling it as a software or ISA co-design experiment.

## Required Evidence Per Candidate

Each candidate must record:

- Git commit or diff summary.
- ROM hex image path and checksum.
- CoreMark/MHz, total ticks and completion cycles.
- DMIPS/MHz and Dhrystone run configuration.
- Directed test result for any changed instruction or pipeline control path.
- FPGA resource and timing result when the candidate is promoted for board testing.

## Baseline Images

- Historical fixed image: `YH_rv_cpu/build/sw/state_cache_cm10.hex`
- Fixed-image runner: `YH_rv_cpu/scripts/run_coremark_fixed_hex_score.bat`

The historical fixed image is used only to verify that RTL behavior is preserved across hardware experiments. It must not be described as a newly achieved hardware optimization result unless the improvement comes from an RTL-only change over the same image.
