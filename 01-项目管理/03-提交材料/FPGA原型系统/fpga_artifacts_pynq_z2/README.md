# YH_rv_cpu PYNQ-Z2 FPGA 原型系统证据包

更新时间：`2026-04-30`

## 目标板与实现口径

- 开发板：`Xilinx PYNQ-Z2`
- FPGA 器件：`xc7z020clg400-1`
- 输入时钟：PYNQ-Z2 板载 `125 MHz` PL 时钟
- CPU 时钟：MMCM 生成 `50.0 MHz`
- CPU 配置：`RV32I + Zmmul + Zba/Zbb/Zbs + JAL early redirect`
- 参数化探索路径：Zbc、XThead indexed memidx/condmov、IDBR 已保留 RTL/回归证据，但未进入本次 PYNQ-Z2 冻结 bitstream
- 约束文件：`constraints/pynq_z2_template.xdc`

## 资源与时序

| 项目 | 结果 | 说明 |
|---|---|---|
| Slice LUTs | `4934 / 53200 = 9.27%` | 满足初赛 `LUT < 5000` |
| Slice Registers | `2327 / 106400 = 2.19%` | 实现后资源报告 |
| Block RAM Tile | `4 / 140 = 2.86%` | 指令/数据存储 |
| DSP | `15 / 220 = 6.82%` | Zmmul 乘法路径 |
| MMCM | `1 / 4 = 25.00%` | 125 MHz 到 50 MHz |
| Setup WNS | `+0.440 ns` | 时序满足 |
| Hold WHS | `+0.151 ns` | 时序满足 |

## 文件说明

| 文件/目录 | 内容 |
|---|---|
| `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_zmmul_bitmanip_noidbr_20260430.bit` | 当前正式 bitstream |
| `pynq_z2_hardware_connection_diagram.png` | PYNQ-Z2 硬件连接图 |
| `constraints/` | PYNQ-Z2 约束文件 |
| `reports/impl_utilization.rpt` | 实现后资源报告 |
| `reports/impl_timing_summary.rpt` | 实现后时序报告 |
| `reports/synth_utilization.rpt` | 综合后资源报告 |
| `reports/synth_timing_summary.rpt` | 综合后时序报告 |
| `logs/pynq_z2_hw_program_final_20260430_2355.log` | 硬件下载日志，包含 `PROGRAM_OK` |

## 上板连接说明

PYNQ-Z2 的 Micro-USB 用于 JTAG 下载和器件识别。软核 UART 通过 Pmod B 外接 3.3V USB-UART 采集：

- `uart_rxd_out`：FPGA TX，`JB1 / Y14`
- `uart_txd_in`：FPGA RX，`JB0 / W14`
- 电平：`3.3 V`
- GND：与外接 USB-UART 共地

2026-04-30 的硬件日志显示 Vivado Hardware Manager 检出 `xc7z020_1` 并完成 bitstream 下载，日志包含 `PROGRAM_OK`。PYNQ-Z2 的 Micro-USB 串口连接 PS 侧，不直接连接 PL 软核 UART；若需在演示视频中展示软核文本输出，需要按上述 Pmod B 连接外部 `3.3 V` USB-UART。
