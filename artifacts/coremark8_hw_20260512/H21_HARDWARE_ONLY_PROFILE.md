# H21 Hardware-Only CoreMark Profile Baseline

Date: 2026-05-14

## Purpose

After H20, the next CoreMark work must separate hardware-only changes from benchmark-image changes. This profile records a fixed ordinary CoreMark image that can be reused for RTL-only comparisons.

## Command

```bat
YH_rv_cpu\scripts\run_coremark_profile.bat rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller 10 2000 100000000UL 220000000 0
```

## Evidence

- Raw profile log: `logs/profiles/h21_coremark_zicond_plain_profile_20260514/profile.log`
- ELF: `logs/profiles/h21_coremark_zicond_plain_profile_20260514/profile.elf`
- Dump: `logs/profiles/h21_coremark_zicond_plain_profile_20260514/profile.dump`
- Top-PC symbol map: `logs/profiles/h21_coremark_zicond_plain_profile_20260514/timed_pc_top_symbols.csv`

## Key Numbers

- Total cycles: `2006899`
- Timed cycles: `1972115`
- Score-equivalent summary for the same image: `5.070698 CoreMark/MHz`
- Timed decode flush cycles: `1461`
- Timed EX redirect cycles: `571`
- Timed ID decode redirect cycles: `114052`
- Timed branch-predict redirect cycles: `49510`
- Timed JAL predict redirect cycles: `2342`
- Timed load cycles: `416010`
- Timed branch cycles: `406239`
- Timed multiply cycles: `93960`

## Hot Regions

The hottest timed PC ranks map mainly to:

- `core_bench_list`
- `core_bench_state`
- `crc16` / `crcu16` / `crcu32` region

The function buckets reported by the profile are:

- `timed_pc_crc_cycles=500480`
- `timed_pc_list_cycles=471690`
- `timed_pc_state_cycles=82560`
- `timed_pc_port_cycles=53920`
- `timed_pc_unknown_cycles=861571`

`timed_pc_unknown_cycles` is large because the profile's coarse address ranges do not classify every unrolled code block. The symbolized top PCs show those cycles are still dominated by `core_bench_list` and `core_bench_state`.

## Hardware-Only Next Actions

1. Keep this benchmark image fixed when testing RTL changes.
2. Avoid benchmark C rewrites and benchmark-specific work skipping.
3. Evaluate reusable hardware mechanisms only:
   - lower-cost branch/redirect handling for the list/state control-flow pattern;
   - standard or documented custom CRC instruction path, clearly separated from source-level benchmark skipping;
   - fetch/refill improvements that reduce redirect bubbles without changing executed instructions.
4. Any retained change must improve `profile.log` and a fresh score run on the same image.
