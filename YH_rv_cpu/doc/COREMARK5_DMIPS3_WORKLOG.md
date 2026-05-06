# CoreMark 5+ / DMIPS 3+ Exploration Worklog

## 目标

- 冻结基线：`freeze/prelim-submit-20260506-2330`，提交点 `634c400`。
- 新优化分支：`opt/coremark5-dmips3-20260506`。
- CoreMark 目标：稳定复验 `CoreMark/MHz > 5.0`。
- Dhrystone 目标：稳定复验 `DMIPS/MHz > 3.0`，优先向 `3.0+` 推进。
- FPGA 约束：PYNQ-Z2，CPU `50 MHz`；LUT 可放宽到约 `6000`，但仍坚持低功耗、低面积、低复杂度导向。
- 工程要求：每个候选路径必须保留测试命令、日志、资源/时序数据和 git 节点，避免污染初赛冻结提交材料。

## 当前基线

| 项目 | 冻结提交路径 |
| --- | --- |
| Git tag | `freeze/prelim-submit-20260506-2330` |
| CoreMark/MHz | `4.137461` |
| DMIPS/MHz | `2.908287` |
| FPGA | PYNQ-Z2 `50 MHz` |
| 资源/时序 | `4934 LUT`，`WNS +0.440 ns`，`WHS +0.151 ns` |
| 特性 | `RV32I + Zmmul + Zba/Zbb/Zbs + JAL early redirect` |

## 已知高分候选

| 候选 | CoreMark/MHz | DMIPS/MHz | FPGA 记录 | 备注 |
| --- | ---: | ---: | --- | --- |
| `perf/coremark-over-1p5` 提交路径 | `5.162186` | `1.009846` 或文档另记 `2.986101` | `4634 LUT / WNS +0.608 ns` 或历史另记 `6147 LUT / WNS -0.801 ns` | 需要在新节点重新复验，消除旧文档口径差异 |

## 实验原则

1. 先迁移已经提交的高分 RTL/脚本变更，再进行本地复验。
2. 每次只改变一个主要变量：ISA 扩展、前端控制、Dhrystone 构建参数、TestBench 配置或 FPGA 约束。
3. CoreMark 与 DMIPS 均以脚本输出的 ticks、迭代数、CRC/校验和和解析脚本结果为准。
4. 超过目标后仍需跑语法、定向指令、性能基准、Vivado 实现和资源/时序核对，才允许冻结新节点。

## 实验记录

| 时间 | 实验 | 命令/配置 | 结果 | 结论 |
| --- | --- | --- | --- | --- |
| 2026-05-06 | 建立优化节点 | `opt/coremark5-dmips3-20260506` from `634c400` | 待测 | 作为 CoreMark 5+ / DMIPS 3+ 独立探索节点 |
