# YH_rv_cpu

## 项目定位

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。目标不是继续堆叠一次性实验，而是维护一套可复现、可验证、可交接、可继续优化的比赛级工程。

当前工程存在两层状态，引用时必须区分：

- 冻结基线：`2026-04-07` 完整收口的比赛提交级基线
- 活跃工作区：`2026-04-08` strict / `full-ui` / baseline fresh 收口已完成；第一轮 `FQ-06A` quick-screen 已执行并拒绝保留

主文档入口：

- `doc/coremark_submission_report.md`
- `doc/performance_experiment_log.md`
- `doc/regression_test_log.md`
- `doc/fpga_bringup_checklist.md`
- `doc/YH_rv_cpu_handoff.md`
- `../01-项目管理/01-赛题要求/七星微赛题答疑整理.md`
- `../01-项目管理/05-汇报与提交材料/初赛提交材料/README.md`

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

## 2026-04-08 活跃工作区状态

以下内容属于当前工作区的活跃验证，不等同于新的冻结基线：

| 项目 | 当前状态 |
|------|------|
| 工作区状态 | `FQ-06A` quick-screen 已完成；主线 RTL 已回退到冻结基线，当前保留文档与诊断资产更新 |
| 扩展验证目标 | 从 baseline 子集扩展到更接近普遍 `rv32ui/rv64ui` 的真实矩阵 |
| `rv32 full-ui` | fresh `42/42`，摘要见 `build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt` |
| `fence_i` 处理策略 | 扩展 UI 覆盖矩阵采用 `rv32i_zicsr_zifencei` 编译口径，`fence_i` 已通过；冻结比赛口径仍维持 `RV32I + Zicsr` |
| `fence_i` 当前结论 | 对当前无 I-cache、同步 ROM/RAM 的核，`fence.i` 以 non-trapping nop 形式即可满足当前 `riscv-tests` 覆盖需求 |
| `ma_data` | 已通过，说明 misaligned trap 软件补偿链路已生效 |
| `rv64 full-ui` | fresh `54/54`，摘要见 `build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt` |
| `rv32 baseline` | fresh `33/33`，归档=`build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt` |
| `rv64 baseline` | fresh `21/21`，归档=`build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt` |
| CoreMark smoke | fresh `620530 cycles` |
| CoreMark short | fresh `0.912472 CoreMark/MHz`，`11014885 cycles`，摘要=`build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt` |
| CoreMark strict | fresh `0.912465 CoreMark/MHz`，`1095991523 cycles`，`10.959325s`，摘要=`build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt` |
| FPGA 实板计划 | 当前仅保留 pre-board 冻结状态；实板闭环继续视为外部阻塞且暂不优先推进 |

当前扩展验证使用的新主线输入文件：

- `scripts/riscv_tests_rv32_ui_all.txt`
- `scripts/riscv_tests_rv64_ui_all.txt`
- `sw/linker/YH_rv_cpu_riscv_tests_large.ld`

## 当前保留优化

- `stall_decode = load_use_hazard`
- FPGA 默认 `IMEM_OUTPUT_REG=0`
- FPGA 默认 `DMEM_OUTPUT_REG=0`

## 当前不保留的方向

- 不能通过简单放松 `stall_decode` 门控继续推进 fetch 前端提分
- 已执行的 `request-cursor / pipe-hit / redirect 同拍取指 / FQ-01 ~ FQ-05` 均未形成可保留收益
- 如果继续做前端优化，必须单列为 `fetch/request/queue` 解耦设计与实验，并在进入优化前先完成当前扩展验证收口

## 当前收口原则

- `2026-04-08` 的 `rv32/rv64 full-ui`、fresh baseline、fresh CoreMark smoke/short/strict 都已闭环
- 如继续进入下一轮优化，先冻结新的 post-closure baseline，再按单变量方式启动 `FQ-06`
- `FQ-06A` 已完成：`IMEM_OUTPUT_REG=0` 路径上的 bounded request cursor 诊断全绿，但 short CoreMark 零收益，因此未保留
- `IMEM_OUTPUT_REG=1` 本轮继续只做 correctness guardrail，严格 redirect/drop-accounting 诊断已通过
- fresh profile 进一步表明 `fetch_queue_empty_cycles` 与 `ex_fetch_redirect_valid_cycles` 完全重合，剩余 fetch 空泡主要来自 redirect 窗口而不是 request-side 缺口
- `2026-04-09` 官方答疑已整理入 `../01-项目管理/01-赛题要求/七星微赛题答疑整理.md`，初赛硬交付口径已改为“设计/技术文档为主，性能/验证为增强材料”
- `2026-04-09` 已将汇报材料集中到 `../01-项目管理/05-汇报与提交材料/`，提交清单、证据索引与答辩口径统一在该目录维护
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
- 赛题答疑整理：`../01-项目管理/01-赛题要求/七星微赛题答疑整理.md`
- 初赛提交材料：`../01-项目管理/05-汇报与提交材料/初赛提交材料/README.md`

## 当前阻塞

### 本机内待推进

- 强制收口阶段已完成；当前如继续本机内工作，下一阶段不是补收口，而是判断是否还存在新的、非重复的 fetch/request/queue 优化假设

### 外部阻塞

- 实体板卡未到位，UART/LED 实板闭环仍无法完成
- XDC 仍缺正式板级 I/O delay 约束，当前只能作为 pre-board 约束口径
