# YH_rv_cpu 初赛提交材料

> 更新日期：2026-04-09

## 目录作用

本目录用于集中维护 `YH_rv_cpu` 的初赛提交口径，避免提交材料、主文档、回归证据和口头汇报再次出现口径漂移。

当前目录内文件分工如下：

- `初赛提交清单.md`：当前提交包应该包含什么、哪些已齐、哪些仍受外部阻塞
- `冻结基线与证据索引.md`：当前可对外引用的冻结结果与证据路径
- `答辩汇报口径.md`：适合汇报/PPT/答辩时直接复用的统一话术

## 当前结论

- 冻结比赛口径仍是 `RV32I + Zicsr`
- CoreMark short / strict、`rv32/rv64 baseline`、`impl50` 与 FPGA-like probe 均已完成 fresh 收口
- `2026-04-08` 额外完成 `rv32 full-ui 42/42` 与 `rv64 full-ui 54/54`
- `FQ-06A` 已完成 quick-screen 并拒绝保留，主线 RTL 仍是冻结基线
- 实板 bring-up 与最终板级 I/O delay 约束仍是外部阻塞

## 当前推荐引用入口

- 项目主入口：`../../YH_rv_cpu/README.md`
- CoreMark 正式口径：`../../YH_rv_cpu/doc/coremark_submission_report.md`
- 回归记录：`../../YH_rv_cpu/doc/regression_test_log.md`
- 性能实验记录：`../../YH_rv_cpu/doc/performance_experiment_log.md`
- 交接文档：`../../YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- 汇报摘要：`../汇报摘要.md`
- 项目进展汇报：`../项目进展汇报-2026-04-01.md`

## 使用规则

1. 任何新的 fresh 结果一旦决定保留，必须同时同步这里和主文档。
2. 任何仍处于实验态的结果，都不能直接升级成“冻结基线”。
3. 实板闭环、视频、最终压缩包格式等外部信息，待赛方要求明确后再补入本目录。
