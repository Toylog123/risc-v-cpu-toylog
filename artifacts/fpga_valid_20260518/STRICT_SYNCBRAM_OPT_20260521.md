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

## Freeze 2026-05-24 - Historical Tag-Trim Snapshot

| LUT | CoreMark/MHz | DMIPS/MHz | CoreMark CRC | CoreMark method | Hardware optimization point |
|---:|---:|---:|---:|---|---|
| 9979 | 5.220343 | 1.279852 | 0xfcaf | full workload, size=666, short-runtime host-parsed, CoreMark core files unchanged | DCache cacheable-window tag trim, 256B DCache, 128-entry redirect cache, branchfold, dynamic BHT, not-taken load fold, DCache load-use speculation, Zicond and XThead MAC/base-update |

This freeze is a hardware-only exploration snapshot under the relaxed 10000-LUT cap. The CoreMark run keeps the public workload files unchanged and uses only RTL/microarchitecture and legal build/port-layer controls. The run is still marked as short-runtime because the simulator execution does not satisfy the EEMBC >=10 second public-valid runtime floor; the result is used for same-method hardware iteration and should be presented with that caveat. The copied synthesis timing report shows negative estimated WNS, so this point is not yet a timing-closed PYNQ-Z2 implementation result.

Post-freeze rechecks on 2026-05-24 showed that the 9979-LUT number is not reproducible under the current corrected synthesis口径 using `RAM_BASE=32'h00010000`, `ROM_BYTES=65536`, and `RAM_BYTES=16384`. Keep the row above as a historical snapshot only; current engineering decisions must use the rechecked rows below.

## Current 2026-05-24 Strict Recheck

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status | Hardware optimization point |
|---|---:|---:|---:|---|---|
| DCache256 + RC128 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim + XThead MAC/base-update | 11594 | 5.220343 | TBD | area rejected under 10000 | Re-synthesized the high-score tag-trim path under the corrected RAM base and ROM/RAM size口径; score is valid for same-method comparison, but area is no longer below the 10000-LUT target |
| DCache256 + RC128 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim, no XCRC/no mempair/no base-update | 10298 | 5.150391 | TBD | area rejected under 10000 | Removes base-update and mempair hardware and disables XCRC while preserving the full CoreMark workload and CRC 0xfcaf; still slightly above 10000 LUT because DCache, fold-target decode and multiply datapath dominate |
| DCache256 + RC128 + branchfold next-cache + BHT32 + tag trim, no NT-load fold/no XCRC/no mempair/no base-update | 9481 | 5.027695 | 1.261816 | superseded | Shrinks the dynamic branch predictor from 64 to 32 entries and removes the not-taken load fold path while preserving the branchfold next-cache path; this keeps CoreMark above 5 under the corrected synthesis口径 and reduces area below 10000 LUT |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT32 + tag trim, no XCRC/no mempair/no base-update | 9594 | 5.150391 | 1.261816 | superseded | Restores the not-taken load fold path on top of the BHT32 area reduction. This recovers the 5.15 CoreMark level while keeping the corrected synthesis path below 10000 LUT; Dhrystone is unchanged, indicating the gain is CoreMark front-end/load-use specific. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT16 + tag trim, no XCRC/no mempair/no base-update | 9163 | 5.150391 | 1.261816 | superseded | Reduces the dynamic branch predictor from 32 to 16 entries while preserving the measured CoreMark and Dhrystone results. This saves 431 LUT versus BHT32 and lowers predictor state without changing the benchmark workload. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT8 + tag trim, no XCRC/no mempair/no base-update | 8943 | 5.150391 | 1.261816 | superseded | Further reduces the dynamic BHT from 16 to 8 entries with no measured CoreMark or Dhrystone loss on the current workload. This saves 220 LUT versus BHT16 and 651 LUT versus BHT32, strengthening the low-area/low-state predictor story. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT4 + tag trim, no XCRC/no mempair/no base-update | 8836 | 5.150524 | 1.261816 | superseded | Reduces the dynamic BHT from 8 to 4 entries while preserving the benchmark workload and CRC-clean CoreMark result. This saves 107 LUT versus BHT8 and slightly improves measured CoreMark ticks on the same short-runtime validation method, so it is the current low-area front-end baseline. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT2 + tag trim, no XCRC/no mempair/no base-update | 8789 | 5.150524 | 1.261816 | superseded | Reduces the dynamic BHT to 2 entries while preserving CoreMark and Dhrystone on the same hardware configuration. This saves another 47 LUT versus BHT4; the measured front-end gain is carried mainly by redirect-cache/next-cache and not-taken load fold, not by predictor table depth. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + tag trim, no XCRC/no mempair/no base-update | 8671 | 5.150524 | 1.261816 | superseded | Removes the dynamic BHT state entirely while keeping redirect-cache/next-cache and not-taken load fold. CoreMark and Dhrystone stay unchanged on the same workload, saving 118 LUT versus BHT2 and improving the low-power/low-state story. |
| DCache512 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + tag trim, no XCRC/no mempair/no base-update | 9181 | 5.591969 | 1.287490 | superseded | Doubles DCache capacity from 256B to 512B while keeping the BHT-free front-end. This reduces CoreMark data-cache/load-use pressure and improves both CoreMark and Dhrystone while staying below 10000 LUT. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + tag trim, no XCRC/no mempair/no base-update | 9943 | 5.659572 | 1.287490 | superseded | Expands DCache to 1024B while retaining the BHT-free front end. CoreMark improves further and remains below the 10000-LUT cap, but the gain over DCache512 is modest and area margin is only 57 LUT. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + tag trim, no XCRC/no mempair/no base-update | 9893 | 5.659572 | 1.287490 | current strict under-10000 candidate | Disables ZBKB in the current DCache1024 line. CoreMark and Dhrystone are unchanged, while LUT drops by 50 and leaves a slightly healthier margin below 10000. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB/no Zicond + tag trim, no XCRC/no mempair/no base-update | 9915 | 5.659572 | TBD | rejected | Disabling Zicond also preserves CoreMark, but synthesis increases LUT versus the no-ZBKB candidate, so Zicond is left enabled for the current best line. |
| DCache2048 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + tag trim, no XCRC/no mempair/no base-update | 12045 | 5.685417 | TBD | area rejected | Further doubling DCache yields only a small CoreMark gain over DCache1024 but exceeds the 10000-LUT cap. This confirms DCache1024 is the current best area/performance capacity point. |

