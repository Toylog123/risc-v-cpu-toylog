# Strict Sync-BRAM Optimization Record - 2026-05-21

This record tracks only hardware-side changes under the current PYNQ-Z2 / sync-BRAM validation line. CoreMark core workload files are not modified for these entries. CoreMark summaries are CRC-clean, short-runtime reproducible runs; a strict EEMBC public-valid report still requires a >=10 second run or board-level timing evidence.

## 2026-05-26 Takeover Entry

Current handoff file:

```text
artifacts/fpga_valid_20260518/SYNCBRAM_OPT_HANDOFF_20260526.md
```

Current frozen best valid candidate:

| Commit | Tag | LUT | CoreMark/MHz | DMIPS/MHz | Hardware optimization point |
|---|---|---:|---:|---:|---|
| `this-commit` | `freeze-strict-rctagtrim-9796lut-coremark5p66-20260528` | 9796 | 5.659572 | 1.287490 | DCache1024, RC128, branchfold next-cache, NT-load fold, no dynamic BHT, no ZBKB, DCache tag trim, redirect-cache PC tag-width trim |

Important handoff note: the 9796-LUT row is the current RTL-level area improvement after the parameter space was exhausted. It preserves the 5.659572 CoreMark/MHz score and reduces LUT by trimming redirect-cache stored PC bits down to the actual tag bits.

Selected main frozen low-area 5+ baseline:

| Commit | Tag | LUT | CoreMark/MHz | DMIPS/MHz | Hardware optimization point |
|---|---|---:|---:|---:|---|
| `tag target` | `freeze-strict-dcache512-rc64-nonext-8201lut-coremark5p07-20260528` | 8201 | 5.072560 | 1.287490 | DCache512, RC64, branchfold, no branchfold next-cache, NT-load fold, no dynamic BHT, no ZBKB, DCache tag trim, redirect-cache PC tag-width trim |
| `tag target` | `freeze-strict-dcache512-rc64-nonext-foldrs3off-7849lut-coremark5p07-20260528` | 7849 | 5.072560 | 1.287490 | DCache512, RC64, branchfold, no branchfold next-cache, NT-load fold, fold-rs3 read port gated off, no dynamic BHT, no ZBKB, DCache tag trim, redirect-cache PC tag-width trim |
| `tag target` | `freeze-strict-dcache512-rc64-nonext-foldrs23off-7639lut-coremark5p07-20260528` | 7639 | 5.067602 | 1.287490 | DCache512, RC64, branchfold, no branchfold next-cache, NT-load fold, fold-rs2/rs3 read ports gated off, no dynamic BHT, no ZBKB, DCache tag trim, redirect-cache PC tag-width trim |
| `tag target` | `freeze-strict-dcache512-rc64-nonext-foldrs23off-nord2-7596lut-coremark5p07-20260528` | 7596 | 5.067602 | 1.287490 | DCache512, RC64, branchfold, no branchfold next-cache, NT-load fold, fold-rs2/rs3 read ports gated off, inactive regfile second write port disabled, no dynamic BHT, no ZBKB, DCache tag trim, redirect-cache PC tag-width trim |
| `5c4476b` | `freeze-strict-dcache512-rc32-next-foldrs23off-nord2-7437lut-coremark5p04-20260529` | 7437 | 5.042742 | 1.287490 | Selected main frozen baseline. DCache512, RC32, branchfold next-cache re-enabled, NT-load fold, fold-rs2/rs3 read ports gated off, inactive regfile second write port disabled, no dynamic BHT, no ZBKB, DCache tag trim, redirect-cache PC tag-width trim |
| `tag target` | `freeze-strict-dcache512-rc32-next-nozicond-7377lut-coremark5p04-20260531` | 7377 | 5.042742 | 1.287490 | Current selected main frozen baseline. Same RC32/next low-area path as the 7437-LUT point, with Zicond hardware disabled. CoreMark and Dhrystone stay unchanged while synthesis drops another 60 LUT. |
| `tag target` | `freeze-strict-dcache512-rc32-next-nozicond-noretiming-notiming-7216lut-coremark5p04-20260601` | 7216 | 5.042742 | 1.287490 | Current selected low-resource freeze. Same RTL/benchmark evidence as the 7377-LUT no-Zicond point; Vivado quick synth disables retiming and timing-driven override, saving another 161 LUT. |
| `tag target` | `freeze-strict-dcache512-rc64-nonext-nozicond-noretiming-notiming-7316lut-coremark5p07-20260601` | 7316 | 5.067602 | 1.287490 | Current balanced low-resource freeze. Same nonext RC64 path as the 7596-LUT point, with Zicond disabled and no-retiming/no-timing-driven quick synth; costs 100 LUT over 7216 while recovering 0.024860 CoreMark/MHz. |

2026-05-28 note: the historical RC64 timeout was rechecked because its old log showed a missing `YH_rv_cpu_coremark_rv32.mem32.hex` warning. With corrected runtime staging, RC64 is CRC-clean. DCache512/RC64 with branchfold next-cache disabled, fold-rs2/rs3 read-port gating, and inactive regfile second-write-port gating is the newest lower-area 5+ point: it saves 2200 LUT versus the RC128 current best, at the cost of a CoreMark drop from 5.659572 to 5.067602. DCache256/RC64 is also CRC-clean but drops below 5 CoreMark/MHz (`4.891219`).

2026-05-29 note: RC32 was rechecked with branchfold next-cache re-enabled. This keeps the full CoreMark workload CRC-clean (`crcfinal=0xfcaf`) and preserves the 5+ target at lower LUT: `7437 LUT / 5.042742 CoreMark/MHz / 1.287490 DMIPS/MHz`. This is now the preferred low-area 5+ frozen point. Compared with the previous 7596-LUT point, it saves another 159 LUT while losing only 0.024860 CoreMark/MHz. DMIPS is unchanged because this path mainly changes front-end redirect/cache area rather than the Dhrystone-dominant integer/control mix.

2026-05-29 freeze decision update: the user selected the `7437 LUT / 5.042742 CoreMark/MHz / 1.287490 DMIPS/MHz` point as the main frozen version because it has the best low-area balance among the validated 5+ CoreMark candidates. The `8983 LUT / 5.608440 CoreMark/MHz` point remains a larger high-score reference only. Interrupted M-extension Dhrystone experiments after this decision produced no valid metric and must not be mixed into the frozen evidence.

2026-05-31 freeze decision update: the same low-area RC32/next path was rechecked with Zicond disabled. The exact CoreMark/Dhrystone metrics are unchanged (`5.042742 CoreMark/MHz / 1.287490 DMIPS/MHz`), while synthesis reports `7377 LUT`. This supersedes the 7437-LUT point as the selected main low-area freeze. The older 7437-LUT tag remains a valid comparison baseline.

2026-06-01 low-resource synth update: the 7377-LUT no-Zicond low-area line was rerun with retiming disabled and timing-driven synth disabled. The RTL and benchmark evidence are unchanged, while quick synthesis reports `7216 LUT`. This supersedes the 7377-LUT point as the selected low-resource freeze; full implementation timing remains a later promotion check.

2026-06-01 balanced low-resource update: the DCache512/RC64/nonext path was rerun with Zicond disabled plus the no-retiming/no-timing-driven quick synth options. CoreMark and Dhrystone stay at `5.067602 CoreMark/MHz / 1.287490 DMIPS/MHz`, while synthesis reports `7316 LUT`. This is the current balanced low-resource point when a small +100 LUT area cost over the 7216-LUT line is acceptable.

2026-05-29 high-score reference recheck: after the regfile/fold-port area trims, the DCache1024/RC128 line was rerun under the same strict sync-BRAM hardware-only rules. It is CRC-clean at `8983 LUT / 5.608440 CoreMark/MHz / 1.287490 DMIPS/MHz`. This is the current best under-10000-LUT reference point, but not the low-area recommendation because the selected 7377-LUT line is much smaller.

2026-05-29 medium-area tradeoff: DCache256/RC128 was rerun as a middle point between the low-area line and the 8983-LUT high-score line. It is CRC-clean at `7914 LUT / 5.106160 CoreMark/MHz / 1.261816 DMIPS/MHz`. Against the selected 7377-LUT line, this buys about `+0.063418 CoreMark/MHz` at the cost of `+537 LUT`, but DMIPS is slightly lower.

