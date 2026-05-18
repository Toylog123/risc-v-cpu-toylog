# Sync-BRAM CoreMark Handoff - 2026-05-15

This handoff records the current hardware-only optimization state. The frozen Chinese submission folders were not used as engineering inputs in this round.

## Current Branch

- Worktree: `D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508`
- Branch: `codex/syncbram-h22-20260514`
- Rule for later work: continue on the latest sync-BRAM / FPGA-like path. Do not mix older async-memory or benchmark-source-tuned scores into the current evidence chain.

## Best Verified Simulation Point

| Metric | Value |
|---|---:|
| CoreMark/MHz | `6.149918` |
| Raw ticks | `1626038` |
| Completion cycles | `1659822` |
| CRC | `0xfcaf` |
| Target | `rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_o2sched_nocaller` |
| Redirect/L0 config | `REDIRECT_CACHE_ENTRIES=16384`, `REDIRECT_CACHE_XOR_INDEX=1`, regular lookup enabled, fetch redirect reuse disabled |
| Artifact | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_after_reuse_param.summary.txt` |

This is a simulation upper-bound point on the sync-BRAM path. It is not yet a PYNQ-Z2 board-facing result because the larger L0 table still needs synthesis, timing, and power review.

Dhrystone cross-check after the cache parameterization is unchanged:

| Metric | Value |
|---|---:|
| DMIPS/MHz | `3.197245` |
| Dhrystones/s | `561756` |
| Runs | `2000` |
| Artifact | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/dhrystone_after_reuse_param.summary.txt` |

## What Changed Today

- Made the redirect/L0 instruction delivery structure configurable:
  - `ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP`
  - `REDIRECT_CACHE_ENTRIES`
  - `REDIRECT_CACHE_XOR_INDEX`
- Passed these generics through CPU, SoC, CoreMark FPGA testbench, profile testbench, PYNQ-Z2 top, Vivado TCL, and build scripts.
- Reverified directed tests:
  - `run_xthead_memidx_test.bat`: PASS
  - `run_redirect_target_cache_diag.bat require_no_redirect_bubble require_loop_stream`: PASS
- Reproduced the best 2048-entry XOR score from the same parameterized RTL.
- Ran capacity and read-port A/B tests to isolate score versus synthesis cost.
- Added a parameterized 2-bit BHT and static branch prediction mode; both are verified, but the best CoreMark path keeps dynamic BHT disabled.
- Added a parameterized fetch redirect buffer reuse switch. The A/B run is correct but unchanged in score, so the best path keeps it disabled.
- Fixed the profile script so it can use the same generics as the score flow; the latest profile now matches the 16384-entry XOR score configuration.

## Capacity Sweep

| Config | CoreMark/MHz | Raw ticks | CRC | Artifact |
|---|---:|---:|---|---|
| 2048 XOR, regular lookup on | `6.140394` | `1628560` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_param_cache_20260515/coremark_2048_xor.summary.txt` |
| 4096 XOR, regular lookup on | `6.140530` | `1628524` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_4096_xor.summary.txt` |
| 8192 XOR, regular lookup on | `6.145451` | `1627220` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_8192_xor.summary.txt` |
| 16384 XOR, regular lookup on | `6.149918` | `1626038` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_after_reuse_param.summary.txt` |
| 32768 XOR, regular lookup on | `6.149918` | `1626038` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_32768_xor.summary.txt` |
| 16384 XOR + fetch redirect reuse | `6.149918` | `1626038` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_reuse.summary.txt` |
| 16384 XOR + 1024-entry BHT | `6.149884` | `1626047` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_bht1024.summary.txt` |
| 16384 XOR + Zbkb target | `6.149918` | `1626038` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_zbkb_autoinc_l0_16384_xor.summary.txt` |
| 1024 direct, regular lookup on | `6.133302` | `1630443` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_param_cache_20260515/coremark_1024_direct.summary.txt` |
| 512 direct, regular lookup on | `6.119910` | `1634011` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_cache_sweep_20260515/coremark_512_direct.summary.txt` |
| 256 direct, regular lookup on | `6.079404` | `1644898` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_cache_sweep_20260515/coremark_256_direct.summary.txt` |
| 512 redirect-only | `5.587585` | `1789682` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_redirect_only_20260515/coremark_512_redirect_only.summary.txt` |
| 64 redirect-only | `5.585475` | `1790358` | `0xfcaf` | `artifacts/syncbram_negedge_zbc_memidx_redirect_only_20260515/coremark_64_redirect_only.summary.txt` |

