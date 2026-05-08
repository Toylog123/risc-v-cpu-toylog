# CICC1003618 初赛 FPGA 原型系统上板演示视频说明

视频文件：

`CICC1003618_初赛_FPGA原型系统上板演示视频.mp4`

## 视频定位

该视频作为 FPGA 原型系统证据材料，用于展示 PYNQ-Z2 上板过程和实时运行证据。它不是完整作品讲解视频；作品讲解视频单独放在 `../功能演示视频/` 目录中。

## 覆盖内容

| 内容 | 说明 |
|---|---|
| Vivado 下载 | 展示 Hardware Manager 识别 `xc7z020_1` 并完成 bitstream 下载 |
| 板卡与接线 | 展示 PYNQ-Z2、CP2102 USB-UART、Pmod B 接线 |
| 串口实时输出 | 展示 `COM7 115200 8N1` 下连续输出 `YH_rv_cpu CoreMark/MHz=4.137461 DMIPS/MHz=2.908287 tick=XX pc=XXXXXXXX` |
| 性能与上板证据 | 证明 FPGA 原型系统下载后持续运行，`tick` 连续变化，`pc` 为 CPU 调试 PC 采样 |

## 关联材料

- bitstream：`fpga_artifacts_pynq_z2/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit`
- 连接图：`fpga_artifacts_pynq_z2/PYNQ-Z2_UART串口连接图_2026-05-06.jpg`
- 上板复验记录：`fpga_artifacts_pynq_z2/BOARD_UART_RESULT_2026-05-06.md`
- UART 日志：`fpga_artifacts_pynq_z2/logs/pl_uart_capture_COM7_20260506_diag_metrics_verified.txt`
