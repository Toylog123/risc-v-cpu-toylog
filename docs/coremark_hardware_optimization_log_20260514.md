# CoreMark Hardware Optimization Log - 2026-05-14

This log records only hardware-side changes and FPGA-like simulation results on the current sync-BRAM correctness baseline. CoreMark source code is not modified.

## Verified Results

| Step | Hardware change | Target/config | CoreMark/MHz | Raw ticks | CRC | Artifact |
|---|---|---|---:|---:|---|---|
| Baseline | sync BRAM correctness baseline before this session | FPGA-like sync IMEM/DMEM | 3.284290 | - | - | artifacts/syncbram_clean_baseline_20260514 |
| Load hazard reduction | reduced sync load hazard stalls | FPGA-like sync IMEM/DMEM | 3.775491 | - | - | commit 3689ef5 |
| DMEM negedge read | same-cycle fast load visibility for FPGA-like sync DMEM | rv32i+Zmmul+Zba/Zbb/Zbs+Zicond+XThead | 4.675978 | 2138590 | 0xfcaf | artifacts/syncbram_negedge_read_20260514 |
| Zbc enable | carry-less multiply instructions enabled for benchmark hot paths | rv32i+Zmmul+Zba/Zbb/Zbs+Zbc+Zicond+XThead | 5.476241 | 1826070 | 0xfcaf | artifacts/syncbram_negedge_zbc_20260514 |
| Redirect/L0 cache 8-entry | direct-mapped redirect target and instruction L0 delivery | same as above | 5.591931 | 1788291 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache_20260514 |
| Redirect/L0 cache 16-entry | reduced low-address aliasing in direct-mapped L0 | same as above | 5.649619 | 1770031 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache16_20260514 |
| Redirect/L0 cache 32-entry | further reduced hot-loop aliasing in direct-mapped L0 | same as above | 5.716978 | 1749176 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache32_20260514 |
| Redirect/L0 cache 64-entry | reduced wider hot-loop aliasing in direct-mapped L0 | same as above | 5.778129 | 1730664 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache64_20260514 |
| Dynamic BHT exploration | 32-entry tagged dynamic taken table for unresolved branches; verified by directed test but not selected as default | same as above, BHT enabled | 5.776460 | 1731164 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache64_bht_20260514 |
| Current default candidate | 64-entry L0 with dynamic BHT disabled by default | same as above | 5.778129 | 1730664 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache64_default_20260515 |
| Redirect/L0 cache 128-entry | reduced 256B target aliasing in direct-mapped L0 | same as above | 5.889694 | 1697881 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache128_20260515 |
| Redirect/L0 cache 256-entry | reduced 512B target aliasing in direct-mapped L0 | same as above | 5.953430 | 1679704 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache256_20260515 |
| Redirect/L0 cache 512-entry | reduced 1024B target aliasing in direct-mapped L0 | same as above | 5.995333 | 1667964 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache512_20260515 |
| Redirect/L0 cache 1024-entry | reduced 2048B target aliasing in direct-mapped L0 | same as above | 6.010381 | 1663788 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache1024_20260515 |
| Redirect/L0 valid-only reset | keep cache tag/data unreset and reset valid bits only | same as above | 6.010381 | 1663788 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache1024_validreset_20260515 |
| Dynamic BHT A/B | 32-entry dynamic taken table enabled through SoC/test generic | same as above, BHT enabled | 6.008648 | 1664268 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache1024_bht_20260515 |
| ID redirect EX validation | let ID-known redirects enter EX for validation instead of becoming decode bubbles | same as above | 6.010381 | 1663788 | 0xfcaf | artifacts/syncbram_negedge_zbc_l0icache1024_idredirect_all_ex_20260515 |
| Zbkb A/B | enable Zbkb hardware/gcc target in current sync-BRAM path | rv32i+Zmmul+Zba/Zbb/Zbs+Zbc+Zicond+Zbkb+XThead | 6.010381 | 1663788 | 0xfcaf | artifacts/syncbram_negedge_zbc_zbkb_l0icache1024_20260515 |
| XTheadMemIdx auto-index repair | added missing auto-index halfword/byte decode and fixed base-update forwarding priority | rv32i+Zmmul+Zba/Zbb/Zbs+Zbc+Zicond+XTheadMemIdx auto-index | 6.133302 | 1630443 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_auto_fixed_20260515/memidx_auto_fixed_coremark.summary.txt |
| No-auto regression after repair | verified forwarding repair does not perturb the previous no-auto path | same as 1024-entry L0/no-auto | 6.010381 | 1663788 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_auto_fixed_20260515/noauto_regression_after_bypassfix.summary.txt |
| Redirect/L0 cache 2048-entry | larger direct-mapped target/instruction delivery table after auto-index repair | auto-index path | 6.140202 | 1628611 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_auto_fixed_20260515/memidx_auto_redirect_cache2048.summary.txt |
| Redirect/L0 cache 4096-entry | larger direct-mapped table; rejected for tiny marginal gain versus area/toggle cost | auto-index path | 6.140273 | 1628592 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_auto_fixed_20260515/memidx_auto_redirect_cache4096.summary.txt |
| Redirect/L0 cache 2048-entry XOR | XOR-folded index reduces hot-code aliasing with lower capacity than 4096 direct | auto-index path | 6.140394 | 1628560 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_auto_rtc2048xor_final_20260515/coremark.summary.txt |
| Redirect/L0 cache 1024-entry XOR | smaller XOR-folded table; rejected because it is below the 2048-entry XOR candidate | auto-index path | 6.132464 | 1630666 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_auto_fixed_20260515/memidx_auto_redirect_cache1024_xor.summary.txt |
| Dynamic BHT after auto-index | repeated A/B with auto-index path; rejected because it is slightly lower than static/default | auto-index path, BHT enabled | 6.131497 | 1630923 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_auto_fixed_20260515/memidx_auto_dynamic_bht.summary.txt |
| Forward BGEU static predict probe | predict BGEU as taken in addition to backward/BNE; rejected because ticks are unchanged | auto-index path | 6.140394 | 1628560 | 0xfcaf | artifacts/syncbram_negedge_zbc_predict_bgeu_probe_20260515/coremark.summary.txt |
| Parameterized 1024-entry direct L0 | moved cache capacity/index policy into generics and rechecked board-friendly default | auto-index path, 1024 direct | 6.133302 | 1630443 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_param_cache_20260515/coremark_1024_direct.summary.txt |
| Parameterized 2048-entry XOR L0 | same RTL with explicit generics reproduces the best measured point | auto-index path, 2048 XOR | 6.140394 | 1628560 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_param_cache_20260515/coremark_2048_xor.summary.txt |
| Parameterized 2-bit BHT disabled regression | added 2-bit saturating BHT and kept default disabled; confirms no regression | auto-index path, 2048 XOR | 6.140394 | 1628560 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_bht_disabled_regression.summary.txt |
| 2-bit BHT 64-entry A/B | enabled tagged 2-bit BHT; rejected because ticks are unchanged | auto-index path, 2048 XOR, BHT enabled | 6.140394 | 1628560 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_bht2_64.summary.txt |
| 2-bit BHT 128-entry A/B | larger BHT capacity; rejected because ticks are unchanged | auto-index path, 2048 XOR, BHT enabled | 6.140394 | 1628560 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_bht2_128.summary.txt |
| Static branch mode 1 | predict BGEU as taken in addition to backward/BNE; rejected because ticks are unchanged | auto-index path, 2048 XOR | 6.140394 | 1628560 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_static_mode1.summary.txt |
| Static branch mode 2 | predict all unresolved conditional branches taken; rejected because it hurts CoreMark | auto-index path, 2048 XOR | 5.912772 | 1691254 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_static_mode2.summary.txt |
| Redirect/L0 cache 4096-entry XOR | larger XOR-folded table after BHT/static parameterization | auto-index path | 6.140530 | 1628524 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_4096_xor.summary.txt |
| Redirect/L0 cache 8192-entry XOR | larger XOR-folded table; simulation upper-bound candidate | auto-index path | 6.145451 | 1627220 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_8192_xor.summary.txt |
| Redirect/L0 cache 16384-entry XOR | largest tested XOR-folded table; current best simulation point but not board-facing until synth/power review | auto-index path | 6.149918 | 1626038 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_after_reuse_param.summary.txt |
| Redirect/L0 cache 32768-entry XOR | capacity check above the current best; rejected because ticks are identical to 16384 with higher expected area/toggle | auto-index path | 6.149918 | 1626038 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_32768_xor.summary.txt |
| Fetch redirect buffer reuse A/B | parameterized redirect-buffer reuse; correct but no CoreMark tick change | auto-index path, 16384 XOR | 6.149918 | 1626038 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_reuse.summary.txt |
| 1024-entry BHT with 16384 L0 | larger dynamic BHT on the latest L0 point; rejected because it is 9 ticks slower | auto-index path, 16384 XOR, BHT enabled | 6.149884 | 1626047 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_bht1024.summary.txt |
| Zbkb plus auto-index on best L0 | enabled Zbkb target on the current 16384 XOR path; correct but no timed tick gain | auto-index path, 16384 XOR, Zbkb enabled | 6.149918 | 1626038 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/coremark_zbkb_autoinc_l0_16384_xor.summary.txt |
| 512-entry direct L0 capacity sweep | smaller table for synthesis/power tradeoff | auto-index path, regular lookup enabled | 6.119910 | 1634011 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_cache_sweep_20260515/coremark_512_direct.summary.txt |
| 512-entry XOR L0 capacity sweep | XOR index at this capacity is slightly worse than direct | auto-index path, regular lookup enabled | 6.118697 | 1634335 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_cache_sweep_20260515/coremark_512_xor.summary.txt |
| 256-entry direct L0 capacity sweep | lower-area candidate; score loss grows but remains above 6 | auto-index path, regular lookup enabled | 6.079404 | 1644898 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_cache_sweep_20260515/coremark_256_direct.summary.txt |
| 256-entry XOR L0 capacity sweep | XOR index is again slightly worse at small capacity | auto-index path, regular lookup enabled | 6.075759 | 1645885 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_cache_sweep_20260515/coremark_256_xor.summary.txt |
| Redirect-only L0 read-port split | disabled regular sequential lookup to isolate one async read port; rejected as main path because the score loss is large | 512-entry redirect-only | 5.587585 | 1789682 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_redirect_only_20260515/coremark_512_redirect_only.summary.txt |
| Redirect-only L0 low-capacity check | score is almost independent of capacity once regular lookup is disabled | 64-entry redirect-only | 5.585475 | 1790358 | 0xfcaf | artifacts/syncbram_negedge_zbc_memidx_redirect_only_20260515/coremark_64_redirect_only.summary.txt |

