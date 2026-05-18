# Not-Taken Load Fold Experiment

Date: 2026-05-18

## Purpose

The previous profile showed many not-taken branch fold candidates blocked by load fall-through instructions.  This experiment added an explicit `ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD` knob to test whether a branch and its fall-through load can be safely consumed together, while leaving the knob disabled by default.

## Result Table

| Experiment | CoreMark/MHz | DMIPS/MHz | Ticks before failure | Timeout PC | LUT | FF | BRAM | DSP | Status |
|---|---:|---:|---:|---|---:|---:|---:|---:|---|
| Baseline non-memory not-taken fold | 5.892738 | 1.371423 | 1,697,004 | none | pending | pending | pending | pending | retained |
| Load fold, unguarded | rejected | not tested | 1,621,176 | 0x000095d0 | pending | pending | pending | pending | invalid |
| Load fold, guarded against recent branch operands | rejected | not tested | 1,645,415 | 0x000095e8 | pending | pending | pending | pending | invalid |

## Evidence

Unguarded load fold:

```text
ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD=1
Total ticks      : 1621176
FAIL: coremark timeout at PC=000095d0 after 2500001 cycles
```

Guarded load fold:

```text
ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD=1
Total ticks      : 1645415
FAIL: coremark timeout at PC=000095e8 after 2500001 cycles
```

The timeout PCs are inside the `ee_printf` byte-copy loop:

```text
95b8: lbu a0,0(a5)
95bc: lbu t6,-1(a5)
95c0: lbu t0,-2(a5)
95c4: lbu t3,-3(a5)
95c8: lbu s7,-4(a5)
95cc: lbu t1,-5(a5)
95d0: lbu s9,-6(a5)
95e8: sb s7,4(a7)
9600: bne t2,a5,95b8
```

## Decision

This direction is not retained for score reporting.  The RTL knob remains off by default so the frozen working path stays on the conservative non-memory not-taken fold.  The negative result is kept because it identifies why broad load/store folding is unsafe without a stronger branch verification or replay mechanism.

## Follow-Up

- Do not enable `ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD` for reported CoreMark/DMIPS numbers.
- Future work should either keep the branch in an EX verification slot when folding a load or add an explicit replay/recovery path before revisiting load fall-through folding.