2026-05-29 rejected boundaries:

- `DCache512 + RC16 + branchfold next-cache`: CRC-clean, but drops to `4.950213 CoreMark/MHz`; RC16 is below the current 5+ capacity floor.
- `DCache512 + RC32 + branchfold next-cache + DCache word-only`: CRC-clean, but drops to `4.427367 CoreMark/MHz`; CoreMark uses enough byte/halfword traffic that bypassing non-word accesses loses too much locality.
- `DCache512 + RC32 + branchfold next-cache + no NT-load fold`: CRC-clean at `5.042666 CoreMark/MHz`, but synthesizes to `7578 LUT`, so it is larger and fractionally slower than the retained `7377 LUT / 5.042742` low-area point.
- `DCache512 + RC32 + branchfold next-cache + no XThead condmove`: timed out at `PC=000004a8`; this hardware path must remain enabled for the current legal benchmark image.
- `DCache512 + RC32 + branchfold next-cache + no regular redirect lookup`: CRC-clean but drops to `4.837321 CoreMark/MHz`; the regular lookup path remains part of the 5+ front-end design.

Next prepared experiment:

```text
DCache1024 + RC128 + no dynamic BHT + no ZBKB + fetch redirect reuse
```

Run from the worktree root:

```powershell
_tmp\run_coremark_ntfold_bht16.cmd
```

Decision rule: promote only if CoreMark is CRC-clean (`0xfcaf`), the workload completes, Dhrystone is rerun for the exact candidate, and a matching LUT report is generated.

2026-05-28 promotion evidence:

- CoreMark summary: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_iter10_20260528.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.rpt`
- Synth hierarchy: `synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.rpt`
- Synth log: `pynq_synth_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.log`

2026-05-28 RC64 lower-area evidence:

- CoreMark summary: `coremark_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
- Dhrystone summary: `dhrystone_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt`
- Synth hierarchy: `synth_util_hier_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt`
- Synth log: `pynq_synth_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.log`
- DCache512 CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
- DCache512 Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
- DCache512 synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt`
- DCache512 synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt`
- DCache512 synth log: `pynq_synth_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.log`
- DCache256 boundary summary: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
- DCache512 nonext CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_recheck_iter10_20260528.summary.txt`
- DCache512 nonext Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_runs1000_20260528.summary.txt`
- DCache512 nonext synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt`
- DCache512 nonext synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt`
- DCache512 nonext fold-rs3-off CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_recheck_iter10_20260528.summary.txt`
- DCache512 nonext fold-rs3-off Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_runs1000_20260528.summary.txt`
- DCache512 nonext fold-rs3-off synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_7849lut_20260528.rpt`
- DCache512 nonext fold-rs3-off synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_7849lut_20260528.rpt`
- DCache512 nonext fold-rs2/rs3-off CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_recheck_iter10_20260528.summary.txt`
- DCache512 nonext fold-rs2/rs3-off Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_runs1000_20260528.summary.txt`
- DCache512 nonext fold-rs2/rs3-off synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_7639lut_20260528.rpt`
- DCache512 nonext fold-rs2/rs3-off synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_7639lut_20260528.rpt`
- DCache512 nonext fold-rs2/rs3-off no-rd2 CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_recheck_iter10_20260528.summary.txt`
- DCache512 nonext fold-rs2/rs3-off no-rd2 Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_runs1000_20260528.summary.txt`
- DCache512 nonext fold-rs2/rs3-off no-rd2 synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_7596lut_20260528.rpt`
- DCache512 nonext fold-rs2/rs3-off no-rd2 synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_7596lut_20260528.rpt`
- DCache512 nonext fold-rs2/rs3-off no-rd2 synth timing: `synth_timing_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_7596lut_20260528.rpt`
- DCache512 nonext fold-rs2/rs3-off RC32 rejected summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_rc32_recheck_iter10_20260528.summary.txt`
- DCache512 nonext fold-rs1/rs2/rs3-off rejected summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs123off_recheck_iter10_20260528.summary.txt`
- DCache512 nonext store-invalidate rejected summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_storeinv_recheck_iter10_20260528.summary.txt`
- DCache512 nonext store-invalidate rejected synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_storeinv_8330lut_20260528.rpt`
- DCache512 nonext store-invalidate rejected synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_storeinv_8330lut_20260528.rpt`
- DCache512 nontload summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nontload_recheck_iter10_20260528.summary.txt`
- DCache512 nontload synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nontload_8362lut_20260528.rpt`
- DCache512 nolspec boundary summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nolspec_recheck_iter10_20260528.summary.txt`
- DCache512 nonext+nontload boundary summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_nontload_recheck_iter10_20260528.summary.txt`
- DCache512 RC32+next low-area CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_rc32_next_recheck_iter10_20260528.summary.txt`
- DCache512 RC32+next low-area Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_rc32_next_runs1000_20260528.summary.txt`
- DCache512 RC32+next low-area synth util: `synth_util_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_7437lut_20260529.rpt`
- DCache512 RC32+next low-area synth hierarchy: `synth_util_hier_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_7437lut_20260529.rpt`
- DCache512 RC32+next low-area synth timing: `synth_timing_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_7437lut_20260529.rpt`
- DCache512 RC32+next no-Zicond selected freeze CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_recheck_iter10_20260528.summary.txt`
- DCache512 RC32+next no-Zicond selected freeze Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_runs1000_20260528.summary.txt`
- DCache512 RC32+next no-Zicond selected freeze synth util: `synth_util_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_nozicond_7377lut_20260531.rpt`
- DCache512 RC32+next no-Zicond selected freeze synth hierarchy: `synth_util_hier_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_nozicond_7377lut_20260531.rpt`
- DCache512 RC32+next no-Zicond no-retiming/no-timing-driven synth util: `synth_util_dcache512_rc32_next_nozicond_noretiming_notiming_20260601.rpt`
- DCache512 RC32+next no-Zicond no-retiming/no-timing-driven synth hierarchy: `synth_util_hier_dcache512_rc32_next_nozicond_noretiming_notiming_20260601.rpt`
- DCache512 RC64/nonext no-Zicond CoreMark summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_nonext_nozicond_recheck_iter10_20260528.summary.txt`
- DCache512 RC64/nonext no-Zicond Dhrystone summary: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_nonext_nozicond_runs1000_20260528.summary.txt`
- DCache512 RC64/nonext no-Zicond no-retiming/no-timing-driven synth util: `synth_util_dcache512_rc64_nonext_nozicond_noretiming_notiming_20260601.rpt`
- DCache512 RC64/nonext no-Zicond no-retiming/no-timing-driven synth hierarchy: `synth_util_hier_dcache512_rc64_nonext_nozicond_noretiming_notiming_20260601.rpt`
- High-score DCache1024/RC128 recheck CoreMark summary: `coremark_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_rc128_current_rerun_recheck_iter10_20260528.summary.txt`
- High-score DCache1024/RC128 recheck Dhrystone summary: `dhrystone_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_rc128_current_rerun_runs1000_20260528.summary.txt`
- High-score DCache1024/RC128 recheck synth util: `synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_current_8983lut_20260529.rpt`
- High-score DCache1024/RC128 recheck synth hierarchy: `synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_current_8983lut_20260529.rpt`
- High-score DCache1024/RC128 recheck synth timing: `synth_timing_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_current_8983lut_20260529.rpt`
- Medium-area DCache256/RC128 CoreMark summary: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256r128_recheck_iter10_20260528.summary.txt`
- Medium-area DCache256/RC128 Dhrystone summary: `dhrystone_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256r128_runs1000_20260528.summary.txt`
- Medium-area DCache256/RC128 synth util: `synth_util_dcache256_rc128_ntfold_nobht_nozbkb_rctagtrim_current_7914lut_20260529.rpt`
- Medium-area DCache256/RC128 synth hierarchy: `synth_util_hier_dcache256_rc128_ntfold_nobht_nozbkb_rctagtrim_current_7914lut_20260529.rpt`
- Medium-area DCache256/RC128 synth timing: `synth_timing_dcache256_rc128_ntfold_nobht_nozbkb_rctagtrim_current_7914lut_20260529.rpt`
- Rejected RC16 summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_rc16_next_recheck_iter10_20260528.summary.txt`
- Rejected word-only summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_rc32_next_wordonly_recheck_iter10_20260528.summary.txt`
- Rejected no-NT-load-fold RC32 summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nontload_r32nn_recheck_iter10_20260528.summary.txt`
- Rejected no-NT-load-fold RC32 synth util: `synth_util_dcache512_rc32_next_nontload_r32nn_7578lut_20260529.rpt`
- Rejected no-NT-load-fold RC32 synth hierarchy: `synth_util_hier_dcache512_rc32_next_nontload_r32nn_7578lut_20260529.rpt`

## Current Best Candidate Under 7000 LUT

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status | Hardware optimization point |
|---|---:|---:|---:|---|---|
| sync-BRAM baseline, RC1024 | 5938 | 3.413191 | 2.381087 | baseline | Current synchronous BRAM鍙ｅ緞; no DMEM preissue |
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

## Strict鍙ｅ緞 Notes

- Only RTL / microarchitecture options are counted here.
- CoreMark algorithm files remain unchanged.
- Sync-BRAM behavior is preserved; no async/negedge DMEM score path is mixed into this table.
- RC128 is frozen as the best under-7000-LUT candidate so far, but timing closure still needs implementation-stage verification.

## Freeze 2026-05-24 - Historical Tag-Trim Snapshot

| LUT | CoreMark/MHz | DMIPS/MHz | CoreMark CRC | CoreMark method | Hardware optimization point |
|---:|---:|---:|---:|---|---|
| 9979 | 5.220343 | 1.279852 | 0xfcaf | full workload, size=666, short-runtime host-parsed, CoreMark core files unchanged | DCache cacheable-window tag trim, 256B DCache, 128-entry redirect cache, branchfold, dynamic BHT, not-taken load fold, DCache load-use speculation, Zicond and XThead MAC/base-update |

This freeze is a hardware-only exploration snapshot under the relaxed 10000-LUT cap. The CoreMark run keeps the public workload files unchanged and uses only RTL/microarchitecture and legal build/port-layer controls. The run is still marked as short-runtime because the simulator execution does not satisfy the EEMBC >=10 second public-valid runtime floor; the result is used for same-method hardware iteration and should be presented with that caveat. The copied synthesis timing report shows negative estimated WNS, so this point is not yet a timing-closed PYNQ-Z2 implementation result.

Post-freeze rechecks on 2026-05-24 showed that the 9979-LUT number is not reproducible under the current corrected synthesis鍙ｅ緞 using `RAM_BASE=32'h00010000`, `ROM_BYTES=65536`, and `RAM_BYTES=16384`. Keep the row above as a historical snapshot only; current engineering decisions must use the rechecked rows below.

