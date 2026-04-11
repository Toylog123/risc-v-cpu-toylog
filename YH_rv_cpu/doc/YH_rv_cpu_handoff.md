# YH_rv_cpu 交接说明

## 1. 项目是什么

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。核心目标不是做更多一次性实验，而是把工程维持在“可复现、可验证、可交接、可继续优化”的提交级状态。

本文件按 live handoff 维护。每完成一个阶段，都应先把这里同步到可接手状态，再继续下一阶段。

当前主线 ISA 口径仍是：

- `RV32I + Zicsr`
- `RV64` baseline regression 作为共线验证

## 2. 当前做到哪一步

- 冻结基线仍然是 `2026-04-07` 的完整收口结果
- `2026-04-08` 的 `riscv-tests` 扩展验证与全文档同步已经完成收口
- `2026-04-08` 的主线收口结果已拆成 focused commits；当前仓库还存在独立的目录整理/材料提交线与 profiling WIP，需分别按各自范围处理
- 当前最新 fresh 活跃证据是：
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt`
  - `rv32 full-ui = 42/42`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt`
  - `rv64 full-ui = 54/54`
  - `fence_i` 已在 `rv32i_zicsr_zifencei` 口径下通过
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt`
  - `rv32 baseline = 33/33`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt`
  - `rv64 baseline = 21/21`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt`
  - fresh `CoreMark short = 0.912472 CoreMark/MHz`
  - fresh `CoreMark smoke = 620530 cycles`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt`
  - fresh `CoreMark strict = 0.912465 CoreMark/MHz`

当前冻结结果：

