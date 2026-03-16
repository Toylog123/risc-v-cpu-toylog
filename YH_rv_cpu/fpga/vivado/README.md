# FPGA 上板说明

这个目录现在承载 `YH_rv_cpu` 的 Vivado 工程脚手架，但真正生成出来的 Vivado 工程目录不放在这里。

## 当前结论

- 当前还没有实物板卡。
- 当前推荐的主申请板卡是 `Digilent Nexys A7-100T`。
- 当前仓库里已经补了：
  - 板级顶层 `src/YH_rv_cpu_fpga_top.v`
  - 串口发送模块 `src/YH_rv_uart_tx.v`
  - 约束模板 `constraints/nexys_a7_100_template.xdc`
  - Vivado 批处理脚本 `scripts/build_nexys_a7_100_project.tcl`
- Vivado 生成工程统一落到仓库根目录 `project/`
- `project/` 是本地目录，不进入 Git 同步范围
- 当前目标是先拿到综合和资源估算，再为后续实物上板做准备。

## 为什么优先用 `Nexys A7-100T`

- 当前项目主线不需要 PS 侧 ARM 和 DDR。
- 纯 `Artix-7` 路线更贴合当前自写 RISC-V CPU + 最小 SoC 的工作方式。
- Digilent 有公开的参考手册和 Master XDC，后续冻结约束更容易。

## 当前目录结构

- `src/`
  - 板级顶层和串口发送模块
- `constraints/`
  - 约束模板和后续正式 XDC 的入口
- `scripts/`
  - Vivado 工程和综合脚本

## 当前使用方法

在仓库根目录执行：

```bat
YH_rv_cpu\scripts\build_vivado_project.bat project
YH_rv_cpu\scripts\build_vivado_project.bat synth
```

说明：

- `project`：在根目录 `project/` 生成工程骨架，方便后续在 GUI 中继续操作
- `synth`：先跑综合，拿资源和时序估算
- 现在没有实物板卡，所以还不建议把“生成最终 bitstream”当成本阶段目标

## 正式上板前还缺什么

- 老师确认并下发板卡
- 基于实物板卡冻结正式 `XDC`
- 确认串口和复位引脚
- 跑一次完整 bitstream 流程
- 固化板级演示脚本和日志
