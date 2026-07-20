# 分赛区报告可用段落：严格 50 MHz 工程候选

更新时间：2026-07-01

## 当前结果表述

在不修改 CoreMark 核心算法文件的前提下，项目完成了一版 PYNQ-Z2
严格 50 MHz post-route timing-closed 工程候选。当前可报告的实现指标为：

| 指标 | 数值 |
|---|---:|
| 候选版本 | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Slice LUT | 9965 |
| Slice FF | 6520 |
| CoreMark/MHz | 4.287521 |
| CPU 时钟 | 50 MHz |
| post-route WNS | +0.056 ns |
| post-route WHS | +0.121 ns |
| Dhrystone/DMIPS | 2.495618 DMIPS/MHz xsim |
| 板级证据 | 待补 PROGRAM_OK、UART 和视频 |

建议报告表述：

“本设计当前严格 50 MHz 工程候选在 PYNQ-Z2 post-route implementation 下达到
9965 LUT、4.287521 CoreMark/MHz、WNS +0.056 ns、WHS +0.121 ns。该结果来自
硬件 RTL、参数配置和 Vivado 实现流程优化，CoreMark 核心算法源文件未修改。
同配置 Dhrystone xsim 为 2.495618 DMIPS/MHz。当前证据等级为
implementation timing-closed + xsim benchmark evidence，后续还需补齐上板 PROGRAM_OK、
UART 输出和视频证据。”

## 设计亮点

1. 严格 sync-BRAM 口径的可复现优化

   设计坚持同步 BRAM 访问时序，不使用忽略存储延迟的非真实模型。优化工作围绕
   RTL 控制路径、分支预测路径、redirect-cache 路径和 Vivado 实现策略展开，使结果
   能对应 FPGA 原型系统的真实 post-route timing。

2. 前端重定向与分支预测路径可配置

   处理器前端包含 redirect target cache、分支 BHT、分支 fold/next-cache 等可配置
   控制路径。当前版本通过参数化方式保留探索空间，同时将容易造成同周期长组合路径的
   更新点拆成可控开关，便于在性能、面积和时序之间做严格 A/B 对比。

3. `ENABLE_BRANCH_BHT_ID_UPDATE` 控制开关

   当前 RTL 新增 `ENABLE_BRANCH_BHT_ID_UPDATE` 参数，用于控制 ID 阶段分支 BHT 更新。
   该开关可以切断此前暴露出的 BHT CE 热点路径，使分支预测更新从不可控的固定组合
   扇入变成可审计、可复现的配置项。默认值保持兼容，实验版本可显式关闭。

4. 面向时序闭合的实现流程

   当前最佳候选采用 `opt_design -directive ExploreArea` 与
   `route_design -directive AdvancedSkewModeling` 的组合，在保持 4.287521
   CoreMark/MHz 评分线的同时，将实现结果收敛到 10000 LUT 以内并闭合 50 MHz 时序。
   相关 timing summary、utilization、route status 和 top path 报告已经归档。

5. 明确区分“高分探索”和“可报告结果”

   项目保留高分但未闭合时序的探索记录，例如 `fast201` 的 4.569338 CoreMark/MHz。
   但该配置对应 `synth224` 在 50 MHz synthesis 下 WNS -11.786 ns，因此不能作为
   可报告候选。当前报告只使用 post-route timing-closed 的 `impl220` 指标。

## 合规边界

- 未修改 `core_list_join.c`、`core_matrix.c`、`core_state.c`、`core_util.c`、
  `core_main.c`。
- 当前 CoreMark 数据是工程 short gate，用于设计迭代和同配置对比，不表述为官方
  EEMBC 10 秒合规结果。
- 当前 `impl220` 是 implementation timing-closed 工程候选，不表述为 board-proven。
- Dhrystone/DMIPS 使用 `impl220` 同配置 `timer50` xsim 证据；板级 DMIPS 需另补 UART raw log。
- 上板展示需要绑定同一 bitstream、timing report、PROGRAM_OK、UART log 和视频。

## 后续补证清单

| ID | 内容 | 完成标准 |
|---|---|---|
| R50-1 | `impl220` 对应 bitstream | 已完成：bitstream 路径和 SHA256 记录到证据文件 |
| R50-2 | PYNQ-Z2 PROGRAM_OK | Vivado Hardware Manager 日志或截图明确 bitstream 身份 |
| R50-3 | UART 输出抓取 | 原始 UART log 与所选 ROM/demo workload 对齐 |
| R50-4 | Dhrystone 同配置 xsim | 已记录 DMIPS/MHz、运行日志和 summary；如需板级结果，补 UART raw log |
| R50-5 | 视频证据 | 视频包含板卡、下载上下文和 UART PASS 输出 |
| R50-6 | 最终冻结 | 新 commit/tag 明确 frozen candidate、指标和证据路径 |

## 答辩问答口径

问：为什么不直接报告更高的 CoreMark/MHz 记录？

答：项目只把 post-route timing-closed 的 exact 配置作为候选。更高分配置保留为
探索记录，但如果综合或实现时序未闭合，就不能作为 FPGA 原型系统指标。当前 `impl220`
是在严格 50 MHz 下通过 post-route timing 的工程候选。

问：CoreMark 是否改过源码？

答：没有修改 CoreMark 核心算法文件。优化集中在 RTL 微结构、前端控制路径、参数配置
和 Vivado 实现流程。

问：现在是否已经可以上板展示？

答：当前已经有严格 50 MHz implementation timing-closed 候选，但还不能声称
board-proven。下一步需要使用已归档的同一配置 bitstream，并补齐 PROGRAM_OK、UART 和
视频证据。