## Current 2026-05-24 Strict Recheck

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status | Hardware optimization point |
|---|---:|---:|---:|---|---|
| DCache256 + RC128 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim + XThead MAC/base-update | 11594 | 5.220343 | TBD | area rejected under 10000 | Re-synthesized the high-score tag-trim path under the corrected RAM base and ROM/RAM size鍙ｅ緞; score is valid for same-method comparison, but area is no longer below the 10000-LUT target |
| DCache256 + RC128 + branchfold + dynamic BHT + NT-load fold + DCache load-use spec + tag trim, no XCRC/no mempair/no base-update | 10298 | 5.150391 | TBD | area rejected under 10000 | Removes base-update and mempair hardware and disables XCRC while preserving the full CoreMark workload and CRC 0xfcaf; still slightly above 10000 LUT because DCache, fold-target decode and multiply datapath dominate |
| DCache256 + RC128 + branchfold next-cache + BHT32 + tag trim, no NT-load fold/no XCRC/no mempair/no base-update | 9481 | 5.027695 | 1.261816 | superseded | Shrinks the dynamic branch predictor from 64 to 32 entries and removes the not-taken load fold path while preserving the branchfold next-cache path; this keeps CoreMark above 5 under the corrected synthesis鍙ｅ緞 and reduces area below 10000 LUT |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT32 + tag trim, no XCRC/no mempair/no base-update | 9594 | 5.150391 | 1.261816 | superseded | Restores the not-taken load fold path on top of the BHT32 area reduction. This recovers the 5.15 CoreMark level while keeping the corrected synthesis path below 10000 LUT; Dhrystone is unchanged, indicating the gain is CoreMark front-end/load-use specific. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT16 + tag trim, no XCRC/no mempair/no base-update | 9163 | 5.150391 | 1.261816 | superseded | Reduces the dynamic branch predictor from 32 to 16 entries while preserving the measured CoreMark and Dhrystone results. This saves 431 LUT versus BHT32 and lowers predictor state without changing the benchmark workload. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT8 + tag trim, no XCRC/no mempair/no base-update | 8943 | 5.150391 | 1.261816 | superseded | Further reduces the dynamic BHT from 16 to 8 entries with no measured CoreMark or Dhrystone loss on the current workload. This saves 220 LUT versus BHT16 and 651 LUT versus BHT32, strengthening the low-area/low-state predictor story. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT4 + tag trim, no XCRC/no mempair/no base-update | 8836 | 5.150524 | 1.261816 | superseded | Reduces the dynamic BHT from 8 to 4 entries while preserving the benchmark workload and CRC-clean CoreMark result. This saves 107 LUT versus BHT8 and slightly improves measured CoreMark ticks on the same short-runtime validation method, so it is the current low-area front-end baseline. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + BHT2 + tag trim, no XCRC/no mempair/no base-update | 8789 | 5.150524 | 1.261816 | superseded | Reduces the dynamic BHT to 2 entries while preserving CoreMark and Dhrystone on the same hardware configuration. This saves another 47 LUT versus BHT4; the measured front-end gain is carried mainly by redirect-cache/next-cache and not-taken load fold, not by predictor table depth. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + tag trim, no XCRC/no mempair/no base-update | 8671 | 5.150524 | 1.261816 | superseded | Removes the dynamic BHT state entirely while keeping redirect-cache/next-cache and not-taken load fold. CoreMark and Dhrystone stay unchanged on the same workload, saving 118 LUT versus BHT2 and improving the low-power/low-state story. |
| DCache512 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + tag trim, no XCRC/no mempair/no base-update | 9181 | 5.591969 | 1.287490 | superseded | Doubles DCache capacity from 256B to 512B while keeping the BHT-free front-end. This reduces CoreMark data-cache/load-use pressure and improves both CoreMark and Dhrystone while staying below 10000 LUT. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + tag trim, no XCRC/no mempair/no base-update | 9943 | 5.659572 | 1.287490 | superseded | Expands DCache to 1024B while retaining the BHT-free front end. CoreMark improves further and remains below the 10000-LUT cap, but the gain over DCache512 is modest and area margin is only 57 LUT. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + tag trim, no XCRC/no mempair/no base-update | 9893 | 5.659572 | 1.287490 | superseded | Disables ZBKB in the current DCache1024 line. CoreMark and Dhrystone are unchanged, while LUT drops by 50 and leaves a slightly healthier margin below 10000. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 9796 | 5.659572 | 1.287490 | current strict under-10000 candidate | Stores only the redirect-cache PC tag bits instead of the full 32-bit PC. CoreMark/Dhrystone are unchanged and LUT drops by another 97, making this the current best validated low-area RTL point. |
| DCache1024 + RC64 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 9185 | 5.351560 | 1.287490 | current lower-area 5+ candidate | Rechecks RC64 with corrected runtime staging after the old timeout log showed a missing mem32 image warning. This saves 611 LUT versus RC128 while keeping CRC-clean CoreMark above 5 and unchanged Dhrystone. |
| DCache512 + RC64 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 8425 | 5.291075 | 1.287490 | current lower-area 5+ candidate | Reduces DCache from 1024B to 512B while keeping the corrected RC64 path. This saves 760 LUT versus DCache1024/RC64 and 1371 LUT versus the RC128 maximum-score line while staying CRC-clean above 5 CoreMark/MHz. |
| DCache256 + RC64 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | TBD | 4.891219 | TBD | boundary rejected | CRC-clean but below the 5 CoreMark/MHz target, so 256B is too small for the current performance goal. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 8201 | 5.072560 | 1.287490 | current lower-area 5+ candidate | Disables the next-cache fold delivery path while keeping NT-load fold. This saves 224 LUT versus the 8425-LUT DCache512/RC64 point and remains CRC-clean above 5 CoreMark/MHz. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + fold-rs3 read-port gated off + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 7849 | 5.072560 | 1.287490 | current lower-area 5+ candidate | Splits the fold rs3 read port from the normal XThead rs3 path. With ALU pair/dependency fold disabled, branch-folded targets that need rs3 are not folded and execute normally, preserving CRC and score while saving 352 LUT versus the 8201-LUT line. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 7639 | 5.067602 | 1.287490 | current lower-area 5+ candidate | Further splits the fold rs2 read port. Folded targets that need rs2 or rs3 are left for normal execution, keeping correctness and 5+ CoreMark while saving 210 LUT versus fold-rs3-off and 562 LUT versus the original 8201-LUT nonext line. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive second regfile write port disabled + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 7596 | 5.067602 | 1.287490 | current lower-area 5+ candidate | Adds an explicit regfile second-write-port parameter and disables it for the no-base-update/no-mempair configuration. CoreMark/Dhrystone stay unchanged, while LUT drops another 43 versus the 7639-LUT line. |
| DCache512 + RC32 + branchfold + no branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | TBD | 4.894676 | TBD | boundary rejected | Reducing redirect cache entries from 64 to 32 lowers cache delivery counts and drops below 5. RC64 is the current front-end capacity floor for this low-area line. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + fold-rs1/rs2/rs3 read ports gated off + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | TBD | 4.934412 | TBD | boundary rejected | Turning off the folded rs1 read port removes nearly all useful fold delivery (`fold_valid=0`, `nt_fold_valid=4`) and drops below 5 CoreMark/MHz. This confirms rs1 is the minimum folded read port to retain for the current low-area 5+ line. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + store-hit invalidate + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 8330 | 4.764133 | TBD | rejected | Replaced store-hit cache-line update with write-through plus cache-line invalidate. The CoreMark workload remains CRC-clean, but store/load locality loss drops below 5 and synthesis increases LUT versus the 8201-LUT point, so this hardware simplification is not retained. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive second regfile write port disabled + single DCache tag/valid read arbitration | 7531 | 4.908619 | TBD | rejected | Shares the DCache tag/valid read between normal cache-hit lookup and load-use probe. CRC remains clean, but simultaneous probe/cache access is on the workload hot path; only 65 LUT are saved versus the 7596-LUT line while CoreMark drops below 5. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive second regfile write port disabled + XThead MAC disabled | N/A | N/A | TBD | rejected | The existing full CoreMark image times out at `PC=0000004c` when XThead MAC is disabled, so this ISA hardware is required by the current legal compiled workload and cannot be removed from this path. |
| DCache512 + RC64 + branchfold next-cache + NT-load fold + fold-rs1/rs2/rs3 read ports gated off + inactive second regfile write port disabled + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim | 7501 | 4.934412 | TBD | rejected | Re-enabling next-cache while disabling folded rs1 still drops below 5. The 95-LUT saving versus the 7596-LUT line is too small for the performance loss, so fold-rs1 remains the minimum retained folded read port. |
| DCache256 + RC128 + branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive second regfile write port disabled + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim | 7914 | 5.106160 | TBD | valid, not promoted | Trades a smaller DCache for a larger redirect cache and restores next-cache. It is CRC-clean and scores above the 7596-LUT line, but costs 318 extra LUT, so it is retained only as a score/area tradeoff reference. |
| DCache128 + RC64 + branchfold + no branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive second regfile write port disabled + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim | TBD | 4.369157 | TBD | rejected | CRC-clean but too slow; 128B DCache is below the practical capacity floor for the current workload. |
| DCache128 + RC128 + branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive second regfile write port disabled + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim | TBD | 4.695781 | TBD | rejected | Larger redirect cache and next-cache recover part of the loss but still remain below 5 CoreMark/MHz, confirming 128B DCache is not viable for the current 5+ target. |
| DCache512 + RC64 + branchfold next-cache + no NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | 8362 | 5.191960 | TBD | superseded low-area candidate | Disabling NT-load fold saves only 63 LUT versus 8425 while preserving more CoreMark than nonext; retained as evidence but not the lowest 5+ point. |
| DCache512 + RC64 + branchfold + no branchfold next-cache + no NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | TBD | 4.981265 | TBD | boundary rejected | CRC-clean but below the 5 CoreMark/MHz target, so both fold trims together are too aggressive. |
| DCache512 + RC64 + branchfold next-cache + NT-load fold + no load-use DCache probe + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim, no XCRC/no mempair/no base-update | TBD | 4.958065 | TBD | boundary rejected | Removing load-use speculation drops below 5, so the DCache probe path remains required for the current 5+ target. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB/no Zicond + tag trim, no XCRC/no mempair/no base-update | 9915 | 5.659572 | TBD | rejected | Disabling Zicond also preserves CoreMark, but synthesis increases LUT versus the no-ZBKB candidate, so Zicond is left enabled for the current best line. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB/no XThead condmove + tag trim, no XCRC/no mempair/no base-update | N/A | N/A | TBD | rejected | Disabling XThead conditional move caused CoreMark timeout at PC=0x00000478, so this path is required by the current compiled target or by the surrounding control/dataflow assumptions. |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB/no Zbc + tag trim, no XCRC/no mempair/no base-update | N/A | N/A | TBD | rejected | Disabling Zbc caused CoreMark timeout at PC=0x00001b58, so Zbc remains required for the current compiled workload/hardware contract. |
| DCache1024 + RC256 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + tag trim, no XCRC/no mempair/no base-update | 10983 | 5.809144 | TBD | area rejected | Doubling redirect cache from 128 to 256 improves CoreMark, but the extra distributed RAM pushes the design above 10000 LUT. This is kept as a performance reference, not a current low-resource candidate. |
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
| DCache256 + RC128 + current corrected鍙ｅ緞 re-synth of tag-trim base-update path | 11594 | 5.220343 | TBD | area rejected | Corrected the synthesis鍙ｅ緞 to `RAM_BASE=32'h00010000`, `ROM_BYTES=65536`, `RAM_BYTES=16384`; the historical 9979-LUT area is not used as the current baseline |
| DCache256 + RC128 + current corrected鍙ｅ緞 no-base/no-mempair/no-XCRC path | 10298 | 5.150391 | TBD | area rejected | Legal hardware-only reduction path; CoreMark is CRC-clean, but area remains 298 LUT above the relaxed 10000-LUT target |
| DCache256 + RC128 + no-base/no-mempair/no-XCRC/no-ZBKB path | 10319 | 5.150391 | TBD | rejected | ZBKB was not required by the executed workload, but disabling it changed synthesis structure and increased area, so the original ZBKB-enabled hardware remains preferred |
| DCache256 + RC128 + branchfold only, no next-cache/no NT-load fold | TBD | 4.750792 | TBD | rejected | Removing both fold accelerators is CRC-clean but loses too much front-end performance |
| DCache256 + RC128 + NT-load fold only, no branchfold next-cache | TBD | 4.860362 | TBD | rejected | Shows next-cache contributes more CoreMark benefit than NT-load fold for this workload |
| DCache256 + RC128 + branchfold next-cache only, no NT-load fold, BHT64 | 10010 | 5.027695 | TBD | near miss | Keeps the high-value next-cache path and removes NT-load fold; score stays above 5 but area is 10 LUT above the 10000 target |
| DCache256 + RC128 + branchfold next-cache only, no NT-load fold, BHT32 | 9481 | 5.027695 | 1.261816 | valid, superseded | BHT64 to BHT32 preserves CoreMark and saves enough control/register area to move the corrected鍙ｅ緞 candidate below 10000 LUT |
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
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB | 9893 | 5.659572 | 1.287490 | superseded | ZBKB is not exercised by this workload path; disabling it preserves score and frees 50 LUT, improving low-area evidence without changing benchmark code |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 9796 | 5.659572 | 1.287490 | current strict under-10000 candidate | Redirect cache stores only PC tag bits, not the full PC. This preserves CoreMark CRC `0xfcaf` and Dhrystone while saving 97 LUT versus the previous frozen best |
| DCache1024 + RC64 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 9185 | 5.351560 | 1.287490 | lower-area valid 5+ candidate | Corrected runtime staging fixes the old RC64 missing mem32-image issue; RC64 saves 611 LUT versus RC128 and remains CRC-clean above 5 CoreMark/MHz |
| DCache512 + RC64 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 8425 | 5.291075 | 1.287490 | current lower-area 5+ candidate | Shrinks DCache capacity while preserving the same front-end and ISA settings; saves another 760 LUT versus the 1024B/RC64 line and remains above 5 CoreMark/MHz |
| DCache256 + RC64 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | TBD | 4.891219 | TBD | rejected | CRC-clean but performance falls below the current 5+ target, so this is recorded only as a low-area boundary |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 8201 | 5.072560 | 1.287490 | current lower-area 5+ candidate | Lowest currently validated 5+ point; disables next-cache fold delivery and keeps NT-load fold |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold, fold-rs3 read-port gated off, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 7849 | 5.072560 | 1.287490 | current lower-area 5+ candidate | Gating the unused folded rs3 read port preserves the current benchmark scores and reduces area by 352 LUT versus the 8201-LUT point |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 7639 | 5.067602 | 1.287490 | current lower-area 5+ candidate | Gating both folded rs2 and rs3 read ports keeps CoreMark above 5 with only a small fold-count reduction and saves 562 LUT versus the original 8201-LUT point |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, inactive second regfile write port disabled, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 7596 | 5.067602 | 1.287490 | current lower-area 5+ candidate | Disables the unused second regfile write port under the current no-base-update/no-mempair build; score is unchanged and area drops by 43 LUT |
| DCache512 + RC32 + branchfold + no branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | TBD | 4.894676 | TBD | rejected | RC32 loses too many redirect-cache deliveries and falls below 5 |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold, fold-rs1/rs2/rs3 read ports gated off, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | TBD | 4.934412 | TBD | rejected | Removing fold-rs1 disables the useful folded load/target path and drops below 5, so it is not synthesized |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, inactive second regfile write port disabled, single DCache tag/valid read arbitration | 7531 | 4.908619 | TBD | rejected | Small LUT saving but below the 5 CoreMark/MHz boundary |
| DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, inactive second regfile write port disabled, XThead MAC disabled | N/A | N/A | TBD | rejected | Current compiled workload depends on XThead MAC; simulation timed out at PC=0000004c |
| DCache512 + RC64 + branchfold next-cache + NT-load fold, fold-rs1/rs2/rs3 read ports gated off, inactive second regfile write port disabled | 7501 | 4.934412 | TBD | rejected | Next-cache does not recover the folded-rs1 loss; below the 5 CoreMark/MHz boundary |
| DCache256 + RC128 + branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, inactive second regfile write port disabled | 7914 | 5.106160 | TBD | valid, not promoted | Higher score than current low-area line, but higher LUT |
| DCache128 + RC64 + branchfold + no branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, inactive second regfile write port disabled | TBD | 4.369157 | TBD | rejected | DCache capacity floor, below 5 |
| DCache128 + RC128 + branchfold next-cache + NT-load fold, fold-rs2/rs3 read ports gated off, inactive second regfile write port disabled | TBD | 4.695781 | TBD | rejected | Front-end recovery insufficient, below 5 |
| DCache512 + RC64 + branchfold next-cache + no NT-load fold, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | 8362 | 5.191960 | TBD | superseded | Saves little area compared with the 8425-LUT line, so the lower 8201-LUT nonext point is preferred |
| DCache512 + RC64 + branchfold + no branchfold next-cache + no NT-load fold, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | TBD | 4.981265 | TBD | rejected | Both fold trims together fall below 5 CoreMark/MHz |
| DCache512 + RC64 + no load-use DCache probe, no dynamic BHT, no ZBKB, redirect-cache tag-width trim | TBD | 4.958065 | TBD | rejected | Removing the DCache probe path saves potential area but loses the load-use benefit needed to stay above 5 |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB/no Zicond | 9915 | 5.659572 | TBD | rejected | Zicond removal changes synthesis packing unfavorably and costs 22 LUT versus no-ZBKB, so it is not retained |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB/no XThead condmove | N/A | N/A | TBD | rejected | CoreMark timeout at PC=0x00000478; not a safe hardware trim |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB/no Zbc | N/A | N/A | TBD | rejected | CoreMark timeout at PC=0x00001b58; not a safe hardware trim |
| DCache1024 + RC256 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB | 10983 | 5.809144 | TBD | area rejected | RC256 improves redirect-cache coverage but costs too much LUTRAM and logic under the 10000-LUT target |
| DCache2048 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT | 12045 | 5.685417 | TBD | area rejected | DCache2048 reduces remaining memory stalls but costs 2102 LUT over DCache1024 for only a small CoreMark gain, so it is not retained under the current low-resource target |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, static predict mode 1 | TBD | 5.552 | TBD | rejected | Adding BGEU prediction (mode 1) worsened CoreMark by ~2% (1801081 vs 1767189 cycles); backward-taken+BNE-taken (mode 0) remains preferred |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, RC regular lookup off | TBD | 4.919 | TBD | rejected | Disabling regular cache lookup caused 13% regression and completely disabled NT-load fold (nt_fold_candidate=0), revealing a hard dependency between regular_cache_lookup and NT-fold functionality |
| DCache896 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB | N/A | N/A | N/A | invalid | Non-power-of-2 DCache (896B) causes $clog2 index overflow; INDEX_W=8 addresses 256 entries but array has only 224, producing X propagation in simulation. PC=xxxxxxxx, CPU never started |
| DCache1024 + RC160 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB | N/A | N/A | N/A | invalid | Non-power-of-2 RC (160 entries) causes $clog2 index overflow; INDEX_W=8 addresses 256 but array has only 160, producing X propagation. PC=xxxxxxxx, CPU never started |
| DCache1024 + RC96 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB | N/A | N/A | N/A | invalid | Non-power-of-2 RC (96 entries) causes $clog2 index overflow; INDEX_W=7 addresses 128 but array has only 96, producing X propagation. PC=xxxxxxxx, CPU never started |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, no EX-branch-forward | TBD | 5.480 | TBD | rejected | Disabling ID_BRANCH_EX_FORWARD caused 3.2% regression (1824732 vs 1767189 cycles); EX forwarding reduces branch resolution latency and is worth the small area cost |
| DCache1024 + RC128 + branchfold next-cache + NT-load fold, no dynamic BHT, no ZBKB, word-only cache | TBD | 4.783 | TBD | rejected | WORD_ONLY mode forces all memory accesses to word-aligned, eliminating byte/half-word DCache support; CoreMark regression of ~15% (2090896 vs 1767189 cycles) confirms byte-level access patterns in CoreMark matter |

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
- Lower-area RC64 summary: `coremark_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
- Lower-area RC64 Dhrystone: `dhrystone_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
- Lower-area RC64 synth util: `synth_util_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt`
- Lower-area RC64 synth hierarchy: `synth_util_hier_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt`
- Lower-area DCache512/RC64 summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
- Lower-area DCache512/RC64 Dhrystone: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
- Lower-area DCache512/RC64 synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt`
- Lower-area DCache512/RC64 synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt`
- Low-area boundary DCache256/RC64 summary: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
- Current lower-area nonext summary: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_recheck_iter10_20260528.summary.txt`
- Current lower-area nonext Dhrystone: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_runs1000_20260528.summary.txt`
- Current lower-area nonext synth util: `synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt`
- Current lower-area nonext synth hierarchy: `synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt`
- Rejected summary: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_nozicond_iter10_20260526.summary.txt`
- Rejected synth util: `synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_nozicond_9915lut_20260526.rpt`
- Rejected synth hierarchy: `synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_nozicond_9915lut_20260526.rpt`
- Rejected timeout log: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_noxtcond_iter10_20260526.log`
- Rejected timeout log: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_nozbc_iter10_20260526.log`
- Area-rejected summary: `coremark_fpga_dcache1024_rc256_ntfold_nobht_nozbkb_iter10_20260526.summary.txt`
- Area-rejected synth util: `synth_util_dcache1024_rc256_ntfold_nobht_nozbkb_10983lut_20260526.rpt`
- Area-rejected synth hierarchy: `synth_util_hier_dcache1024_rc256_ntfold_nobht_nozbkb_10983lut_20260526.rpt`
- Area-rejected summary: `coremark_fpga_dcache2048_rc128_ntfold_nobht_iter10_20260526.summary.txt`
- Area-rejected synth util: `synth_util_dcache2048_rc128_ntfold_nobht_12045lut_20260526.rpt`
- Area-rejected synth hierarchy: `synth_util_hier_dcache2048_rc128_ntfold_nobht_12045lut_20260526.rpt`
- Area-rejected synthesis log: `pynq_synth_dcache2048_rc128_ntfold_nobht_12045lut_20260526.log`
- Rejected log: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_staticpred1_iter10_20260527.log`
- Rejected log: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_noreglookup_iter10_20260527.log`
- Invalid log: `coremark_fpga_dcache896_rc128_ntfold_nobht_nozbkb_iter10_20260527.log`
- Invalid log: `coremark_fpga_dcache1024_rc160_ntfold_nobht_nozbkb_iter10_20260527.log`
- Invalid log: `coremark_fpga_dcache1024_rc96_ntfold_nobht_nozbkb_iter10_20260527.log`
- Rejected log: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_noexfwd_iter10_20260527.log`
- Rejected log: `coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_wordonly_iter10_20260527.log`
- Incomplete log (interrupted): `coremark_fpga_dcache512_rc128_ntfold_nobht_nozbkb_iter10_20260527.log`