## DMIPS Cross-Check

| Step | Target/config | Runs | DMIPS/MHz | Dhrystones/s | Artifact |
|---|---|---:|---:|---:|---|
| Current 1024-entry L0 candidate | rv32i+Zmmul+Zba/Zbb/Zbs+Zbc+Zicond+XThead, sync DMEM negedge read | 2000 | 3.197245 | 561756 | artifacts/syncbram_negedge_zbc_l0icache1024_validreset_20260515/dhrystone_current_runs2000.summary.txt |
| ID redirect EX validation candidate | same as above | 2000 | 3.197245 | 561756 | artifacts/syncbram_negedge_zbc_l0icache1024_idredirect_all_ex_20260515/dhrystone_runs2000.summary.txt |
| Auto-index + 2048-entry XOR candidate | rv32i+Zmmul+Zba/Zbb/Zbs+Zbc+Zicond+XTheadMemIdx, sync DMEM negedge read | 2000 | 3.197245 | 561756 | artifacts/syncbram_negedge_zbc_memidx_auto_rtc2048xor_final_20260515/dhrystone_runs2000.summary.txt |
| After redirect/L0 parameterization | same Dhrystone software and RTL defaults; confirms no DMIPS regression from new cache generics | 2000 | 3.197245 | 561756 | artifacts/syncbram_negedge_zbc_memidx_param_cache_20260515/dhrystone_after_cache_param.summary.txt |
| After BHT/static/reuse parameterization | same Dhrystone software and RTL defaults; confirms no DMIPS regression from new predictor/reuse generics | 2000 | 3.197245 | 561756 | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/dhrystone_after_bht_static_params.summary.txt |
| After fetch reuse default regression | same Dhrystone software and RTL defaults after the fetch redirect reuse switch landed | 2000 | 3.197245 | 561756 | artifacts/syncbram_negedge_zbc_memidx_bht2_20260515/dhrystone_after_reuse_param.summary.txt |

