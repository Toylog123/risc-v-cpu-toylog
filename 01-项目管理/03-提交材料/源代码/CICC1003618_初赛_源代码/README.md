# CICC1003618_初赛_源代码

本目录为第十届全国大学生集成电路创新创业大赛初赛“技术数据（代码类）”提交内容，包含 YH_rv_cpu 处理器设计、验证程序、基准测试程序以及 FPGA 原型实现所需的主要源码与脚本。

## 目录说明

- `rtl/`：CPU、SoC、存储与缓存等 RTL 设计代码
- `tb/`：功能回归、性能测试、定向诊断 TestBench
- `sw/`：RISC-V 测试程序、CoreMark/Dhrystone 适配程序、示例应用与链接脚本
- `fpga/`：PYNQ-Z2 适配工程、约束文件、Vivado TCL 脚本与顶层封装
- `scripts/`：构建、仿真、性能测试、Vivado 构建与结果整理脚本
- `运行环境说明.md`：软硬件环境说明与基本复现入口

## 代码内容说明

- 处理器实现：五级流水 RV32 处理器，支持整数指令、乘法相关扩展和位操作扩展
- 验证内容：包含功能回归、基准程序、定向诊断和 SoC 烟雾测试
- FPGA 原型：提供 PYNQ-Z2 顶层、约束文件、构建脚本和板级验证入口

## 复现入口

1. 功能回归与定向测试：`scripts/` 下各类 `run_*.bat`
2. CoreMark：`scripts/run_coremark_score.bat`
3. Dhrystone：`scripts/run_dhrystone_score.bat`
4. PYNQ-Z2 工程生成与实现：`scripts/build_pynq_z2_project.bat`

## 板级串口说明

PYNQ-Z2 板载 Micro-USB 主要用于 JTAG 下载与 PS 侧串口识别。PL 侧软核 UART 通过 Pmod B 引出，如需采集软核输出信息，应外接 `3.3 V` USB-UART 模块：

- FPGA TX：`uart_rxd_out`，`JB1 / Y14`，连接外部 USB-UART 适配器 `RX`
- FPGA RX：`uart_txd_in`，`JB0 / W14`，可选连接外部 USB-UART 适配器 `TX`
- GND：外部 USB-UART 与 PYNQ-Z2 共地

串口采集命令：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\capture_uart.ps1 -List
powershell -ExecutionPolicy Bypass -File .\scripts\capture_uart.ps1 -Port COMx -Seconds 20
```

示例固件会通过 MMIO UART 输出 `YH_rv_cpu boot`，可用于板级功能演示。

## 主要结果

- CoreMark：`4.137461 CoreMark/MHz`
- Dhrystone：`2.908287 DMIPS/MHz`
- FPGA 实现资源：`4934 LUT / 2327 FF / 4 BRAM / 15 DSP`
- 板级实现频率：`50.0 MHz`

## 说明

本目录仅保留与设计复现、验证和 FPGA 原型实现直接相关的代码、脚本与说明文件。详细的性能结果、验证数据和提交文档请参见提交材料目录中的对应文件。