| 项目 | 结果 |
|------|------|
| CoreMark short score | `0.912472 CoreMark/MHz` |
| CoreMark short completion cycles | `11014885` |
| CoreMark strict score | `0.912465 CoreMark/MHz` |
| CoreMark strict completion cycles | `1095991523` |
| CoreMark strict runtime | `10.959325s` |
| CoreMark smoke | `620530 cycles` |
| RV32 baseline | `33/33` |
| RV64 baseline | `21/21` |
| impl50 | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP` |
| impl50 timing | `WNS = +5.599ns`，`WHS = +0.025ns` |
| FPGA-like probe | `156442 cycles`，`7.728811 CoreMark/MHz` |

## 3. 已完成的关键工作

- CoreMark short 与 strict `>=10s` 口径均已收口并形成正式文档
- 当前冻结 baseline 的 RV32 / RV64 / impl50 / FPGA-like probe 均有 fresh 可引用证据
- `timer_irq_smoke` 已修复并纳入基线
- Vivado `impl50` 默认 payload 已冻结为 `YH_rv_cpu_demo`
- `redirect/flush/drop-accounting` 双变体 strict 诊断已补齐
- `2026-04-09` 已整理赛方答疑，并把汇报/初赛提交材料集中到 `01-项目管理/04-汇报与提交材料/`
- 第一轮与第二轮单变量前端候选均已完成快速门禁并拒绝保留：
  - `request-cursor`
  - `pipe-hit`
  - `redirect 同拍取指`
  - `FQ-01`
  - `FQ-02`
  - `FQ-03`
  - `FQ-04`
  - `FQ-05A/B/C`
- 为扩大 `riscv-tests` 覆盖，当前工作区已补入：
  - full-ui manifest
  - large linker
  - custom `tohost_addr`
  - misaligned trap 软件补偿

## 4. 当前阻塞与风险

### 本机内待收口

- `rv32 full-ui` 已闭环；当前 `fence_i` 处理策略是：扩展 UI 覆盖矩阵使用 `zifencei`，但冻结比赛 ISA 口径仍是 `RV32I + Zicsr`
- 对当前无 I-cache、同步 ROM/RAM 的核，`fence.i` 作为 non-trapping nop 足以通过当前测试覆盖；这不等于完整 `Zifencei` signoff
- fresh baseline 与 fresh CoreMark smoke/short/strict 已全部补齐
- `2026-04-08` dated strict summary/log 已归档，并与冻结 strict 口径一致

### 外部阻塞

- 缺实体板卡，无法完成 UART/LED 实板闭环
- 缺最终板级 I/O delay 约束，`XDC` 仍是 pre-board 版本

### 风险

- 如果后续文档把扩展 UI 覆盖矩阵误写成“冻结比赛 ISA 口径升级”，会造成口径漂移
- 如果跳过文档同步继续做高侵入优化，会让口径再次失真

## 5. 下一步最值得做的 5 项

1. 先把当前 profiling / docs WIP 收口成 focused commit
2. 单独清理脚本 BOM / 换行差异与冲突备份文件
3. 如果继续优化，围绕 branch-dominant redirect 成本设计新的单变量假设
4. 每轮优化完整重跑 CoreMark / baseline / impl50 并同步日志
5. 如新一轮优化无明确收益，及时关闭方向并回到 clean worktree

`FQ-06A` 已在 `2026-04-08` 执行完 quick-screen，并已收口为 rejected。
这轮的真实结论是：

- 性能目标路径：`IMEM_OUTPUT_REG=0`
- 结构目标：bounded request cursor / request-side decouple
- 不动的部分：IF/ID payload path、fetch buffer 深度、比赛 ISA 口径
- correctness guardrail：`run_fetch_redirect_reuse_diag.bat` 严格覆盖 `IMEM_OUTPUT_REG=0/1` 的 queue preserve 与 drop-accounting，均已通过
- quick-screen gate：`require_prefetch` / `require_queue_fill` / redirect / memwait / smoke 全绿，但 CoreMark short 仍为 `11014885 / 0.912472`
- 收口动作：实验 RTL 已回退，主线只保留更强的 prefetch 诊断和脚本 plusarg 归一化
- fresh profile follow-up：`YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-08.log` 显示 `fetch_queue_empty_cycles = ex_fetch_redirect_valid_cycles = 1504970`，说明剩余大头是 redirect 代价，不是 request-side 缺口
- `2026-04-09` split profile：`YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-09.log` 显示
  - `ex_branch_redirect_cycles = 1235790`
  - `ex_jal_redirect_cycles = 153354`
  - `ex_jalr_redirect_cycles = 115826`
  - `fetch_redirect_reuse_cycles = 0`
  - `fetch_redirect_reuse_miss_cycles = 1504970`
- 这说明 CoreMark 的 redirect 开销是“taken branch 主导 + reuse 完全不起作用”，下一轮若继续，应优先围绕 branch-dominant redirect 代价做新假设，而不是重复 queue/reuse 微调或重开 `jal-only` 快捷路径

## 6. 关键文档与命令

关键文档：

- `doc/CURRENT_STATUS.md`
- `README.md`
- `doc/技术文档.md`
- `doc/coremark_submission_report.md`
- `doc/performance_experiment_log.md`
- `doc/regression_test_log.md`
- `doc/fpga_bringup_checklist.md`
- `fpga/vivado/README.md`
- `../01-项目管理/01-赛题要求/七星微赛题答疑整理.md`
- `../01-项目管理/04-汇报与提交材料/README.md`

关键命令：

```bat
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
scripts\run_coremark_profile.bat rv32 10 2000 100000000UL 20000000
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64
scripts\run_riscv_tests_subset.bat rv32 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv32_ui_all.txt rv32i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
scripts\run_riscv_tests_subset.bat rv64 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv64_ui_all.txt rv64i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
```

关键证据位置：

- CoreMark short summary: `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt`
- CoreMark short dated summary: `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt`
- CoreMark strict summary: `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt`
- CoreMark strict dated summary: `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt`
- CoreMark strict dated log: `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.log`
- CoreMark profile split log: `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-09.log`
- `rv32` baseline current summary: `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt`
- `rv64` baseline current summary: `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt`
- `rv32 full-ui` current summary: `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt`
- `rv64 full-ui` current summary: `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt`
- FPGA reports: `project/reports/clk_20p000ns/`

## 7. 文档缺口与建议补齐项

- 文档已同步到“冻结基线 + 2026-04-08 活跃验证”双层口径
- 赛方最新答疑已明确初赛以设计/技术文档为硬交付；性能/验证/FPGA 证据继续作为增强材料
- 初赛提交材料目录已迁入项目管理目录，但仍需在后续新结果出现时持续同步
- 当前主要不再是收口缺口，而是下一阶段优化工作：
  - freeze post-closure baseline
  - start from a control-flow-first hypothesis backed by the `2026-04-09` split profile
  - do not reopen request/queue micro-tuning unless a new control-flow hypothesis justifies it
  - keep docs aligned if optimization resumes

## 2026-04-10 当前工作区补充（交接必读）

### 当前环境与分支

- 主机：`Toylog_desktop`
- 系统 / shell：`Windows + PowerShell 5.1`
- 仓库根目录：`D:\BaiduSyncdisk\icdc_workspace`
- 当前分支：`main`
- push 状态：未推送；当前分支相对 `origin/main` 显示 `ahead 57`

### 当前工作区真实状态

- 当前工程主线不是新的性能收益版本，而是“冻结基线已稳定，后续优化仍停留在 profiling / hypothesis 筛选阶段”。
- 最新有实质内容的本地未提交改动集中在：
  - `doc/performance_experiment_log.md`
  - `scripts/run_coremark_profile.bat`
  - `tb/YH_rv_cpu_coremark_profile_tb.v`
  - `doc/2026-04-09_optimization_status_addendum.md`（未跟踪）
- 这些改动的真实目的不是改主线 RTL 行为，而是继续细化 redirect profiling，并把 `decode-stage early JAL redirect` 的拒绝结论写入文档。
- 当前还存在两类应单独处理的工作区噪声：
  - `scripts/build_coremark.bat`、`scripts/open_vivado_project.bat` 的 BOM / 换行差异
  - `scripts/build_coremark_冲突文件_佟亚龙_20260409225716.bat`
  - `scripts/open_vivado_project_冲突文件_佟亚龙_20260409225716.bat`

### 当前最新可复核结论

- `rv32 full-ui` 真实证据路径应为：
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt`
  - 结果：`42/42`
