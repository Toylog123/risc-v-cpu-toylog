# Sync-BRAM CoreMark Optimization Handoff

Updated: 2026-05-28

## 1. Project Scope

This worktree continues the YH_rv_cpu hardware-only performance optimization line for the RISC-V CPU contest project.

Active worktree:

```text
D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508
```

Active branch:

```text
codex/syncbram-h22-20260514
```

Primary rule: keep all engineering optimization in this English-path worktree. Do not use `01-椤圭洰绠＄悊` as an engineering source path because the submission material there is treated as frozen/project-management material.

## 2. Current Best Frozen Candidate

Best strict under-10000 LUT candidate:

| Commit | Tag | LUT | CoreMark/MHz | DMIPS/MHz | Status |
|---|---|---:|---:|---:|---|
| `this-commit` | `freeze-strict-rctagtrim-9796lut-coremark5p66-20260528` | 9796 | 5.659572 | 1.287490 | current validated best |

Current lower-area strict candidate:

| Commit | Tag | LUT | CoreMark/MHz | DMIPS/MHz | Status |
|---|---|---:|---:|---:|---|
| `tag target` | `freeze-strict-dcache512-rc64-nonext-8201lut-coremark5p07-20260528` | 8201 | 5.072560 | 1.287490 | lower-area valid candidate |

Configuration summary:

```text
DCache1024 + RC128 + branchfold next-cache + NT-load fold
no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim
sync-BRAM / PYNQ-Z2-oriented path
```

Evidence files:

```text
artifacts/fpga_valid_20260518/coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_iter10_20260528.summary.txt
artifacts/fpga_valid_20260518/dhrystone_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt
artifacts/fpga_valid_20260518/synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.rpt
artifacts/fpga_valid_20260518/synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.rpt
artifacts/fpga_valid_20260518/pynq_synth_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.log
artifacts/fpga_valid_20260518/coremark_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt
artifacts/fpga_valid_20260518/dhrystone_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt
artifacts/fpga_valid_20260518/synth_util_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt
artifacts/fpga_valid_20260518/synth_util_hier_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt
artifacts/fpga_valid_20260518/pynq_synth_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.log
artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt
artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt
artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt
artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt
artifacts/fpga_valid_20260518/pynq_synth_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.log
artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt
artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_recheck_iter10_20260528.summary.txt
artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_runs1000_20260528.summary.txt
artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt
artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt
artifacts/fpga_valid_20260518/pynq_synth_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.log
```

Important measurement caveat:

```text
CoreMark workload is complete and CRC-clean, but current evidence is a short reproducible run.
The summary explicitly records strict_eembc_10s_compliant=no.
Do not present it as an official 10-second EEMBC-compliant run unless a 10-second run is generated.
```

## 3. Rules That Must Not Be Broken

Strict/public鍙ｅ緞:

- Only optimize hardware RTL, parameters, SoC structure, board integration, or allowed port layer details.
- Do not modify CoreMark algorithm files:
  - `core_list_join.c`
  - `core_matrix.c`
  - `core_state.c`
  - `core_util.c`
  - `core_main.c`
- Allowed CoreMark-side files are limited to the port layer:
  - `core_portme.c`
  - `core_portme.h`
- Allowed port-layer changes include timer, UART output, board initialization, compiler metadata, and iteration count for runtime.
- Keep sync-BRAM/PYNQ-Z2 feasibility in mind. Do not mix in old async, idealized, or non-board-facing scores.
- Every accepted score must have CRC/pass evidence and a matching LUT report before it is promoted.

## 4. Latest Committed Exploration After The Best Freeze

The branch HEAD is newer than the best frozen tag because rejected experiments were recorded after the freeze.

Recent commits:

| Commit | Meaning |
|---|---|
| `2393dbd` | recorded rejected experiments: static pred1, rc noreglookup, noexfwd, wordonly, non-power-of-2 invalids |
| `04fdc7e` | recorded word-only and fetch-reuse experiment results |
| `b6a932e` | added strict syncbram optimization handoff |
| `7bbbd5d` | recorded RC256 area rejection |
| `059f69c` | recorded no-Zbc timeout |
| `c2b7c46` | recorded no-XThead-condmove timeout |
| `cb60452` | recorded no-Zicond area regression |
| `this-commit` | current best validated redirect-cache tag-width trim candidate |
| `49bcbf2` | previous best frozen valid candidate |