Interpretation: the regular sequential lookup read port is worth roughly `0.53 CoreMark/MHz`, but it is also the main synthesis-cost suspect. Increasing the XOR-indexed L0 beyond 2048 entries still gives small gains through 16384 entries, but 32768 entries has identical ticks to 16384. Treat 16384 as the current simulation saturation point; larger front-end tables should be rejected unless synthesis/power data changes the tradeoff.

The Zbkb-enabled target is also a rejected score direction for the current compiler build. It stays correct and does not regress raw ticks, but it does not reduce the timed CoreMark region. The emitted hot code still mainly uses the already-supported Zbc carry-less multiply instructions rather than a new Zbkb-specific hotspot.

Enabling the older `ICACHE_EN=1` path on top of this configuration is not a valid score candidate. It times out at `PC=ffffffb0` and needs a separate root-cause debug before it can be used with the current sync-BRAM/redirect path. The failure log is `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_icache_on.log`.

## Latest Profile Snapshot

The 16384-entry XOR profile was run with the same score-flow generics and confirms the remaining front-end bubbles are small:

- `timed_cycles=1626038`
- `timed_id_ex_valid_cycles=1624254`
- `timed_non_idex_cycles=1784`
- `timed_if_id_bubble_cycles=343`
- `timed_stall_decode_cycles=0`
- `timed_mem_wait_cycles=0`
- `timed_id_branch_decode_pending_cycles=113180`
- `timed_id_branch_decode_candidate_cycles=406239`
- `timed_id_branch_decode_redirect_cycles=98521`
- `timed_branch_predict_redirect_cycles=49509`
- `timed_id_beq_decode_pending_cycles=63981`
- `timed_id_bne_decode_pending_cycles=49199`
- `timed_id_blt_decode_pending_cycles=0`
- `timed_id_bge_decode_pending_cycles=0`
- `timed_id_bltu_decode_pending_cycles=0`
- `timed_id_bgeu_decode_pending_cycles=0`
- `timed_load_branch_fuse_candidate_cycles=34`
- `timed_load_beq_fuse_candidate_cycles=24`
- `timed_load_bne_fuse_candidate_cycles=10`
- `timed_id_branch_fold_ready_cycles=293059`
- `timed_id_branch_fold_not_taken_queue_cycles=271`
- `timed_id_branch_fold_taken_cache_cycles=98379`
- `timed_id_branch_fold_any_next_cycles=98650`
- `timed_id_ex_clmul_cycles=5840`
- `timed_id_ex_clmulh_cycles=5840`
- `timed_id_ex_shadd_cycles=26600`
- `timed_id_ex_xthead_ext_cycles=76442`
- `timed_id_ex_xthead_condmove_cycles=27780`
- `timed_id_ex_zicond_cycles=0`
- `timed_id_ex_pack_cycles=0`
- `timed_id_ex_xcrc_cycles=0`
- `id_branch_decode_rs1_idex_pending_cycles=113174`
- Pending-reason profile:
  - `id_branch_decode_rs1_idex_load_pending_cycles=113174`
  - `id_branch_decode_rs1_idex_lui_pending_cycles=0`
  - `id_branch_decode_rs1_idex_pc4_pending_cycles=0`
  - `id_branch_decode_rs1_idex_alu_pending_cycles=0`
  - `id_branch_decode_rs2_idex_load_pending_cycles=585`
  - `id_branch_decode_rs2_idex_alu_pending_cycles=56`
- Profile artifacts:
  - `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_profile_pending_reasons.log`
  - `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_profile_pending_pc.log`
  - `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_profile_fuse_opportunity.log`
  - `artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_profile_dynamic_isa_branchfold.log`

