# YH_rv_cpu

## 项目定位

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。仓库目标不是继续堆叠一次性实验，而是维持一套可复现、可验证、可交接、可继续优化的竞赛级基线。

当前主线口径以 `2026-04-03` 的 fresh 结果为准，历史实验过程请看：

- `doc/coremark_submission_report.md`
- `doc/performance_experiment_log.md`
- `doc/regression_test_log.md`
- `doc/fpga_bringup_checklist.md`
- `doc/YH_rv_cpu_handoff.md`

## 冻结基线

### 当前比赛提交口径

| 项目 | 结果 |
|------|------|
| CoreMark score | `0.912472 CoreMark/MHz` |
| completion cycles | `11014885` |
| CoreMark score 结论 | `competition_reportable=yes`，`strict_eembc_10s_compliant=no` |
| CoreMark smoke | `620530 cycles` |
| riscv-tests rv32 | `33/33` |
| riscv-tests rv64 | `21/21` |
| impl50 资源 | `2555 LUT / 2170 FF / 4 BRAM / 0 DSP` |
| impl50 时序 | `WNS = +5.822ns`，`WHS = +0.057ns` |
| FPGA-like probe | `156442 cycles`，`7.728811 CoreMark/MHz` |

### 100MHz 参考口径

`100MHz` 结果仅保留为参考实现，不是当前比赛冻结提交口径。最新顶层实现报告为：

- `2598 LUT / 2240 FF / 4 BRAM / 0 DSP`
- `WNS = +0.062ns`
- `WHS = +0.048ns`

不要再引用历史 `async_default` 子路径值作为顶层 `100MHz` 总结值；当前应以整设计 `Design Timing Summary` 为准。

## 当前保留优化

- `stall_decode = load_use_hazard`
- FPGA 默认 `IMEM_OUTPUT_REG=0`
- FPGA 默认 `DMEM_OUTPUT_REG=0`

## 当前不保留的方向

- 不能通过简单放松 `stall_decode` 门控继续推进 fetch 前端提分。
- 如果继续做前端优化，必须单列为 `fetch/request/queue` 解耦设计与实验。
- 所有后续优化都必须保持单变量、小步、可回归。

## 快速验证命令

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
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64

scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
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

## 当前剩余阻塞

- strict EEMBC `>=10s` 的 CoreMark 长跑证据仍在补齐中；在长跑完成前，当前正式冻结分数仍然只能标记为 `competition_reportable=yes`、`strict_eembc_10s_compliant=no`
- 实体板卡未到位，UART/LED 实板闭环仍需按 checklist 补证据
- XDC 仍缺正式板级 I/O delay 约束，当前只能作为 pre-board 约束口径
