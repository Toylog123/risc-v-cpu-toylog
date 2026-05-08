# YH_rv_cpu FPGA 应用演示 UART 说明

## 1. 本次用途

本文件用于功能演示视频录制。该 bitstream 在 PYNQ-Z2 上运行 YH_rv_cpu 软核，并由 CPU 软件程序通过 PL UART 输出应用级演示信息。演示内容包含排序、CRC/位运算混合、2x2 矩阵乘法、性能指标摘录和持续心跳输出。

## 2. bitstream 路径

Vivado 手动烧录时优先选择英文路径，避免中文路径导致 Vivado 兼容性问题：

```text
D:\BaiduSyncdisk\02_icdc_workspace\vivado_program\YH_rv_cpu_pynq_z2_fpga_app_demo_cpu50_20260507.bit
```

提交材料证据留档路径：

```text
D:\BaiduSyncdisk\02_icdc_workspace\01-项目管理\03-提交材料\FPGA原型系统\fpga_artifacts_pynq_z2\app_demo_20260507\YH_rv_cpu_pynq_z2_fpga_app_demo_cpu50_20260507.bit
```

## 3. 串口连接

- 板卡：Xilinx PYNQ-Z2
- 器件：xc7z020clg400-1
- UART：PL 软核 UART，Pmod B 输出
- 连接：CP2102 RXD 接 JB1/Y14，GND 接 Pmod B GND
- 注意：CP2102 的 VCC 不接板卡，板卡由 Micro-USB/JTAG 或独立电源供电
- 串口参数：COM7，115200，8N1

## 4. 视频录制操作

1. 打开 Vivado Hardware Manager，连接 PYNQ-Z2。
2. Program Device，选择 `vivado_program` 下的 app-demo bitstream。
3. 烧录完成后打开 PowerShell，进入源代码目录：

```powershell
Set-Location "D:\BaiduSyncdisk\02_icdc_workspace\01-项目管理\03-提交材料\源代码\CICC1003618_初赛_源代码"
```

4. 启动 UART 监听：

```powershell
.\scripts\watch_uart_live.bat
```

## 5. 预期 UART 输出

启动后应看到类似输出：

```text
YH_rv_cpu FPGA APP DEMO
Board=PYNQ-Z2 CPU=50MHz ISA=RV32I+Zmmul+Bitmanip
[1] Sort N=4 Sort PASS checksum=0x00004B39
[2] CRC CRC PASS crc=0x1D80A71E
[3] MatrixMul 2x2 MatrixMul PASS checksum=0x00000086
CoreMark/MHz=4.137461 DMIPS/MHz=2.908287
APP_DEMO_DONE
LIVE tick=00 app=running
LIVE tick=01 app=running
LIVE tick=02 app=running
```

录制时重点展示：

- `YH_rv_cpu FPGA APP DEMO`：证明输出来自本作品 CPU 应用演示固件；
- 三个 `PASS`：证明 CPU 在 FPGA 上运行实际应用程序并完成校验；
- `CoreMark/MHz` 与 `DMIPS/MHz`：与性能与验证报告指标对应；
- `LIVE tick=XX` 持续递增：证明串口输出为实时运行，不是静态截图。

## 6. 本次实现报告

- 固件目标：`scripts\build_firmware.bat fpga_app_demo`
- 仿真命令：`scripts\run_soc_fpga_app_demo.bat`
- Vivado 构建命令：`scripts\build_pynq_z2_fpga_app_demo.bat`
- FPGA 顶层诊断串口：关闭，`DEBUG_UART_DIAG_MODE=0`
- CPU 软件 UART：开启，由 SoC MMIO UART 输出
- CPU 频率：50.0 MHz
- 实现后资源：5191 LUT / 2380 FF / 8 BRAM / 15 DSP
- 实现后时序：WNS +0.307 ns / WHS +0.054 ns

本 app-demo bitstream 作为功能演示视频增强证据使用；初赛冻结提交指标仍以技术说明书、性能与验证报告和提交清单中记录的冻结版本为准。