## PYNQ-Z2 Synthesis Notes

All synthesis probes below use the PYNQ-Z2 part `xc7z020clg400-1`, 50 MHz CPU clock generic, synchronous ROM/RAM images, and the English worktree path.

| Candidate | Vivado result | LUT | FF | BRAM | DSP | WNS | Notes |
|---|---|---:|---:|---:|---:|---:|---|
| 1024-entry direct L0 with regular lookup | stopped after 30 min without reports | - | - | - | - | - | Timing optimization did not finish in the time budget; large dual-lookup async table is too heavy for this route. |
| 256-entry direct L0 with regular lookup | stopped after additional wait without reports | - | - | - | - | - | Completed timing optimization but still spent too long in technology mapping. |
| 64-entry redirect-only L0 | synth reports generated | 7994 | 6856 | 32 | 15 | -3.042 ns | This single-read-port low-score route is synthesizable, but still not timing/resource clean enough for a board-facing claim. |
| 64-entry redirect-only L0 with distributed-RAM attribute | synth reports generated | 7994 | 6856 | 32 | 15 | -3.042 ns | Attribute did not change Vivado's reported mapping (`LUT as Memory` stayed 0), so structural RTL change is still required. |

Worst synth timing path for the 64-entry redirect-only probe starts at the synchronous ROM output (`u_soc/g_shared_sync_rom.u_sync_rom/imem_rdata_r_reg_7`) and ends at the IF/ID instruction register clock enable (`u_soc/u_cpu/if_id_instruction_r_reg[0]/CE`). The path goes through fetch/decode/control selection logic, so the next timing-oriented hardware task should decouple IF/ID write-enable generation from current-cycle ROM data and redirect-control fan-in.

