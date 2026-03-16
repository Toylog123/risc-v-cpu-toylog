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
- `scripts/build_vivado_project.bat` 现在会自动临时映射 ASCII 盘符，规避中文路径导致的 Vivado 退出问题。
- 如果本地已存在 `build/tests/riscv-tests/rv32/simple.hex`，综合脚本会自动把它挂到 `ROM_INIT_HEX`，并用 `8KB/8KB` 的 `ROM/RAM` 做本地资源估算。

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
YH_rv_cpu\scripts\clean_vivado_project.bat
```

说明：

- `project`：在根目录 `project/` 生成工程骨架，方便后续在 GUI 中继续操作
- `synth`：先跑综合，拿资源和时序估算
- `clean_vivado_project.bat`：清掉 `project/` 下的 Vivado 临时目录和历史备份，只保留报告、检查点和最新日志
- 现在没有实物板卡，所以还不建议把“生成最终 bitstream”当成本阶段目标

## 当前综合结果

- 当前本地综合目标器件：`xc7a100tcsg324-1`
- 当前资源估算口径：`ROM=8KB`、`RAM=8KB`、`ROM_INIT_HEX=simple.hex`
- 当前综合结果：
  - `Slice LUTs = 3445`
  - `Slice Registers = 1962`
  - `LUT as Memory = 1024`
  - `BRAM = 0`
  - `DSP = 0`
- 当前时序结果：
  - `sys_clk = 100MHz`
  - `WNS = -2.405ns`
  - 当前 100MHz 还未收敛，但赛题要求的 `50MHz` 目标仍有较大空间
- 当前还存在的板级约束问题：
  - `no_input_delay(1)`
  - `no_output_delay(4)`
  - 正式板卡到位后要用正式 `XDC` 补齐

## 正式上板前还缺什么

- 老师确认并下发板卡
- 基于实物板卡冻结正式 `XDC`
- 确认串口和复位引脚
- 跑一次完整 bitstream 流程
- 固化板级演示脚本和日志
