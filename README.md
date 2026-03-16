# 集创赛工作区

## 当前项目

这个仓库当前只服务一个正式项目：

- 赛题：七星微杯《基于 RISC-V 的高性能 CPU 设计及 FPGA 验证》
- 正式工程：`YH_rv_cpu`
- 当前目标：在 `2026-05-07` 初赛截止前，做出可提交、可复现、可上板展示的完整闭环版本

## 当前做到哪一步

已经完成：

- 锁定七星微为唯一主赛题
- 正式工程整体切换为 `YH_rv_cpu`
- 五级流水 `RV32I` 基线打通
- 关键数据通路 `XLEN` 参数化骨架
- 最小 SoC 打通
  - `ROM`
  - `RAM`
  - `UART`
  - `DONE`
  - `timer`
- 最小机器态 `CSR / trap` 打通
  - `mstatus`
  - `mie`
  - `mip`
  - `mtvec`
  - `mscratch`
  - `mepc`
  - `mcause`
  - `csrrw/csrrs/csrrc`
  - `ecall / ebreak / mret`
- machine timer interrupt 最小闭环打通
- `xsim` 下通过 3 条烟测
  - `SoC smoke`
  - `trap smoke`
  - `timer irq smoke`
- `xsim` 下通过 `xlen64 smoke`

当前还没完成：

- `RV64` 指令级扩展和更完整验证
- `riscv-tests`
- `CoreMark`
- 正式 `Vivado` 工程和 FPGA 上板闭环
- 两项性能优化的最终冻结

## 仓库结构

- `YH_rv_cpu/`
  - 正式比赛工程，包含 RTL、脚本、测试平台、固件和工程内技术文档
- `04-工具链/`
  - 队伍安装清单和工具链说明
- `01-项目管理/`
  - `01-赛题要求/`
  - `02-项目规划/`
  - `03-过程管理/`
  - `04-资料索引/`

以下目录保留在本地，但不纳入当前 Git 协作范围：

- `02-官方与规范/`
- `03-参考实现/`
- `05-验证测试/`

## 接手顺序

1. `01-项目管理/03-过程管理/工作交接.md`
2. `01-项目管理/03-过程管理/任务清单.md`
3. `01-项目管理/02-项目规划/项目总体规划.md`
4. `01-项目管理/01-赛题要求/七星微赛题要求.md`
5. `01-项目管理/01-赛题要求/七星微赛方答疑整理.md`
6. `04-工具链/YH_rv_cpu_toolchain/队伍安装清单.md`
7. `YH_rv_cpu/README.md`

## 默认协作范围

默认同步这三块：

- `YH_rv_cpu`
- `04-工具链`
- `01-项目管理`

默认暂存脚本：

```bat
YH_rv_cpu\scripts\stage_default_sync.bat
```

只看默认范围内变更：

```bat
YH_rv_cpu\scripts\stage_default_sync.bat --dry-run
```

## 当前最值得继续做的事

1. 在 `XLEN` 骨架和 `xlen64` 烟测基础上继续补 `RV64` 译码、访存和相关语义。
2. 接入 `riscv-tests`，建立第一版可回归验证。
3. 接入 `CoreMark`，形成可复现跑分链路。
4. 建正式 `Vivado` 工程，准备 FPGA 上板闭环。