- `rv64 full-ui` 真实证据路径应为：
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt`
  - 结果：`54/54`
- `rv32 baseline` 真实证据路径应为：
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt`
  - 结果：`33/33`
- `rv64 baseline` 真实证据路径应为：
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt`
  - 结果：`21/21`
- strict CoreMark dated 证据路径应为：
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.log`
- `2026-04-09` split profile 真实证据路径应为：
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-09.log`
- 当前 branch-dominant redirect 结论已被该 profile 支撑：
  - `ex_branch_redirect_cycles = 1235790`
  - `ex_jal_redirect_cycles = 153354`
  - `ex_jalr_redirect_cycles = 115826`
  - `fetch_redirect_reuse_cycles = 0`
  - `fetch_redirect_reuse_miss_cycles = 1504970`
- 新增的 branch breakdown 证据路径是：
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_branch_breakdown_2026-04-09.log`
  - 当前可直接读到：
    - `ex_beq_redirect_cycles = 329513`
    - `ex_bne_redirect_cycles = 849894`
    - `ex_blt_redirect_cycles = 3863`
    - `ex_bge_redirect_cycles = 10573`
    - `ex_bltu_redirect_cycles = 13963`
    - `ex_bgeu_redirect_cycles = 27984`
- `2026-04-11` 已用同一命令在当前工作区复核：
  - 工作日志：`YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile.log`
  - 与 `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_branch_breakdown_2026-04-09.log` 的文本差异仅剩时间戳与仿真运行时行
  - 关键计数保持一致，说明 branch-dominant redirect 结论在当前工作区仍成立
- `decode-stage early JAL redirect` 已经拒绝保留，最小 guardrail 失败证据为：
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_jal_early_redirect_debug_2026-04-09.txt`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/jal_early_redirect_debug_2026-04-09.log`
  - 失败摘要：`jal -> FAIL`，最终 `tohost=5`

### 当前最值得直接接手的动作

1. 先把 profiling / docs WIP 收口成 focused commit：
   - `tb/YH_rv_cpu_coremark_profile_tb.v`
   - `scripts/run_coremark_profile.bat`
   - `doc/performance_experiment_log.md`
   - `doc/2026-04-09_optimization_status_addendum.md`
2. 单独清理 BOM / 换行差异与冲突备份脚本，不要和 profiling 结论混在同一个 commit。
3. 如果继续优化，下一轮不要再试 `jal-only` 快捷路径，而要直接围绕 branch-dominant redirect 代价设计新的单变量假设。
4. 后续所有文档引用 build 证据时，统一使用 `YH_rv_cpu/build/...`，不要再误写成仓库根目录 `build/...`。
