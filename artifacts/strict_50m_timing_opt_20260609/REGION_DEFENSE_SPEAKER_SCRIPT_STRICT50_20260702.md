# 分赛区答辩讲稿 strict50 2026-07-02

本文用于现场口播。所有表述只适用于当前 `impl220` strict 50 MHz
post-route 工程候选，不声明板级证据已经完成。

## 3 分钟主讲稿

各位老师好，我们的项目是在 PYNQ-Z2 FPGA 平台上实现一款自研 RV32 五级流水
RISC-V CPU。设计采用 IF、ID、EX、MEM、WB 五级流水结构，包含 forwarding、
load-use 处理、分支重定向、BHT、redirect-cache 以及 DCache/BRAM 访问控制。

本轮分赛区材料的核心结果是当前冻结的 strict 50 MHz 工程候选：
`impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`。
该版本在 PYNQ-Z2 post-route implementation 下达到 9965 LUT、6520 FF、
32 BRAM Tile、8 DSP，CoreMark/MHz 为 4.287521。在 50 MHz 时钟约束下，
Vivado timing report 给出的 WNS 为 +0.056 ns，WHS 为 +0.121 ns。

这里我们特别强调 strict sync-BRAM 口径。FPGA BRAM 是同步读资源，如果在仿真中
忽略存储延迟，可能得到更高分数，但这些分数无法直接对应真实 FPGA 实现。
因此当前报告只采用能和 post-route timing 对齐的 strict 结果，不把 fast-only、
synthesis timing-failed 或 demo-ROM 结果作为当前候选。

本设计的主要时序挑战来自 MEM/DCache/load-use/redirect-cache/front-end control
对 PC 或 IF/ID 控制的同周期组合扇入。高分探索配置往往会把 DCache 或 redirect-cache
信息直接用于前端选择，造成长组合路径。我们的优化方向不是修改 benchmark 软件，
而是通过 RTL 参数和实现流程缩短硬件关键路径。

具体来说，当前候选采用了几个关键取舍。第一，通过 `ENABLE_BRANCH_BHT_ID_UPDATE`
控制 BHT ID 阶段更新路径，把原来的 BHT CE 热点变成可审计的配置项。第二，对
redirect-cache、fold 和 next-cache 相关同周期路径进行取舍，避免高分配置重新引入
长组合路径。第三，围绕 DCache/load-use 控制削减 MEM 状态到前端控制的组合扇入。
第四，在 Vivado 实现阶段采用 ExploreArea 与 AdvancedSkewModeling 的组合，使当前
版本在保持 4.287521 CoreMark/MHz 的同时实现 50 MHz timing closure。

合规边界方面，我们没有修改 CoreMark 核心算法文件，包括 `core_list_join.c`、
`core_matrix.c`、`core_state.c`、`core_util.c` 和 `core_main.c`。当前 CoreMark 是工程
short-gate 结果，不表述为官方 EEMBC 10 秒合规结果。当前 `impl220` 同配置
Dhrystone xsim 已补齐，结果为 2.495618 DMIPS/MHz；bitstream 与 SHA256 已归档；但 PROGRAM_OK、
UART 和视频证据还需要补齐，因此我们现在把它
严格表述为 post-route timing-closed engineering candidate，而不是 board-proven result。

后续工作会围绕同一配置补齐板级证据：使用已归档的 `impl220` bitstream 和 SHA256，
完成 PYNQ-Z2 PROGRAM_OK，抓取 UART raw log，录制上板视频；如需要板级 DMIPS，
再用同一 bitstream 补充 Dhrystone UART raw log。
完成这些证据后，报告、PPT、bitstream、UART 和视频将绑定到同一个 frozen candidate。

## 1 分钟压缩版

我们的设计是面向 PYNQ-Z2 的自研 RV32 五级流水 RISC-V CPU。当前 strict 50 MHz
工程候选为 `impl220`，在 post-route implementation 下达到 9965 LUT、
4.287521 CoreMark/MHz、WNS +0.056 ns、WHS +0.121 ns。

优化重点不是修改 CoreMark，而是缩短硬件关键路径。我们坚持 sync-BRAM 真实口径，
围绕 BHT 更新、redirect/fold、DCache/load-use 以及 Vivado implementation directive
做时序收敛。高分但 timing-failed 的探索结果只作为审计记录，不作为当前候选。

当前边界是：CoreMark 核心算法文件未修改；CoreMark 是工程 short-gate，不称官方
EEMBC 10 秒；`impl220` DMIPS 已有同配置 xsim 证据，但 board evidence 仍待补。
因此当前可报告结论是：
`impl220` 是 strict 50 MHz post-route timing-closed engineering candidate。

## 高频快答

| 问题 | 现场回答 |
|---|---|
| 现在主指标是多少？ | 9965 LUT / 4.287521 CoreMark/MHz / 50 MHz / WNS +0.056 ns / WHS +0.121 ns。 |
| CoreMark 源码改了吗？ | 没有修改核心算法文件，优化集中在 RTL、参数配置和 Vivado 实现流程。 |
| 是否已经 board-proven？ | 还不能这么说。当前是 post-route timing-closed，bitstream/SHA256 已归档，但 PROGRAM_OK、UART 和视频待补。 |
| DMIPS 是多少？ | `impl220` 同配置 Dhrystone xsim 为 2.495618 DMIPS/MHz；板级 DMIPS 需另补 UART raw log。 |
| 为什么不用更高 CoreMark 分数？ | 更高 fast score 对应配置没有闭合 strict 50 MHz timing，不能代表 FPGA 原型系统候选。 |
| strict sync-BRAM 为什么重要？ | 它把 BRAM 真实读延迟纳入设计和 timing，避免仿真高分无法对应 FPGA 实现。 |
| 当前最大风险是什么？ | 板级证据未补齐，DMIPS 目前是 xsim 证据，材料中已明确边界。 |

## 禁止现场说法

| 禁止说法 | 原因 |
|---|---|
| `impl220` 已经上板验证通过 | 尚无 PROGRAM_OK、UART、视频证据 |
| 当前 DMIPS/MHz 是板级结果 | 目前只有同配置 xsim 证据，尚无板级 UART raw log |
| CoreMark 是官方 EEMBC 10 秒认证 | 当前只是工程 short-gate |
| `fast201` 4.569338 是当前候选 | 对应 `synth224` timing failed |
| 旧 `4961 LUT / 4.137461 / board-proven` 是当前 strict50 结果 | 那是旧初赛口径，不是 `impl220` |
