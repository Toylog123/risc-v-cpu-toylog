# 分赛区技术报告大纲 strict50 2026-07-02

本文档用于把当前 `impl220` strict 50 MHz 工程候选整理成分赛区技术报告。
所有当前指标必须绑定到归档证据，不能把历史 timing-failed 或旧 board-proven 口径
写成当前结果。

## 1. 设计目标与赛题对照

建议内容：

- 设计对象：面向 PYNQ-Z2 / xc7z020 的自研 RV32 五级流水 RISC-V CPU。
- 主要约束：FPGA 原型系统时钟不低于 50 MHz，需给出 CoreMark、资源、时序等量化指标。
- 当前候选：`impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`。
- 当前证据等级：post-route implementation timing-closed，board evidence pending。

可引用表：

| 指标 | 当前值 | 证据 |
|---|---:|---|
| Slice LUT | 9965 | `impl_utilization.rpt` |
| Slice FF | 6520 | `impl_utilization.rpt` |
| CPU clock | 50 MHz | Vivado constraints / timing summary |
| WNS / WHS | +0.056 ns / +0.121 ns | `impl_timing_summary.rpt` |
| CoreMark/MHz | 4.287521 | `fast210...summary.txt` |
| DMIPS/MHz | 2.495618 xsim | `sim220...timer50...summary.txt` |

## 2. CPU 微结构

建议讲清楚这些点：

- 五级流水：IF、ID、EX、MEM、WB。
- 数据相关处理：forwarding、load-use stall/forward 控制。
- 控制相关处理：branch redirect、redirect-cache、BHT、fold/next-cache 相关控制。
- 存储系统：严格 sync-BRAM 口径，承认并处理 BRAM 读延迟，不使用非真实零延迟模型。
- 参数化设计：通过 RTL 参数控制预测、fold、load-use、BHT update 等功能，支持可复现 A/B。

建议配图：

详见 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` 的图 1。

## 3. 时序热点与优化动机

报告重点：

- 早期低 LUT/高分探索中，MEM/DCache/load-use/redirect-cache/front-end control
  同周期组合扇入 PC 或 IF/ID 控制，导致 50 MHz 难闭合。
- 当前优化方向不是修改 benchmark 软件，而是削减硬件同周期长路径。
- 高分但 timing-failed 的配置保留为审计记录，不作为报告指标。

禁止写法：

- 不能写“所有高分配置都满足 50 MHz”。
- 不能把 `fast201` 的 4.569338 CoreMark/MHz 当作当前候选。
- 不能把 `5918 LUT / 5.162186` 作为 strict CoreMark-ROM 当前结果。

## 4. 关键硬件优化

建议分四类描述：

| 优化点 | 报告说法 | 边界 |
|---|---|---|
| BHT ID-update 可控 | 新增 `ENABLE_BRANCH_BHT_ID_UPDATE`，将 BHT 更新热点变成可配置路径 | 不夸大为复杂动态预测准确率 |
| redirect/fold 路径取舍 | 对同周期 fold/next-cache 路径做取舍，避免重建长组合路径 | 高分 fold 配置未闭合时序 |
| DCache/load-use 路径削减 | 避免 DCache/MEM 状态直接放大到前端控制同周期扇入 | 仍需后续进一步优化性能 |
| Vivado 实现策略 | `ExploreArea` + `AdvancedSkewModeling` 收敛当前候选 | 这是实现策略，不替代 RTL 合理性 |

## 5. 实验与结果

主结果表：

| Candidate | LUT | FF | CoreMark/MHz | Clock | WNS | WHS | Status |
|---|---:|---:|---:|---:|---:|---:|---|
| `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | 9965 | 6520 | 4.287521 | 50 MHz | +0.056 ns | +0.121 ns | post-route timing-closed |

邻近结果只作为审计：

| Candidate | 结果 | 决策 |
|---|---|---|
| `impl218` | 9963 LUT / WNS +0.006 ns | 低 2 LUT，但 setup margin 明显更薄 |
| `impl223` | 9968 LUT / WNS +0.003 ns | 面积和 margin 均不优 |
| `synth224` | 4.569338 CoreMark/MHz fast score，但 WNS -11.786 ns | timing failed，不报告为候选 |

## 6. 合规性说明

必须写清：

- 未修改 CoreMark 核心算法文件：
  `core_list_join.c`、`core_matrix.c`、`core_state.c`、`core_util.c`、`core_main.c`。
- 当前 CoreMark 是工程 short-gate，不称官方 EEMBC 10 秒合规。
- 当前 `impl220` 同配置 DMIPS/MHz 来自 xsim 证据，不能外推历史 DMIPS，也不能写成板级 UART 结果。
- 当前还没有 `impl220` board evidence，不能称 board-proven。

## 7. 应用演示计划

赛题需要通过相关程序体现性能。当前建议报告写法：

- 已有 CPU/SoC 能运行 benchmark 类工作负载，并能通过 UART 输出性能相关结果。
- strict50 当前 `impl220` bitstream/SHA256 已归档，仍需完成 PROGRAM_OK、UART、视频证据。
- 应用演示应绑定同一 bitstream、同一 ROM/demo workload、同一 UART log。

后续可补：

| 演示项 | 目的 | 完成标准 |
|---|---|---|
| CoreMark UART 输出 | 展示 benchmark 跑通和 CRC/PASS | raw log + 视频 |
| Dhrystone UART 输出 | 补 DMIPS/MHz | summary + raw log |
| 自定义性能 demo | 展示 CPU 对实际程序的处理能力 | 程序源码 + UART 输出 |

## 8. 结论建议

推荐结论：

“当前 `impl220` 在严格 sync-BRAM 和 PYNQ-Z2 post-route implementation 口径下，
实现了 50 MHz 时序闭合，并在不修改 CoreMark 核心算法的条件下达到
4.287521 CoreMark/MHz。后续工作集中在补齐上板证据、板级演示输出，以及将演示程序
与当前 bitstream 绑定归档。”
