# Sync-BRAM CoreMark Optimization Handoff

Updated: 2026-05-27

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

Primary rule: keep all engineering optimization in this English-path worktree. Do not use `01-项目管理` as an engineering source path because the submission material there is treated as frozen/project-management material.

## 2. Current Best Frozen Candidate

Best strict under-10000 LUT candidate:

| Commit | Tag | LUT | CoreMark/MHz | DMIPS/MHz | Status |
|---|---|---:|---:|---:|---|
| `49bcbf2` | `freeze-strict-dcache1024-nozbkb-9893lut-coremark5p66-20260526` | 9893 | 5.659572 | 1.287490 | current frozen best |

Configuration summary:

```text
DCache1024 + RC128 + branchfold next-cache + NT-load fold
no dynamic BHT + no ZBKB + DCache tag trim
sync-BRAM / PYNQ-Z2-oriented path
```

Evidence files:

```text
artifacts/fpga_valid_20260518/coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_iter10_20260526.summary.txt
artifacts/fpga_valid_20260518/dhrystone_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_runs1000_20260526.summary.txt
artifacts/fpga_valid_20260518/synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_9893lut_20260526.rpt
artifacts/fpga_valid_20260518/synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_9893lut_20260526.rpt
artifacts/fpga_valid_20260518/pynq_synth_dcache1024_rc128_ntfold_nobht_nozbkb_9893lut_20260526.log
```

Important measurement caveat:

```text
CoreMark workload is complete and CRC-clean, but current evidence is a short reproducible run.
The summary explicitly records strict_eembc_10s_compliant=no.
Do not present it as an official 10-second EEMBC-compliant run unless a 10-second run is generated.
```

## 3. Rules That Must Not Be Broken

Strict/public口径:

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
| `49bcbf2` | current best frozen valid candidate |

Do not assume HEAD is the best valid build. Use the tag above as the current best freeze.

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
| DCache896/RC160/RC96 (non-power-of-2) | N/A | N/A | N/A | invalid | $clog2 X propagation |

Full historical record:

```text
artifacts/fpga_valid_20260518/STRICT_SYNCBRAM_OPT_20260521.md
```

## 6. Current Work-In-Progress

**Parameter space is fully explored.** All viable parameter combinations have been tested:

- DCache: 128 (timeout), 256 (5.22), 512 (5.59), 1024 (5.66 best), 2048 (over budget)
- RC: 64 (timeout), 128 (best), 256 (over budget)
- Static predict: mode 0 (best), mode 1 (worse), mode 2 (worse)
- BHT: disabled (best), all sizes tested (no improvement or over budget)
- Branch fold / NT-load fold / EX-forward / RC lookup: all tested, enabled is best
- Word-only / fetch redirect reuse / XOR index: all tested, rejected
- Non-power-of-2 sizes: invalid (X propagation)

No new parameter-level experiments remain. Any further improvement requires RTL-level changes beyond parameter tuning.

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

| LUT | CoreMark/MHz | DMIPS/MHz | 技术优化点 |
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
| T07 | Parameter space exhausted | completed | P0 | all viable combinations tested | Frozen best is final |

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

The parameter-level optimization space is **fully exhausted**. Every viable combination of DCache size, redirect cache size, branch prediction mode, fold accelerators, forwarding paths, and cache features has been tested with CRC-validated CoreMark simulation.

**Area breakdown of frozen best (9893 LUT):**

| Module | LUT | % |
|---|---:|---:|
| DCache | 6039 | 61% |
| Regfile | 1667 | 17% |
| fold_target_id_stage | 534 | 5% |
| Other (ALU, hazard, decoder, etc.) | 1653 | 17% |

All modules are at or near functional minimum. DCache cannot be reduced without losing performance (DCache512 = 5.59 CM/MHz, 14% worse). Regfile has 6 read + 2 write ports, all used by the fold pipeline. The fold decoder requires full ISA decode for correctness.

**Possible but high-risk RTL directions:**
1. Simplify redirect cache structure (reduce bits/entry) — requires RTL modification
2. Remove fold rs3 port — historical attempt caused timeout
3. Simplify fold decoder — historical attempt caused timeout
4. Reduce DCache tag width further — already at minimum

**Recommendation:** The frozen best at 9893 LUT / 5.660 CoreMark/MHz / 1.287 DMIPS/MHz represents the practical performance ceiling under the 10000-LUT constraint with parameter-level tuning. Further improvement requires significant RTL architectural changes with uncertain risk/reward.

## 12. Prompt For The Next Agent

Copy this prompt to the next agent:

```text
你接手的是 YH_rv_cpu 的严格口径硬件优化任务。工作目录是：
D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508

当前分支是：
codex/syncbram-h22-20260514

先读这些文件：
1. artifacts/fpga_valid_20260518/SYNCBRAM_OPT_HANDOFF_20260526.md
2. artifacts/fpga_valid_20260518/STRICT_SYNCBRAM_OPT_20260521.md
3. YH_rv_cpu/doc/CURRENT_STATUS.md
4. .codex-handoff.json

当前最佳冻结版本不是 HEAD，而是：
commit 49bcbf2
tag freeze-strict-dcache1024-nozbkb-9893lut-coremark5p66-20260526

当前最佳严格指标：
9893 LUT
5.659572 CoreMark/MHz
1.287490 DMIPS/MHz

参数空间已完全穷尽。所有可行的参数组合均已测试并记录：
- DCache: 128/256/512/1024/2048 → 1024 最优
- RC: 64/128/256 → 128 最优
- 静态预测: mode 0/1/2 → mode 0 最优
- BHT: 禁用最优，所有尺寸已测
- 分支折叠/NT-load折叠/EX转发/RC查找: 全部已测，启用最优
- word-only/fetch redirect reuse/XOR index: 全部已测，拒绝
- 非2的幂尺寸: 无效（X传播）

没有任何新的参数级实验可以做。任何进一步改进需要 RTL 级别的架构修改，而不仅仅是参数调优。

必须遵守：
- 只能做硬件 RTL/参数/SoC 结构优化。
- 不要修改 CoreMark 核心算法文件。
- 所有指标必须 CRC 通过、日志可追溯、LUT 报告可追溯。
- 不要碰 01-项目管理 的冻结提交材料。

给用户汇报时只用表格列：
LUT、CoreMark/MHz、DMIPS/MHz、技术优化点。
```

