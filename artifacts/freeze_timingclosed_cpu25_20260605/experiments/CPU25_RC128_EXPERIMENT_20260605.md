# CPU25 RC128 Experiment 2026-06-05

## Purpose

Check whether increasing redirect-cache entries from 64 to 128 can recover CoreMark/MHz while preserving the CPU25 timing-closed configuration.

## Result Summary

| LUT | CoreMark/MHz | DMIPS/MHz | Timing | Technical optimization point |
|---:|---:|---:|---|---|
| 7076 post-route | 4.627215 | 1.205669 | WNS +0.514 ns / WHS +0.056 ns | RC64 -> RC128 under CPU25 timing cuts; Dhrystone rebuilt with no-auto-inc target matching base-update-disabled hardware |

## What Passed

- CoreMark xsim completed and passed acceptance checks.
- CoreMark/MHz improved from `4.501191` to `4.627215`.
- Dhrystone xsim completes with `1.205669 DMIPS/MHz` after using the no-auto-inc Dhrystone target that matches the current CPU25 timing-cut hardware generics.
- PYNQ-Z2 full implementation closed timing.
- LUT remains below 8000.

Evidence:

- `coremark_cpu25_rc128_iter10_20260605.summary.txt`
- `coremark_cpu25_rc128_iter10_20260605.log`
- `dhrystone_cpu25_rc128_noautoinc_runs1000_20260605.summary.txt`
- `dhrystone_cpu25_rc128_noautoinc_runs1000_20260605.log`
- `../reports/impl_utilization_cpu25_rc128_coremark_7076lut.rpt`
- `../reports/impl_timing_summary_cpu25_rc128_coremark_wns+0p514.rpt`

Repeatable simulation wrapper:

```powershell
cmd /c YH_rv_cpu\scripts\run_cpu25_rc128_validated.bat
```

By default this writes fresh rerun summaries/logs under `artifacts/freeze_timingclosed_cpu25_20260605/experiments/repro_cpu25_rc128` so the dated evidence above is not overwritten. The wrapper sets the CPU25 timing-cut hardware generics, selects `REDIRECT_CACHE_ENTRIES=128`, and uses the benchmark-specific ISA targets required for this result.

Fresh wrapper rerun on 2026-06-05 passed:

- `repro_cpu25_rc128/coremark_cpu25_rc128_iter10.summary.txt`: `4.627215 CoreMark/MHz`, `crcfinal=0xfcaf`, `acceptance_pass=yes`.
- `repro_cpu25_rc128/dhrystone_cpu25_rc128_noautoinc_runs1000.summary.txt`: `1.205669 DMIPS/MHz`, `PASS: dhrystone completed`.

Implementation reproduction wrapper:

```powershell
cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_coremark.bat impl
```

This rerun completed on 2026-06-05 and wrote a fresh bitstream plus reports:

- `../YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_coremark_repro_20260605.bit`
- `../reports/impl_utilization_cpu25_rc128_repro_7124lut_20260605.rpt`
- `../reports/impl_timing_summary_cpu25_rc128_repro_wns+1p881_20260605.rpt`

Parser row:

```text
cpu25_rc128_repro_20260605 | 7124 | 3211 | 20 | 8 | 4.627215 | 1.205669 | 1.881 | 0.100 | yes | Reproduced CPU25 RC128 CoreMark implementation wrapper; DCache512 RC128 timing cuts
```

## Follow-up: Branch-Fold Next-Cache Restored

Restoring `ENABLE_ID_BRANCH_FOLD_NEXT_CACHE=1` on the same CPU25 RC128 timing-cut family improved CoreMark while preserving timing closure.

Simulation:

- CoreMark: `experiments/repro_cpu25_rc128_bfnext1/coremark_cpu25_rc128_bfnext1_iter10.summary.txt`
- Dhrystone: `experiments/repro_cpu25_rc128_bfnext1/dhrystone_cpu25_rc128_bfnext1_noautoinc_runs1000.summary.txt`

Implementation wrapper:

```powershell
cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_bfnext_coremark.bat impl
```

Result:

```text
cpu25_rc128_bfnext_20260606 | 7505 | 3213 | 20 | 8 | 4.741458 | 1.205669 | 1.138 | 0.100 | yes | CPU25 RC128 with branch-fold next-cache restored; DCache512 timing cuts
```

Artifacts:

- `../YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_20260606.bit`
- `../reports/impl_utilization_cpu25_rc128_bfnext_7505lut_20260606.rpt`
- `../reports/impl_timing_summary_cpu25_rc128_bfnext_wns+1p138_20260606.rpt`

Rejected boundary check:

- Disabling `ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD` reduced CoreMark to `4.468699`, below the user gate of 4.5, so it was not implemented.

## Resolved Debug Note

The first Dhrystone attempts did not complete. Their logs showed repeated sync-trap events around `pc=00000e5c`, with `mepc=00000e54`.

Root cause: the attempted Dhrystone image generated an XThead base-update auto-increment instruction at `0x00000e54`:

```text
e54: 4885c80b  th.lwib a6,(a1),8,0
```

The CPU25 timing-closed hardware disables `ENABLE_XTHEAD_BASE_UPDATE_EXTENSION`, so this instruction traps. This was a software ISA-target mismatch, not an RC128 hardware failure.

Resolution: rebuild Dhrystone with the existing `rv32i_zmmul_zba_zbb_zbs_xthead_noautoinc_nocondmov_idbr` target and force the same CPU25 timing-cut hardware generics used by the RC128 implementation family. The resulting dump no longer contains `th.lwib`; the 1000-run simulation completes:

```text
PASS: dhrystone completed at PC=00000070 in 516078 cycles
DMIPS/MHz (host-parsed): 1.205669 / Dhrystones/s 211836 / runs 1000
```

Historical failed evidence kept for audit:

- `dhrystone_cpu25_rc128_runs100_20260605.log`
- `dhrystone_cpu25_rc128_nozicond_runs1000_20260605.log`

## Decision

RC128 is now a validated CPU25 timing-closed optimization candidate:

- `7076 post-route LUT`, below the user limit of 8000.
- `4.627215 CoreMark/MHz`, above the user limit of 4.5.
- `1.205669 DMIPS/MHz`.
- PYNQ-Z2 post-route timing closes with `WNS +0.514 ns / WHS +0.056 ns`.
- The 2026-06-05 reproducibility wrapper rerun also closes at `7124 post-route LUT / WNS +1.881 ns / WHS +0.100 ns`.
- The 2026-06-06 BFNext follow-up closes at `7505 post-route LUT / WNS +1.138 ns / WHS +0.100 ns` and improves CoreMark/MHz to `4.741458`.

Keep the frozen CPU25 RC64 bitstream as the board-facing fallback until the user explicitly chooses to replace it and regenerate board evidence for RC128.

## Next Step

If RC128 is selected as the successor baseline, regenerate the RC128 CoreMark bitstream package, then collect PROGRAM_OK, UART, and video evidence for the selected board image.
