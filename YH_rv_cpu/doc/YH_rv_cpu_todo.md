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
- [x] 创建初赛提交材料目录并补齐提交清单、证据索引、答辩口径
- [x] 整理 `2026-04-09` 赛题答疑，并将初赛口径修正为“设计/技术文档为硬交付”

## 正在进行

- [x] 明确 `fence_i` 的处理策略：扩展 UI 覆盖矩阵采用 `zifencei` 并已通过；冻结比赛口径仍维持 `RV32I + Zicsr`
- [x] 重跑并归档 `rv32 full-ui`：`42/42`，归档=`YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt`
- [x] 重跑并归档 `rv64 full-ui`：`54/54`，归档=`YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt`
- [x] 重跑 fresh `rv32 baseline`：`33/33`，归档=`YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt`
- [x] 重跑 fresh `rv64 baseline`：`21/21`，归档=`YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt`
- [x] 补 fresh CoreMark smoke / short：`620530 cycles`，`0.912472 CoreMark/MHz`
- [x] 等待 fresh strict `>=10s` CoreMark 长跑完成并归档 dated summary/log
- [x] 对齐 README / 技术文档 / handoff / regression log / performance log / submission report
- [x] 做 focused git commit，只提交当前阶段直接相关成果
- [x] 冻结新的 post-closure 优化前基线
- [x] 启动 `FQ-06A` 单变量实验并完成 quick-screen
- [ ] 每轮优化继续同步 performance / regression / handoff / todo / 项目管理目录下的初赛提交材料

## 当前事实

- [x] `rv32im` CoreMark short has exceeded the long-term `>1.5` target:
  `2.365118 CoreMark/MHz`, `4269236 cycles`
- [x] `rv32im_o3unroll` is the current short best:
  `2.455226 CoreMark/MHz`, `4112023 cycles`
- [x] `rv32im_o3` was tested and rejected:
  `2.331563 CoreMark/MHz`, `4327580 cycles`
- [x] `rv32im_o3unroll` profile captured:
  `mem_wait=578409`, `stall_decode=204495`, `branch_redirect=149208`,
  `fetch_queue_empty=314532`
- [x] `mem_wait overlap fetch request` tried and rejected:
  directed `overlap_requests=1`, but short score stayed
  `2.455226 CoreMark/MHz` / `4112023 cycles`; RTL reverted
- [x] `scripts\run_m_extension_test.bat` currently returns PASS with `11/11`
- [x] Legacy `rv32i_zicsr` short score remains `0.925186` after adding the
  `rv32im` score path
- [x] `rv32 full-ui` 最新活跃结果是 `42/42`
- [x] `rv64 full-ui` 最新活跃结果是 `54/54`
- [x] `fence_i` 已在 `rv32i_zicsr_zifencei` 口径下通过
- [x] fresh baseline 已闭环到 `33/33` / `21/21`
- [x] fresh CoreMark smoke / short 已复现冻结短口径
- [x] fresh CoreMark strict 已完成 dated rerun：`0.912465 CoreMark/MHz`
- [x] 当前收口阶段已经结束，下一阶段转入 post-closure 优化
- [ ] `rv32im` strict `>=10s` long run is still pending because the faster
  score path requires more than the old `1000` iterations to satisfy the
  runtime floor
- [ ] Next CoreMark >5 direction must not repeat request-only memwait overlap;
  prioritize a larger measured bucket or a compiler/runtime path with direct
  instruction-count leverage

## 暂不推进

- [x] 暂不重启高侵入 `FQ-06`，直到扩展验证和文档闭环完成
- [ ] 暂不推进实板 bring-up，当前只保留 pre-board 冻结状态

## `FQ-06` 当前开工范围

- [x] 将 `2026-04-08` strict / full-ui / baseline fresh 结果作为新的优化前基线
- [x] 选定本轮唯一候选：`IMEM_OUTPUT_REG=0` 路径上的 bounded request cursor
- [x] 明确 `IMEM_OUTPUT_REG=1` 本轮只做 redirect/drop-accounting correctness guardrail
- [x] 先让更严格的 stall-prefetch 定向测试在 frozen baseline 上失败
- [x] 再改 `rtl/YH_rv_cpu.v` 并补齐 redirect/memwait 诊断
- [x] 通过 quick-screen 做出保留决策：`FQ-06A` 已拒绝保留并回退 RTL

## `FQ-06` 当前结论

- [x] `FQ-06A` 诊断全绿，但 short CoreMark 仍是 `11014885 / 0.912472`
- [x] 主线 RTL 已回退到冻结基线，不携带无收益 fetch 改动
- [x] 保留新的 `require_queue_fill` 诊断与 `run_fetch_prefetch_diag.bat` plusarg 归一化
- [x] fresh profile 已确认 `fetch_queue_empty_cycles` 与 `ex_fetch_redirect_valid_cycles` 完全重合，request-side 不是当前主矛盾
- [x] `2026-04-09` split profile 已确认 `branch redirect = 1235790`、`jal = 153354`、`jalr = 115826`、`reuse hit = 0`
- [x] `2026-04-11` branch-first `BEQ/BNE` pipe-hit 试验已让 `fetch_redirect_reuse_cycles` 变成 `305277`，但 `fetch_queue_empty_cycles` 仍是 `1504970`，short CoreMark 仍是 `11014885 / 0.912472`，因此已拒绝保留并回退 RTL
- [ ] 下一条非重复假设固定为 taken `BEQ/BNE` decode-stage early redirect，并要求带 operand-ready gating、完整 wrong-path flush 和单独 quick-screen retain/reject 判定

## 仅外部阻塞

- [ ] 实体板卡到位后完成 UART/LED 实板闭环
- [ ] 板卡到位后补齐正式 I/O delay 约束与实板证据

## 重新进入性能优化的门禁

只有满足以下条件后，才允许继续下一轮性能优化：

1. `fence_i` 口径已经写清楚
2. `rv32/rv64 full-ui` 已有 fresh 归档结果
3. fresh baseline 与 fresh CoreMark smoke/short/strict 已全部补齐
4. README / handoff / regression / performance / submission report 全部同步
5. 当前阶段成果已做 focused git commit
