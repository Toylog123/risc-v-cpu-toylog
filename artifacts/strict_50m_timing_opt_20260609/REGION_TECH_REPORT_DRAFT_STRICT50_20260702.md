# 分赛区技术报告正文草稿 strict50 2026-07-02

本文可作为分赛区技术报告中“处理器设计与性能优化”章节的正文草稿。当前口径只适用于
`impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`
这一 strict 50 MHz post-route 工程候选。本文不声明板级验证已经完成。

## 设计目标

本项目面向 PYNQ-Z2 / xc7z020 FPGA 平台实现一款自研 RV32 五级流水 RISC-V CPU。
设计目标是在真实 FPGA 原型系统约束下完成处理器功能、性能优化和实现时序闭合，
并通过 CoreMark、资源占用和 Vivado post-route timing report 给出可复现的量化证据。

当前 strict 50 MHz 工程候选为
`impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`。
该候选在 PYNQ-Z2 post-route implementation 下达到
9965 LUT、6520 FF、32 BRAM Tile、8 DSP、4.287521 CoreMark/MHz，
同配置 Dhrystone xsim 为 2.495618 DMIPS/MHz，
并在 50 MHz 约束下取得 WNS +0.056 ns、WHS +0.121 ns。该结果来自 RTL 控制路径、
参数配置和 Vivado 实现流程优化，不修改 CoreMark 核心算法源文件。

## 微结构设计

处理器采用 IF、ID、EX、MEM、WB 五级流水组织。IF 阶段负责 PC 选择和取指；
ID 阶段完成指令译码、寄存器读和冒险检测；EX 阶段执行 ALU、分支条件判断和目标地址计算；
MEM 阶段连接 DCache/BRAM 访问路径；WB 阶段完成寄存器堆回写。

为了提高流水线吞吐率，设计包含 forwarding、load-use 检测、redirect 控制、BHT、
redirect-cache、fold/next-cache 等可配置控制结构。这些结构能够在不同工作负载下减少
不必要的停顿或前端取指损失，但同时也可能把 MEM/DCache 状态、load-use 判断、
redirect-cache 命中和前端 PC 选择连接成同周期长组合路径。因此，本项目将这些前端和
存储相关优化做成参数化开关，用于进行可复现的 A/B 审计。

## 严格 sync-BRAM 口径

FPGA BRAM 是同步读资源，真实实现中不能忽略读延迟。如果在仿真中使用零延迟存储模型，
前端取指、DCache 命中和 fold 逻辑可能得到偏乐观的分数，但这些分数无法直接对应
综合、布局布线和上板行为。当前 strict50 路径坚持同步 BRAM 口径，将 BRAM 延迟纳入
RTL 和 Vivado timing 约束，使性能数据能够和 post-route timing report 对齐。

这一选择降低了部分高分探索配置的可报告性，但提升了结果的可审计性。当前报告只把
post-route timing-closed 的实现候选作为主结果；fast-only、synthesis timing-failed、
demo-ROM 或历史 board-proven 口径都不替代当前 strict CoreMark-ROM 候选。

## 时序热点定位

早期优化中，最主要的时序风险来自 MEM/DCache/load-use/redirect-cache/front-end control
对 PC 或 IF/ID 控制的同周期组合扇入。高分配置通常会尝试在同一周期利用 DCache 或
redirect-cache 信息减少前端损失，但这些信号跨越 MEM、hazard、redirect 和 IF 选择逻辑后，
容易形成很长的组合路径，导致 50 MHz 难以闭合。

当前 `impl220` 的优化方向不是修改 benchmark 软件，而是缩短硬件关键路径。具体做法包括：
把分支 BHT 更新热点变成可配置路径，谨慎取舍 fold/next-cache 同周期路径，削减
DCache/load-use 状态对前端控制的组合扇入，并配合 Vivado implementation directive
寻找时序和面积的可实现平衡。

## 关键优化点

第一，设计引入并使用 `ENABLE_BRANCH_BHT_ID_UPDATE` 控制项，使 ID 阶段 BHT 更新路径
从固定组合扇入变为可控配置。该开关用于切断此前暴露出的 BHT CE 热点路径，便于对分支
预测更新和时序影响进行单变量审计。

