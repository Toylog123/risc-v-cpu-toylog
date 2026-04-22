# FPGA 产物说明

更新时间：`2026-04-18`

本目录用于集中收纳当前可直接提交或复核的 FPGA 相关产物，避免后续再从工程内部路径手工翻找。

## 当前文件

- `YH_rv_cpu_nexys_a7_100_20p000.bit`
- `impl_timing_summary.rpt`
- `impl_utilization.rpt`
- `synth_timing_summary.rpt`
- `synth_utilization.rpt`

## 当前口径

- 目标板卡：`Nexys A7-100T`
- 目标流程：`Vivado impl50`
- 当前结论性质：`pre-board closure`

## 说明

- 这些文件用于支撑当前 `50MHz` 路径下的 bitstream、资源占用和时序结果。
- 目录中的内容来自工程主路径 `project/` 下的最新可引用实现产物。
- 本目录不代表实体板已完成最终连线、调试日志与长期稳定运行闭环；这些内容仍属于后续待补齐项。