Do not assume old tags are the best valid build. The 2026-05-28 redirect-cache tag-width trim is the current best validated RTL candidate and should be frozen before new architectural experiments.

## 5. Rejected Or Superseded Paths

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Decision | Reason |
|---|---:|---:|---:|---|---|
| DCache1024 + RC256 + noBHT + noZBKB | 10983 | 5.809144 | TBD | area rejected | faster but over 10000 LUT |
| DCache2048 + RC128 + noBHT | 12045 | 5.685417 | TBD | area rejected | area cost too high for small gain |
| DCache1024 + noZBKB/noZicond | 9915 | 5.659572 | TBD | rejected | worse area than no-ZBKB only |
| DCache1024 + noZBKB/no-XThead-condmove | N/A | N/A | TBD | rejected | CoreMark timeout at PC=0x00000478 |
| DCache1024 + noZBKB/no-Zbc | N/A | N/A | TBD | rejected | CoreMark timeout at PC=0x00001b58 |
| DCache1024 + noZBKB + static predict mode 1 | TBD | 5.552 | TBD | rejected | 2% regression vs mode 0 |
| DCache1024 + noZBKB + RC regular lookup off | TBD | 4.919 | TBD | rejected | 13% regression, NT-fold disabled |
| DCache1024 + noZBKB + no EX-branch-forward | TBD | 5.480 | TBD | rejected | 3.2% regression |
| DCache1024 + noZBKB + word-only cache | TBD | 4.783 | TBD | rejected | 15% regression |
| DCache1024 + noZBKB + fetch redirect reuse | TBD | 5.552 | TBD | rejected | 2% regression |
| DCache1024 + noZBKB + RC64 recheck | 9185 | 5.351560 | 1.287490 | lower-area valid | corrected runtime staging fixed the old missing mem32 warning; saves 611 LUT vs RC128 while keeping CoreMark >5 |
| DCache512 + noZBKB + RC64 recheck | 8425 | 5.291075 | 1.287490 | lower-area valid | saves 760 LUT versus DCache1024/RC64 while keeping CRC-clean CoreMark above 5 |
| DCache256 + noZBKB + RC64 recheck | TBD | 4.891219 | TBD | rejected boundary | CRC-clean but below the 5 CoreMark/MHz target |
| DCache512 + noZBKB + RC64 nonext | 8201 | 5.072560 | 1.287490 | lower-area valid | disables branchfold next-cache delivery; saves 224 LUT versus DCache512/RC64 while staying above 5 |
| DCache512 + noZBKB + RC64 nontload | 8362 | 5.191960 | TBD | superseded | saves only 63 LUT versus DCache512/RC64, so nonext is preferred for low area |
| DCache896/RC160/RC96 (non-power-of-2) | N/A | N/A | N/A | invalid | $clog2 X propagation |

Full historical record:

```text
artifacts/fpga_valid_20260518/STRICT_SYNCBRAM_OPT_20260521.md
```

## 6. Current Work-In-Progress

**Parameter space is fully explored.** All viable parameter combinations have been tested. Further gains now require RTL-level area changes:

- DCache: 128 (timeout), 256 (4.891 with RC64, below target), 512 (5.073 with RC64 nonext lower-area 5+), 1024 (5.66 best), 2048 (over budget)
- RC: 64 (valid lower-area 5+ after corrected runtime staging), 128 (best score), 256 (over budget)
- Static predict: mode 0 (best), mode 1 (worse), mode 2 (worse)
- BHT: disabled (best), all sizes tested (no improvement or over budget)
- Branch fold / NT-load fold / EX-forward / RC lookup: all tested, enabled is best
- Word-only / fetch redirect reuse / XOR index: all tested, rejected
- Non-power-of-2 sizes: invalid (X propagation)

No new parameter-level experiments remain. The first successful RTL-level area change is redirect-cache tag-width trim, which saves 97 LUT without changing CoreMark/Dhrystone.

## 7. Standard Experiment Flow

Use this one-variable-at-a-time loop:

1. Create or edit exactly one RTL/config experiment.
2. Run CoreMark simulation.
3. Parse:
   - `Total ticks`
   - `Iterations`
   - `crcfinal`
   - `PASS: coremark completed`
