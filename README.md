# icdc_workspace

本 worktree 围绕第十届集创赛“七星微”企业命题的 `YH_rv_cpu` 初赛材料、PYNQ-Z2 原型和 CoreMark 优化展开。

## 当前推荐入口

- 正式工程入口：`YH_rv_cpu/README.md`
- 当前状态：`YH_rv_cpu/doc/CURRENT_STATUS.md`
- 技术交接：`YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- 后续任务：`YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- 性能实验：`YH_rv_cpu/doc/performance_experiment_log.md`
- 回归记录：`YH_rv_cpu/doc/regression_test_log.md`
- 赛题要求：`../../01-项目管理/01-赛题要求/`
- 初赛提交材料：`../../01-项目管理/03-提交材料/`

## 当前正式口径

- CoreMark/MHz：`5.162186`
- CPU/ISA：`RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect`
- PYNQ-Z2：`50.0 MHz`
- FPGA 资源：`4634 LUT / 2317 FF / 4 BRAM / 15 DSP`
- 时序：`WNS=+0.608 ns`，`WHS=+0.121 ns`
- Dhrystone：`177430 Dhrystones/s`，`1.009846 DMIPS/MHz`
- 上板：`PROGRAM_OK: xc7z020_1`

这一版满足当前初赛硬约束：`LUT < 5000`、PYNQ-Z2 50MHz 实现收敛、CoreMark CRC 正确、bitstream 已通过 Vivado Hardware Manager 下载验证。

## 工作区边界

本 worktree 只保留工程与最小状态文档。正式提交材料位于主工作区：

```text
../../01-项目管理/03-提交材料/
```

后续新增材料时，项目管理、提交清单、PPT、PDF、源码包和 FPGA 附件都应优先放在主工作区提交目录，不在 `.worktrees` 内重复维护。
