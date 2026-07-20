# 分赛区答辩 PPT 分镜 strict50 2026-07-02

本文档用于制作答辩 PPT。PPT 主线只讲当前 `impl220` strict50 工程候选，
不做旧版本指标堆叠。

## 1. 开场：项目目标

标题建议：`面向 PYNQ-Z2 的 50 MHz RISC-V 五级流水 CPU`

要点：

- 自研 RV32 五级流水 CPU。
- 面向 FPGA 原型验证，不使用忽略 BRAM 延迟的非真实口径。
- 当前实现候选已在 Vivado post-route 下闭合 50 MHz。

讲稿：

“我们的目标是在 PYNQ-Z2 上实现一个可综合、可实现、可审计的 RISC-V 五级流水 CPU。
当前汇报的主结果不是软件层改分，而是硬件 RTL、控制路径和实现流程共同收敛出的
strict 50 MHz post-route 候选。”

## 2. 赛题要求对照

主表：

| 要求 | 当前状态 |
|---|---|
| RV32/RV64 基础整数 ISA | 当前验证 RV32 |
| 五级流水 | IF/ID/EX/MEM/WB |
| 性能优化技术 | branch/BHT、redirect-cache、DCache/load-use、Vivado directives |
| FPGA 时钟 >= 50 MHz | `impl220` post-route WNS +0.056 ns |
| 性能量化 | 4.287521 CoreMark/MHz |
| 资源统计 | 9965 LUT / 6520 FF / 32 BRAM / 8 DSP |

讲稿重点：把“已完成”和“待补证”分开讲，DMIPS 只按 xsim 证据报告，board evidence 不提前宣称。

## 3. 架构总览

画面建议：

- 使用 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` 图 1，左到右五级流水。
- 下方画 forwarding/load-use/hazard。
- 上方画 BHT/redirect-cache 回到 IF。

要点：

- IF 负责 PC 与取指。
- ID 做译码、hazard、部分前端控制。
- EX 做 ALU 和 branch resolve。
- MEM 接 DCache/BRAM。
- WB 回写寄存器。

讲稿重点：说明性能优化和时序风险都集中在前端 redirect 与 MEM/DCache 状态交互。

## 4. 为什么严格 sync-BRAM 重要

要点：

- FPGA BRAM 是同步读，延迟不可忽略。
- 忽略延迟会让仿真分数失真，最终上板不可靠。
- 当前 strict50 口径把 BRAM 延迟纳入 RTL 和 timing report。

讲稿：

“我们没有把存储器建成零延迟理想模型。这样做会让早期分数更好看，但不对应真实 FPGA。
当前材料只保留能够和实现时序对得上的 strict 口径。”

## 5. 时序热点

画面建议：

使用 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` 图 2。

要点：

- 同周期组合扇入会形成长路径。
- 高分配置如果引入 MEM 到 front-end 的直接组合回路，即使 fast score 高，也不能报告。
- 当前优化把可疑路径变成可控配置，并选择 timing-safe 组合。

## 6. 关键优化

建议三栏：

| 优化 | 解决的问题 | 当前收益 |
|---|---|---|
| `ENABLE_BRANCH_BHT_ID_UPDATE` | BHT CE 热点可控 | 保持 score line，改善可实现性 |
| fold/next-cache 取舍 | 避免高分配置重建长路径 | strict 50 MHz 可闭合 |
| ExploreArea + AdvancedSkewModeling | 实现阶段面积/时序收敛 | 9965 LUT，WNS +0.056 ns |

讲稿重点：这些是硬件和实现优化，不是修改 CoreMark。

## 7. 当前结果

主结果表：

| 指标 | 数值 |
|---|---:|
| Candidate | `impl220` |
| LUT | 9965 |
| FF | 6520 |
| CoreMark/MHz | 4.287521 |
| DMIPS/MHz | 2.495618 xsim |
| Clock | 50 MHz |
| WNS / WHS | +0.056 ns / +0.121 ns |
| Evidence | post-route timing-closed |

脚注必须有：

- CoreMark 核心算法未修改。
- DMIPS 为同配置 Dhrystone xsim，不能写成板级 UART 结果。
- board evidence pending。

## 8. 为什么不报更高分

要点：

- `fast201` 有 4.569338 CoreMark/MHz，但对应 `synth224` WNS -11.786 ns。
- timing-failed 高分不能代表 FPGA 原型系统指标。
- 当前报告使用可复现、可审计、post-route timing-closed 的 `impl220`。

讲稿：

“我们把探索记录和可报告结果分开。评审看到的主指标必须能从 timing report 和 summary
逐项追溯，不能只看 fast gate 分数。”

## 9. 合规边界

建议直接列：

- 未修改 CoreMark 核心算法文件。
- 当前 CoreMark 是工程 short-gate，不称官方 EEMBC 10 秒。
- 当前 `impl220` 还未 board-proven。
- 当前 `impl220` DMIPS/MHz 已有同配置 xsim 证据，但不是板级结果。

讲稿重点：主动讲清边界比被问到后解释更稳。

## 10. 演示与后续补证

要点：

- `impl220` bitstream/SHA256 已归档。
- PROGRAM_OK 证据。
- UART raw log。
- 上板视频。
- 如需板级 DMIPS，补 Dhrystone UART raw log。

结束语：

“下一步不是更换口径，而是把当前已闭合的 strict50 候选补齐板级证据和应用演示证据，
让报告指标、bitstream、UART 输出和视频来自同一配置。”
