# YH_rv_cpu

## 项目定位

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。目标不是继续堆叠一次性实验，而是维护一套可复现、可验证、可交接、可继续优化的比赛级工程。

当前工程存在两层状态，引用时必须区分：

- 冻结基线：`2026-04-07` 完整收口的比赛提交级基线
- 活跃工作区：`2026-04-08` 正在推进的 `riscv-tests` 扩展验证与文档同步，尚未提交收口

主文档入口：

- `doc/coremark_submission_report.md`
- `doc/performance_experiment_log.md`
- `doc/regression_test_log.md`
- `doc/fpga_bringup_checklist.md`
- `doc/YH_rv_cpu_handoff.md`

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
| 工作区状态 | dirty，存在未提交 RTL/脚本/文档/manifest/linker 改动 |
| 扩展验证目标 | 从 baseline 子集扩展到更接近普遍 `rv32ui/rv64ui` 的真实矩阵 |
| `rv32 full-ui` | fresh `41/42`，摘要见 `build/tests/riscv-tests/rv32/summary.txt` |
| 当前唯一失败项 | `fence_i` |
| `fence_i` 根因 | 当前编译口径为 `-march=rv32i_zicsr`，而 `fence_i.S` 需要 `zifencei` 扩展，属于 ISA/march 口径问题，不是超时问题 |
| `ma_data` | 已通过，说明 misaligned trap 软件补偿链路已生效 |
| `rv64 full-ui` | 尚待 fresh 重跑并归档 |
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

- 在 `fence_i` 口径明确前，不要声称 `rv32 full-ui` 已全部通过
- 在 `rv32/rv64 full-ui` 与 fresh baseline 没有闭环前，不要重启高侵入优化
- 在新的 fresh CoreMark smoke/short/strict 复核没有完成前，不要更新 CoreMark 基线数字
- 文档、脚本、summary、handoff 必须同步更新，不能只改代码不记记录

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
scripts\run_riscv_tests_subset.bat rv32 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv32_ui_all.txt - continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
scripts\run_riscv_tests_subset.bat rv64 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv64_ui_all.txt - continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
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

## 当前阻塞

### 本机内待收口

- `fence_i` 的 ISA/march 口径必须明确：要么纳入 `zifencei`，要么明确排除在当前矩阵之外
- `rv64 full-ui`、fresh baseline、fresh CoreMark 复核仍待补齐

### 外部阻塞

- 实体板卡未到位，UART/LED 实板闭环仍无法完成
- XDC 仍缺正式板级 I/O delay 约束，当前只能作为 pre-board 约束口径
