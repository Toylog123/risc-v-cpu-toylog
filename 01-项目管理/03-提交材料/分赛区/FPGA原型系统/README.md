# FPGA 原型系统证据说明

本目录当前只放置 strict50 `impl220` 的 bitstream 生成证据和 SHA256。

## 当前状态

- `strict50_impl220_bitstream/`：已归档 bitstream、bitstream 生成日志、timing/utilization 报告和 SHA256。
- PROGRAM_OK、board UART raw log、board video：待补。
- 旧初赛 PYNQ-Z2 上板证据不再放在分赛区当前主证据目录中；如需查阅，请回到 `../初赛/FPGA原型系统/`。

## 边界

bitstream 生成成功不等同于板级 PROGRAM_OK。补齐 PROGRAM_OK、UART raw log 和视频前，不应把 `impl220` 写成 board-proven。