## 2026-06-01 low-area strict sync-BRAM checkpoint

Objective changed from maximum CoreMark under 10k LUT to low-resource /
low-power-first exploration. The current acceptance boundary is:

- CoreMark/MHz must stay above the initial submission result `4.137461`.
- RTL must remain sync-BRAM and PYNQ-Z2 compatible.
- CoreMark core algorithm files remain unchanged.
- Short-run summaries are acceptable for exploration, but the strict EEMBC
  10-second compliance field must remain visible.

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Optimization point | Decision |
|---|---:|---:|---:|---|---|
| DCache64 + RC64 + next | 6832 | 4.336028 | 1.166238 | 64-entry DCache, 64-entry return/redirect cache, next-cache path retained | Current best low-area/performance tradeoff; +138 LUT over the minimum floor |
| DCache64 + RC32 + next, no Zicond, no NT-load fold | 6523 | 4.181209 | 1.166238 | 64-entry DCache, 32-entry return/redirect cache, next-cache path retained, Zicond and not-taken load fold disabled | New lowest verified LUT point above the initial submission boundary |
| DCache64 + RC32 + next, no Zicond | 6619 | 4.181261 | 1.166238 | 64-entry DCache, 32-entry return/redirect cache, next-cache path retained, Zicond hardware disabled | New lowest verified LUT point above the initial submission boundary |
| DCache64 + RC64 + next, read-mux share RTL cleanup | 6955 | 4.336028 | TBD | DCache array read expression sharing / valid vector cleanup | Rejected: behavior unchanged but Vivado increased LUT |
| DCache64 + RC64 + next, no load-use spec | 6955 | 4.289242 | 1.149744 | Disable DCache probe/load-use speculation | Rejected: LUT increased and score decreased |
| DCache64 + RC64 + next, no Zicond | 6860 | 4.336028 | TBD | Disable Zicond while keeping the same CoreMark image | Rejected: LUT increased by 28 with no performance gain |
| DCache64 + RC64 + next, no Zbc | TBD | timeout | TBD | Disable Zbc while keeping the same CoreMark image | Rejected: CoreMark did not complete within the simulation budget |
| DCache128 + RC32 + next | 6955 | 4.329743 | 1.208287 | 128-entry DCache, 32-entry return/redirect cache, next-cache path retained | Balanced candidate: better score than the 6694-LUT floor for +261 LUT |
| DCache128 + RC64 + next | synth pending | 4.495875 | 1.208287 | 128-entry DCache, 64-entry return/redirect cache, next-cache path retained | Performance-valid but not frozen; synth did not close in the time budget |
| DCache64 + RC32 + next | 6694 | 4.181261 | 1.166238 | 64-entry DCache, 32-entry return/redirect cache, next-cache path retained, no dynamic BHT/ZBKB/Zicond | Freeze candidate: lowest verified LUT point above initial submission |
| DCache64 + RC32 + next, no regular lookup | TBD | 4.041588 | TBD | Disable regular redirect-cache lookup | Rejected: below initial submission |
| DCache64 + RC32 + next, no XThead condmov | TBD | timeout | TBD | Disable XThead conditional move hardware | Rejected: CoreMark did not complete within simulation budget |
| DCache64 + RC32 + next, no XThead MUL/MAC | TBD | timeout | TBD | Disable XThead MUL/MAC hardware | Rejected: CoreMark did not complete within simulation budget |
| DCache64 + RC32 + next, regfile LUTRAM/no-reset | TBD | timeout | TBD | Remove register-file reset to encourage distributed RAM inference | Rejected: current simulation profile no longer completes |
| DCache64 + RC32 + next + word-only DCache | TBD | 3.970315 | TBD | Word-only DCache data path trim | Rejected: below initial submission |
| DCache64 + RC16 + next | TBD | 4.117348 | TBD | RC reduced from 32 to 16 | Rejected: below initial submission |
| DCache32 + RC32 + next | TBD | 4.074163 | TBD | Further DCache reduction | Rejected: below initial submission |

