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

## LUT<10000 Exploration Log

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status | Hardware optimization point |
|---|---:|---:|---:|---|---|
| DCache128 + RC128 + branchfold/next-cache/NT-load-fold + trimmed XThead/Zbc | N/A | N/A | TBD | rejected | Reduced DCache from 256B to 128B to save area, but FPGA-like CoreMark simulation timed out at PC=0x00000588 after 5,000,001 cycles; no valid summary generated |
| DCache256 + RC128 + branchfold/next-cache/NT-load-fold, DCache load-use spec disabled | N/A | N/A | TBD | rejected | Tried to remove DCache load-use speculation for area reduction, but FPGA-like CoreMark simulation timed out at PC=0x00003a0c after 5,000,001 cycles |
| DCache256 + RC128 + branchfold/next-cache/NT-load-fold, global XThead base-update disabled | N/A | N/A | TBD | rejected | Tried to remove XThead base-update hardware globally, but the compiled target no longer completed; timeout at PC=0x00003a04 |
| DCache256 + RC128 + branchfold, fold decoder trimmed to hot/basic ISA only | N/A | N/A | TBD | rejected | Tried to reduce branchfold shadow decode LUT by disabling complex extension decode only in the fold decoder, but the branchfold/fetch handshake no longer completed; RTL change reverted |
| DCache512 + RC128 + no branchfold + trimmed XThead without Zbc | N/A | N/A | TBD | rejected | Tried to use larger DCache without branchfold, but removing Zbc made the run fail to complete within 5,000,001 cycles |
| DCache512 + RC128 + no branchfold + Zbc trimmed XThead | N/A | N/A | TBD | rejected | Kept Zbc but removed heavy XThead options; still timed out at PC=0x00001ec0, so this is not a viable >5 path |
| DCache256 + RC128 + no branchfold + BHT64 trimmed/fullhot | N/A | N/A | TBD | rejected | Small dynamic BHT did not complete in either trimmed or fullhot mode; current BHT path is not accepted for sync-BRAM+DCache |
| DCache256 + RC128 + no branchfold + next-word prefetch fullhot | N/A | N/A | TBD | rejected | DCache next-word prefetch timed out at PC=0x00001730; not accepted |
| DCache256 + RC128 + branchfold + Zbc/XThead condmove, no retiming/no timing driven synth | 10632 | 5.015624 | TBD | rejected | Same valid CoreMark candidate as the 10627-LUT path; synthesis options did not reduce area below 10000 LUT |
| DCache256 + RC128 + branchfold + Zbc/XThead condmove, hierarchical util rerun | 10714 | 5.015624 | TBD | area rejected | Hierarchical report shows main LUT hotspots: DCache 5668 LUT and regfile 2769 LUT |
| DCache256 + RC128 + branchfold + Zbc/XThead condmove, full implementation attempt | N/A | 5.015624 | TBD | rejected | Route/phys-opt did not converge usefully within the run window; WNS stayed around -17 ns to -18 ns, so the candidate is not a valid PYNQ-Z2 implementation path |
| DCache tag replicated RAM experiment | N/A | N/A | TBD | rejected | Unit DCache word test passed, but CoreMark timed out; RTL change reverted |
| Regfile fold-rs3 removal / no folded-store experiment | N/A | N/A | TBD | rejected | Removing fold rs3 and blocking folded store caused CoreMark timeout; RTL change reverted |
| DCache256 + RC128 + branchfold + Zbc/XThead condmove, word-only cache trial (wrong target smoke) | N/A | 13.700995 | TBD | invalid / rejected | Command used an unsupported target string and fell back to rv32i_zicsr, size=400, single algorithm; not comparable and not counted |
| DCache256 + RC128 + branchfold + Zbc/XThead condmove, word-only full workload | 10670 | 4.569993 | TBD | rejected | Correct full-workload rerun completed with CRC final 0xfcaf, but score dropped and LUT stayed above 10000; DCache area is not dominated by byte/half format logic |
| DCache256 + RC128 + branchfold + Zbc/XThead condmove, no base-update/mempair | 9546 | 5.015624 | 1.264622 | valid, superseded | Keeps condmove and branchfold but disables unused base-update/mempair for this no-auto-inc target, removing regfile second-write area while preserving CoreMark score |
| DCache256 + RC128 + branchfold + Zbc/Zicond/ZBKB/XThead condmove, no base-update/mempair | 9662 | 5.059065 | TBD | valid, superseded | Restores Zicond/ZBKB hot-path decode on the low-area no-base-update line; score improves while staying below 10000 LUT |
| DCache256 + RC128 + branchfold + Zbc/Zicond/XThead MAC+condmove, no base-update/mempair | 9591 | 5.150524 | 1.264622 | current best under 10000 | Restores XThead MAC on the no-base-update line; CoreMark improves without exceeding the relaxed 10000-LUT exploration cap |
| DCache256 + RC128 + branchfold + Zbc/Zicond/ZBKB/XThead MAC+condmove, no base-update/mempair | 9636 | 5.150524 | 1.264622 | valid, not best | Enables ZBKB together with XThead MAC; result is CRC-clean and under 10000 LUT, but CoreMark is identical to MAC-only with slightly higher LUT |
| DCache256 + RC128 + branchfold + Zicond/ZBKB/MAC combined target before build-script fix | N/A | 5.150524 | TBD | invalid / rejected | Build target lacked complete script/report macro support and printed fallback compiler flags; fixed rerun above is the counted result |

