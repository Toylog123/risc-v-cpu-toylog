# PYNQ-Z2 PL UART 上板复验记录

复验日期：`2026-05-06`

## 硬件连接

- 开发板：`Xilinx PYNQ-Z2`
- 下载链路：PYNQ-Z2 Micro-USB / Vivado Hardware Manager
- PL 侧 UART：外接 CP2102 USB-UART，`3.3 V` 电平
- 接线：CP2102 `RXD -> Pmod B JB1 / Y14`，CP2102 `GND -> Pmod B GND`，CP2102 `VCC` 不连接
- 串口参数：`COM7`，`115200 8N1`，无校验，无流控

## 最终复验结果

| 项目 | 结果 |
|---|---|
| bitstream | `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit` |
| Vivado 下载 | `PROGRAM_OK: xc7z020_1` |
| 串口日志 | `logs/pl_uart_capture_COM7_20260506_diag_metrics_verified.txt` |
| 输出内容 | `YH_rv_cpu CoreMark/MHz=4.137461 DMIPS/MHz=2.908287 tick=XX pc=XXXXXXXX` |
| 抓取统计 | 20 秒抓取 `188` 行，`188` 个不同 `tick`，`5` 个不同 PC 采样值 |
| 实现资源 | `4961 LUT / 2367 FF / 6 BRAM / 15 DSP` |
| 实现时序 | `WNS +0.338 ns / WHS +0.059 ns` |

该 UART 输出为 PL 侧板级诊断流，用于演示 bitstream 下载后 FPGA 原型系统持续运行、性能摘要口径和 CPU 调试 PC 采样状态。`CoreMark/MHz` 与 `DMIPS/MHz` 为性能与验证报告采用的冻结指标，`tick` 为板级实时计数，`pc` 为 CPU 调试 PC 采样。

## 录制口径

视频中建议同时展示 Vivado Hardware Manager 下载成功界面、PYNQ-Z2 板卡连线、CP2102 接线和 PowerShell 串口终端输出。串口终端使用：

```powershell
Set-Location "D:\BaiduSyncdisk\02_icdc_workspace\01-项目管理\03-提交材料\源代码\CICC1003618_初赛_源代码"
.\scripts\watch_uart_live.bat
```