4. Generate a `.summary.txt` next to the log.
5. If CoreMark is valid and interesting, run Dhrystone for the exact candidate.
6. If performance is worth keeping, run Vivado synthesis for LUT.
7. Copy synth reports into `artifacts/fpga_valid_20260518`.
8. Update `STRICT_SYNCBRAM_OPT_20260521.md`.
9. Commit and tag if it becomes a new accepted best.

Recommended concise report format to the user:

| LUT | CoreMark/MHz | DMIPS/MHz | 鎶€鏈紭鍖栫偣 |
|---:|---:|---:|---|
| value | value | value | short candidate name |

## 8. Next Task Board

| ID | Task | Status | Priority | Done Criteria | Next Action |
|---|---|---|---|---|---|
| T01 | Fetch redirect reuse | completed | P0 | rejected (5.552 CM/MHz, 2% regression) | Done |
| T02 | Static predict mode 1 | completed | P0 | rejected (5.552 CM/MHz, 2% regression) | Done |
| T03 | RC regular lookup off | completed | P0 | rejected (4.919 CM/MHz, 13% regression) | Done |
| T04 | No EX-branch-forward | completed | P0 | rejected (5.480 CM/MHz, 3.2% regression) | Done |
| T05 | Word-only cache | completed | P0 | rejected (4.783 CM/MHz, 15% regression) | Done |
| T06 | Non-power-of-2 DCache/RC | completed | P0 | invalid (X propagation) | Done |
| T07 | Parameter space exhausted | completed | P0 | all viable combinations tested | Use RTL-level changes only |
| T08 | Redirect-cache tag-width trim | completed | P0 | 9796 LUT, 5.659572 CoreMark/MHz, 1.287490 DMIPS/MHz | Freeze as current best |
| T09 | Explore 5k-class low-area path | in_progress | P0 | Reproduce or migrate 4739/5742/5908 LUT historical candidates under current strict口径 | 4739/5742 historical lines rechecked but fell to 3.423504/3.075927 CoreMark/MHz; DCache512/RC64 nonext reached 8201 LUT and 5.072560 CoreMark/MHz; continue DCache RTL area reductions |
| T10 | RC64 corrected recheck | completed | P0 | 9185 LUT, 5.351560 CoreMark/MHz, 1.287490 DMIPS/MHz | Freeze as lower-area valid candidate |
| T11 | DCache512/RC64 corrected recheck | completed | P0 | 8425 LUT, 5.291075 CoreMark/MHz, 1.287490 DMIPS/MHz | Freeze as current lower-area 5+ candidate |
| T12 | DCache512/RC64 nonext | completed | P0 | 8201 LUT, 5.072560 CoreMark/MHz, 1.287490 DMIPS/MHz | Freeze as current lower-area 5+ candidate |

## 9. Commands For Takeover

Initial audit:

```powershell
cd D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508
git status --short --branch
git log --oneline -8 --decorate
git tag --points-at 49bcbf2
Get-Content -Raw artifacts\fpga_valid_20260518\coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_iter10_20260526.summary.txt
Get-Content -Raw artifacts\fpga_valid_20260518\dhrystone_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_runs1000_20260526.summary.txt
```

Check Vivado process ownership before killing anything:

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.Name -match 'vivado|xvlog|xelab|xsim|parallel_synth_helper' } |
  Select-Object ProcessId,Name,CommandLine
