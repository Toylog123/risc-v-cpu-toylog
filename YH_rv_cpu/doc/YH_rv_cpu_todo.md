# YH_rv_cpu 当前任务板

## 已完成

- [x] 冻结 CoreMark 正式短跑口径
- [x] 冻结 RV32 baseline `33/33`
- [x] 冻结 RV64 baseline `21/21`
- [x] 冻结 FPGA `impl50` 比特流和 fresh 资源/时序口径
- [x] 冻结 FPGA-like CoreMark probe 入口
- [x] 收口 FPGA pre-board SOP、串口口径、evidence 路径和 firmware staging 说明
- [x] 归档长期执行计划文档
  - `docs/superpowers/plans/2026-04-02-yh-rv-cpu-competition-closure.md`
  - `docs/superpowers/plans/2026-04-03-yh-rv-cpu-long-horizon-execution.md`
- [x] 完成 strict EEMBC `>=10s` CoreMark 长跑
  - `CoreMark/MHz = 0.912465`
  - `completion_cycles = 1095991523`
  - `total_seconds = 10.959325`
  - `strict_eembc_10s_compliant = yes`
- [x] 完成当前状态文档统一
- [x] 完成剩余 debug/trace 资产治理
  - `debug` 与 `trace` 临时工具已归档到 `_tmp\legacy\`
- [x] 明确保留优化：
  - `stall_decode = load_use_hazard`
  - `IMEM_OUTPUT_REG=0`
  - `DMEM_OUTPUT_REG=0`
- [x] 明确关闭“简单放松 stall_decode 继续优化 fetch”的方向

## 进行中

## 待处理

- [ ] 冻结第二轮优化前基线
- [ ] 启动 `fetch/request/queue` 解耦方向的单变量设计与实验
- [ ] 对任何 retained 优化补齐完整 fresh 回归矩阵

## 仅外部阻塞

- [ ] 实体板卡到位后完成 UART/LED 实板闭环
- [ ] 板卡到位后补齐正式 I/O delay 约束与实板证据

## 下一轮性能优化入口

只允许在下面条件全部满足后启动：

1. 当前优化方案有明确的单变量边界
2. 新基线已写入 `doc/performance_experiment_log.md`
3. 每轮实验都承诺重跑 fresh 回归矩阵
4. 工作区保持只含 intentional 内容或外部阻塞

启动后仅允许优先探索：

- `fetch/request/queue` 解耦设计
- 单变量实验
- 每轮都完整重跑 CoreMark score / smoke / RV32 / RV64 / impl50

## 2026-04-04 Update

- [x] Added directed fetch diagnostic assets:
  - `tb/YH_rv_cpu_fetch_prefetch_tb.v`
  - `scripts/run_fetch_prefetch_diag.bat`
- [x] Completed the first `fetch/request/queue` single-variable trial.
- [x] Rejected the 1-entry request-side cursor RTL after `0` CoreMark score delta.
- [ ] Re-open front-end optimization only after redirect/flush/drop accounting gets a new small-step validation plan.
