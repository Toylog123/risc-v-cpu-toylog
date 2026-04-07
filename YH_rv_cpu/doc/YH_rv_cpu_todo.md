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

- [x] 设计并冻结 `FQ-03` 全新非重复假设（explicit 3-entry queue 语义）
- [x] 执行 `FQ-03` quick screen：redirect diag 默认 + redirect accounting strict(`IMEM_OUTPUT_REG=0/1`) + CoreMark smoke + CoreMark short
- [x] 完成 `FQ-03` 保留决策：不保留（short score 未优于 `11014885 cycles`，已回退 RTL）
- [x] 执行下一轮方向切换：停止重复前端已拒绝候选（request-cursor / pipe-hit / redirect 同拍取指 / FQ-01 / FQ-02 / FQ-03）
- [x] 跑 `scripts\run_coremark_profile.bat rv32` 并固化 profile 证据（作为 `FQ-04` 立项输入）
- [x] 设计并冻结 `FQ-04` 非重复单变量候选（已执行，结果为 `if_id` redirect-hit bubble bypass）
- [x] 执行 `FQ-04` quick screen（与 FQ-03 相同门禁，结果：guardrail 全绿但 short score 未提升）
- [x] 完成 `FQ-04` 保留决策：不保留（short score 仅到 `11014886 cycles`，已回退 RTL）
- [x] 切换到 `FQ-05`：基于 fresh profile / 复盘结果提出下一轮非重复单变量候选（P1/P2/P3）
- [x] 执行 `FQ-05A` quick screen（queue-consume/data-write 对齐，guardrail 全绿但 short score 无提升）
- [x] 完成 `FQ-05A` 保留决策：不保留（`11014885 cycles`，与冻结基线相同，已回退 RTL）
- [x] 执行 `FQ-05B` quick screen（redirect-reuse next-line prefetch，guardrail 全绿但 short score 无提升）
- [x] 完成 `FQ-05B` 保留决策：不保留（`11014885 cycles`，与冻结基线相同，已回退 RTL）
- [ ] 执行 `FQ-05C` quick screen（mem_wait 期间 IF/ID 预装载，单变量、非重复）
- [ ] 仅当 `FQ-05C` short score 提升时，补跑完整矩阵：RV32 / RV64 / strict CoreMark `>=10s` / `impl50`
- [ ] 若出现 retained 候选，补齐完整 fresh 回归矩阵并统一同步文档口径（README / handoff / todo / regression / performance）

## 仅外部阻塞

- [ ] 实体板卡到位后完成 UART/LED 实板闭环
- [ ] 板卡到位后补齐正式 I/O delay 约束与实板证据

## 下一轮性能优化入口

只有满足以下条件后，才允许进入下一轮性能优化：

1. 当前优化方案有明确的单变量边界。
2. 新基线已写入 `doc/performance_experiment_log.md`。
3. 每轮实验都承诺重跑 fresh 回归矩阵。
4. 工作区保持只有 intentional 内容或外部阻塞。

当前建议执行顺序：

1. 先执行 `FQ-03` 结果归档（已完成，结论：rejected）。
2. 进入 `FQ-04`：先跑 profile，再定候选，避免无证据重复试验。
3. `FQ-04` / `FQ-05A` / `FQ-05B` 已执行并拒绝保留（均无 short score 提升）。
4. 下一步进入 `FQ-05C`，仍坚持“short score 先过门，再扩完整矩阵”的门禁策略。

允许优先探索的方向：

- `fetch/request/queue` 解耦设计
- redirect/flush/drop accounting 定向验证
- 单变量 RTL 实验

禁止直接重开的方向：

- 没有新验证计划时重开 redirect `pipe-hit` RTL
- 继续拍脑袋放松 `stall_decode`