Evidence for `DCache64 + RC32 + next, no Zicond, no NT-load fold`:

- CoreMark: `coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_nontload_d64_rc32_next_nozicond_nontload_recheck_iter10_20260528.summary.txt`
- Dhrystone: `dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_nontload_d64_rc32_next_nozicond_nontload_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache64_rc32_next_nozicond_nontload_6523lut_20260601.rpt`
- Synth hierarchy: `synth_util_hier_dcache64_rc32_next_nozicond_nontload_6523lut_20260601.rpt`

Evidence for `DCache64 + RC32 + next, no Zicond`:

- CoreMark: `coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_nozicond_recheck_iter10_20260528.summary.txt`
- Dhrystone: `dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_nozicond_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache64_rc32_next_nozicond_6619lut_20260601.rpt`
- Synth hierarchy: `synth_util_hier_dcache64_rc32_next_nozicond_6619lut_20260601.rpt`

Evidence for `DCache64 + RC32 + next`:

- CoreMark: `coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_recheck_iter10_20260528.summary.txt`
- Dhrystone: `dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache64_rc32_next_loadspec_6694lut_20260601.rpt`
- Synth hierarchy: `synth_util_hier_dcache64_rc32_next_loadspec_6694lut_20260601.rpt`

Evidence for `DCache128 + RC32 + next`:

