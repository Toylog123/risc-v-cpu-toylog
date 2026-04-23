# YH_rv_cpu 交接说明

## 1. 项目是什么

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。核心目标不是做更多一次性实验，而是把工程维持在“可复现、可验证、可交接、可继续优化”的提交级状态。

本文件按 live handoff 维护。每完成一个阶段，都应先把这里同步到可接手状态，再继续下一阶段。

当前赛题与工程 ISA 口径是：

- 赛题题面允许 CPU 基于 `RV32I` 或 `RV64I`
- 当前冻结性能/提交主口径仍以 `RV32I + Zicsr` 为主
- 当前工程验证能力已覆盖 `RV32/RV64` 双 XLEN，且 `baseline` / `full-ui` 都有 fresh 结果

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
3. 如果继续优化，优先试做 taken `BEQ/BNE` 的 decode-stage early redirect，并保持 operand-ready gating 与完整 wrong-path flush
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
- `../01-项目管理/01-赛题要求/七星微赛题要求.md`
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
- `2026-04-11` branch-first `BEQ/BNE` pipe-hit quick-screen 已执行并归档：
  - 基线失败日志：`YH_rv_cpu/build/tests/branch-first/branch_reuse_beqbne_baseline_fail_2026-04-11.log`
  - 试验通过日志：`YH_rv_cpu/build/tests/branch-first/branch_reuse_beqbne_diag_2026-04-11.log`
  - `rv32 beq` / `rv32 bne` guardrail：
    - `YH_rv_cpu/build/tests/branch-first/summary_beq_branch_pipehit_beqbne_2026-04-11.txt`
    - `YH_rv_cpu/build/tests/branch-first/summary_bne_branch_pipehit_beqbne_2026-04-11.txt`
  - CoreMark profile：
    - `YH_rv_cpu/build/tests/branch-first/YH_rv_cpu_coremark_rv32_profile_branch_pipehit_beqbne_2026-04-11.log`
    - 关键信号变化：`fetch_redirect_reuse_cycles = 305277`，`fetch_redirect_reuse_miss_cycles = 1199693`
    - 但 `fetch_queue_empty_cycles` 仍为 `1504970`
  - CoreMark short：
    - `YH_rv_cpu/build/tests/branch-first/YH_rv_cpu_coremark_rv32_score_branch_pipehit_beqbne_2026-04-11.summary.txt`
    - 结果仍为 `11014885 cycles`，`0.912472 CoreMark/MHz`
  - 结论：主线 RTL 已在同轮回退；本轮保留的是更强的 `require_branch_reuse` 诊断，而不是新的性能收益 RTL
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
3. 如果继续优化，下一轮不要再试 `jal-only` 快捷路径，也不要重复 `BEQ/BNE pipe-hit-only` 切片；优先执行 `docs/superpowers/plans/2026-04-12-yh-rv-cpu-beqbne-early-redirect-plan.md` 中的 taken `BEQ/BNE` decode-stage early redirect 试验。
4. 后续所有文档引用 build 证据时，统一使用 `YH_rv_cpu/build/...`，不要再误写成仓库根目录 `build/...`。

## 2026-04-12 当前工作区补充（优先阅读）

### 当前结论

- 当前 active worktree 已保留新的前端优化：
  - taken `BEQ/BNE` decode-stage early redirect
  - 显式 operand-ready gating
- 这不是新的 frozen competition baseline；本轮还没有 fresh 完成：
  - strict CoreMark long run
  - `impl50`
  - FPGA-like probe

### 本轮 fresh 证据

- 定向 red/green：
  - baseline `FAIL`：
    `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_baseline_2026-04-12.log`
  - trial `PASS`：
    `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_trial_2026-04-12.log`
  - default redirect diag `PASS`：
    `YH_rv_cpu/build/tests/branch-first/redirect_diag_default_trial_2026-04-12.log`
- `rv32 full-ui = 42/42`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-12.txt`
- `rv64 full-ui = 54/54`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-12.txt`
- `rv32 baseline = 33/33`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-12.txt`
- `rv64 baseline = 21/21`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-12.txt`
- CoreMark short 两次独立摘要完全一致：
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-12.summary.txt`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_rerun_2026-04-12.summary.txt`
  - 结果：`10862713 cycles`，`0.925186 CoreMark/MHz`
