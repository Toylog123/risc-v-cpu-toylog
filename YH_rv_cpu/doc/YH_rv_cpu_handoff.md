# YH_rv_cpu 交接说明

## 1. 项目是什么

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。核心目标不是做更多一次性实验，而是把工程维持在“可复现、可验证、可交接、可继续优化”的提交级状态。

当前主线 ISA 口径仍是：

- `RV32I + Zicsr`
- `RV64` baseline regression 作为共线验证

## 2. 当前做到哪一步

- 冻结基线仍然是 `2026-04-07` 的完整收口结果
- 当前工作区正在做 `2026-04-08` 的 `riscv-tests` 扩展验证与全文档同步
- 工作区不是 clean，存在未提交 RTL/脚本/manifest/linker 改动
- 当前最新 fresh 活跃证据是：
  - `build/tests/riscv-tests/rv32/summary.txt`
  - `rv32 full-ui = 41/42`
  - 当前唯一失败项：`fence_i`

当前冻结结果：

| 项目 | 结果 |
|------|------|
| CoreMark short score | `0.912472 CoreMark/MHz` |
| CoreMark short completion cycles | `11014885` |
| CoreMark strict score | `0.912465 CoreMark/MHz` |
| CoreMark strict completion cycles | `1095991523` |
| CoreMark strict runtime | `10.959325s` |
| CoreMark smoke | `620530 cycles` |
| RV32 baseline | `33/33` |
| RV64 baseline | `21/21` |
| impl50 | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP` |
| impl50 timing | `WNS = +5.599ns`，`WHS = +0.025ns` |
| FPGA-like probe | `156442 cycles`，`7.728811 CoreMark/MHz` |

## 3. 已完成的关键工作

- CoreMark short 与 strict `>=10s` 口径均已收口并形成正式文档
- 当前冻结 baseline 的 RV32 / RV64 / impl50 / FPGA-like probe 均有 fresh 可引用证据
- `timer_irq_smoke` 已修复并纳入基线
- Vivado `impl50` 默认 payload 已冻结为 `YH_rv_cpu_demo`
- `redirect/flush/drop-accounting` 双变体 strict 诊断已补齐
- 第一轮与第二轮单变量前端候选均已完成快速门禁并拒绝保留：
  - `request-cursor`
  - `pipe-hit`
  - `redirect 同拍取指`
  - `FQ-01`
  - `FQ-02`
  - `FQ-03`
  - `FQ-04`
  - `FQ-05A/B/C`
- 为扩大 `riscv-tests` 覆盖，当前工作区已补入：
  - full-ui manifest
  - large linker
  - custom `tohost_addr`
  - misaligned trap 软件补偿

## 4. 当前阻塞与风险

### 本机内待收口

- `fence_i` 的根因已经定位：不是跑得慢，也不是 trap 死循环，而是 `zifencei` ISA 口径问题
- 在 `fence_i` 的 ISA 边界没有明确前，不能声称 `rv32 full-ui` 全通过
- `rv64 full-ui`、fresh baseline 复跑、fresh CoreMark 复核仍待补齐

### 外部阻塞

- 缺实体板卡，无法完成 UART/LED 实板闭环
- 缺最终板级 I/O delay 约束，`XDC` 仍是 pre-board 版本

### 风险

- 如果把 `fence_i` 直接当作功能失败，会误判当前问题
- 如果跳过文档同步继续做高侵入优化，会让口径再次失真

## 5. 下一步最值得做的 5 项

1. 明确 `fence_i` 处理策略：纳入 `zifencei` 还是显式排除出当前普遍矩阵
2. 重跑并归档 `rv32 full-ui` 与 `rv64 full-ui`
3. 重跑 fresh `rv32 baseline` / `rv64 baseline`
4. 补 fresh CoreMark smoke / short，按预算决定 strict 是否重跑
5. 文档、summary、git commit 一起收口后，再决定是否启动 `FQ-06`

## 6. 关键文档与命令

关键文档：

- `README.md`
- `doc/技术文档.md`
- `doc/coremark_submission_report.md`
- `doc/performance_experiment_log.md`
- `doc/regression_test_log.md`
- `doc/fpga_bringup_checklist.md`
- `fpga/vivado/README.md`

关键命令：

```bat
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64
scripts\run_riscv_tests_subset.bat rv32 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv32_ui_all.txt - continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
scripts\run_riscv_tests_subset.bat rv64 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv64_ui_all.txt - continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
```

关键证据位置：

- CoreMark short summary: `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt`
- CoreMark strict summary: `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt`
- `rv32 full-ui` current summary: `build/tests/riscv-tests/rv32/summary.txt`
- FPGA reports: `project/reports/clk_20p000ns/`

## 7. 文档缺口与建议补齐项

- 文档已同步到“冻结基线 + 2026-04-08 活跃验证”双层口径
- 剩余缺口主要不是文档结构，而是 fresh 证据尚未完全补齐：
  - `rv64 full-ui`
  - fresh baseline rerun
  - fresh CoreMark rerun
- 待 `fence_i` 策略明确后，需要再做一次 focused docs commit，避免 README / handoff / regression / performance 出现二次漂移
