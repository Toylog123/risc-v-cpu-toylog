# Not-Taken Branch Fold Freeze

Date: 2026-05-18

## Scope

This node freezes a conservative lightweight superscalar-style control-path optimization.  When a decoded conditional branch is resolved as not taken in ID, the front end may fold the fall-through instruction into the EX input path in the same cycle.  The retained implementation only folds fall-through instructions that decode as non-control, non-load, non-store operations and whose operands are ready.

The implementation does not modify CoreMark workload files.  It changes RTL control/data delivery only.

## Result Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark ticks | Completion cycles | LUT | FF | BRAM | DSP | CRC | Strict 10s | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|
| RC8192 + DMem negedge baseline | 5.729438 | 1.371423 | 1,745,372 | 1,778,653 | pending | pending | pending | pending | 0xfcaf | no | frozen baseline |
| Not-taken fold, memory-capable trial | rejected | not tested | 1,609,156 before hang | timed out at 5,000,001 | pending | pending | pending | pending | partial only | no | rejected, PC stuck at 0x000095c0 |
| Not-taken fold, non-memory conservative | 5.892738 | 1.371423 | 1,697,004 | 1,729,193 | pending | pending | pending | pending | 0xfcaf | no | retained |

## Verification Evidence

CoreMark command:

```text
YH_COREMARK_FPGA_ID_BRANCH_FOLD=1
YH_COREMARK_FPGA_REDIRECT_CACHE_ENTRIES=8192
YH_COREMARK_FPGA_REDIRECT_CACHE_XOR_INDEX=1
YH_COREMARK_FPGA_DMEM_NEGEDGE_READ=1
scripts/run_coremark_fpga.bat rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_zbkx_xthead_memidx_mac_mempair_o2sched_nocaller 10 2000 100000000UL 30000000 artifacts/superscalar_profile_20260518/coremark_not_taken_fold_simple_rc8192.summary.txt 0
```

CoreMark evidence:

```text
total_ticks=1697004
coremark_per_mhz=5.892738
crcfinal=0xfcaf
completion_cycles=1729193
acceptance_pass=yes
strict_eembc_10s_compliant=no
```

Dhrystone evidence:

```text
dmips_per_mhz=1.371423
dhrystones_per_second=240959
completion_cycles=873680
```

Regression tests:

```text
run_branch_not_taken_fold_test.bat: PASS, folds=4, x2=5, x4=5
run_branch_target_issue_test.bat: PASS, PC=0x18, cycles=25, folds=3
run_redirect_target_cache_diag.bat require_no_redirect_bubble require_loop_stream: PASS, PC=0x18, cycles=21
run_xthead_mempair_test.bat: PASS, cycles=13
run_xthead_mac_test.bat: PASS, cycles=25
```

CoreMark source integrity:

```text
core_list_join.c core_main.c core_matrix.c core_state.c core_util.c coremark.h: clean
```

## Technical Notes

- Retained path is a low-cost control-flow form of superscalarization: the branch and its fall-through ALU-class instruction can be consumed without inserting an extra front-end bubble.
- Load/store fall-through folding is intentionally disabled in the retained node.  A memory-capable trial reduced ticks before result printing, but then timed out at PC `0x000095c0`; it is therefore invalid and only kept as negative evidence.
- Fresh PYNQ-Z2 implementation resource/timing data is still pending for this RTL node.