- CoreMark: `coremark_fpga_dcache128_rc64_ntfold_nobht_nozbkb_rctagtrim_d128_rc32_next_recheck_iter10_20260528.summary.txt`
- Dhrystone: `dhrystone_fpga_dcache128_rc64_ntfold_nobht_nozbkb_rctagtrim_d128_rc32_next_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache128_rc32_next_loadspec_6955lut_20260601.rpt`
- Synth hierarchy: `synth_util_hier_dcache128_rc32_next_loadspec_6955lut_20260601.rpt`

Evidence for `DCache64 + RC64 + next`:

- CoreMark: `coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc64_next_recheck_iter10_20260528.summary.txt`
- Dhrystone: `dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc64_next_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache64_rc64_next_loadspec_6832lut_20260601.rpt`
- Synth hierarchy: `synth_util_hier_dcache64_rc64_next_loadspec_6832lut_20260601.rpt`

Performance-only evidence for `DCache128 + RC64 + next`:

- CoreMark: `coremark_fpga_dcache128_rc64_ntfold_nobht_nozbkb_rctagtrim_d128_rc64_next_recheck_iter10_20260528.summary.txt`
- Dhrystone: `dhrystone_fpga_dcache128_rc64_ntfold_nobht_nozbkb_rctagtrim_d128_rc64_next_runs1000_20260528.summary.txt`

