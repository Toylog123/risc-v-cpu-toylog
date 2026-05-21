# Freeze Snapshot - 2026-05-21 15:28 +08:00

## Result Classes

| Class | LUT | CoreMark/MHz | DMIPS/MHz | Status |
|---|---:|---:|---:|---|
| Initial-submission frozen evidence | 4961 | 4.137461 | 2.908287 | Submitted-material baseline with PYNQ-Z2 evidence; keep as official initial-freeze口径 |
| Current branch fully synthesized sync-BRAM evidence | 5938 | 3.413191 | 2.381087 | Latest PYNQ-like sync IMEM/sync DMEM口径, CoreMark + Dhrystone + 50 MHz synth utilization complete |
| Current branch best sync-BRAM performance candidate | pending | 3.767699 | 2.485060 | DMEM read-preissue fixed; CoreMark + Dhrystone FPGA-like simulation complete, but Vivado synth was interrupted before final LUT/timing |

## Why The Score Looks Lower

- The current branch intentionally moved to a stricter PYNQ-Z2-compatible sync-BRAM model. This exposes the real one-cycle Block RAM read latency instead of hiding it behind async/negedge simulation behavior.
- Earlier 4.4+ short-run rows on this branch were score-TB/negedge-DMEM style exploration and are not the same as the latest FPGA-like sync-BRAM口径.
- 6+ DCache/redirect-cache results exist in the artifacts, but synthesis reports show LUTs from about 12013 up to 86991, so they are rejected for the low-resource/low-power target.
- Historical 7+/9+ experiments involved software/coremark-side modifications or non-current assumptions and cannot be mixed into the current rule set that forbids modifying CoreMark core algorithm files.

## Current Technical Highlight

The newest hardware-only improvement is synchronous DMEM read preissue with stale-valid protection. It issues eligible aligned word loads one stage earlier and adds `ex_mem_load_waited_r` so non-preissued loads cannot consume an older `dmem_rvalid`. This recovers CoreMark from the current sync-BRAM baseline toward the old level without changing CoreMark core files, but it still needs a completed PYNQ-Z2 synthesis run before promotion.

## Evidence Paths

- `artifacts/fpga_valid_20260518/coremark_fpga_xthead_baseupd_baseline_rc1024_alignedopt_syncbram_iter1_20260521.summary.txt`
- `artifacts/fpga_valid_20260518/dhrystone_fpga_xthead_baseupd_lowarea_aligned_o3_lto_stripnoinline_runs1000_20260521.summary.txt`
- `artifacts/fpga_valid_20260518/synth_util_xthead_nozicond_nomac_idfwd_hotext_noaddsl_nocondmov_nomempair_baseupd_cpu50_5938lut_20260521.rpt`
- `artifacts/fpga_valid_20260518/coremark_fpga_xthead_baseupd_preissue_syncbram_iter1_20260521.summary.txt`
- `artifacts/fpga_valid_20260518/dhrystone_fpga_xthead_baseupd_preissue_o3_lto_stripnoinline_runs1000_20260521.summary.txt`
- `artifacts/fpga_valid_20260518/pynq_synth_xthead_baseupd_preissue_syncbram_cpu50_20260521.log`
