# Strict Sync-BRAM Optimization Record - 2026-05-21

This record tracks only hardware-side changes under the current PYNQ-Z2 / sync-BRAM validation line. CoreMark core workload files are not modified for these entries. CoreMark summaries are CRC-clean, short-runtime reproducible runs; a strict EEMBC public-valid report still requires a >=10 second run or board-level timing evidence.

## Current Best Candidate Under 7000 LUT

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status | Hardware optimization point |
|---|---:|---:|---:|---|---|
| sync-BRAM baseline, RC1024 | 5938 | 3.413191 | 2.381087 | baseline | Current synchronous BRAM口径; no DMEM preissue |
| DMEM preissue, RC1024 | 11064 | 3.767699 | 2.485060 | rejected | Earlier aligned word-load issue, but redirect cache area too high |
| DMEM preissue, RC256 | 7226 | 3.755262 | TBD | rejected | Near-best performance, but exceeds 7000 LUT target |
| DMEM preissue, RC128 | 6462 | 3.703951 | 2.485060 | current best | Keeps early aligned word-load issue while reducing redirect cache LUTRAM |
| DMEM preissue, RC256 no regular lookup | TBD | 3.533369 | TBD | rejected | Area-oriented cache lookup pruning loses too much CoreMark performance |

## Evidence Files

- CoreMark RC128: `coremark_fpga_xthead_baseupd_preissue_rc128_syncbram_iter1_20260521.summary.txt`
- Dhrystone RC128: `dhrystone_fpga_xthead_baseupd_preissue_rc128_o3_lto_stripnoinline_runs1000_20260521.summary.txt`
- LUT RC128: `synth_util_xthead_baseupd_preissue_rc128_syncbram_cpu50_20260521.rpt`
- Timing RC128: `synth_timing_xthead_baseupd_preissue_rc128_syncbram_cpu50_20260521.rpt`
- RC256 rejected area reference: `synth_util_xthead_baseupd_preissue_rc256_syncbram_cpu50_20260521.rpt`

## Strict口径 Notes

- Only RTL / microarchitecture options are counted here.
- CoreMark algorithm files remain unchanged.
- Sync-BRAM behavior is preserved; no async/negedge DMEM score path is mixed into this table.
- RC128 is frozen as the best under-7000-LUT candidate so far, but timing closure still needs implementation-stage verification.
