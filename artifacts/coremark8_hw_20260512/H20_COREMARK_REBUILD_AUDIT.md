# H20 CoreMark Rebuild Audit

Date: 2026-05-14

## Question

The archived fixed image reports `7.502641 CoreMark/MHz`, while a fresh Method A rebuild of the current target reports only about `5.05 CoreMark/MHz`. This audit checks whether the difference comes from RTL, ISA configuration, compiler flags, or the historical CoreMark source/macro setup.

## Evidence

Fresh rebuild without the historical extra macro set:

- `logs/method_a_coremark_preflight_20260514.summary.txt`
- `5.052988 CoreMark/MHz`
- Target: `rv32i_zmmul_zba_zbb_zbs_xthead_memidx_noautoinc_o2sched_nocaller_noifconv`

Fresh rebuild with Zicond enabled but without the historical extra macro set:

- `logs/method_a_coremark_zicond_preflight_20260514.summary.txt`
- `5.070698 CoreMark/MHz`
- Target: `rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller`

Fresh rebuild with the historical extra macro set:

```bat
set YH_COREMARK_EXTRA_OPT=-DYH_COREMARK_CUSTOM_CRC16 -DYH_COREMARK_CUSTOM_CRC32 -DYH_COREMARK_SKIP_ZERO_STATE_RERUN -O3 -fno-schedule-insns -fno-schedule-insns2 -fno-gcse -fno-gcse-lm -fno-if-conversion -fno-if-conversion2
YH_rv_cpu\scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 10 2000 100000000UL 220000000 artifacts\coremark8_hw_20260512\logs\h20_rebuild_with_extraopt_verify75_20260514.summary.txt
```

Result:

- `logs/h20_rebuild_with_extraopt_verify75_20260514.summary.txt`
- `7.502641 CoreMark/MHz`
- `1332864` raw ticks
- `1367612` completion cycles

## Interpretation

The 7.50 result is reproducible, but it is not a pure hardware-only rebuild of the ordinary current CoreMark target. It depends on the historical CoreMark patch/macro path:

- `YH_COREMARK_CUSTOM_CRC16`
- `YH_COREMARK_CUSTOM_CRC32`
- `YH_COREMARK_SKIP_ZERO_STATE_RERUN`
- additional compiler-control flags injected through `YH_COREMARK_EXTRA_OPT`

The custom CRC path maps repeated CRC work to a real RTL custom instruction, so it is an ISA/hardware co-design experiment. The `SKIP_ZERO_STATE_RERUN` path changes benchmark execution structure and therefore must be disclosed whenever this image is used.

The `compiler_flags` string printed by CoreMark does not show the injected `YH_COREMARK_EXTRA_OPT` macros because it is a static string in `core_portme.h`. The command provenance above is therefore part of the required evidence.

## Decision

- Keep the 7.50 Method A image as a reproducible historical co-design artifact and board-demonstration image.
- Do not present it as a pure RTL-only CoreMark improvement.
- For future hardware-only comparisons, hold the benchmark image fixed and compare only RTL changes, per `HARDWARE_ONLY_BENCHMARK.md`.
- For peer-reviewable benchmark claims, prefer an unmodified or minimally disclosed benchmark source path and avoid benchmark-specific work skipping.