## Technical Highlights For Later Report

- The score is now recovered and improved on the sync-BRAM/FPGA-like path rather than the older asynchronous-memory shortcut.
- DMEM negedge read keeps the FPGA Block RAM model while allowing load data to become visible soon enough for downstream forwarding in the same core cycle.
- Zbc support gives a large and reproducible gain on the current CoreMark build without changing benchmark source.
- The lightweight L0/BTB-style instruction cache stores fetched instructions by full PC tag and removes redirect refetch bubbles after warm-up.
- L0 capacity was increased by evidence: an alias-pair test failed on the smaller direct-mapped cache and passed after expansion.
- 64-entry L0 was the first high-performance candidate; later 128/256/512/1024-entry experiments show the remaining fetch-bubble gain and the resource/power tradeoff.
- A small tagged dynamic BHT was added as a parameterized exploration path. It correctly predicts repeated unresolved forward branches in directed simulation, but the CoreMark run is slightly lower than the default L0 path, so it remains disabled for the current best candidate.
- 128-entry L0 passed a new 256B alias regression and produced the best score so far. This is a real hardware-side gain from reducing redirect-target instruction refill bubbles, not a benchmark source change.
- 256/512/1024-entry L0 experiments show a clear diminishing-return curve. The 1024-entry version crosses 6 CoreMark/MHz and reduces `timed_if_id_bubble_cycles` from 71369 (64-entry) to 4493, but it is a high-area/high-toggle candidate that needs synthesis and power review before any board-facing claim.
- Resetting only L0 valid bits leaves tag/data arrays unreset. This does not change CoreMark ticks, but it is a cleaner FPGA implementation style because it avoids large resettable storage and should map better to distributed RAM or lower-reset-fanout logic.
- ID redirect EX validation improves pipeline occupancy in the FPGA-like profile (`timed_non_idex_cycles=5654`, `timed_if_id_bubble_cycles=4493`) but does not improve the measured CoreMark score. It is a control-flow robustness/occupancy optimization, not a score claim.
- Dynamic BHT and Zbkb are verified A/B experiments but are not selected for the current best score because they do not beat the default 1024-entry L0 path.
- XThead auto-index memidx was repaired and promoted from a failing exploration path to the current score candidate. The root causes were incomplete decode coverage for `th.lhia`, `th.lbuia`, and `th.shia`, plus a forwarding priority bug where an older base-update writeback could override a newer normal EX/MEM result.
- The auto-index repair is covered by `run_xthead_memidx_test.bat`, the no-auto regression run, and the final CoreMark CRC `0xfcaf`.
- The 2048-entry XOR redirect/L0 index is the current best measured point. 4096 direct mapping is only 32 ticks faster than 2048 direct and 32 ticks slower than 2048 XOR, so it is not selected because the extra storage would add area and switching with no useful score gain.
- Fetch redirect buffer reuse, dynamic BHT, Zbkb combination, and forward `BGEU` static prediction were all tested as A/B candidates and rejected because they did not improve raw timed ticks.
- Redirect/L0 capacity and index are now explicit RTL generics (`REDIRECT_CACHE_ENTRIES`, `REDIRECT_CACHE_XOR_INDEX`), so the simulation-best path and the board-facing exploration path can be selected from the same source tree.
- The regular sequential lookup read port accounts for roughly 0.53 CoreMark/MHz on the auto-index path (`6.119910` with 512-entry regular lookup versus `5.587585` redirect-only). This is the current highest-value fetch-side hardware feature, but it is also the main synthesis-cost suspect.
- The latest PYNQ-Z2 synth probes show that the large async-read L0 is not yet board-ready. Future work should replace the dual async read table with a smaller banked/pipelined or BRAM-friendly structure rather than simply increasing capacity.
- A distributed-RAM attribute on L0 tag/data arrays did not change the PYNQ-Z2 synthesis report, so the issue is not just an inference hint; the read structure itself needs to be simplified.
- Current remaining profile bottlenecks are mostly instruction count and load-dependent unresolved branch prediction/validation. Load-use decode stalls and memory wait cycles are already zero in the timed region.
- The 2-bit BHT, larger BHT capacities, and more aggressive static prediction were tested on the current sync-BRAM path. They are kept as documented exploration hooks, but the best measured path still disables dynamic BHT because it does not improve raw ticks.
- 4096/8192/16384/32768-entry XOR L0 experiments show the front-end has reached a capacity saturation point. The 16384-entry result is the current simulation best (`6.149918 CoreMark/MHz`), while 32768 entries gives identical ticks and should be rejected for area/power. The 16384 point should still be described as an upper-bound until PYNQ-Z2 synthesis and power data exist.
- Fetch redirect buffer reuse was cleaned up into a real parameter and passed through scripts/top-levels. It is correct, but the A/B result has identical ticks, so it is not a score feature for the current best path.
- The profile flow now accepts the same generics as the score flow. The latest profile shows only `343` timed IF/ID bubble cycles, while `id_branch_decode_rs1_idex_pending_cycles=113174`; the next meaningful hardware gain must attack branch operand readiness or branch folding rather than adding another simple front-end table.
- Pending-reason profiling shows the remaining ID branch operand gap is almost entirely load-to-branch: `id_branch_decode_rs1_idex_load_pending_cycles=113174`, with LUI/PC4/ordinary ALU rs1 pending all at `0`. This rules out small ALU forwarding case additions as a useful next score path.
- Pending-PC profiling narrows those remaining dependencies to BEQ/BNE list/state patterns. Timed pending counts are `63981` for BEQ, `49199` for BNE, and `0` for BLT/BGE/BLTU/BGEU, with top PCs such as `0x000005a4`, `0x00000bc4`, `0x00000bcc`, `0x00000bd4`, and `0x00000bdc`.
- A first load-branch fusion opportunity counter found only `34` timed cycles visible through the current shallow fetch queue (`24` BEQ, `10` BNE). This rejects a small local macro-fusion patch as a likely score win; any real load-branch folding attempt needs deeper two-instruction lookahead or a broader front-end/decode redesign.
- Zbkb was rechecked on top of the current best auto-index path. It is correct and leaves the score unchanged, but the dump shows the relevant hot emitted operations are still dominated by Zbc carry-less multiply rather than a new Zbkb hotspot, so it is not a current score feature.
- The old `ICACHE_EN=1` path was tested on top of the current 16384-entry XOR configuration and timed out at `PC=ffffffb0`. This is a correctness failure, not a score result, and should be debugged separately before it is mentioned as a usable cache feature.
- Dynamic ISA profiling shows the hardware extensions that actually execute in the timed region: `clmul=5840`, `clmulh=5840`, `shadd=26600`, `XThead ext/extu=76442`, and `XThead condmove=27780`. `Zicond`, `Zbkb/pack`, and `XCRC` are `0` in the timed region for the current compiler output.
- Branch-fold feasibility profiling shows `293059` ready branch cycles, but only `98650` currently have the next instruction visible through the existing queue/cache path (`98379` taken-cache hits and only `271` not-taken queue cases). This is the first direction with enough theoretical headroom to matter beyond 6.15, but it needs a real decode/read-path design; simply dropping the branch from EX would create a bubble and not improve CoreMark.