- fresh profile：
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-12.log`
  - `total_cycles = 12364249`
  - `ex_branch_redirect_cycles = 1081457`
  - `ex_fetch_redirect_valid_cycles = 1350637`
  - `fetch_queue_empty_cycles = 1504970`

### 这轮的真实解释

- 相比 frozen short baseline `11014885 / 0.912472`，当前 retained worktree
  已经稳定改善到 `10862713 / 0.925186`
- 这个收益来源是 branch redirect 窗口缩短，不是 queue/reuse 路径起效：
  - `ex_branch_redirect_cycles 1235790 -> 1081457`
  - `fetch_queue_empty_cycles` 保持 `1504970`
- 所以不要把这轮写成“fetch queue 优化成功”；更准确的口径是
  “branch-dominant redirect timing 优化成功”

### 工具链补充

- `scripts/run_coremark_score.bat` 已在本轮修成：
  - 从 summary 路径自动派生产物名前缀
  - short / strict 后续不再互相覆盖 `score.log` 与 `score.*`

### 下一步接手动作

1. 在 retained RTL 上补 fresh strict CoreMark long run。
2. 在 retained RTL 上补 `impl50` 与 FPGA-like probe。
3. 如果上述仍然为正向结果，再刷新 README / CURRENT_STATUS /
   CoreMark report 里的 frozen competition tables。
4. freeze refresh 完成前，不要把 `2026-04-12` 结果直接写成新的
   frozen implementation baseline。

## 2026-04-23 当前工作区补充（M扩展测试 + C扩展预留）

### 本次完成的工作

1. **M扩展指令测试 11/11 全部通过**
   - 修复了 `YH_rv_cpu_m_extension_tb.v` 中的指令编码错误
   - ADDI指令rd字段编码错误：原为x17，应为x1/x2
   - MULHSU指令编码错误：使用了MULHU的funct3编码
   - 测试覆盖：MUL, MULH, MULHU, MULHSU, DIV, DIVU, REM, REMU 及除零特殊处理

2. **C扩展预留接口已添加**
   - `YH_rv_cpu_if_stage.v` 添加 `C_EXT` 参数（默认0=禁用）
   - 新增信号：`pc_plus_2`（压缩指令PC增量）、`instr_is_compressed`（压缩指令判断）
   - `YH_rv_cpu.v` 透传 `C_EXT` 参数到 if_stage
   - 条件编译：`C_EXT=1` 时根据指令低两位判断是否压缩

3. **dcache错误修复**
   - `YH_rv_cpu_dcache.v` 添加 `cache_line_idx` 声明
   - 修复 `hit_way` 在always @*中procedural assignment问题
   - 改为使用连续赋值 `assign hit_way = ...`

### 本次修改的文件

| 文件 | 状态 | 说明 |
|------|------|------|
| `tb/YH_rv_cpu_m_extension_tb.v` | 修改 | 修复ADDI/MULHSU编码 |
| `rtl/YH_rv_cpu_if_stage.v` | 修改 | 添加C_EXT参数和预留信号 |
| `rtl/YH_rv_cpu.v` | 修改 | 透传C_EXT参数 |
| `rtl/YH_rv_cpu_dcache.v` | 修改 | 修复编译错误 |

### 测试验证

M扩展测试在 `D:/BaiduSyncdisk/02_icdc_workspace/YH_rv_cpu/build/tests/m_extension_fresh` 目录下验证通过：
- `xvlog` + `xelab` + `xsim m_final` 验证 11/11 PASS
- 测试文件：`tb/YH_rv_cpu_m_extension_tb.v`

### 下一步建议

1. 更新 README.md 中的扩展支持状态说明
2. 考虑将C扩展预留接口写入设计文档
3. 如继续优化性能，可参考 2026-04-12 的 branch redirect 优化方向

## 2026-04-23 下午补充（dcache集成修复）

### 本次完成的工作

1. **dcache集成到CPU核**
   - `YH_rv_cpu.v` 添加 `DCACHE_EN` 参数（默认0=禁用，1=启用）
   - 当 `DCACHE_EN=1` 时实例化 dcache 模块，插入到 mem_stage 和外部 dmem 之间
   - 当 `DCACHE_EN=0` 时保持原有直连模式（向后兼容）

2. **修复dcache集成bug**
   - 问题：M扩展测试 0/11 通过，寄存器显示 'z'（高阻抗）
   - 根因：`DCACHE_EN == 1` 分支中 dcache 未正确驱动外部 `dmem_*` 信号
   - 修复：添加 `dmem_read_req`、`dmem_we`、`dmem_wdata`、`dmem_wstrb` 的赋值

### 关键代码变更

```verilog
// DCACHE_EN=1 分支中添加了缺失的信号赋值
assign dmem_read_req = dcache_mem_req;
assign dmem_we       = dcache_mem_we;
assign dmem_wdata    = dcache_mem_wdata;
assign dmem_wstrb    = dcache_mem_wstrb;
```

### 本次修改的文件

| 文件 | 状态 | 说明 |
|------|------|------|
| `rtl/YH_rv_cpu.v` | 修改 | 添加DCACHE_EN参数、dcache实例化、信号连接 |
| `rtl/YH_rv_cpu_alu.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_decoder.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_defs.vh` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_ex_stage.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_hazard_unit.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_id_stage.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_if_stage.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_mem_stage.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_regfile.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_wb_stage.v` | 修改 | 添加`timescale |
| `rtl/YH_rv_cpu_dcache.v` | 新增 | 数据缓存模块 |
| `rtl/YH_rv_cpu_icache.v` | 新增 | 指令缓存模块（已集成） |
| `rtl/YH_rv_cpu_axi_lite_if.v` | 新增 | AXI-Lite接口模块 |
| `tb/YH_rv_cpu_m_extension_tb.v` | 新增 | M扩展测试平台 |
| `scripts/run_m_extension_test.bat` | 新增 | M扩展测试脚本 |

### 测试验证

在 `D:/BaiduSyncdisk/02_icdc_workspace/YH_rv_cpu/build/tests/dcache_clean3` 目录下验证：
- `xelab` 编译成功，无错误
- M扩展测试 **11/11 通过** ✓
- DCACHE_EN=1（dcache启用）和 DCACHE_EN=0（直连模式）均正常工作

### 架构说明

```
                    DCACHE_EN=0                 DCACHE_EN=1
                    ==========                 ==========
mem_stage.dmem_*  ──────────────────────────►  mem_stage.dmem_*
                                               │
                                               ▼
                                          ┌─────────┐
                                          │  dcache │
                                          └─────────┘
                                               │
                                               ▼
                                          外部dmem信号
```

当 DCACHE_EN=1 时，dcache 驱动所有外部 dmem 信号（dmem_addr, dmem_read_req, dmem_we, dmem_wdata, dmem_wstrb），mem_stage 通过中间变量与 dcache 通信。
