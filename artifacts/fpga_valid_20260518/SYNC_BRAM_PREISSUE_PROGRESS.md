# Sync BRAM Preissue Experiment

Date: 2026-05-20

## Result

The sync DMem word preissue path is rejected for the current optimization branch. It is kept disabled in the SoC default path.

| Node | LUT | CoreMark/MHz | DMIPS/MHz | Conclusion |
|---|---:|---:|---:|---|
| sync BRAM RC2048 + store fold baseline recheck | pending | 4.236988 | pending | retained, CRC `0xfcaf` |
| sync BRAM word preissue | pending | timeout | pending | rejected, unsafe under CoreMark |
| negedge DMem RC8192 | invalid | 5.934774 | 1.371423 | rejected, Vivado cannot infer RAM |

## Findings

| Technical point | Status | Note |
|---|---|---|
| DMem negedge read | rejected | Simulation improves score, but Vivado reports unsupported RAM template for the FPGA target. |
| Sync DMem word preissue | rejected | Small load-use diagnostics can remove bubbles, but CoreMark exposes state corruption and timeout cases around list initialization. |
| Per-load fast-forward gating | retained as safe infrastructure | Hazard checks now use actual per-load readiness instead of treating every sync load as fast-forwardable. |
| Store/DMem port guard | retained as safe infrastructure | Preissue is blocked when MEM stage occupies the single DMem port, avoiding store-address corruption. |

## Evidence

- Baseline recheck:
  `artifacts/fpga_valid_20260518/coremark_syncbram_preissue_rejected_rc2048_baseline_recheck.summary.txt`
- Rejected timeout logs:
  `artifacts/fpga_valid_20260518/coremark_syncbram_word_preissue_rc2048.log`
  `artifacts/fpga_valid_20260518/coremark_syncbram_word_preissue_rc2048_debug.summary.txt`
  `artifacts/fpga_valid_20260518/coremark_syncbram_word_preissue_rc2048_debug2.summary.txt`

## Verification

- `cmd /c YH_rv_cpu\scripts\run_sync_dmem_preissue_diag.bat`
- `cmd /c YH_rv_cpu\scripts\run_branch_not_taken_store_fold_test.bat`
- `cmd /c YH_rv_cpu\scripts\run_load_use_fast_diag.bat require_no_stall_decode`
- `cmd /c YH_rv_cpu\scripts\run_coremark_fpga.bat ... artifacts\fpga_valid_20260518\coremark_syncbram_preissue_rejected_rc2048_baseline_recheck.summary.txt 0`

