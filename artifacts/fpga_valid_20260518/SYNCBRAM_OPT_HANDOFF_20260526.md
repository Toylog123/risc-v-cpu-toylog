# Sync-BRAM CoreMark Optimization Handoff

Updated: 2026-05-26

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

Full historical record:

```text
artifacts/fpga_valid_20260518/STRICT_SYNCBRAM_OPT_20260521.md
```

## 6. Current Work-In-Progress

Prepared next experiment:

```text
DCache1024 + RC128 + noBHT + noZBKB + fetch redirect reuse
```

Prepared command:

```powershell
cd D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508
_tmp\run_coremark_ntfold_bht16.cmd
```

Expected output log:

```text
artifacts/fpga_valid_20260518/coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_fetchreuse_iter10_20260526.log
```

Decision rule:

- If CoreMark does not complete or CRC is not `0xfcaf`, record it as rejected.
- If CoreMark completes and improves or preserves score, generate a summary and run Dhrystone.
- Only after benchmark evidence is clean, run synthesis and compare LUT.

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
| T01 | Run fetch redirect reuse CoreMark | pending | P0 | CRC `0xfcaf`, pass line, summary generated | Run `_tmp\run_coremark_ntfold_bht16.cmd` |
| T02 | Decide fetch reuse retention | pending | P0 | accepted/rejected row in `STRICT_SYNCBRAM_OPT_20260521.md` | Compare against 5.659572 CoreMark/MHz |
| T03 | If valid, run Dhrystone | pending | P0 | matching `dhrystone_*summary.txt` exists | Use exact same RTL/config |
| T04 | If valid, run synth LUT | pending | P0 | util/hier reports copied to artifacts | Keep under current 10000-LUT policy unless user changes cap |
| T05 | Freeze new best | pending | P0 | commit + tag with evidence files | Stage only relevant RTL, summaries, synth reports, and record docs |
| T06 | Try RC256 area reduction | pending | P1 | approach toward 5.809 CoreMark/MHz under area target | Reduce redirect-cache storage/control cost |
| T07 | Analyze remaining area hotspots | pending | P1 | hierarchy table identifies top 3 modules | Start from DCache, regfile, redirect/fold logic |

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

## 11. Prompt For The Next Agent

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

必须遵守：
- 只能做硬件 RTL/参数/SoC 结构优化。
- 不要修改 CoreMark 核心算法文件：core_list_join.c、core_matrix.c、core_state.c、core_util.c、core_main.c。
- 只能在必要时修改 core_portme.c/core_portme.h 这类移植层。
- 所有指标必须 CRC 通过、日志可追溯、LUT 报告可追溯。
- 不要混用旧 async/理想化跑分，继续沿 sync-BRAM/PYNQ-Z2 可上板口径。
- 不要碰 01-项目管理 的冻结提交材料。
- 不要 git add .，只精确 stage 当前实验相关文件。

下一步先执行：
cd D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508
_tmp\run_coremark_ntfold_bht16.cmd

这个命令当前用于测试：
DCache1024 + RC128 + noBHT + noZBKB + fetch redirect reuse

如果 CoreMark CRC 不是 0xfcaf 或者 timeout，就把它记录为 rejected。
如果通过并且指标有价值，再跑 Dhrystone 和 Vivado synth，最后更新 STRICT_SYNCBRAM_OPT_20260521.md。

给用户汇报时只用表格列：
LUT、CoreMark/MHz、DMIPS/MHz、技术优化点。
```