第二，设计对 redirect-cache、fold 和 next-cache 相关路径进行取舍。直接启用部分
高分 fold 配置可以提高 fast-gate CoreMark/MHz，但会重新引入 DCache/MEM 到前端控制的
长组合路径。当前候选选择 timing-safe 配置，不把未闭合时序的高分探索记录作为主结果。

第三，设计围绕 DCache/load-use 控制路径做收敛，避免 MEM 阶段状态在同一周期直接放大到
前端 PC 或 IF/ID 选择。该策略牺牲了部分极限投机性能，但让严格 50 MHz 实现成为可报告结果。

第四，当前候选采用 `opt_design -directive ExploreArea` 与
`route_design -directive AdvancedSkewModeling` 的实现流程组合。该组合在保持
4.287521 CoreMark/MHz 评分线的同时，将资源收敛到 9965 LUT，并取得正 setup/hold slack。

## 实验结果

当前可报告主结果如下：

| 指标 | 数值 |
|---|---:|
| 候选版本 | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Slice LUT | 9965 |
| Slice FF | 6520 |
| BRAM Tile | 32 |
| DSP | 8 |
| CPU 时钟 | 50 MHz |
| CoreMark/MHz | 4.287521 |
| DMIPS/MHz | 2.495618 xsim |
| post-route WNS | +0.056 ns |
| post-route WHS | +0.121 ns |

主要证据文件包括：

| 证据 | 路径 |
|---|---|
| timing summary | `impl220.../reports_cpu50/impl_timing_summary.rpt` |
| utilization | `impl220.../reports_cpu50/impl_utilization.rpt` |
| route status | `impl220.../reports_cpu50/impl_route_status.rpt` |
| CoreMark summary | `fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt` |
| Dhrystone summary | `sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt` |
| freeze note | `FREEZE_STRICT50_IMPL220_20260701.md` |

邻近探索结果中，`fast201` 可取得 4.569338 CoreMark/MHz 的 fast-gate 分数，但对应
`synth224_defaultfast_foldnext0_cpu50` 在 50 MHz synthesis 下 WNS 为 -11.786 ns，
不能作为当前 FPGA 原型系统候选。`impl223` 可以完成 routed timing closure，但 LUT 和 setup
slack 均不优于 `impl220`，因此不作为当前推荐版本。

## 合规边界

当前优化没有修改以下 CoreMark 核心算法文件：
`core_list_join.c`、`core_matrix.c`、`core_state.c`、`core_util.c`、`core_main.c`。
CoreMark 结果是工程 short-gate 数据，用于同配置设计迭代和审计，不表述为官方 EEMBC
10 秒合规认证。

当前 `impl220` 同配置 Dhrystone/DMIPS xsim 已补齐，报告值为 2.495618 DMIPS/MHz；
该值不能替代板级 UART 证据。当前 `impl220` bitstream 和 SHA256 已归档，但 PROGRAM_OK、UART raw log
和视频证据尚未补齐，因此不称为
board-proven。后续上板证据必须绑定同一 bitstream、同一 timing report 和同一 workload。

## 应用演示计划

赛题需要相关程序体现处理器性能。当前建议将应用演示分为三类：

| 演示项 | 目的 | 证据 |
|---|---|---|
| CoreMark UART 输出 | 展示标准 benchmark 跑通和 CRC/PASS | raw UART log、视频 |
| Dhrystone UART 输出 | 补充 DMIPS/MHz 指标 | summary、raw log |
| 小型矩阵/内存访问 demo | 展示 ALU、load/store、branch 综合行为 | 程序源码、ROM 生成脚本、UART 输出 |

上述演示必须在 `impl220` bitstream 身份明确后执行。若演示程序不是 CoreMark，不能把其
UART 输出写成 CoreMark 官方结果；若报告板级 DMIPS，必须补充同一 bitstream 的
Dhrystone UART raw log，不能用 xsim 证据冒充上板结果。

## 小结

当前 `impl220` 证明了该 CPU 在严格 sync-BRAM 和 PYNQ-Z2 post-route implementation 口径下
可以闭合 50 MHz，并在不修改 CoreMark 核心算法的条件下达到 4.287521 CoreMark/MHz。
后续工作重点是基于已归档 bitstream 补齐 PROGRAM_OK、UART、视频和板级演示证据，
将 implementation-evidence candidate 推进为可上板展示的完整分赛区材料包。
