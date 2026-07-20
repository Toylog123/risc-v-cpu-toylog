# strict50 上板与应用演示补证 runbook 2026-07-02

本文档用于后续把 `impl220` 从 implementation-evidence candidate 推进到 board evidence complete。当前不要在任何材料中提前写 board-proven。

## 前置身份

| 项目 | 值 |
|---|---|
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Freeze tag | `freeze-strict50-impl220-20260701` |
| CPU clock | 50 MHz |
| Timing | WNS +0.056 ns / WHS +0.121 ns |
| CoreMark/MHz | 4.287521 |
| DMIPS/MHz | 2.495618 xsim，同配置 `timer50` Dhrystone evidence |
| Bitstream | `board_impl220_bitstream_20260702/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit` |
| Bitstream SHA256 | `13DD28472DBEF194E57B9C4D217CD5E886F34234CE17746E4F47854401AE6DBD` |
| Board | PYNQ-Z2 |
| Evidence template | `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` |

## 执行原则

1. bitstream、timing report、UART log、视频必须绑定同一配置。
2. 不要用旧 CPU25 bitstream 或旧 board-proven 口径覆盖 `impl220`。
3. CoreMark 核心算法文件不能修改。
4. 当前只完成 Vivado bitstream 生成，仍不能称 board-proven。
5. 如果 UART 跑的是应用 demo，不要把它写成 CoreMark 官方结果。

## Step 1: bitstream 身份确认

当前状态：已完成。

| 文件 | 状态 |
|---|---|
| `.bit` | `board_impl220_bitstream_20260702/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit` |
| bitstream SHA256 | `13DD28472DBEF194E57B9C4D217CD5E886F34234CE17746E4F47854401AE6DBD` |
| Vivado bitstream log | `board_impl220_bitstream_20260702/vivado_write_bitstream_from_impl220.log` |
| bitstream manifest | `board_impl220_bitstream_20260702/bitstream_manifest.md` |
| `.ltx` optional | pending |

上板时必须使用上表中的 `.bit`，并在 `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` 中填写同一 SHA256。

## Step 2: PROGRAM_OK 证据

目标：使用 Vivado Hardware Manager 下载同一个 `.bit` 到 PYNQ-Z2，并记录 PROGRAM_OK。

建议证据：

| 证据 | 要求 |
|---|---|
| Hardware Manager log | 能看到 `program_hw_devices` 成功 |
| 截图 | 能看到目标 board/device 和 program 完成状态 |
| 照片 optional | 板卡连接状态 |

## Step 3: UART raw log

目标：捕获原始串口输出，输出中应能识别 workload、PASS/CRC 或性能 marker。

建议保存：

| 文件 | 内容 |
|---|---|
| `uart_coremark_impl220_YYYYMMDD.log` | CoreMark 或 benchmark 输出 |
| `uart_demo_impl220_YYYYMMDD.log` | 应用 demo 输出 |
| `uart_dhrystone_impl220_YYYYMMDD.log` | Dhrystone 输出，如已补跑 |

注意：

- 如果当前 ROM 不是 CoreMark，不要把 UART log 写成 CoreMark 证据。
- 当前 DMIPS/MHz 是 xsim host-parsed 证据；板级 DMIPS 需要另补 UART raw log。

## Step 4: 应用演示程序

赛题需要相关程序体现性能。当前 strict50 perf demo 已有 xsim 证据，后续上板建议沿用同一 demo 或明确记录新 ROM 身份。

| Demo | 目的 | 证据 |
|---|---|---|
| CoreMark | 标准 CPU benchmark 跑通 | score/CRC/PASS log |
| Dhrystone | DMIPS/MHz 补证 | runs、DMIPS summary |
| strict50 perf demo | 展示 CRC32、MATMUL8、MEMCPYFILL、BRANCH、LOADUSE | `PERF_DEMO PASS`、checksum、UART raw log |

应用 demo 的最低要求：源码归档、编译命令或 ROM 生成脚本归档、UART raw log 归档、视频能看到运行输出。

## Step 5: 视频证据

视频建议包含：

- PYNQ-Z2 实物和连接。
- Vivado program 或已完成 program 的上下文。
- 串口终端输出。
- benchmark/demo PASS 或关键结果。

视频文件命名建议：

`strict50_impl220_pynqz2_uart_demo_YYYYMMDD.mp4`

## Step 6: 证据归档

建议新增目录：

`artifacts/strict_50m_timing_opt_20260609/board_impl220_YYYYMMDD/`

建议内容：

| 文件 | 内容 |
|---|---|
| `README.md` | 本次上板证据索引 |
| `SHA256SUMS.txt` | bitstream、log、视频 checksum |
| `program_hw.log` | PROGRAM_OK log |
| `uart_*.log` | 原始 UART 输出 |
| `video_manifest.md` | 视频文件路径、时长、内容说明 |
| `bitstream_manifest.md` | bitstream 身份、来源、SHA256 |

## 完成后允许口径

只有当 bitstream、PROGRAM_OK、UART 和视频都补齐后，才允许写：

`impl220 strict 50 MHz bitstream has board evidence on PYNQ-Z2, with PROGRAM_OK and UART output archived.`

如果 PROGRAM_OK、UART 或视频任一项未完成，只能写：

`impl220 is a strict 50 MHz post-route timing-closed engineering candidate; board evidence is pending.`
