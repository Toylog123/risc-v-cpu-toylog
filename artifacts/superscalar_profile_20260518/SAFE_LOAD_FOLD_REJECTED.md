# Safe Not-Taken Load Fold Rejected

Date: 2026-05-18

## Result

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Decision |
|---|---:|---:|---:|---|
| retained store fold | pending | 5.934774 | 1.371423 | retained |
| safe load fold enabled | pending | rejected | not rerun | timeout |
| load fold default off after guard | pending | 5.934774 | 1.371423 | retained |

## Technical Note

The load-fold experiment added a raw next-cache match and an immediate load-use guard, so a branch fall-through load is folded only when the instruction at `PC+8` does not consume the load destination. Directed tests verified both the guard and an independent-load positive case.

Even with the guard, the full CoreMark run timed out in the `ee_printf` byte-copy region after printing ticks, so load folding remains disabled for reported scores.

## Evidence

- `coremark_safe_load_fold_rc8192.log`: timeout at `PC=000095c8`
- `coremark_defaultoff_after_safe_load_rc8192.summary.txt`: `coremark_per_mhz=5.934774`, `crcfinal=0xfcaf`
- Directed tests:
  - `run_branch_not_taken_load_use_guard_test.bat`
  - `run_branch_not_taken_load_independent_fold_test.bat`