Evidence:

- Timeout log: `coremark_fpga_dcache128_rc128_branchfold_zbc_trim_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_branchfold_zbc_trim_noloadspec_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_branchfold_zbc_trim_nobaseupd_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_branchfold_hotfolddecoder_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache512_rc128_nofold_trim_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache512_rc128_nofold_zbc_trim_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_nofold_dynbht64_zbc_trim_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_nofold_dynbht64_fullhot_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_nofold_nextprefetch_fullhot_iter10_20260521.log`
- Synth util: `synth_util_dcache256_rc128_branchfold_zbc_condmov_nozicond_nomac_trim_quickutil_noretiming_notiming_20260521.rpt`
- Synth util: `synth_util_dcache256_rc128_branchfold_zbc_condmov_nozicond_nomac_trim_quickutil_hier_20260521.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_branchfold_zbc_condmov_nozicond_nomac_trim_quickutil_20260521.rpt`
- Implementation log: `_tmp/tool_logs/vivado/vivado_pynq_z2_impl.log`
- Timeout log: `coremark_fpga_dcache256_rc128_branchfold_zbc_condmov_tagram_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_branchfold_zbc_condmov_nofoldrs3_iter10_20260521.log`
- Invalid smoke log: `coremark_fpga_dcache256_rc128_branchfold_zbc_condmov_wordonly_iter10_20260521.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_branchfold_zbc_condmov_wordonly_fullwork_iter10_20260521.summary.txt`
- Synth util: `synth_util_dcache256_rc128_branchfold_zbc_condmov_wordonly_quickutil_20260521.rpt`
- Full workload summary: `coremark_fpga_dcache256_rc128_branchfold_zbc_condmov_nobaseupd_fullwork_iter10_20260521.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_branchfold_zbc_condmov_nobaseupd_o3_runs1000_20260521.summary.txt`
- Synth util: `synth_util_dcache256_rc128_branchfold_zbc_condmov_nobaseupd_quickutil_20260521.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_branchfold_zbc_condmov_nobaseupd_quickutil_20260521.rpt`
- Full workload summary: `coremark_fpga_dcache256_rc128_branchfold_zicond_zbkb_condmov_nobaseupd_fullwork_iter10_20260521.summary.txt`
- Synth util: `synth_util_dcache256_rc128_branchfold_zicond_zbkb_condmov_nobaseupd_quickutil_20260521.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_branchfold_zicond_zbkb_condmov_nobaseupd_quickutil_20260521.rpt`
- Full workload summary: `coremark_fpga_dcache256_rc128_branchfold_zicond_mac_condmov_nobaseupd_fullwork_iter10_20260521.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_branchfold_zicond_zbkb_mac_condmov_nobaseupd_o3_runs1000_20260521.summary.txt`
- Synth util: `synth_util_dcache256_rc128_branchfold_zicond_mac_condmov_nobaseupd_quickutil_20260521.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_branchfold_zicond_mac_condmov_nobaseupd_quickutil_20260521.rpt`
- Full workload summary: `coremark_fpga_dcache256_rc128_branchfold_zicond_zbkb_mac_condmov_nobaseupd_fullwork_iter10_20260521_fixed.summary.txt`
- Synth util: `synth_util_dcache256_rc128_branchfold_zicond_zbkb_mac_condmov_nobaseupd_quickutil_20260521.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_branchfold_zicond_zbkb_mac_condmov_nobaseupd_quickutil_20260521.rpt`