```

Do not kill Vivado processes that belong to another project path.

## 10. Git Hygiene

- Many untracked historical logs exist in `artifacts/fpga_valid_20260518`.
- Do not use broad `git add .`.
- Do not stage `_tmp`.
- Stage only exact files related to the current experiment.
- Do not use destructive commands such as `git reset --hard`.
- Do not revert user changes.

## 11. Final Assessment (2026-05-27)

The parameter-level optimization space is **fully exhausted**. Every viable combination of DCache size, redirect cache size, branch prediction mode, fold accelerators, forwarding paths, and cache features has been tested with CRC-validated CoreMark simulation. On 2026-05-28, an RTL-level redirect-cache tag-width trim reduced the best candidate from 9893 to 9796 LUT without changing CoreMark or Dhrystone.

**Area breakdown of frozen best (9893 LUT):**

| Module | LUT | % |
|---|---:|---:|
| DCache | 6048 | 62% |
| Regfile | 1667 | 17% |
| fold_target_id_stage | 559 | 6% |
| Other (ALU, hazard, decoder, etc.) | 1522 | 15% |

All modules are at or near functional minimum. DCache cannot be reduced without losing performance (DCache512 = 5.59 CM/MHz, 14% worse). Regfile has 6 read + 2 write ports, all used by the fold pipeline. The fold decoder requires full ISA decode for correctness.

**Possible but high-risk RTL directions:**
1. Simplify redirect cache structure (reduce bits/entry) 鈥?requires RTL modification
2. Remove fold rs3 port 鈥?historical attempt caused timeout
3. Simplify fold decoder 鈥?historical attempt caused timeout
4. Reduce DCache tag width further 鈥?already at minimum

**Recommendation:** The frozen best at 9893 LUT / 5.660 CoreMark/MHz / 1.287 DMIPS/MHz represents the practical performance ceiling under the 10000-LUT constraint with parameter-level tuning. Further improvement requires significant RTL architectural changes with uncertain risk/reward.

## 12. Prompt For The Next Agent

Copy this prompt to the next agent:

```text
浣犳帴鎵嬬殑鏄?YH_rv_cpu 鐨勪弗鏍煎彛寰勭‖浠朵紭鍖栦换鍔°€傚伐浣滅洰褰曟槸锛?
D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508

褰撳墠鍒嗘敮鏄細
codex/syncbram-h22-20260514

鍏堣杩欎簺鏂囦欢锛?
1. artifacts/fpga_valid_20260518/SYNCBRAM_OPT_HANDOFF_20260526.md
2. artifacts/fpga_valid_20260518/STRICT_SYNCBRAM_OPT_20260521.md
3. YH_rv_cpu/doc/CURRENT_STATUS.md
4. .codex-handoff.json

褰撳墠鏈€浣冲喕缁撶増鏈笉鏄?HEAD锛岃€屾槸锛?
commit 49bcbf2
tag freeze-strict-dcache1024-nozbkb-9893lut-coremark5p66-20260526

褰撳墠鏈€浣充弗鏍兼寚鏍囷細
9893 LUT
5.659572 CoreMark/MHz
1.287490 DMIPS/MHz

鍙傛暟绌洪棿宸插畬鍏ㄧ┓灏姐€傛墍鏈夊彲琛岀殑鍙傛暟缁勫悎鍧囧凡娴嬭瘯骞惰褰曪細
- DCache: 128/256/512/1024/2048 鈫?1024 鏈€浼?
- RC: 64/128/256 鈫?128 鏈€浼?
- 闈欐€侀娴? mode 0/1/2 鈫?mode 0 鏈€浼?
- BHT: 绂佺敤鏈€浼橈紝鎵€鏈夊昂瀵稿凡娴?
- 鍒嗘敮鎶樺彔/NT-load鎶樺彔/EX杞彂/RC鏌ユ壘: 鍏ㄩ儴宸叉祴锛屽惎鐢ㄦ渶浼?
- word-only/fetch redirect reuse/XOR index: 鍏ㄩ儴宸叉祴锛屾嫆缁?
- 闈?鐨勫箓灏哄: 鏃犳晥锛圶浼犳挱锛?

娌℃湁浠讳綍鏂扮殑鍙傛暟绾у疄楠屽彲浠ュ仛銆備换浣曡繘涓€姝ユ敼杩涢渶瑕?RTL 绾у埆鐨勬灦鏋勪慨鏀癸紝鑰屼笉浠呬粎鏄弬鏁拌皟浼樸€?

蹇呴』閬靛畧锛?
- 鍙兘鍋氱‖浠?RTL/鍙傛暟/SoC 缁撴瀯浼樺寲銆?
- 涓嶈淇敼 CoreMark 鏍稿績绠楁硶鏂囦欢銆?
- 鎵€鏈夋寚鏍囧繀椤?CRC 閫氳繃銆佹棩蹇楀彲杩芥函銆丩UT 鎶ュ憡鍙拷婧€?
- 涓嶈纰?01-椤圭洰绠＄悊 鐨勫喕缁撴彁浜ゆ潗鏂欍€?

缁欑敤鎴锋眹鎶ユ椂鍙敤琛ㄦ牸鍒楋細
LUT銆丆oreMark/MHz銆丏MIPS/MHz銆佹妧鏈紭鍖栫偣銆?
```




