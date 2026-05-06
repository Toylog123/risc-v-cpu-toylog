# YH_rv_cpu PYNQ-Z2 FPGA 原型系统证据包

更新时间：`2026-05-06`

## 目标板与实现口径

- 开发板：`Xilinx PYNQ-Z2`
- FPGA 器件：`xc7z020clg400-1`
- 输入时钟：PYNQ-Z2 板载 `125 MHz` PL 时钟
- CPU 时钟：MMCM 生成 `50.0 MHz`
- CPU 配置：`RV32I + Zmmul + Zba/Zbb/Zbs + JAL early redirect`
- 参数化探索路径：Zbc、XThead indexed memidx/condmov、IDBR 已保留 RTL/回归证据，但未进入本次 PYNQ-Z2 提交 bitstream
- 约束文件：`constraints/pynq_z2_template.xdc`

## 资源与时序

| 项目 | 结果 | 说明 |
|---|---:|---|
| Slice LUTs | `4961 / 53200 = 9.33%` | 满足初赛 `LUT < 5000` |
| Slice Registers | `2367 / 106400 = 2.22%` | 实现后资源报告 |
| Block RAM Tile | `6 / 140 = 4.29%` | 指令/数据存储，含 UART 上板复验所需片上 RAM |
| DSP | `15 / 220 = 6.82%` | Zmmul 乘法路径 |
| MMCM | `1 / 4 = 25.00%` | 125 MHz 到 50 MHz |
| Setup WNS | `+0.338 ns` | 时序满足 |
| Hold WHS | `+0.059 ns` | 时序满足 |

## 文件说明

| 文件/目录 | 内容 |
|---|---|
| `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit` | 当前提交 bitstream |
| `PYNQ-Z2_UART串口连接图_2026-05-06.jpg` | PYNQ-Z2 与 CP2102 的 PL UART 串口连接图 |
| `constraints/` | PYNQ-Z2 约束文件 |
| `reports/impl_utilization.rpt` | 实现后资源报告 |
| `reports/impl_timing_summary.rpt` | 实现后时序报告 |
| `reports/synth_utilization.rpt` | 综合后资源报告 |
| `reports/synth_timing_summary.rpt` | 综合后时序报告 |
| `logs/program_pynq_z2_bitstream.log` | 最终 bitstream 硬件下载日志，包含 `PROGRAM_OK` |
| `logs/pl_uart_capture_COM7_20260506_diag_metrics_verified.txt` | 最终 bitstream 下载后串口抓取日志，连续输出 `YH_rv_cpu CoreMark/MHz=4.137461 DMIPS/MHz=2.908287 tick=XX pc=XXXXXXXX` |
| `../CICC1003618_初赛_FPGA原型系统上板演示视频.mp4` | FPGA 原型系统上板演示视频，展示 Vivado 下载、PYNQ-Z2 连线和 UART 实时输出 |
| `BOARD_UART_RESULT_2026-05-06.md` | 上板 UART 复验记录 |

## 上板连接说明

PYNQ-Z2 的 Micro-USB 用于 JTAG 下载和器件识别。PL 软核 UART 通过 Pmod B 外接 3.3 V USB-UART 采集：

- `uart_rxd_out`：FPGA TX，`JB1 / Y14`，连接 CP2102 `RXD`
- `uart_txd_in`：FPGA RX，`JB0 / W14`，本次打印复验未使用
- GND：连接 CP2102 `GND`
- CP2102 `VCC` 不连接，避免反向供电
- 串口参数：`COM7`，`115200 8N1`，无校验，无流控

2026-05-06 的硬件日志显示 Vivado Hardware Manager 检出 `xc7z020_1` 并完成 bitstream 下载，日志包含 `PROGRAM_OK`。同次下载后的串口抓取日志显示 PL 侧 UART 诊断流连续输出 `YH_rv_cpu CoreMark/MHz=4.137461 DMIPS/MHz=2.908287 tick=XX pc=XXXXXXXX`，其中 `tick` 持续变化，`pc` 为 CPU 调试 PC 采样，可作为演示视频中的上板运行证据。
