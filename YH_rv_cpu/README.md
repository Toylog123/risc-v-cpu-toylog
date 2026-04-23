# YH_rv_cpu

## 项目定位

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。目标不是继续堆叠一次性实验，而是维护一套可复现、可验证、可交接、可继续优化的比赛级工程。

当前工程存在两层状态，引用时必须区分：

- 冻结基线：`2026-04-07` 完整收口的比赛提交级基线
- 活跃工作区：`2026-04-12` 已保留一轮 branch-dominant redirect 优化，但
  frozen competition baseline 尚未刷新到这版 RTL

当前赛题题面允许 CPU 基于 `RV32I` 或 `RV64I`。当前工程已经具备
`RV32/RV64` 双 XLEN 验证能力，但冻结提交中的性能统计与主叙述口径仍以
`RV32I + Zicsr` 路径为主。

主文档入口：

- `doc/coremark_submission_report.md`
- `doc/performance_experiment_log.md`
- `doc/regression_test_log.md`
- `doc/fpga_bringup_checklist.md`
- `doc/YH_rv_cpu_handoff.md`
- `../01-项目管理/01-赛题要求/七星微赛题要求.md`
- `../01-项目管理/04-汇报与提交材料/README.md`

## 冻结基线

### 当前比赛提交口径

| 项目 | 结果 |
|------|------|
| CoreMark short score | `0.912472 CoreMark/MHz` |
| CoreMark short completion cycles | `11014885` |
| CoreMark strict score | `0.912465 CoreMark/MHz` |
| CoreMark strict completion cycles | `1095991523` |
| CoreMark strict runtime | `10.959325s` (`Total ticks = 1095932534`) |
| CoreMark score 结论 | short path `competition_reportable=yes`，strict path `strict_eembc_10s_compliant=yes` |
| CoreMark smoke | `620530 cycles` |
| riscv-tests rv32 baseline | `33/33` |
| riscv-tests rv64 baseline | `21/21` |
| impl50 资源 | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP` |
| impl50 时序 | `WNS = +5.599ns`，`WHS = +0.025ns` |
| FPGA-like probe | `156442 cycles`，`7.728811 CoreMark/MHz` |

### 100MHz 参考实现

`100MHz` 结果仅保留为参考实现，不是当前比赛冻结提交口径：

- `2598 LUT / 2240 FF / 4 BRAM / 0 DSP`
- `WNS = +0.062ns`
- `WHS = +0.048ns`

不要再引用历史 `async_default` 子路径值作为顶层 `100MHz` 总结值；当前应以整设计 `Design Timing Summary` 为准。

## 2026-04-12 活跃工作区状态

以下内容属于当前工作区的活跃验证，不等同于新的冻结基线：

| 项目 | 当前状态 |
|------|------|
| 工作区状态 | 已保留 taken `BEQ/BNE` decode-stage early redirect with operand-ready gating；冻结比赛基线尚未刷新到这版 RTL |
| 当前优化结果 | short CoreMark `10862713 cycles`，`0.925186 CoreMark/MHz`；profile `12364249 cycles` |
| 关键定向证据 | `require_branch_decode_kill` 基线 `FAIL`：`build/tests/branch-first/branch_decode_kill_baseline_2026-04-12.log`；试验 `PASS`：`build/tests/branch-first/branch_decode_kill_trial_2026-04-12.log`；default redirect diag `PASS`：`build/tests/branch-first/redirect_diag_default_trial_2026-04-12.log` |
| branch profile delta | `ex_branch_redirect_cycles 1235790 -> 1081457`，`ex_fetch_redirect_valid_cycles 1504970 -> 1350637`，`fetch_queue_empty_cycles` 保持 `1504970` |
| `rv32 full-ui` | fresh `42/42`，摘要见 `build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-12.txt` |
| `fence_i` 处理策略 | 扩展 UI 覆盖矩阵采用 `rv32i_zicsr_zifencei` 编译口径，`fence_i` 已通过；冻结比赛口径仍维持 `RV32I + Zicsr` |
| `fence_i` 当前结论 | 对当前无 I-cache、同步 ROM/RAM 的核，`fence.i` 以 non-trapping nop 形式即可满足当前 `riscv-tests` 覆盖需求 |
| `ma_data` | 已通过，说明 misaligned trap 软件补偿链路已生效 |
| `rv64 full-ui` | fresh `54/54`，摘要见 `build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-12.txt` |
| `rv32 baseline` | fresh `33/33`，归档=`build/tests/riscv-tests/rv32/summary_baseline_2026-04-12.txt` |
| `rv64 baseline` | fresh `21/21`，归档=`build/tests/riscv-tests/rv64/summary_baseline_2026-04-12.txt` |
| CoreMark short | fresh `0.925186 CoreMark/MHz`，`10862713 cycles`，摘要=`build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-12.summary.txt`；重复 rerun=`build/sw/YH_rv_cpu_coremark_rv32_score_rerun_2026-04-12.summary.txt` |
| CoreMark strict | 本轮 fresh rerun 暂未完成；最近可引用 long-run 仍是 `build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt` |
| impl50 / probe | 本轮 retained RTL 尚未 fresh rerun；最近可引用实现侧证据仍是冻结 `2026-04-08` 的 `impl50` / FPGA-like probe |
| FPGA 实板计划 | 当前仅保留 pre-board 冻结状态；实板闭环继续视为外部阻塞且暂不优先推进 |

## 2026-04-23 更新

- dcache 集成完成：`DCACHE_EN=1` 时 dcache 模块正确插入，M 扩展测试 **11/11 通过** ✓
- 新增模块：`rtl/YH_rv_cpu_dcache.v`、`rtl/YH_rv_cpu_icache.v`（预留）、`rtl/YH_rv_cpu_axi_lite_if.v`
- C扩展预留：`rtl/YH_rv_cpu_if_stage.v` 添加 `C_EXT` 参数

当前扩展验证使用的新主线输入文件：

- `scripts/riscv_tests_rv32_ui_all.txt`
- `scripts/riscv_tests_rv64_ui_all.txt`
- `sw/linker/YH_rv_cpu_riscv_tests_large.ld`

## 当前保留优化

- `stall_decode = load_use_hazard`
- FPGA 默认 `IMEM_OUTPUT_REG=0`
- FPGA 默认 `DMEM_OUTPUT_REG=0`
- taken `BEQ/BNE` decode-stage early redirect with operand-ready gating

## 当前不保留的方向

- 不能通过简单放松 `stall_decode` 门控继续推进 fetch 前端提分
- 已执行的 `request-cursor / pipe-hit / redirect 同拍取指 / FQ-01 ~ FQ-05` 均未形成可保留收益
- `decode-stage early JAL redirect` 已拒绝保留；不要重开 `jal-only` 快捷路径
- `BEQ/BNE pipe-hit-only` 已拒绝保留；当前保留的是更强的 decode-stage early redirect 切片，不是旧的 pipe-hit 提示路径
- 如果继续做前端优化，必须在当前 retained worktree 完成 strict / impl / probe 刷新后，再单列下一轮 `fetch/request/queue` 或 control-flow 实验

## 当前收口原则

- `2026-04-12` 的 `rv32/rv64 full-ui` 与 `rv32/rv64 baseline` fresh rerun 已闭环
- 当前 retained worktree 变化是：decode-stage taken `BEQ/BNE` early redirect，但必须满足 operand-ready gating
- short CoreMark 已至少两次得到完全一致的 fresh 结果：`10862713 cycles`，`0.925186 CoreMark/MHz`
- fresh profile 表明收益来自 branch redirect window 缩短，而不是 queue-empty 或 reuse 激活：
  - `ex_branch_redirect_cycles 1235790 -> 1081457`
  - `ex_fetch_redirect_valid_cycles 1504970 -> 1350637`
  - `fetch_queue_empty_cycles` 仍为 `1504970`
- 本轮仍未完成的 freeze-refresh 项目是：strict CoreMark long run、`impl50`、FPGA-like probe
- `scripts/run_coremark_score.bat` 已改成从 summary 路径自动派生产物名前缀，后续 strict / short 不会再互相覆盖 `score.log` 和 `score.*`
- 赛题要求与详细逐点整理已统一收口到 `../01-项目管理/01-赛题要求/七星微赛题要求.md`，当前文档与提交材料均按该文件对齐
- `2026-04-09` 已将汇报材料集中到 `../01-项目管理/04-汇报与提交材料/`，初赛正式提交物和内部支撑材料统一在该目录维护
- 文档、脚本、summary、handoff 必须继续同步更新，不能在下一阶段重新产生口径漂移

## 快速验证命令

### 冻结基线命令

```bat
scripts\check_toolchain.bat
scripts\check_syntax.bat
scripts\build_firmware.bat