Evidence for this freeze:

- CoreMark summary: `coremark_fpga_dcache256_luspec_rc128_dynbht_branchfold_ntload_zicond_mac_baseupd_tagtrim_rerun2k_iter10_20260524.summary.txt`
- CoreMark log: `coremark_fpga_dcache256_luspec_rc128_dynbht_branchfold_ntload_zicond_mac_baseupd_tagtrim_rerun2k_iter10_20260524.log`
- Dhrystone summary: `dhrystone_fpga_tagtrim_samehw_runs10_20260524.summary.txt`
- Dhrystone log: `YH_rv_cpu_dhrystone_zmmul_zbc_zicond_xthead_mac_idbr.log`
- Frozen synthesis utilization: `synth_util_dcache256_luspec_rc128_dynbht_branchfold_ntload_zicond_mac_baseupd_tagtrim_9979lut_20260524.rpt`
- Frozen synthesis timing: `synth_timing_dcache256_luspec_rc128_dynbht_branchfold_ntload_zicond_mac_baseupd_tagtrim_20260524.rpt` (synthesis estimate WNS -16.326 ns; timing closure remains open)

Next optimization focus:

- Raise DMIPS without changing Dhrystone benchmark logic: inspect Dhrystone profile and reduce call/branch/load-use bubbles in hardware.
- Preserve CoreMark >=5.2 while lowering DCache/regfile area where possible.
- Re-run synthesis after each accepted RTL change and record only candidates with LUT, CoreMark/MHz, DMIPS/MHz and technical point.