Next low-area trials should avoid further RC reduction unless a new compensating
front-end optimization is added. `DCache64 + RC16 + next` is already below the
initial-submission boundary; the better near-term search space is DCache128/64
with small front-end control trims that preserve next-cache hit behavior.

## 2026-06-01 under-8000 5+ follow-up

The user selected the under-8000 LUT / CoreMark > 5 objective. The 7377-LUT
no-Zicond point remains the lowest-LUT 5+ baseline, and a new DCache256/RC128
tradeoff was added for a higher CoreMark option below 8000 LUT.

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Optimization point | Decision |
|---|---:|---:|---:|---|---|
| DCache512 + RC32 + next, no Zicond | 7377 | 5.042742 | 1.287490 | Previous lowest-LUT 5+ baseline; DCache512, RC32, branchfold next-cache, NT-load fold, fold-rs2/rs3 read ports gated off, inactive regfile second write port disabled, no dynamic BHT, no ZBKB, no Zicond | Superseded by the no-retiming/no-timing-driven 7216-LUT synth |
| DCache512 + RC32 + next, no Zicond, retiming/timing-driven override disabled | 7216 | 5.042742 | 1.287490 | Same RTL/benchmark evidence as the 7377-LUT line; Vivado quick synth disables retiming and timing-driven override | Current lowest-LUT 5+ baseline |
| DCache512 + RC32 + next, no Zicond, timing-driven impl | 7532 impl | 5.042742 | 1.287490 | Same benchmark/RTL configuration as the low-LUT 5+ candidate, but run through full implementation with timing-driven synthesis and retiming | Rejected for board-facing use: post-route `WNS -12.744 ns`; critical path remains sync instruction ROM to IF/ID/front-end control |
| DCache512 + RC32 + next, no Zicond, IMEM output register | TBD | 3.988680 | TBD | Adds one output register stage on the synchronous instruction ROM response path | Rejected: timing-friendly direction, but coarse fetch latency drops below the initial-submission and 5+ performance targets |
| DCache512 + RC64 + nonext, no Zicond, retiming/timing-driven override disabled | 7316 | 5.067602 | 1.287490 | Disables branchfold next-cache, increases redirect cache to RC64, keeps NT-load fold, disables Zicond, and uses no-retiming/no-timing-driven quick synth | Current balanced low-resource candidate; +100 LUT versus 7216 for +0.024860 CoreMark/MHz |
| DCache512 + RC64 + nonext, no Zicond, no ID-branch EX-forward | 6872 | 5.023480 | 1.275942 | Keeps the RC64/nonext front-end but removes the ID-stage branch compare path that depends on the EX-stage same-cycle result | New lowest-LUT 5+ candidate; saves 344 LUT versus the 7216 line, with small CoreMark/DMIPS loss |
| DCache512 + RC128 + nonext, no Zicond, no ID-branch EX-forward | 7164 | 5.208729 | 1.275942 | Enlarges redirect cache to 128 entries while keeping no-next-cache and no EX-forward for lower ID/front-end area than the old DCache256/RC128 path | New recommended under-8000 performance/area candidate; beats the old 7676-LUT 5.106 point while saving 512 LUT |
| DCache512 + RC128 + nonext, no Zicond, no ID-branch EX-forward, timing-driven impl | 7677 impl | 5.208729 | 1.275942 | Same benchmark configuration as the 7164-LUT recommended point, but run through full implementation with timing-driven synthesis and retiming | Rejected for board-facing use: post-route `WNS -11.408 ns`; worst path moved to MEM/address-to-ID/EX-control logic |
| DCache512 + RC256 + nonext, no Zicond, no ID-branch EX-forward | 7853 | 5.281995 | 1.275942 | Further enlarges redirect cache to 256 entries while keeping no-next-cache and no EX-forward | New under-8000 high-CoreMark candidate; performance gain costs 689 LUT versus the 7164-LUT recommended point |
| DCache512 + RC64 + nonext, no Zicond, timing-driven impl | 7674 impl | 5.067602 | 1.287490 | Same benchmark/RTL configuration as the balanced candidate, but run through full implementation with timing-driven synthesis and retiming | Rejected for board-facing use: post-route `WNS -11.425 ns`; keep only as timing-failure evidence |
| DCache512 + RC32 + next, no Zicond, static predict mode 1, retiming/timing-driven override disabled | 7232 | 5.042742 | TBD | Static predict mode 1 is performance-neutral from the prior CoreMark run, but the same quick synth options produce a larger design than the 7216-LUT mode-0 baseline | Rejected: +16 LUT with no measured performance gain |
| DCache512 + RC32 + next, no Zicond, no Zbc | N/A | N/A | TBD | Attempts to trim Zbc hardware from the current low-area line | Rejected: CoreMark times out at `PC=00000478`; the current legal benchmark image depends on Zbc |
| DCache512 + RC32 + next, no Zicond, no XThead condmove | N/A | N/A | TBD | Attempts to trim XThead conditional-move hardware from the current low-area line | Rejected: CoreMark times out at `PC=000004a8`; the current legal benchmark image depends on condmove |
| DCache512 + RC32 + next, no Zicond, no ID branch fold | TBD | 4.880429 | TBD | Removes the whole ID-stage branch fold path | Rejected: below the 5+ target, though still above initial-submission performance |
| DCache512 + RC32 + next, no Zicond, no ID-branch EX-forward | TBD | 4.994062 | TBD | Keeps ID branch fold but removes the EX-result early compare source | Rejected for the RC32/next line: just below 5+ |
| DCache256 + RC256 + nonext, no Zicond, no ID-branch EX-forward | TBD | 4.862945 | TBD | Tries to save DCache area while retaining the larger redirect cache | Rejected: below 5+, showing DCache512 is still needed for the no-EX-forward 5+ family |
| DCache256 + RC128 + next, no Zicond | 7897 | 5.106160 | 1.261816 | Trades DCache capacity for larger redirect cache; keeps branchfold next-cache and NT-load fold, disables Zicond, keeps no dynamic BHT/no ZBKB/tag trims | Valid under-8000 higher-CoreMark candidate |
| DCache256 + RC128 + next, no Zicond, synth retiming disabled | 7827 | 5.106160 | 1.261816 | Same RTL/benchmark evidence as 7897 point; Vivado quick synth run with retiming disabled | New lower-LUT implementation of the under-8000 higher-CoreMark candidate; full implementation timing still needs recheck |
| DCache256 + RC128 + next, no Zicond, retiming/timing-driven override disabled | 7676 | 5.106160 | 1.261816 | Same RTL/benchmark evidence as the 7897/7827 points; Vivado quick synth with retiming disabled and timing-driven override disabled | Current under-8000 higher-CoreMark candidate; saves 151 LUT versus the no-retiming-only synth and 221 LUT versus the original quick synth |
| DCache512 + RC32 + next, no Zicond, redirect-cache XOR index | TBD | 4.998261 | TBD | XOR indexing on the redirect cache | Rejected: CRC-clean but below 5 CoreMark/MHz |
| DCache512 + RC32 + next, no Zicond, fetch redirect reuse | TBD | 5.042742 | TBD | Enables fetch redirect reuse path | Neutral: CRC-clean but no measured performance benefit |
| DCache256 + RC128 + next, no Zicond, no NT-load fold | TBD | N/A | TBD | Attempts to remove NT-load fold in the DCache256/RC128 tradeoff | No metric: xsim generated-C compile failed before benchmark output |
| DCache256 + RC128 + next, no Zicond, redirect-cache XOR index | TBD | 5.096227 | TBD | XOR indexing on the redirect cache | Rejected: CRC-clean but slower than the retained 5.106160 point |
| DCache256 + RC128 + next, no Zicond, fetch redirect reuse | TBD | 5.106160 | TBD | Enables fetch redirect reuse path | Neutral: CRC-clean but no measured performance benefit |
| DCache256 + RC128 + next, no Zicond, no regular lookup | TBD | 4.598094 | TBD | Disables regular redirect-cache lookup | Rejected: regular lookup is required for this front-end path |
| DCache256 + RC128 + next, no Zicond, DCache next-prefetch | TBD | 5.099317 | TBD | Enables data-cache next-line prefetch | Rejected: CRC-clean but slower than the retained point |
| DCache512 + RC32 + next, no Zicond, DCache next-prefetch | 8407 | 5.067158 | 1.287501 | Enables data-cache next-line prefetch on the 7377-LUT low-area baseline | Area rejected: improves CoreMark versus 7377, but exceeds the 8000-LUT limit |
| DCache512 + RC32 + next, no Zicond, static predict mode 1 | TBD | 5.042742 | TBD | Switches static branch predict mode | Neutral: CRC-clean but no measured performance benefit |
| DCache256 + RC128 + next, no Zicond, no DCache load-use speculation | TBD | 4.898993 | TBD | Disables DCache load-use probe/speculation | Rejected: below 5 CoreMark/MHz; load-use probe is required for the under-8000 performance line |

