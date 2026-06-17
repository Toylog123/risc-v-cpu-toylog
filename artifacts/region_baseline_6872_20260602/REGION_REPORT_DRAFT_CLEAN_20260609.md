# 分赛区报告口径草稿 2026-06-09

## 当前推荐表述

本项目围绕 `YH_rv_cpu` 处理器开展严格 sync-BRAM 口径下的硬件优化。
优化过程不修改 CoreMark 核心算法文件，而是通过 RTL 微结构、前端控制、
缓存配置、时钟配置和 Vivado 实现流程进行调整。

当前可作为正式基线报告的是：

| 版本 | 定位 | LUT | CoreMark/MHz | DMIPS/MHz | 时钟 | 时序状态 |
|---|---|---:|---:|---:|---:|---|
| CPU25 baseline | 当前 accepted timing-closed baseline | 6791 post-route | 4.501191 | 1.205669 | 25 MHz | WNS +0.291 ns / WHS +0.065 ns |
| CPU25 RC128 BFNext/no-ZBKB | timing-closed successor candidate | 7473 post-route | 4.741458 | 1.205669 | 25 MHz | WNS +1.348 ns / WHS +0.041 ns |

当前没有可报告为正式基线的严格 50 MHz CoreMark-ROM timing-closed 版本。

## 已降级的历史成绩

| 历史记录 | 降级原因 | 允许使用方式 |
|---|---|---|
| 6872 LUT / 5.023480 CoreMark/MHz | PYNQ-Z2 full implementation 未闭合，WNS -10.360 ns | 只能作为 timing-failed low-resource engineering reference |
| 5918 LUT / 5.162186 CoreMark/MHz / WNS +0.358 ns | timing closure 来自 demo/default ROM，不是 exact CoreMark-ROM freeze build | 只能作为 historical demo-ROM timing evidence |
| 11182 LUT / 5.162186 CoreMark/MHz / 50 MHz | exact CoreMark-ROM implementation failed timing，WNS -5.800 ns | 只能作为 rejected strict 50 MHz audit evidence |
| 7216/7316/7164/7853 quick-synth rows | quick synth 或 implementation timing failed，不是 timing-closed exact board build | 只能作为探索记录 |
| 8983/9796 high-score references | 缺少当前口径下 accepted timing-closed implementation evidence | 只能作为历史高分探索记录 |

## 演示程序说明

为满足分赛区对实际程序演示的要求，项目新增自动 UART 性能演示程序。
该程序不依赖 UART RX 输入，适配当前 TX-only 演示路径，上电后自动运行并
打印每个 workload 的周期数、校验值和 PASS/FAIL 状态。

演示程序包含 5 类 workload：

| Workload | 作用 |
|---|---|
| CRC32 | 数据流和位运算压力 |
| MATMUL8 | 整数乘加计算压力 |
| MEMCPYFILL | RAM 读写和带宽路径 |
| BRANCH | 分支和控制流压力 |
| LOADUSE | 相关 load-use 和访存相关性压力 |

xsim 已验证最终输出：

```text
PERF_DEMO PASS checksum=0xe727358b total_cycles=0x00038add
```

该 demo 已嵌入 CPU25 PYNQ-Z2 bitstream，并完成 implementation timing 检查：

```text
6791 LUT / WNS +0.291 ns / WHS +0.065 ns
```

## 不应写入正式结论的内容

- 不应声称存在严格 50 MHz CoreMark-ROM timing-closed baseline。
- 不应声称 6872 LUT / 5.023480 CoreMark/MHz 是当前基线。
- 不应声称 6872 LUT 版本已经 timing-closed 或 board-proven。
- 不应声称 5918 LUT / WNS +0.358 ns 是严格 CoreMark-ROM 证据。
- 不应在 PROGRAM_OK、UART 抓取和视频证据完成前声称任一 demo 已经 board-proven。
- 不应把 CoreMark short-run 结果写成严格 10 秒 EEMBC 合规结果。

## 建议答辩口径

如果被问到为什么当前可报基线不是 50 MHz，可以回答：

“我们重新梳理后采用严格证据口径：只有 exact ROM 的 post-route timing-closed
implementation 才能作为基线。此前 6872 LUT 和 11182 LUT 的高分记录都没有在
PYNQ-Z2 完整实现后闭合 50 MHz 时序；5918 LUT 的闭合结果对应 demo/default
ROM，不是 exact CoreMark-ROM freeze build。因此当前正式基线采用
CPU25 timing-closed 版本：6791 LUT、4.501191 CoreMark/MHz、1.205669
DMIPS/MHz、WNS +0.291 ns。后续优化以 7473 LUT、4.741458 CoreMark/MHz、
WNS +1.348 ns 的 timing-closed candidate 为主要性能恢复方向，同时继续推进
50 MHz exact-ROM 时序优化。”