## LUT<10000 Exploration Log

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status | Hardware optimization point |
|---|---:|---:|---:|---|---|
| DCache256 + RC128 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + Zicond/XThead MAC + tag trim | 9979 | 5.220343 | 1.279852 | frozen exploration candidate, timing open | Keeps the synchronous BRAM line, trims DCache tag width to the cacheable RAM window, restores branch prediction and NT-load fold, and preserves the benchmark workload without changing CoreMark algorithm files |
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
| DCache128 + RC128 + branchfold + Zbc/Zicond/XThead MAC+condmove, no base-update/mempair | N/A | N/A | TBD | rejected | Tried to halve DCache area while preserving branchfold and MAC, but the FPGA-like simulation did not complete in the 15-minute wall-clock window; log reached CYCLE=10000000 at PC=0x00000054 |
| DCache256 + RC256 + branchfold + Zbc/Zicond/XThead MAC+condmove, no base-update/mempair | N/A | N/A | TBD | rejected | Tried larger redirect cache for fewer front-end misses, but simulation did not complete in the 15-minute wall-clock window; log reached CYCLE=10000000 at PC=0x00001af4 |
| DCache256 + RC128 + branchfold + fetch-redirect-reuse + Zbc/Zicond/XThead MAC+condmove, no base-update/mempair | N/A | N/A | TBD | rejected | Tried to reuse in-flight fetch responses after redirects, but the FPGA-like simulation timed out at PC=0x0000004c after 20,000,001 cycles |
| DCache256 + RC128 + branchfold + Zbc/Zicond/XThead MAC+base-update, fold rd2 bypass trimmed | 10853 | 5.220479 | TBD | area rejected | Preserved the higher base-update CoreMark path and removed second-write bypass only from fold read ports, but synthesis stayed above the 10000-LUT cap; hierarchy still shows DCache 5845 LUT and regfile 2767 LUT, so fold-port rd2 bypass is not the dominant area root cause |
| DCache256 + RC128 + branchfold + dynamic BHT strong-only + NT-load fold + DCache load-use spec + tag trim | TBD | 5.220370 | TBD | valid, not promoted | Strong-only BHT counter update is CRC-clean but the gain over the frozen RC128/tag-trim candidate is negligible, so no area synthesis was retained |
| DCache256 + RC128 + redirect-cache XOR index + branchfold + dynamic BHT + NT-load fold + tag trim | TBD | 5.179544 | TBD | rejected | XOR indexing reduced CoreMark on the same workload, so the direct-index redirect cache remains preferred |
| DCache256 + RC256 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim | 13205 | 5.354124 | TBD | area rejected | Doubling redirect-cache entries reduces front-end misses and improves CoreMark, but synthesis exceeds the relaxed 10000-LUT cap; not frozen as a valid low-area candidate |
| DCache256 + RC512 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim | 15259 | 5.424232 | TBD | area rejected | Larger redirect cache continues to improve CoreMark but LUTRAM/DCache/fold-target area grows sharply; rejected under the current low-resource target |
| DCache256 + RC1024 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim | TBD | 5.436801 | TBD | area-risk, not synthesized | Valid CRC-clean simulation, but RC512 is already 15259 LUT, so this size is not retained under the current area policy |
| DCache256 + RC2048 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim | TBD | 5.446641 | TBD | synth timeout / area-risk | Valid CRC-clean simulation with diminishing gain over RC512/RC1024; synthesis was stopped after timeout and the candidate is not retained |
| DCache256 + RC128 + ID ALU pair fold + branchfold + dynamic BHT + tag trim | N/A | N/A | TBD | rejected | Tried to fold a hot ALU pair in ID for hardware-side IPC improvement, but CoreMark timed out at PC=0x00001968 after 5,000,001 cycles |
| DCache256 + RC128 + ID ALU dependency fold + branchfold + dynamic BHT + tag trim | N/A | N/A | TBD | rejected | Tried dependent ALU fold in ID, but CoreMark timed out at PC=0x000082e8 after 5,000,001 cycles |
| DCache256 + RC128 + current corrected口径 re-synth of tag-trim base-update path | 11594 | 5.220343 | TBD | area rejected | Corrected the synthesis口径 to `RAM_BASE=32'h00010000`, `ROM_BYTES=65536`, `RAM_BYTES=16384`; the historical 9979-LUT area is not used as the current baseline |
| DCache256 + RC128 + current corrected口径 no-base/no-mempair/no-XCRC path | 10298 | 5.150391 | TBD | area rejected | Legal hardware-only reduction path; CoreMark is CRC-clean, but area remains 298 LUT above the relaxed 10000-LUT target |
| DCache256 + RC128 + no-base/no-mempair/no-XCRC/no-ZBKB path | 10319 | 5.150391 | TBD | rejected | ZBKB was not required by the executed workload, but disabling it changed synthesis structure and increased area, so the original ZBKB-enabled hardware remains preferred |
| DCache256 + RC128 + branchfold only, no next-cache/no NT-load fold | TBD | 4.750792 | TBD | rejected | Removing both fold accelerators is CRC-clean but loses too much front-end performance |
| DCache256 + RC128 + NT-load fold only, no branchfold next-cache | TBD | 4.860362 | TBD | rejected | Shows next-cache contributes more CoreMark benefit than NT-load fold for this workload |
| DCache256 + RC128 + branchfold next-cache only, no NT-load fold, BHT64 | 10010 | 5.027695 | TBD | near miss | Keeps the high-value next-cache path and removes NT-load fold; score stays above 5 but area is 10 LUT above the 10000 target |
| DCache256 + RC128 + branchfold next-cache only, no NT-load fold, BHT32 | 9481 | 5.027695 | 1.261816 | valid, superseded | BHT64 to BHT32 preserves CoreMark and saves enough control/register area to move the corrected口径 candidate below 10000 LUT |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, BHT32 | 9594 | 5.150391 | 1.261816 | valid, superseded | Adding back the not-taken load fold path costs 113 LUT over the 9481-LUT point and restores CoreMark to the corrected 5.15 level; benchmark workload remains unchanged and CRC stays 0xfcaf |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, BHT16 | 9163 | 5.150391 | 1.261816 | valid, superseded | BHT16 preserves the BHT32 CoreMark result and reduces synthesized LUT by 431; this is now the preferred low-resource configuration for the current corrected sync-BRAM line |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, BHT8 | 8943 | 5.150391 | 1.261816 | valid, superseded | BHT8 preserves the BHT16 score and cuts another 220 LUT; current workload behavior shows the front-end benefits come mainly from redirect-cache/next-cache and NT-load fold rather than a larger BHT table |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, BHT4 | 8836 | 5.150524 | 1.261816 | valid, superseded | BHT4 preserves the front-end acceleration with the smallest verified predictor state so far, cuts another 107 LUT versus BHT8, and keeps CoreMark CRC final at 0xfcaf without touching CoreMark algorithm files |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, BHT2 | 8789 | 5.150524 | 1.261816 | valid, superseded | BHT2 keeps the same CRC-clean CoreMark score as BHT4 while reducing predictor state and synthesized LUT again; this is the current low-area baseline before testing whether dynamic BHT can be removed entirely |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT | 8671 | 5.150524 | 1.261816 | valid, superseded | Removing dynamic BHT does not hurt this workload because the redirect-cache/next-cache path still supplies most early redirect wins; this saves state and LUT while preserving CRC 0xfcaf |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, static mode 2 | TBD | 5.036392 | TBD | rejected | Always-taken static prediction increased decode flushes and slowed CoreMark, so it was not synthesized |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, DCache next-prefetch | TBD | 5.143249 | TBD | rejected | Next-word DCache prefetch increased `mem_wait` and did not improve the workload, so it was not synthesized |
| DCache256 + RC64 + branchfold next-cache + NT-load fold, no dynamic BHT | TBD | 4.891428 | TBD | rejected | Smaller redirect cache reduces cache deliveries and drops CoreMark, confirming RC128 is the lower practical capacity point for this front-end |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, ICache enabled | N/A | N/A | TBD | rejected | Current ICache path timed out at PC=0x0000011c and is not valid for this sync-BRAM CoreMark line |
| DCache512 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT | 9181 | 5.591969 | 1.287490 | valid, superseded | Increasing DCache to 512B sharply reduces load-use and memory-wait pressure while keeping area below the 10000-LUT cap; this is the current best strict hardware-only point |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT | 9943 | 5.659572 | 1.287490 | valid, superseded | DCache1024 reduces CoreMark ticks again and still fits under 10000 LUT, although the area margin is tight; this becomes the current maximum-score strict point under the relaxed cap |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB | 9893 | 5.659572 | 1.287490 | current strict under-10000 candidate | ZBKB is not exercised by this workload path; disabling it preserves score and frees 50 LUT, improving low-area evidence without changing benchmark code |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB/no Zicond | 9915 | 5.659572 | TBD | rejected | Zicond removal changes synthesis packing unfavorably and costs 22 LUT versus no-ZBKB, so it is not retained |
| DCache2048 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT | 12045 | 5.685417 | TBD | area rejected | DCache2048 reduces remaining memory stalls but costs 2102 LUT over DCache1024 for only a small CoreMark gain, so it is not retained under the current low-resource target |

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
- Timeout log: `coremark_fpga_dcache128_rc128_branchfold_zicond_mac_condmov_nobaseupd_fullwork_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc256_branchfold_zicond_mac_condmov_nobaseupd_fullwork_iter10_20260521.log`
- Timeout log: `coremark_fpga_dcache256_rc128_branchfold_fetchreuse_zicond_mac_condmov_nobaseupd_fullwork_iter10_20260521.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_branchfold_zicond_mac_baseupd_foldbypass0_iter10_20260522.summary.txt`
- Synth util: `synth_util_dcache256_rc128_branchfold_zicond_mac_baseupd_foldbypass0_quickutil_20260522.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_branchfold_zicond_mac_baseupd_foldbypass0_quickutil_20260522.rpt`
- Full workload summary: `coremark_fpga_dcache256_tagtrim_bhtstrong_iter10_20260524.summary.txt`
- Full workload summary: `coremark_fpga_dcache256_tagtrim_rcxor_iter10_20260524.summary.txt`
- Full workload summary: `coremark_fpga_dcache256_tagtrim_rc256_iter10_20260524.summary.txt`
- Synth util: `synth_util_dcache256_tagtrim_rc256_13205lut_20260524.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_tagtrim_rc256_20260524.rpt`
- Synthesis log: `pynq_synth_dcache256_tagtrim_rc256_quickutil_20260524.log`
- Full workload summary: `coremark_fpga_dcache256_tagtrim_rc512_iter10_20260524.summary.txt`
- Synthesis log: `pynq_synth_dcache256_tagtrim_rc512_quickutil_20260524.log`
- Full workload summary: `coremark_fpga_dcache256_tagtrim_rc1024_iter10_20260524.summary.txt`
- Full workload summary: `coremark_fpga_dcache256_tagtrim_rc2048_iter10_20260524.summary.txt`
- Timeout log: `coremark_fpga_dcache256_tagtrim_alupair_iter10_20260524.log`
- Timeout log: `coremark_fpga_dcache256_tagtrim_aludep_iter10_20260524.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_nobase_nomempair_noxcrc_current_iter10_20260524.summary.txt`
- Synth util: `synth_util_dcache256_rc128_nobase_nomempair_noxcrc_current_10298lut_20260524.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_nobase_nomempair_noxcrc_current_10298lut_20260524.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_nobase_nomempair_noxcrc_current_10298lut_20260524.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_next_no_ntfold_bht32_current_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_next_no_ntfold_bht32_current_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache256_rc128_next_no_ntfold_bht32_current_9481lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_next_no_ntfold_bht32_current_9481lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_next_no_ntfold_bht32_current_9481lut_20260525.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_ntfold_bht32_current_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_ntfold_bht32_current_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache256_rc128_ntfold_bht32_current_9594lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_ntfold_bht32_current_9594lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_ntfold_bht32_current_9594lut_20260525.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_ntfold_bht16_current_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_ntfold_bht16_current_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache256_rc128_ntfold_bht16_current_9163lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_ntfold_bht16_current_9163lut_20260525.rpt`
- Synth timing: `synth_timing_dcache256_rc128_ntfold_bht16_current_9163lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_ntfold_bht16_current_9163lut_20260525.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_ntfold_bht8_current_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_ntfold_bht8_current_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache256_rc128_ntfold_bht8_current_8943lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_ntfold_bht8_current_8943lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_ntfold_bht8_current_8943lut_20260525.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_ntfold_bht4_current_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_ntfold_bht4_current_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache256_rc128_ntfold_bht4_current_8836lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_ntfold_bht4_current_8836lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_ntfold_bht4_current_8836lut_20260525.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_ntfold_bht2_current_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_ntfold_bht2_current_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache256_rc128_ntfold_bht2_current_8789lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_ntfold_bht2_current_8789lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_ntfold_bht2_current_8789lut_20260525.log`
- Full workload summary: `coremark_fpga_dcache256_rc128_ntfold_nobht_current_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache256_rc128_ntfold_nobht_current_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache256_rc128_ntfold_nobht_current_8671lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_ntfold_nobht_current_8671lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache256_rc128_ntfold_nobht_current_8671lut_20260525.log`
- Rejected log: `coremark_fpga_dcache256_rc128_ntfold_nobht_static2_iter10_20260525.log`
- Rejected log: `coremark_fpga_dcache256_rc128_ntfold_nobht_dcpref_iter10_20260525.log`
- Rejected log: `coremark_fpga_dcache256_rc64_ntfold_nobht_iter10_20260525.log`
- Rejected log: `coremark_fpga_dcache256_rc128_ntfold_nobht_icache_iter10_20260525.log`
- Full workload summary: `coremark_fpga_dcache512_rc128_ntfold_nobht_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache512_rc128_ntfold_nobht_runs1000_20260525.summary.txt`
- Synth util: `synth_util_dcache512_rc128_ntfold_nobht_9181lut_20260525.rpt`
- Synth hierarchy: `synth_util_hier_dcache512_rc128_ntfold_nobht_9181lut_20260525.rpt`
- Synthesis log: `pynq_synth_dcache512_rc128_ntfold_nobht_9181lut_20260525.log`
- Full workload summary: `coremark_fpga_dcache1024_rc128_ntfold_nobht_iter10_20260525.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache1024_rc128_ntfold_nobht_runs1000_20260526.summary.txt`
- Synth util: `synth_util_dcache1024_rc128_ntfold_nobht_9943lut_20260526.rpt`
- Synth hierarchy: `synth_util_hier_dcache1024_rc128_ntfold_nobht_9943lut_20260526.rpt`
- Synthesis log: `pynq_synth_dcache1024_rc128_ntfold_nobht_9943lut_20260526.log`
- Full workload summary: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_iter10_20260526.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_runs1000_20260526.summary.txt`
- Synth util: `synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_9893lut_20260526.rpt`
- Synth hierarchy: `synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_9893lut_20260526.rpt`
- Synthesis log: `pynq_synth_dcache1024_rc128_ntfold_nobht_nozbkb_9893lut_20260526.log`
- Rejected summary: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_nozicond_iter10_20260526.summary.txt`
- Rejected synth util: `synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_nozicond_9915lut_20260526.rpt`
- Rejected synth hierarchy: `synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_nozicond_9915lut_20260526.rpt`
- Area-rejected summary: `coremark_fpga_dcache2048_rc128_ntfold_nobht_iter10_20260526.summary.txt`
- Area-rejected synth util: `synth_util_dcache2048_rc128_ntfold_nobht_12045lut_20260526.rpt`
- Area-rejected synth hierarchy: `synth_util_hier_dcache2048_rc128_ntfold_nobht_12045lut_20260526.rpt`
- Area-rejected synthesis log: `pynq_synth_dcache2048_rc128_ntfold_nobht_12045lut_20260526.log`