Evidence for `DCache256 + RC128 + next, no Zicond`:

- CoreMark: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_recheck_iter10_20260528.summary.txt`
- Dhrystone: `dhrystone_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_runs1000_20260528.summary.txt`
- Synth util: `synth_util_dcache256_rc128_next_nozicond_20260601.rpt`
- Synth hierarchy: `synth_util_hier_dcache256_rc128_next_nozicond_20260601.rpt`
- No-retiming synth util: `synth_util_dcache256_rc128_next_nozicond_noretiming_20260601.rpt`
- No-retiming synth hierarchy: `synth_util_hier_dcache256_rc128_next_nozicond_noretiming_20260601.rpt`
- No-retiming/no-timing-driven synth util: `synth_util_dcache256_rc128_next_nozicond_noretiming_notiming_20260601.rpt`
- No-retiming/no-timing-driven synth hierarchy: `synth_util_hier_dcache256_rc128_next_nozicond_noretiming_notiming_20260601.rpt`
- Rejected XOR CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_xor1_recheck_iter10_20260528.summary.txt`
- Neutral fetch-reuse CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_fetchreuse_recheck_iter10_20260528.summary.txt`
- DCache256/RC128 rejected XOR CoreMark: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_xor1_recheck_iter10_20260528.summary.txt`
- DCache256/RC128 neutral fetch-reuse CoreMark: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_fetchreuse_recheck_iter10_20260528.summary.txt`
- DCache256/RC128 rejected no-regular-lookup CoreMark: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_noreglookup_recheck_iter10_20260528.summary.txt`
- DCache256/RC128 rejected DCache-next-prefetch CoreMark: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_dnextpf_recheck_iter10_20260528.summary.txt`
- DCache512/RC32 area-rejected DCache-next-prefetch CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_dnextpf_recheck_iter10_20260528.summary.txt`
- DCache512/RC32 area-rejected DCache-next-prefetch Dhrystone: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_dnextpf_runs1000_20260528.summary.txt`
- DCache512/RC32 area-rejected DCache-next-prefetch synth util: `synth_util_dcache512_rc32_next_nozicond_dnextpf_20260601.rpt`
- DCache512/RC32 neutral static-predict CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_static1_recheck_iter10_20260528.summary.txt`
- DCache256/RC128 rejected no-load-use-spec CoreMark: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_nolspec_d256_rc128_next_nozicond_nolspec_recheck_iter10_20260528.summary.txt`
- DCache512/RC64/nonext timing-driven implementation synth util: `synth_util_dcache512_rc64_nonext_nozicond_timingdriven_implrun_20260601.rpt`
- DCache512/RC64/nonext timing-driven implementation utilization: `impl_util_dcache512_rc64_nonext_nozicond_timingdriven_timingfail_20260601.rpt`
- DCache512/RC64/nonext timing-driven implementation timing: `impl_timing_dcache512_rc64_nonext_nozicond_timingdriven_timingfail_20260601.rpt`
- DCache512/RC64/nonext/no-EX-forward CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc64_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
- DCache512/RC64/nonext/no-EX-forward Dhrystone: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc64_nonext_nozicond_noexfwd_runs1000_20260528.summary.txt`
- DCache512/RC64/nonext/no-EX-forward synth util: `synth_util_dcache512_rc64_nonext_nozicond_noexfwd_noretiming_notiming_6872lut_20260601.rpt`
- DCache512/RC64/nonext/no-EX-forward synth hierarchy: `synth_util_hier_dcache512_rc64_nonext_nozicond_noexfwd_noretiming_notiming_6872lut_20260601.rpt`
- DCache512/RC64/nonext/no-EX-forward synth timing: `synth_timing_dcache512_rc64_nonext_nozicond_noexfwd_noretiming_notiming_6872lut_20260601.rpt`
- DCache512/RC128/nonext/no-EX-forward CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc128_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
- DCache512/RC128/nonext/no-EX-forward Dhrystone: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc128_nonext_nozicond_noexfwd_runs1000_20260528.summary.txt`
- DCache512/RC128/nonext/no-EX-forward synth util: `synth_util_dcache512_rc128_nonext_nozicond_noexfwd_noretiming_notiming_7164lut_20260601.rpt`
- DCache512/RC128/nonext/no-EX-forward synth hierarchy: `synth_util_hier_dcache512_rc128_nonext_nozicond_noexfwd_noretiming_notiming_7164lut_20260601.rpt`
- DCache512/RC128/nonext/no-EX-forward synth timing: `synth_timing_dcache512_rc128_nonext_nozicond_noexfwd_noretiming_notiming_7164lut_20260601.rpt`
- DCache512/RC128/nonext/no-EX-forward timing-driven implementation synth util: `synth_util_dcache512_rc128_nonext_nozicond_noexfwd_timingdriven_implrun_20260602.rpt`
- DCache512/RC128/nonext/no-EX-forward timing-driven implementation utilization: `impl_util_dcache512_rc128_nonext_nozicond_noexfwd_timingdriven_timingfail_20260602.rpt`
- DCache512/RC128/nonext/no-EX-forward timing-driven implementation timing: `impl_timing_dcache512_rc128_nonext_nozicond_noexfwd_timingdriven_timingfail_20260602.rpt`
- DCache512/RC256/nonext/no-EX-forward CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc256_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
- DCache512/RC256/nonext/no-EX-forward Dhrystone: `dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc256_nonext_nozicond_noexfwd_runs1000_20260528.summary.txt`
- DCache512/RC256/nonext/no-EX-forward synth util: `synth_util_dcache512_rc256_nonext_nozicond_noexfwd_noretiming_notiming_7853lut_20260602.rpt`
- DCache512/RC256/nonext/no-EX-forward synth hierarchy: `synth_util_hier_dcache512_rc256_nonext_nozicond_noexfwd_noretiming_notiming_7853lut_20260602.rpt`
- DCache512/RC256/nonext/no-EX-forward synth timing: `synth_timing_dcache512_rc256_nonext_nozicond_noexfwd_noretiming_notiming_7853lut_20260602.rpt`
- DCache512/RC32/next timing-driven implementation synth util: `synth_util_dcache512_rc32_next_nozicond_timingdriven_implrun_20260601.rpt`
- DCache512/RC32/next timing-driven implementation utilization: `impl_util_dcache512_rc32_next_nozicond_timingdriven_timingfail_20260601.rpt`
- DCache512/RC32/next timing-driven implementation timing: `impl_timing_dcache512_rc32_next_nozicond_timingdriven_timingfail_20260601.rpt`
- DCache512/RC32/next rejected IMEM output-register CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_imemout_recheck_iter10_20260528.summary.txt`
- DCache512/RC32/next rejected no-ID-fold CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_nofold_recheck_iter10_20260528.summary.txt`
- DCache512/RC32/next rejected no-EX-forward CoreMark: `coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
- DCache256/RC256/nonext rejected no-EX-forward CoreMark: `coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_d256_rc256_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`

Implementation timing note: the timing-driven full implementation of the
balanced DCache512/RC64/nonext/no-Zicond line produced `7674 LUT` but failed
50 MHz timing with `WNS -11.425 ns`. The reported critical path starts at the
synchronous instruction ROM/BRAM read data register and reaches the IF/ID
instruction register. This result should guide the next RTL work toward
shortening or staging the sync-ROM fetch-to-decode path; it must not be
promoted as a board-valid bitstream. The DCache512/RC32/next/no-Zicond low-LUT
line was also checked through full implementation and produced `7532 LUT` with
`WNS -12.744 ns`; changing cache capacity/redirect-cache size alone is not
enough to close timing.



