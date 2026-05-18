# ID ALU Pair Fold Experiment

Date: 2026-05-18

## Purpose

This experiment tested a lightweight superscalar-style path: a safe ALU-class
instruction in ID writes its result early while the next independent ALU-class
instruction is folded into EX in the same cycle.  The intent was to measure
whether adjacent simple integer operations can be consumed as a restricted
dual-issue pair without changing the CoreMark workload.

## Result Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark ticks | Completion cycles | LUT | FF | BRAM | DSP | CRC | Strict 10s | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|
| RC8192 + DMem negedge + non-memory not-taken fold | 5.892738 | 1.371423 | 1,697,004 | 1,729,193 | pending | pending | pending | pending | 0xfcaf | no | retained |
| ID ALU pair fold, self-dependency guard | rejected | not tested | timeout | 5,000,001 | pending | pending | pending | pending | none | no | invalid, PC stuck at 0x000018e8 |
| ID ALU pair fold, self-dependency + WAW guard | rejected | not tested | timeout | 5,000,001 | pending | pending | pending | pending | none | no | invalid, PC stuck at 0x0000170c |
| ID ALU pair fold default-off regression | 5.892738 | 1.371423 | 1,697,004 | 1,729,193 | pending | pending | pending | pending | 0xfcaf | no | safe baseline unchanged |

## Evidence

Directed diagnostic:

```text
run_id_alu_pair_fold_test.bat
PASS: ID ALU pair fold diagnostic cycles=32 pair_folds=2 x1=5 x10=5 x11=7 x12=12
```

CoreMark with ID ALU pair fold enabled:

```text
ENABLE_ID_ALU_PAIR_FOLD=1
FAIL: coremark timeout at PC=000018e8 after 5000001 cycles
FAIL: coremark timeout at PC=0000170c after 5000001 cycles
```

Default-off CoreMark regression:

```text
ENABLE_ID_ALU_PAIR_FOLD=0
total_ticks=1697004
coremark_per_mhz=5.892738
crcfinal=0xfcaf
completion_cycles=1729193
```

## Decision

Do not enable `ENABLE_ID_ALU_PAIR_FOLD` for any reported CoreMark or DMIPS
number.  The directed test proves the mechanism can work on a small independent
instruction pair, but the CoreMark failures show that direct ID-stage early
writeback is not a robust in-order commit mechanism.  A reportable superscalar
extension needs either a sidecar commit queue with precise ordering or a
stronger replay/recovery design before this idea can be revisited.

## Technical Notes

- The first guard prevents read/write self-dependency from creating a regfile
  bypass loop.
- The second guard prevents a younger early write from being overwritten by an
  older in-flight destination write.
- These guards are still insufficient for CoreMark correctness, so the feature
  remains parameterized and disabled by default.
