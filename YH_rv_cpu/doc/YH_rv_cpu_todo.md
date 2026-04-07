# YH_rv_cpu 当前任务表

## 已完成

- [x] 冻结 CoreMark 正式短跑口径
- [x] 冻结 strict EEMBC `>=10s` CoreMark 长跑口径
- [x] 冻结 RV32 baseline `33/33`
- [x] 冻结 RV64 baseline `21/21`
- [x] 冻结 FPGA `impl50` 比特流和 fresh 资源/时序口径
- [x] 冻结 FPGA-like CoreMark probe 入口
- [x] 收口 FPGA pre-board SOP、串口口径、evidence 路径和 firmware staging 说明
- [x] 完成当前状态文档统一
- [x] 完成 debug/trace 资产治理
- [x] 明确保留优化：
  - `stall_decode = load_use_hazard`
  - `IMEM_OUTPUT_REG=0`
  - `DMEM_OUTPUT_REG=0`
- [x] 明确关闭“简单放松 `stall_decode` 继续优化 fetch”的方向
- [x] 完成第一轮 `fetch/request/queue` 单变量实验
- [x] 拒绝保留 1-entry request-side cursor RTL，原因是 short score delta 为 `0`
- [x] 新增 `mem-wait overlap` 定向诊断
- [x] 完成 `mem-wait overlap` 单变量 RTL 试验并拒绝保留（short score 无收益）
- [x] 修复 `timer_irq_smoke` 回归
- [x] 重新冻结第二轮优化前基线
- [x] 让 `scripts/build_vivado_project.bat impl50` 默认绑定冻结 demo payload
- [x] 已补齐 redirect/flush/drop-accounting 小步验证方案，并完成双变体 strict 通过
- [x] 完成 redirect `pipe-hit` 单变量复核并拒绝保留（strict 可过但 short score 无收益）
- [x] 完成 redirect 同拍取指单变量复核并拒绝保留（定向诊断通过但 short score 无收益）
- [x] 完成 FQ-01（queue 语义解耦）单变量复核并拒绝保留（诊断全绿但 short score 无收益）
- [x] 完成 FQ-02（queue/FIFO occupancy）单变量复核并拒绝保留（诊断全绿但 short score 无收益）

## 待处理

- [ ] 对未来任意 retained 优化补齐完整 fresh 回归矩阵
- [ ] 若继续优化前端，需提出全新非重复假设（不得重复 request-cursor / pipe-hit / redirect 同拍取指 / FQ-01 / FQ-02）

## 仅外部阻塞

- [ ] 实体板卡到位后完成 UART/LED 实板闭环
- [ ] 板卡到位后补齐正式 I/O delay 约束与实板证据

## 下一轮性能优化入口

只有满足以下条件后，才允许进入下一轮性能优化：

1. 当前优化方案有明确的单变量边界。
2. 新基线已写入 `doc/performance_experiment_log.md`。
3. 每轮实验都承诺重跑 fresh 回归矩阵。
4. 工作区保持只有 intentional 内容或外部阻塞。

允许优先探索的方向：

- `fetch/request/queue` 解耦设计
- redirect/flush/drop accounting 定向验证
- 单变量 RTL 实验

禁止直接重开的方向：

- 没有新验证计划时重开 redirect `pipe-hit` RTL
- 继续拍脑袋放松 `stall_decode`
