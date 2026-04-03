# YH_rv_cpu 当前任务板

## 已完成

- [x] 冻结 CoreMark 正式短跑口径
- [x] 冻结 RV32 baseline `33/33`
- [x] 冻结 RV64 baseline `21/21`
- [x] 冻结 FPGA `impl50` 比特流和 fresh 资源/时序口径
- [x] 冻结 FPGA-like CoreMark probe 入口
- [x] 收口 FPGA pre-board SOP、串口口径、evidence 路径和 firmware staging 说明
- [x] 明确保留优化：
  - `stall_decode = load_use_hazard`
  - `IMEM_OUTPUT_REG=0`
  - `DMEM_OUTPUT_REG=0`
- [x] 明确关闭“简单放松 stall_decode 继续优化 fetch”的方向

## 进行中

- [ ] strict EEMBC `>=10s` CoreMark 长跑
  - 当前冻结短跑结果仍为 `0.912472 CoreMark/MHz`
  - 当前状态仍只能标记为 `competition_reportable=yes`
  - 在 strict 长跑 fresh 通过前，不得改写为 strict valid
- [ ] 当前状态文档统一
  - 目标：README / handoff / todo / regression log / 汇报材料 / 技术文档口径一致

## 待处理

- [ ] 对剩余未跟踪 debug/trace 资产做去留分类
- [ ] 整理并提交长期执行计划文档
- [ ] 在 strict CoreMark 收口后冻结第二轮优化前基线

## 仅外部阻塞

- [ ] 实体板卡到位后完成 UART/LED 实板闭环
- [ ] 板卡到位后补齐正式 I/O delay 约束与实板证据

## 下一轮性能优化入口

只允许在下面条件全部满足后启动：

1. strict CoreMark 长跑口径收口
2. 当前文档和材料全部同步
3. 工作区未跟踪文件完成分类
4. 新基线完成 fresh 回归

启动后仅允许优先探索：

- `fetch/request/queue` 解耦设计
- 单变量实验
- 每轮都完整重跑 CoreMark score / smoke / RV32 / RV64 / impl50