scripts\run_soc_smoke.bat
scripts\run_trap_smoke.bat
scripts\run_timer_irq_smoke.bat
scripts\run_xlen64_smoke.bat

scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64

scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
```

### 扩展验证命令

```bat
scripts\run_riscv_tests_subset.bat rv32 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv32_ui_all.txt rv32i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
scripts\run_riscv_tests_subset.bat rv64 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv64_ui_all.txt rv64i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
```

## 文档入口

- 总体技术基线：`doc/技术文档.md`
- CoreMark 正式口径：`doc/coremark_submission_report.md`
- 性能实验历史：`doc/performance_experiment_log.md`
- 回归记录：`doc/regression_test_log.md`
- FPGA pre-board / bring-up：`doc/fpga_bringup_checklist.md`
- 接手说明：`doc/YH_rv_cpu_handoff.md`
- 当前任务板：`doc/YH_rv_cpu_todo.md`
- Vivado 使用说明：`fpga/vivado/README.md`
- 赛题要求总文件：`../01-项目管理/01-赛题要求/七星微赛题要求.md`
- 汇报与提交材料入口：`../01-项目管理/04-汇报与提交材料/README.md`
- 初赛设计说明书（最新 dated 版）：`../01-项目管理/04-汇报与提交材料/初赛提交材料/YH_rv_cpu初赛设计说明书-2026-04-18.pdf`

## 当前阻塞

### 本机内待推进

- 强制收口阶段已完成；当前如继续本机内工作，下一阶段不是补收口，而是判断是否还存在新的、非重复的 fetch/request/queue 优化假设

### 外部阻塞

- 实体板卡未到位，UART/LED 实板闭环仍无法完成
- XDC 仍缺正式板级 I/O delay 约束，当前只能作为 pre-board 约束口径
