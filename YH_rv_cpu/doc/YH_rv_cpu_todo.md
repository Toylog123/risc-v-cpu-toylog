# YH_rv_cpu 当前任务表

## 已完成

- [x] 冻结 CoreMark short 正式口径
- [x] 冻结 strict EEMBC `>=10s` CoreMark 长跑口径
- [x] 冻结 RV32 baseline `33/33`
- [x] 冻结 RV64 baseline `21/21`
- [x] 冻结 FPGA `impl50` fresh 资源/时序/bitstream 口径
- [x] 冻结 FPGA-like CoreMark probe 入口与结果
- [x] 收口 FPGA pre-board SOP、串口口径、evidence 路径和 demo payload staging
- [x] 明确保留优化：
  - `stall_decode = load_use_hazard`
  - `IMEM_OUTPUT_REG=0`
  - `DMEM_OUTPUT_REG=0`
- [x] 明确关闭“简单放松 `stall_decode` 继续优化 fetch”的方向
- [x] 完成 `request-cursor / pipe-hit / redirect 同拍取指 / FQ-01 ~ FQ-05` 单变量试验并拒绝保留
- [x] 修复 `timer_irq_smoke` 回归
- [x] 为普遍 `riscv-tests` 扩展验证补入：
  - full-ui manifest
  - large linker
  - custom `tohost_addr`
  - misaligned trap 软件补偿
- [x] 用 fresh `rv32 full-ui` 证明 `ma_data` 已通过，不再是 trap 回到 `0x0` 的旧问题

## 正在进行

- [ ] 明确 `fence_i` 的处理策略：
  - 选项 A：把 `zifencei` 纳入当前矩阵并重跑
  - 选项 B：保持 `RV32I + Zicsr` 口径，并明确把 `fence_i` 标为超出口径项
- [ ] 重跑并归档 `rv32 full-ui`
- [ ] 重跑并归档 `rv64 full-ui`
- [ ] 重跑 fresh `rv32 baseline`
- [ ] 重跑 fresh `rv64 baseline`
- [ ] 补 fresh CoreMark smoke / short
- [ ] 视本机预算决定是否补 fresh strict `>=10s` CoreMark
- [ ] 对齐 README / 技术文档 / handoff / regression log / performance log / submission report
- [ ] 做 focused git commit，只提交当前阶段直接相关成果

## 当前事实

- [x] `rv32 full-ui` 最新活跃结果是 `41/42`
- [x] 当前唯一失败项是 `fence_i`
- [x] `fence_i` 当前根因是 `-march=rv32i_zicsr` 不包含 `zifencei`
- [x] 当前问题不是“跑得慢”，而是 ISA/march 口径问题

## 暂不推进

- [ ] 暂不重启高侵入 `FQ-06`，直到扩展验证和文档闭环完成
- [ ] 暂不推进实板 bring-up，当前只保留 pre-board 冻结状态

## 仅外部阻塞

- [ ] 实体板卡到位后完成 UART/LED 实板闭环
- [ ] 板卡到位后补齐正式 I/O delay 约束与实板证据

## 重新进入性能优化的门禁

只有满足以下条件后，才允许继续下一轮性能优化：

1. `fence_i` 口径已经写清楚
2. `rv32/rv64 full-ui` 已有 fresh 归档结果
3. fresh baseline 与 fresh CoreMark 已补齐到可接受程度
4. README / handoff / regression / performance / submission report 全部同步
5. 当前阶段成果已做 focused git commit
