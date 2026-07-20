# 分赛区 strict50 提交与答辩工作计划 2026-07-02

本文档面向当前 `impl220` strict 50 MHz 工程候选，目标是把分赛区材料从
“已有实现证据”推进到“可提交、可答辩、可上板补证”的闭环。当前结论必须保持
严格边界：`impl220` 是 post-route timing-closed engineering candidate，
尚不是 board-proven result。

## 当前基准口径

| 项目 | 当前值 |
|---|---|
| 冻结 tag | `freeze-strict50-impl220-20260701` |
| 上一轮材料基点 commit | `69b814a Add strict50 region delivery package` |
| 候选版本 | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| FPGA 平台 | PYNQ-Z2 / xc7z020 |
| CPU 时钟 | 50 MHz |
| Slice LUT | 9965 |
| Slice FF | 6520 |
| BRAM Tile / DSP | 32 / 8 |
| CoreMark/MHz | 4.287521 |
| post-route timing | WNS +0.056 ns / WHS +0.121 ns |
| DMIPS/MHz | 2.495618 xsim，同配置 `timer50` Dhrystone 证据 |
| 板级证据 | partial：bitstream/SHA256 已归档；PROGRAM_OK、UART、视频 pending |

可报告一句话：

`当前 strict50 工程候选在 PYNQ-Z2 post-route implementation 下达到 9965 LUT / 4.287521 CoreMark/MHz / 50 MHz / WNS +0.056 ns / WHS +0.121 ns；CoreMark 核心算法未修改，板级证据待补。`

## 提交包结构建议

| 包/材料 | 内容 | 当前状态 | 下一步 |
|---|---|---|---|
| 源码包 | `YH_rv_cpu/rtl`、必要 scripts、TB、约束和配置 | 仓库已有 | 最终打包前按 CICC 命名清理，不带历史 scratch |
| 技术报告 | 架构、优化方法、资源、性能、时序、合规边界 | strict50 段落已准备 | 合并 `REGION_REPORT_STRICT50_SECTION_20260701.md` 和 requirement matrix |
| 答辩 PPT | 设计目标、架构、优化亮点、实验结果、演示计划 | 分镜和内容母稿已准备 | 按 `REGION_WORK_INTRO_AND_PPT_MASTER_STRICT50_20260706.md` 拆页制作 |
| 严格验证门禁 | PPT、报告、提交包、board evidence 的硬检查项 | 已补清单 | 按 `REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md` 逐项复核 |
| 实验证据 | timing/utilization/route/CoreMark summary、Dhrystone xsim summary | `impl220` 已归档 | 上板后如需板级 DMIPS，再补 UART raw log |
| 应用演示 | strict50 perf demo xsim、runner、testbench、SHA256 | 已补 `strict50_perf_demo_20260702/` | 上板后补同 demo UART/视频 |
| 上板证据 | bitstream SHA256、PROGRAM_OK、UART、视频 | bitstream/SHA256 已完成；其余未完成 | 按 `STRICT50_BOARD_DEMO_RUNBOOK_20260702.md` 补齐 |
| 答辩口径 | 高频 QA、边界说明、旧结果隔离 | 已准备 | 现场材料只使用 strict50 QA |

## PPT 建议结构