Top pending PCs are list/state load-branch patterns such as `0x000005a4`, `0x00000bc4`, `0x00000bcc`, `0x00000bd4`, and `0x00000bdc`. The remaining pending branches are essentially BEQ/BNE after loads; BLT/BGE/BLTU/BGEU do not show timed pending cycles.

Interpretation: fetch refills are no longer the dominant cycle loss. The main remaining hardware bottleneck is dynamic instruction count around branches, loads, and CRC/list hot code. A simple macro-fusion attempt against the current one-instruction fetch queue is not attractive because the exposed load-branch fusion opportunity is only `34` timed cycles. Branch folding is the only profile-supported path with enough headroom to matter, but the current implementation cannot simply skip a branch without adding decode/read capacity: `98650` ready branches have the next instruction visible, mostly through taken-target cache hits, but folding them safely requires either an extra decode/register-read path or an equivalent front-end structure. The dynamic ISA profile also shows what is already useful: XThead extraction and conditional move are hot, Zbc CLMUL is used, while Zicond, Zbkb/pack, and XCRC are not emitted in the timed region.

## PYNQ-Z2 Synthesis Status

The 64-entry redirect-only route produced synth reports on `xc7z020clg400-1`, 50 MHz CPU clock:

| LUT | FF | BRAM | DSP | Synth WNS |
|---:|---:|---:|---:|---:|
| `7994` | `6856` | `32` | `15` | `-3.042 ns` |

This is not board-ready. The regular-lookup versions with 1024 and 256 entries did not produce reports within the time budget, so the next real task is a structure change, not another capacity increase.

Adding `ram_style="distributed"` to the L0 tag/data arrays did not change the 64-entry redirect-only synth report (`LUT as Memory` stayed `0`, LUT stayed `7994`, WNS stayed `-3.042 ns`). Treat this as a rejected mapping-hint attempt.

The worst synth timing path is not the L0 array itself. It starts at the shared synchronous ROM output (`u_soc/g_shared_sync_rom.u_sync_rom/imem_rdata_r_reg_7`) and ends at the IF/ID instruction register clock enable (`u_soc/u_cpu/if_id_instruction_r_reg[0]/CE`). It passes through fetch/decode/control fan-in. The next timing fix should therefore decouple IF/ID write-enable/control generation from current-cycle ROM data.

## Next Tasks

1. Replace the current dual async-read redirect/L0 table with a synthesis-friendly structure:
   - single physical read path with registered lookup, or
   - small victim buffer for redirect target plus a separate tiny sequential fetch buffer, or
   - banked distributed RAM with only one active read per cycle.
2. Re-run CoreMark on each structure with the same sync-BRAM command and record raw ticks/CRC.
3. Shorten the ROM-to-IF/ID clock-enable critical path, likely by registering or simplifying IF/ID write-enable selection for synchronous IMEM.
4. Re-run PYNQ-Z2 synth after each promising structure before considering any bitstream build.
5. Keep Dhrystone honest: the current Dhrystone script is a DMEM-sync score path, not yet a full sync-IMEM Method-A score path. If the next report needs board-equivalent DMIPS, add a dedicated FPGA-like Dhrystone testbench before claiming that number as board-equivalent.
6. Treat 16384-entry XOR as a simulation upper-bound until the PYNQ-Z2 synth/power numbers are known. The 32768-entry check is identical in ticks and should not be selected because it only increases expected area/toggle cost. A lower-capacity path may still be the right low-power board candidate.
7. Do not spend the next round on the current shallow load-branch macro-fusion hook. The profile shows only `34` cycles visible to the existing fetch queue. If load-branch folding is attempted, first add deeper lookahead diagnostics or a real two-instruction front-end design.
8. If chasing a score above the current `6.149918` point, prioritize a principled branch-fold/decode-width experiment over new predictor-table capacity. A safe implementation likely needs additional register-read capacity or a narrow second decoder; otherwise the folded branch only becomes an EX bubble and does not reduce timed cycles.
