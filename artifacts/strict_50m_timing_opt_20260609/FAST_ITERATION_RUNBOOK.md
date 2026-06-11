# Strict 50MHz Fast Iteration Runbook

Purpose: reduce RTL timing-optimization turnaround time while keeping freeze evidence strict and reproducible.

## Gates

| Stage | Command | Typical use | Pass condition | Action |
|---|---|---|---|---|
| Fast gate | `cmd /c YH_rv_cpu\scripts\run_coremark50_fast_gate.bat <out> 1 1500000` | Single-candidate smoke test | simulation completes, `acceptance_pass=yes`, CoreMark/MHz roughly `>=4.15` for the current relaxed gate | keep candidate |
| Fast matrix | `cmd /c YH_rv_cpu\scripts\run_coremark50_fast_matrix.bat <out> 1 1500000` | Batch feature-switch sweep | same as fast gate | promote only passing rows |
| Strict sim | `cmd /c YH_rv_cpu\scripts\run_coremark_fpga.bat rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_xthead_memidx_mac_noautoinc_o2sched_nocaller 10 2000 100000000UL 5000000 <summary> 0` | Performance confirmation | full CoreMark-ROM run completes and remains `>=4.3 CoreMark/MHz` | run implementation |
| Implementation | `cmd /c YH_rv_cpu\scripts\build_pynq_z2_project.bat impl` with candidate env explicitly set | Timing evidence | PYNQ-Z2 post-route `WNS >= 0`, `WHS >= 0`, LUT `<15000` | freeze candidate |

## Policy

- Do not run Vivado implementation for candidates that fail fast gate or drop below `4.3 CoreMark/MHz`.
- Do not freeze from fast-gate evidence. Fast gate is only a filter.
- Do not claim 50 MHz compliance until strict CoreMark-ROM implementation closes post-route timing.
- Keep all candidate outputs under `artifacts\strict_50m_timing_opt_20260609`.
- Do not modify CoreMark algorithm files.

## Recommended Loop

1. Run the fast matrix after a local RTL change:

   ```bat
   cmd /c YH_rv_cpu\scripts\run_coremark50_fast_matrix.bat artifacts\strict_50m_timing_opt_20260609\fast_matrix_next 1 1500000
   ```

2. Read `<out>\MATRIX_SUMMARY.md`.
3. Promote only `PASS` rows with `coremark_per_mhz >= 4.15` under the current relaxed gate.
4. Run strict iter10 simulation for promoted rows.
5. Run Vivado implementation only for strict iter10 survivors.
6. Freeze only after implementation has non-negative setup and hold slack.

## Latest Fast-Matrix Calibration

Run:

```bat
cmd /c YH_rv_cpu\scripts\run_coremark50_fast_matrix.bat artifacts\strict_50m_timing_opt_20260609\fast_matrix_20260610_a 1 1500000
```

Result:

| Candidate | Fast result | CoreMark/MHz | Completion cycles | Decision |
|---|---:|---:|---:|---|
| `fast_default` | PASS | 4.590378 | 258544 | calibration only |
| `foldexmem0` | PASS | 4.590378 | 258544 | promote for strict sim / timing check |
| `ntnext0_foldexmem0` | PASS | 4.504565 | 263417 | promote if timing benefit is expected |
| `reglookup0` | PASS | 4.182840 | 284345 | reject for current `>=4.3` target |
| `foldnext0` | PASS | 4.483199 | 264120 | promote if timing path points at fold-next logic |
| `pcskip0` | FAIL | NA | NA | reject; timed out at 1,500,000 cycles |

Observed matrix wall time was about 5.5 minutes on this host. Use it to screen multiple switch-only candidates before spending time on strict sim or implementation.

## Candidate Priority

| Priority | Candidate | Reason |
|---:|---|---|
| 1 | `FOLD_EXMEM_LOAD_USE_SPEC=0` | Existing fast evidence keeps score; may reduce part of load-use/fold path. |
| 2 | `ID_BRANCH_NT_NEXT_CACHE=0 + FOLD_EXMEM_LOAD_USE_SPEC=0` | Combines the known score-safe NT-next cut with fold cut. |
| 3 | `REDIRECT_CACHE_REGULAR_LOOKUP=0` | Directly targets redirect-cache to PC same-cycle path; performance risk is higher. |
| 4 | `ID_BRANCH_FOLD_NEXT_CACHE=0` | Cuts another branch/fetch shortcut if performance budget allows. |
| 5 | `REDIRECT_CACHE_PC_SKIP=0` | Historical evidence timed out; keep as regression check only. |

## Freeze Evidence Checklist

| Evidence | Required |
|---|---|
| Git commit hash | yes |
| Exact env/config values | yes |
| CoreMark algorithm file hashes unchanged | yes |
| Strict iter10 CoreMark-ROM summary/log | yes |
| Vivado utilization report | yes |
| Vivado timing summary with WNS/WHS | yes |
| Worst path report | yes |
| Bitstream / PROGRAM_OK / UART / video | later, only after timing closure |