| 页码 | 标题 | 重点内容 | 证据来源 |
|---:|---|---|---|
| 1 | 项目概览 | 自研 RV32 五级流水 CPU，PYNQ-Z2，strict 50 MHz | 报告正文 |
| 2 | 赛题要求对照 | RV32、流水线、优化技术、50 MHz、性能量化 | `REGION_REQUIREMENT_MATRIX_20260702.md` |
| 3 | 处理器架构 | IF/ID/EX/MEM/WB、hazard、redirect、memory subsystem | RTL 和 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` |
| 4 | 时序问题定位 | DCache/MEM/front-end 长路径，sync-BRAM 真实延迟 | `RESULTS_20260611.md`、timing reports |
| 5 | 关键优化一 | BHT ID-update 控制、redirect/fold 路径取舍 | `REGION_REPORT_STRICT50_SECTION_20260701.md` |
| 6 | 关键优化二 | DCache/load-use/fold 同周期路径削减 | RTL 参数和审计结果 |
| 7 | 实现流程优化 | ExploreArea + AdvancedSkewModeling，post-route evidence | `impl220` reports |
| 8 | 当前指标 | 9965 LUT、4.287521 CoreMark/MHz、50 MHz timing closed | freeze 和 summary |
| 9 | 合规边界 | CoreMark 未改、DMIPS 为同配置 xsim、不是官方 EEMBC 10 秒 | QA 文档 |
| 10 | 演示与后续 | strict50 perf demo xsim 已通过；bitstream/SHA256 已归档；PROGRAM_OK、UART、视频待补 | app demo evidence、Dhrystone evidence、bitstream evidence、board evidence template |

PPT 中不要放旧 `4961 LUT / 4.137461 / board-proven` 初赛口径作为当前结果；如需历史对比，只能放在附录并明确“历史记录，不代表当前 strict50 候选”。

## 技术报告章节建议

| 章节 | 建议内容 | 状态 |
|---|---|---|
| 1. 设计目标 | 面向 PYNQ-Z2 的 RV32 五级流水 CPU，目标不低于 50 MHz | 待整合 |
| 2. 微结构 | 流水级、forwarding、load-use、redirect、BHT、DCache/BRAM | 架构图已补，见 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` |
| 3. 性能优化 | 前端预测/redirect、fold/next-cache、DCache 控制、实现策略 | 已有段落 |
| 4. 时序优化 | 最差路径历史、同周期组合扇入削减、impl220 收敛方式 | 已有证据 |
| 5. 实验结果 | strict50 当前指标、资源、CoreMark、timing summary | 已有 |
| 6. 合规性 | 未改 CoreMark 核心算法、short-gate 边界、DMIPS xsim 边界 | 已有 |
| 7. 演示计划 | 上板证据闭环和应用程序展示 | xsim demo 与 bitstream 已补，待补 PROGRAM_OK/UART/视频 |

## 当前 P0 任务

| ID | 任务 | 输入 | 输出 | 完成标准 |
|---|---|---|---|---|
| P0-1 | `impl220` bitstream 归档 | frozen routed DCP | `.bit`、SHA256、生成日志 | 已完成，见 `board_impl220_bitstream_20260702/` |
| P0-2 | PYNQ-Z2 PROGRAM_OK | `impl220` bitstream | Vivado Hardware Manager 日志/截图 | 证据中能识别 bitstream |
| P0-3 | UART 证据 | `strict50` perf demo workload | raw UART log | log 与 `baseline=strict50 impl220 cpu_clk=50MHz`、CRC/PASS 口径一致 |
| P0-4 | 同配置 Dhrystone | `impl220` 配置 | DMIPS/MHz summary | 已完成 xsim；若需板级 DMIPS，后续补 UART raw log |
| P0-5 | 上板视频 | PYNQ-Z2、UART、programming context | 视频文件路径 | 能看到板卡、下载、UART 输出 |

## 当前 P1 任务

| ID | 任务 | 输出 |
|---|---|---|
| P1-1 | 五级流水架构图 | 已完成，见 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` |
| P1-2 | timing hotspot 优化前后逻辑示意图 | 已完成，见 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` |
| P1-3 | 整理最终提交 README | in progress：当前索引已加入架构图、作品介绍母稿和 bitstream evidence，最终上板后再收敛 pending 项 |
| P1-4 | 清理 CICC 命名与打包路径 | 不再出现 ICDC 主材料名 |
| P1-5 | 准备现场 QA 速答卡 | 只使用 strict50 当前口径 |
| P1-6 | PPT/报告严格验证 | 按 `REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md` 检查禁用口径、主指标和证据等级 |

## 禁止混用项

| 项 | 原因 |
|---|---|
| `fast201` / `synth224` 作为当前结果 | fast score 高，但 synthesis WNS -11.786 ns |
| `5918 LUT / 5.162186` 作为当前 strict50 结果 | 不是当前 strict CoreMark-ROM routed candidate |
| `6872 LUT / 5.023480` 作为当前 50 MHz 结果 | 历史低资源线，post-route 50 MHz 未闭合 |
| 旧初赛 QA 的 `4961 LUT / 4.137461 / board-proven` | 旧 bitstream/口径，不是 `impl220` |
| 官方 EEMBC 10 秒合规 | 当前 CoreMark 是工程 short-gate |

## 完成定义

分赛区材料达到可提交状态，需要同时满足：

1. 报告、PPT、README 只使用 `impl220` 当前 strict50 口径。
2. timing/utilization/CoreMark evidence 可直接追溯到归档文件。
3. bitstream/SHA256 已归档；PROGRAM_OK、UART、视频补齐后，board evidence template 已填写。
4. DMIPS 使用 `impl220` 同配置 `timer50` xsim summary；不得外推旧 DMIPS，板级 DMIPS 需另补 UART raw log。
5. 历史实验只作为审计过程，不作为当前结果。
6. PPT、报告和最终包通过严格验证门禁清单，未把 pending board evidence 写成已完成。