## Current Best Profile Snapshot

Best current score candidate in the current RTL line: `syncbram_negedge_zbc_memidx_bht2_20260515/coremark_l0_16384_xor_after_reuse_param.summary.txt`.

Latest FPGA-like profile confirms the current best total ticks (`1626038`) with no load-use or memory-wait bubbles in the timed region:

- `timed_cycles=1626038`
- `timed_id_ex_valid_cycles=1624254`
- `timed_non_idex_cycles=1784`
- `timed_if_id_bubble_cycles=343`
- `timed_decode_flush_cycles=1461`
- `timed_id_branch_decode_pending_cycles=113180`
- `timed_id_beq_decode_pending_cycles=63981`
- `timed_id_bne_decode_pending_cycles=49199`
- `timed_id_blt_decode_pending_cycles=0`
- `timed_id_bge_decode_pending_cycles=0`
- `timed_id_bltu_decode_pending_cycles=0`
- `timed_id_bgeu_decode_pending_cycles=0`
- `timed_load_branch_fuse_candidate_cycles=34`
- `timed_id_branch_fold_ready_cycles=293059`
- `timed_id_branch_fold_not_taken_queue_cycles=271`
- `timed_id_branch_fold_taken_cache_cycles=98379`
- `timed_id_branch_fold_any_next_cycles=98650`
- `timed_stall_decode_cycles=0`
- `timed_mem_wait_cycles=0`
- `timed_branch_predict_redirect_cycles=49509`
- `timed_id_decode_redirect_cycles=114053`
- `id_branch_decode_rs1_idex_load_pending_cycles=113174`
- `id_branch_decode_rs1_idex_lui_pending_cycles=0`
- `id_branch_decode_rs1_idex_pc4_pending_cycles=0`
- `id_branch_decode_rs1_idex_alu_pending_cycles=0`
- `id_branch_decode_rs2_idex_load_pending_cycles=585`
- `id_branch_decode_rs2_idex_alu_pending_cycles=56`
- `timed_id_ex_clmul_cycles=5840`
- `timed_id_ex_clmulh_cycles=5840`
- `timed_id_ex_shadd_cycles=26600`
- `timed_id_ex_xthead_ext_cycles=76442`
- `timed_id_ex_xthead_condmove_cycles=27780`
- `timed_id_ex_zicond_cycles=0`
- `timed_id_ex_pack_cycles=0`
- `timed_id_ex_xcrc_cycles=0`

## Next Hardware Candidates

- Rework the L0/redirect instruction cache into a synthesis-friendly structure: one registered lookup per cycle, a small victim buffer, or banked distributed RAM with a single physical read path.
- Re-run PYNQ-Z2 synth after each L0 structure change before claiming a board-facing score.
- Explore a low-area branch-folding design for ready branches with visible next instruction. The profile-supported opportunity is about `98650` cycles, mostly taken-target cache hits. Do not start with the current shallow load-branch fusion hook because its visible opportunity is only `34` cycles.
- Debug `ICACHE_EN=1` separately if it becomes important. The latest run timed out at `PC=ffffffb0`, so it is currently a failing configuration, not an optimization candidate.
- Add focused diagnostics around auto-index base-update forwarding age priority, especially when a normal ALU write and an older base update target the same architectural register.
- Keep all results reportable with raw ticks, CRC, target name, and artifact path.
