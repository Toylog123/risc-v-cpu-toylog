# 分赛区作品介绍与PPT内容母稿 strict50 2026-07-06

本文档用于快速制作分赛区答辩 PPT、技术报告摘要和现场讲稿。它只描述当前
`impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`
这一 strict 50 MHz 工程候选，不混用历史低面积线、高分但 timing failed 的探索线、
旧初赛 board-proven 口径或 demo-ROM 口径。

当前允许使用的主指标为：

| 指标 | 当前值 |
|---|---:|
| FPGA 平台 | PYNQ-Z2 / xc7z020 |
| CPU 时钟 | 50 MHz |
| Slice LUT | 9965 |
| Slice FF | 6520 |
| BRAM Tile | 32 |
| DSP | 8 |
| CoreMark/MHz | 4.287521 |
| DMIPS/MHz | 2.495618 xsim |
| post-route timing | WNS +0.056 ns / WHS +0.121 ns |
| 证据等级 | post-route timing-closed engineering candidate，尚未 board-proven |

硬边界：

- CoreMark 核心算法文件未修改：`core_list_join.c`、`core_matrix.c`、
  `core_state.c`、`core_util.c`、`core_main.c`。
- 当前 CoreMark 是工程 short-gate 结果，不声明为官方 EEMBC 10 秒认证结果。
- 当前 DMIPS/MHz 来自同配置 Dhrystone xsim，不声明为板级 UART 结果。
- 当前 bitstream 和 SHA256 已归档，但 PROGRAM_OK、board UART raw log、视频仍待补；
  因此不能写成已上板验证通过。

## 1. 当前分赛区文档完成度

分赛区材料已经开始写，并且已经有较完整的技术材料骨架。当前缺少的不是
“有没有开始”，而是把现有材料进一步收敛成可以直接制作 PPT 的作品介绍主稿。
本文就是这份主稿。

| 材料 | 状态 | 用途 |
|---|---|---|
| `REGION_DELIVERY_INDEX_20260702.md` | ready | 分赛区材料总入口、指标口径、证据缺口 |
| `REGION_REQUIREMENT_MATRIX_20260702.md` | ready | 赛题要求逐条对照 |
| `REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md` | draft ready | 技术报告正文草稿 |
| `REGION_REPORT_OUTLINE_STRICT50_20260702.md` | ready | 技术报告章节大纲 |
| `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` | ready | 五级流水、时序热点、证据链 Mermaid 图 |
| `REGION_PPT_STORYBOARD_STRICT50_20260702.md` | ready | PPT 分镜和页级讲稿 |
| `REGION_DEFENSE_SPEAKER_SCRIPT_STRICT50_20260702.md` | ready | 1 分钟/3 分钟现场讲稿 |
| `REGION_DEFENSE_QA_STRICT50_20260702.md` | ready | 现场问答边界 |
| `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md` | ready | 指标到原始证据的追踪表 |
| `STRICT50_APP_DEMO_EVIDENCE_20260702.md` | ready | 应用演示 xsim 证据 |
| `STRICT50_DHRYSTONE_EVIDENCE_20260702.md` | ready | Dhrystone/DMIPS xsim 证据 |
| `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` | pending fill | 上板 PROGRAM_OK、UART、视频证据模板 |

## 2. 作品一句话介绍

### 2.1 答辩首页版本

本作品面向 PYNQ-Z2 FPGA 平台实现了一款自研 RV32 五级流水 RISC-V CPU，
在严格同步 BRAM 口径下完成 50 MHz post-route 时序闭合，并通过 CoreMark、
Dhrystone xsim、资源利用率和 Vivado timing report 给出可复核的性能证据。

### 2.2 技术报告摘要版本

本项目围绕 FPGA 原型系统中 RISC-V 处理器的性能、资源和时序收敛问题，
设计并实现了一款 RV32 五级流水 CPU。处理器采用 IF/ID/EX/MEM/WB 经典流水线，
配套实现数据前递、load-use 处理、分支重定向、BHT、redirect-cache、
DCache/BRAM 访问控制等优化结构。针对 FPGA 同步 BRAM 延迟和前端 PC 选择长组合路径，
项目进一步采用参数化 RTL 控制和 Vivado implementation directive 组合优化，
形成当前 `impl220` strict 50 MHz 工程候选。该候选在 PYNQ-Z2 post-route
implementation 下达到 9965 LUT、4.287521 CoreMark/MHz、2.495618 DMIPS/MHz xsim，
并在 50 MHz 约束下取得 WNS +0.056 ns、WHS +0.121 ns。

### 2.3 现场 20 秒版本

我们的作品不是只跑通仿真的 CPU，而是把 RV32 五级流水处理器推进到了
PYNQ-Z2 上可实现、可复核的 strict 50 MHz post-route 工程候选。重点贡献是
在不修改 CoreMark 核心算法的前提下，通过前端控制、存储访问和实现流程优化，
同时给出性能、资源和时序闭合证据。

## 3. PPT 主叙事

答辩主线建议采用“赛题要求 -> 设计方案 -> 时序难点 -> 优化方法 -> 实验证据 ->
合规边界 -> 上板补证计划”的顺序。

### 3.1 评委需要听清楚的核心信息

第一，作品是自研 CPU，不是直接复用开源 CPU；当前报告只声明已验证的 RV32 配置。

第二，作品是五级流水结构，不是单周期或多周期 demo；流水线中有真实的数据冒险、
控制冒险和存储访问处理。

第三，性能优化不是修改 benchmark，而是集中在硬件 RTL、配置参数和 Vivado 实现流程。

第四，当前选择 strict sync-BRAM 口径。同步 BRAM 延迟会真实进入取指、访存和时序路径，
因此分数比理想零延迟仿真更保守，但更接近可实现 FPGA 原型系统。

第五，当前主结果是 post-route timing closed。高分但 timing failed 的历史探索只作为
审计记录，不作为当前候选。

第六，当前还不能称为 board-proven，因为 PROGRAM_OK、UART raw log 和视频还没有补齐。

### 3.2 建议 PPT 总结句

`impl220` 证明了该 CPU 在严格同步 BRAM 和 PYNQ-Z2 post-route 约束下，可以在
50 MHz 闭合时序，并保持 4.287521 CoreMark/MHz 的工程性能线；该结果来自硬件路径
收敛和实现流程优化，而不是 CoreMark 软件改分。

## 4. 设计目标

### 4.1 功能目标

- 实现 RV32 基础整数指令路径，当前报告只声明已验证的 32 位配置。
- 构建 IF/ID/EX/MEM/WB 五级流水微结构。
- 支持寄存器堆读写、ALU 运算、访存、分支跳转、异常/暂停类基础控制路径。
- 提供 SoC 集成所需的 ROM/BRAM、UART、计时和仿真/上板调试接口。
- 支持 CoreMark、Dhrystone 和应用演示程序的工程运行链路。

### 4.2 性能目标

- FPGA 原型系统时钟不低于 50 MHz。
- CoreMark/MHz 至少保持可参赛口径，当前候选为 4.287521 CoreMark/MHz。
- 通过 Dhrystone xsim 补充 DMIPS/MHz 指标，当前为 2.495618 DMIPS/MHz xsim。
- 在资源可接受范围内优先保证时序闭合和证据可复核。

### 4.3 工程目标

- 不修改 CoreMark 核心算法文件。
- 不用无法综合或无法时序闭合的高分配置冒充 FPGA 原型指标。
- 每个主指标都有原始文件、复核脚本和报告边界。
- 分赛区材料中把 post-route evidence、xsim evidence、board evidence 三类证据明确分开。

## 5. 总体架构

### 5.1 系统视角

作品可以按“CPU Core + 存储子系统 + 外设/调试 + 软件 workload + 证据脚本”五层介绍。

| 层级 | 内容 | PPT 讲法 |
|---|---|---|
| CPU Core | RV32 五级流水、寄存器堆、ALU、分支、访存、回写 | 这是作品主体，负责指令执行和流水控制 |
| 存储子系统 | 指令 ROM、数据 BRAM/DCache 访问控制、同步 BRAM 时序 | strict 口径下把 BRAM 延迟纳入设计 |
| 外设/调试 | UART、timer、仿真 testbench、PYNQ-Z2 bitstream | 用于输出 benchmark 和演示结果 |
| 软件 workload | CoreMark、Dhrystone、perf demo | 用于量化性能和展示实际程序运行 |
| 证据脚本 | metric verify、board audit、demo audit、package script | 保证报告数字可复核 |

### 5.2 五级流水

| 流水级 | 主要职责 | 关键设计点 | 答辩讲法 |
|---|---|---|---|
| IF | PC 选择、取指、前端 redirect 接收 | PC mux、redirect-cache、BHT/fold 相关控制 | 前端决定下一条指令，是性能和时序都敏感的位置 |
| ID | 指令译码、寄存器读、立即数生成、冒险检测 | forwarding 选择、load-use 检测、stall/flush | ID 是控制决策集中区，决定流水是否暂停或重定向 |
| EX | ALU、比较、分支解析、目标地址计算 | branch resolve、ALU forwarding、条件判断 | EX 给出真实分支结果，是纠正预测的关键点 |
| MEM | load/store、DCache/BRAM 访问、访存状态 | 同步 BRAM 延迟、load-use、访存返回数据 | MEM 与前端控制若同周期强耦合，会形成长路径 |
| WB | 写回寄存器堆 | ALU/load/PC+4 等写回选择 | WB 关闭数据通路回路，配合前递减少停顿 |

### 5.3 数据通路

数据通路以寄存器堆和 ALU 为中心。ID 阶段读取源寄存器，EX 阶段执行算术逻辑、
比较和地址计算，MEM 阶段处理 load/store，WB 阶段将 ALU 结果、访存结果或跳转返回值
写回寄存器堆。为了降低 RAW 数据冒险造成的停顿，设计通过 EX/MEM/WB 结果前递，
让后续指令在数据正式写回前尽早使用正确值。

PPT 可以画成：

`RegFile -> ALU -> MEM/DCache -> WB mux -> RegFile`

旁路标注：

- EX/MEM 到 ID/EX 的 forwarding。
- MEM/WB 到 ID/EX 的 forwarding。
- load-use 无法同周期满足时触发 stall 或 replay。

### 5.4 控制通路

控制通路主要围绕 PC 选择、stall、flush、redirect 和 branch update 展开。分支类指令
在 EX 阶段解析真实方向和目标地址；前端可以利用 BHT、redirect-cache、fold/next-cache
等结构减少取指损失。但这些结构如果直接和 MEM/DCache/load-use 状态在同一周期组合到
PC 选择，就会形成较长的组合扇入路径。

当前 `impl220` 的核心取舍是：保留有价值的前端优化能力，但对高风险同周期长路径进行
裁剪或参数化控制，把 timing-safe 作为主候选选择标准。

## 6. strict sync-BRAM 口径

### 6.1 为什么必须强调

FPGA 的 Block RAM 是同步读资源。真实硬件中，地址、使能和数据返回之间存在时钟边界，
不能把存储器当作零延迟数组使用。如果仿真模型忽略这一点，CoreMark 或其他 workload
可能在仿真中得到更高分，但这个分数无法直接对应综合、布局布线和上板行为。

### 6.2 对本项目的影响

strict sync-BRAM 口径会让前端取指、访存返回、load-use 判断和 redirect 控制更保守。
这会牺牲一部分理想仿真分数，但换来两个重要收益：

- 报告指标能与 Vivado post-route timing report 对齐。
- 后续上板时，bitstream、UART 输出和视频证据可以绑定到同一工程候选。

### 6.3 PPT 表达

建议用一页讲清楚：

| 不严格口径 | strict sync-BRAM 口径 |
|---|---|
| 仿真分数可能更高 | 分数更保守但更可信 |
| 可能隐藏 BRAM 读延迟 | BRAM 延迟进入 RTL 和 timing |
| 难以和 post-route report 对齐 | 可用 timing/utilization/bitstream 复核 |
| 不适合作为当前主结果 | 当前 `impl220` 使用该口径 |

现场讲法：

“我们没有把存储器建成理想零延迟模型来换取好看的分数。当前汇报只采用能和
PYNQ-Z2 post-route timing 对齐的 strict 口径。”

## 7. 性能优化技术亮点

### 7.1 亮点一：五级流水和数据前递

五级流水把取指、译码、执行、访存和写回分离，使多条指令能够重叠执行。为了让流水线
保持吞吐，设计实现了 forwarding 和 load-use 处理。普通 ALU RAW 冒险可以通过前递降低
停顿；load-use 这类数据需要等访存返回的场景，则由 hazard 逻辑触发暂停或重放。

PPT 重点：

- 五级流水提供基础并行执行能力。
- forwarding 减少不必要的等待。
- load-use 控制保证结果正确，不靠软件插空。

### 7.2 亮点二：前端 redirect 和分支控制

分支和跳转会破坏顺序取指。设计中通过 branch redirect、BHT、redirect-cache、
fold/next-cache 等参数化机制降低前端损失。分支真实结果在 EX 阶段解析，前端控制路径
负责将错误路径 flush，并把 PC 切换到正确目标。

当前答辩不要把它包装成复杂商用级预测器；准确说法是：

“我们实现了面向本项目 workload 的参数化前端 redirect/branch 控制，并在 strict50
候选中选择 timing-safe 配置。”

### 7.3 亮点三：DCache/load-use 与前端控制解耦

早期高分探索中，MEM/DCache/load-use 状态、redirect-cache 命中、BHT 更新和 PC 选择
容易在同一周期组合到一起。这种设计能减少少数场景的前端损失，但会把路径拉长，
导致 50 MHz 难以闭合。

当前优化重点不是删除功能，而是减少“同周期必须立即影响 PC”的组合扇入：

- 把部分高风险控制变成参数化开关。
- 对 fold/next-cache 类路径做 timing-safe 取舍。
- 降低 MEM 阶段状态对 IF PC mux 的直接组合影响。
- 使用 post-route timing 结果筛选候选，而不是只看 fast-gate 分数。

### 7.4 亮点四：BHT ID-update 热点可配置化

`ENABLE_BRANCH_BHT_ID_UPDATE` 让 BHT ID 阶段更新路径从固定组合热点变成可审计的配置项。
这样可以在不同候选中比较性能和时序影响，避免一个看似局部的 BHT CE 路径成为全局
timing blocker。

PPT 可以这样讲：

“我们把前端分支更新路径做成可配置结构，使它既能参与性能探索，也能在 strict50
候选中被时序约束管理。”

### 7.5 亮点五：实现流程与 RTL 共同优化

当前 `impl220` 不只依靠 RTL 参数取舍，还配合 Vivado implementation directive：

- `opt_design -directive ExploreArea`
- `route_design -directive AdvancedSkewModeling`

该组合在当前工程中取得较好的资源和时序平衡，使候选达到 9965 LUT 和 50 MHz
post-route timing closure。

答辩重点：

“我们没有把 Vivado directive 当作黑盒玄学，而是把它作为 RTL timing-safe 配置后的
实现收敛手段。候选是否可报告，最终仍以 post-route report 为准。”

### 7.6 亮点六：证据驱动的候选冻结机制

项目中历史上出现过更高 CoreMark/MHz 的探索结果，但只要对应配置无法通过 strict 50 MHz
synthesis/implementation timing，就不作为主候选。当前 `impl220` 的价值在于它同时满足：

- strict sync-BRAM 口径。
- CoreMark 核心算法未修改。
- 50 MHz post-route timing closed。
- 资源低于当前阶段可接受范围。
- 有 CoreMark、Dhrystone xsim、应用 demo xsim、bitstream 归档和复核脚本。

## 8. 时序问题定位与解决思路

### 8.1 原始问题

最核心的时序风险来自前端 PC 选择路径。MEM/DCache/load-use、redirect-cache、
branch/BHT 更新和 IF/ID 控制如果在同一周期强组合耦合，就会形成多级组合逻辑。
历史审计中已经观察到从 MEM 地址/访存状态到 PC 寄存器输入的长路径问题。

### 8.2 为什么这条路径难

这条路径同时具有三类困难：

| 困难 | 说明 |
|---|---|
| 逻辑扇入大 | 多个控制源同时争夺 PC 选择权 |
| 跨流水级 | MEM 状态影响 IF，路径跨越多个阶段概念边界 |
| 性能诱惑强 | 直接同周期使用这些信号可能减少停顿，提高 fast score |

因此，单纯“多试几个 Vivado directive”不够，必须先从 RTL 控制路径上减少同周期长组合依赖。

### 8.3 当前 `impl220` 的解决方式

当前候选采用的总体策略是：

1. 保留五级流水和基本前端优化能力。
2. 对 BHT、redirect-cache、fold/next-cache、DCache/load-use 等路径做参数化裁剪。
3. 避免 MEM 阶段状态直接放大到前端 PC 选择。
4. 使用 post-route timing 作为最终接受标准。
5. 使用白名单文档和脚本锁定证据边界。

### 8.4 PPT 讲法

“这个项目的难点不是 CPU 能不能跑 benchmark，而是在真实 FPGA 同步 BRAM 和
50 MHz 约束下，哪些性能优化可以保留，哪些同周期路径必须收敛。我们的 `impl220`
就是在这个边界上做出的工程化取舍。”

## 9. 当前实验结果

### 9.1 主结果表

| 项目 | 结果 | 证据 |
|---|---:|---|
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | `FREEZE_STRICT50_IMPL220_20260701.md` |
| Slice LUT | 9965 | `impl220.../reports_cpu50/impl_utilization.rpt` |
| Slice FF | 6520 | `impl220.../reports_cpu50/impl_utilization.rpt` |
| BRAM Tile | 32 | `impl220.../reports_cpu50/impl_utilization.rpt` |
| DSP | 8 | `impl220.../reports_cpu50/impl_utilization.rpt` |
| CPU clock | 50 MHz | timing constraint/report |
| WNS | +0.056 ns | `impl220.../reports_cpu50/impl_timing_summary.rpt` |
| WHS | +0.121 ns | `impl220.../reports_cpu50/impl_timing_summary.rpt` |
| CoreMark/MHz | 4.287521 | `fast210.../coremark50_fast_gate_iter10.summary.txt` |
| CoreMark CRC | `0xfcaf` | `fast210...summary.txt` |
| Dhrystone | 2.495618 DMIPS/MHz xsim | `sim220_dhrystone_impl220_strict50_match/` |

### 9.2 复核命令

```powershell
powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/verify_strict50_impl220_metrics.ps1
```

期望结果：

```text
verification_status=PASS
timing_closed=True
lut=9965
coremark_per_mhz=4.287521
wns_ns=0.056
whs_ns=0.121
```

### 9.3 当前不可写成的结果

| 不能写 | 原因 |
|---|---|
| `impl220` 已上板验证通过 | PROGRAM_OK、UART raw log、视频未补齐 |
| `impl220` 板级 DMIPS/MHz | 当前 DMIPS 是 xsim evidence |
| 官方 EEMBC 10 秒 CoreMark | 当前是工程 short-gate |
| `fast201` 4.569338 是当前候选 | 对应配置 timing failed |
| 旧初赛 board-proven 口径代表当前 strict50 | 旧 bitstream/旧材料，不是 `impl220` |

## 10. 应用演示程序说明

赛题要求不仅要有 benchmark，也要有相关程序体现处理器能力。当前 strict50 线已经补充
应用演示 xsim 证据：`strict50_perf_demo_20260702/`。

### 10.1 demo 覆盖内容

perf demo 不是 CoreMark 替代品，而是面向展示的综合 workload。它覆盖：

| 模块 | 展示能力 |
|---|---|
| CRC32 | 整数逻辑、循环、数据相关 |
| MATMUL8 | 算术、嵌套循环、访存局部性 |
| MEMCPYFILL | load/store、顺序访存、内存写入 |
| BRANCH | 分支跳转和控制流 |
| LOADUSE | load-use hazard 处理能力 |

当前 xsim 输出中包含：

```text
PERF_DEMO PASS checksum=0xe727358b
```

### 10.2 PPT 讲法

“除了 CoreMark 和 Dhrystone，我们准备了一个面向演示的综合程序，覆盖 CRC、矩阵、
内存搬移、分支和 load-use 场景。当前该 demo 已有 strict50 `impl220` 匹配参数的
xsim 证据；后续上板时会使用同一 bitstream 采集 UART 和视频。”

### 10.3 演示材料边界

- 可以写：应用 demo xsim 已通过。
- 可以写：后续可用于上板 UART/视频演示。
- 不能写：应用 demo 已经板级演示完成。

## 11. 建议 PPT 详细大纲

下面给出 20 页 PPT 的完整内容母稿。实际答辩时间短时，可以按第 12 节压缩。

### 第 1 页：标题页

标题建议：

`面向 PYNQ-Z2 的 strict 50 MHz RV32 五级流水 RISC-V CPU`

画面内容：

- 项目名称。
- 团队/学校/成员信息。
- 一行主指标：`9965 LUT / 4.287521 CoreMark/MHz / 50 MHz / WNS +0.056 ns`。
- 页脚标注：`post-route timing-closed engineering candidate; board evidence pending`。

讲稿：

“各位老师好，我们汇报的是一款面向 PYNQ-Z2 FPGA 平台的自研 RV32 五级流水
RISC-V CPU。当前 strict50 工程候选已经完成 50 MHz post-route 时序闭合，并给出
CoreMark、Dhrystone xsim、资源和 timing report 证据。”

证据来源：

- `FREEZE_STRICT50_IMPL220_20260701.md`
- `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md`

### 第 2 页：赛题要求与当前状态

画面内容：

| 赛题要求 | 当前状态 |
|---|---|
| RV32/RV64 基础 ISA | 当前验证 RV32 |
| 五级流水 | IF/ID/EX/MEM/WB |
| 性能优化 | forwarding、branch/redirect、DCache/load-use、implementation directive |
| FPGA 时钟不低于 50 MHz | post-route WNS +0.056 ns |
| 性能量化 | CoreMark/MHz、DMIPS/MHz xsim |
| 相关程序演示 | perf demo xsim 已通过，上板证据待补 |

讲稿：

“我们按赛题要求把 CPU 设计、性能优化、时钟、资源和程序演示分别建立了证据链。
当前严格说法是：实现证据已经闭合，上板 PROGRAM_OK、UART、视频仍待补齐。”

证据来源：

- `REGION_REQUIREMENT_MATRIX_20260702.md`

### 第 3 页：作品总体架构

画面内容：

- 使用 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` 中五级流水图。
- 左侧：IF/ID/EX/MEM/WB。
- 上方：BHT/redirect-cache/fold 控制。
- 下方：forwarding/load-use/stall/flush。

讲稿：

“整体结构是经典五级流水，但为了让它在 FPGA 上有性能和可实现性，我们增加了
前递、load-use 处理、分支重定向和前端缓存类控制。后续优化也主要围绕这些控制路径展开。”

证据来源：

- `YH_rv_cpu/rtl`
- `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md`

### 第 4 页：IF 取指与 PC 选择

画面内容：

- PC 寄存器。
- 顺序 PC+4。
- 分支/跳转 redirect。
- redirect-cache/BHT/fold 输入。
- IF/ID stall/flush 控制。

讲稿：

“IF 阶段决定下一条取哪条指令。它直接影响性能，也容易成为时序热点，因为多个控制源
都会影响 PC 选择。我们的 strict50 优化重点之一，就是限制这些控制源在同一周期形成过长组合扇入。”

### 第 5 页：ID 译码与冒险检测

画面内容：

- 指令译码。
- 寄存器堆读。
- 立即数生成。
- forwarding 选择。
- load-use 检测。
- stall/flush 产生。

讲稿：

“ID 阶段不仅负责译码，也负责判断当前指令是否能继续推进。普通数据相关通过前递处理；
load-use 这种必须等待访存返回的情况，则由 hazard 逻辑暂停或重放，保证正确性。”

### 第 6 页：EX 执行与分支解析

画面内容：

- ALU。
- 比较器。
- branch target 计算。
- branch resolve。
- redirect 输出到 IF。

讲稿：

“EX 阶段给出 ALU 结果，也给出分支真实方向和目标地址。前端可以预测或缓存目标，
但最终都要由 EX 的真实结果纠正。”

### 第 7 页：MEM 访存与 strict BRAM

画面内容：

- DCache/BRAM 访问。
- load/store address。
- 同步 BRAM read latency。
- load-use 返回路径。

讲稿：

“MEM 阶段是 strict50 设计中最关键的位置之一。因为 FPGA BRAM 是同步读，访存状态
不能被当成零延迟信号随意接回前端。否则仿真看似更快，post-route timing 会失败。”

### 第 8 页：WB 回写与数据闭环

画面内容：

- ALU result。
- load data。
- PC+4。
- writeback mux。
- register file write port。

讲稿：

“WB 阶段完成寄存器堆写回，是数据通路闭环。配合前递网络，很多数据相关不必等到
真正写回后才继续执行，从而提升流水吞吐。”

### 第 9 页：性能优化总览

画面内容：

| 优化 | 作用 |
|---|---|
| 五级流水 | 指令重叠执行 |
| forwarding | 减少 RAW 停顿 |
| load-use 控制 | 正确处理访存数据相关 |
| branch redirect/BHT | 降低控制冒险损失 |
| redirect-cache/fold/next-cache | 改善前端取指连续性 |
| Vivado directive | 改善实现阶段收敛 |

讲稿：

“这里的优化不是单点，而是围绕流水吞吐、前端损失和 FPGA 实现收敛形成的一组组合。”

### 第 10 页：为什么高分配置不一定可报告

画面内容：

- 左侧：fast score 高。
- 中间：synthesis/implementation timing failed。
- 右侧：不能作为 FPGA 原型系统指标。

建议放一行：

`fast201: 4.569338 CoreMark/MHz, but synth224 WNS -11.786 ns -> rejected`

讲稿：

“我们把探索结果和可报告结果分开。高分配置如果无法闭合 strict 50 MHz timing，
就不能代表 FPGA 原型系统。当前主结果采用 post-route timing-closed 的 `impl220`。”

证据来源：

- `RESULTS_20260611.md`
- `REGION_DELIVERY_INDEX_20260702.md`

### 第 11 页：时序热点机制

画面内容：

- 使用 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` 中 timing hotspot 图。
- 高亮 MEM/DCache/load-use -> front-end PC select。
- 高亮 BHT/redirect-cache -> PC mux。

讲稿：

“最危险的路径来自多个控制源同周期汇入 PC 选择。MEM 阶段状态、load-use、redirect-cache
和 BHT 更新如果直接组合到 IF，会跨越多个流水阶段形成长路径。”

### 第 12 页：`impl220` 的时序优化策略

画面内容：

| 策略 | 解决问题 |
|---|---|
| BHT ID-update 可配置 | 降低 BHT CE 热点风险 |
| fold/next-cache 取舍 | 避免高分路径重新拉长 PC 选择 |
| DCache/load-use 扇入削减 | 减少 MEM 到 IF 的组合依赖 |
| ExploreArea + AdvancedSkewModeling | 改善实现阶段面积/时序平衡 |

讲稿：

“`impl220` 的核心不是盲目加资源，而是识别哪些优化会把同周期路径拉长，然后做参数化收敛。
实现阶段再通过 Vivado directive 辅助收敛。”

### 第 13 页：strict sync-BRAM 的合规价值

画面内容：

| 维度 | strict sync-BRAM |
|---|---|
| 存储模型 | 同步读延迟进入设计 |
| 性能数字 | 更保守 |
| 时序报告 | 可对齐 |
| 上板风险 | 更低 |

讲稿：

“这页要主动讲清楚：我们不用零延迟存储模型换取虚高分数。strict 口径让分数更难看一点，
但更能经得起实现和上板检查。”

### 第 14 页：当前主指标

画面内容：

大表格：

| LUT | FF | BRAM | DSP | CoreMark/MHz | DMIPS/MHz xsim | Clock | WNS/WHS |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 9965 | 6520 | 32 | 8 | 4.287521 | 2.495618 | 50 MHz | +0.056 / +0.121 ns |

讲稿：

“这是当前可以报告的主指标。它不是历史最好 fast score，而是当前 strict50
post-route timing-closed 工程候选。”

证据来源：

- `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md`
- `verify_strict50_impl220_metrics.ps1`

### 第 15 页：CoreMark 证据

画面内容：

- `CoreMark/MHz = 4.287521`
- `CRC = 0xfcaf`
- `acceptance_pass = yes`
- `strict_eembc_10s_compliant = no`

讲稿：

“CoreMark 核心算法文件没有修改。当前是工程 short-gate，用于同配置设计迭代和分赛区
材料，不声明为官方 EEMBC 10 秒认证结果。”

证据来源：

- `fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt`

### 第 16 页：Dhrystone 与 DMIPS

画面内容：

- `2.495618 DMIPS/MHz`
- `Dhrystones/s = 219240`
- `runs = 1000`
- 标注：`xsim host-parsed, not board UART result`

讲稿：

“DMIPS 已经按 `impl220` 同配置补了 Dhrystone xsim 证据。这里必须强调它是仿真证据，
不是板级 UART 结果；后续如果报告板级 DMIPS，需要重新采集同一 bitstream 的 UART log。”

证据来源：

- `STRICT50_DHRYSTONE_EVIDENCE_20260702.md`
- `sim220_dhrystone_impl220_strict50_match/`

### 第 17 页：应用演示程序

画面内容：

| demo 子项 | 覆盖能力 |
|---|---|
| CRC32 | 整数逻辑和循环 |
| MATMUL8 | 算术密集和访存 |
| MEMCPYFILL | load/store |
| BRANCH | 控制流 |
| LOADUSE | 冒险处理 |

底部：

`PERF_DEMO PASS checksum=0xe727358b`

讲稿：

“应用演示用于补充说明处理器不仅能跑 benchmark，还能执行覆盖算术、访存、分支和
load-use 的综合程序。当前已经有 xsim 证据，后续会补同一 bitstream 的 UART 和视频。”

证据来源：

- `STRICT50_APP_DEMO_EVIDENCE_20260702.md`
- `strict50_perf_demo_20260702/`

### 第 18 页：证据链和复现方式

画面内容：

- RTL/config -> implementation report -> CoreMark summary -> Dhrystone xsim ->
  app demo xsim -> bitstream/SHA256 -> pending board evidence。
- 使用 `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` 中 evidence chain 图。

讲稿：

“每个数字都有证据路径和脚本。打包脚本使用白名单，不包含 DCP、不包含旧提交材料目录、
不包含 CoreMark 核心算法修改证据。”

证据来源：

- `make_cicc_strict50_package.ps1`
- `CICC_STRICT50_PACKAGE_DRYRUN_20260702.md`

### 第 19 页：合规边界

画面内容：

建议直接列四条：

- CoreMark 核心算法未修改。
- 当前 CoreMark 是 short-gate，不是官方 EEMBC 10 秒。
- 当前 DMIPS 是 xsim，不是 board UART。
- 当前 `impl220` 尚未 board-proven，PROGRAM_OK/UART/video 待补。

讲稿：

“我们主动把边界讲清楚，避免把工程探索、仿真证据和板级证据混在一起。当前可报告的结论是
post-route timing-closed engineering candidate。”

### 第 20 页：总结与后续上板计划

画面内容：

总结三点：

1. 自研 RV32 五级流水 CPU，具备真实流水控制和性能优化结构。
2. strict sync-BRAM 口径下实现 50 MHz post-route timing closure。
3. 已归档 bitstream/SHA256，下一步补齐 PROGRAM_OK、UART、视频。

讲稿：

“总结来说，当前版本已经完成 strict50 的实现证据闭环，下一步不再更换候选，而是围绕
已归档 bitstream 补齐板级证据，使报告、PPT、bitstream、UART 和视频都绑定到同一版本。”

## 12. 不同时长 PPT 压缩方案

### 12.1 8-10 分钟完整答辩

使用 16-20 页：

1. 标题页。
2. 赛题要求。
3. 总体架构。
4. 五级流水细节。
5. strict sync-BRAM。
6. 性能优化总览。
7. 时序热点。
8. `impl220` 优化策略。
9. Vivado 实现流程。
10. 主指标。
11. CoreMark。
12. Dhrystone。
13. 应用 demo。
14. 证据链。
15. 合规边界。
16. 上板计划。

### 12.2 5 分钟答辩

压缩到 10 页：

1. 标题和主指标。
2. 赛题要求对照。
3. 总体架构。
4. 五级流水和冒险处理。
5. 时序热点。
6. 关键优化。
7. 实验结果。
8. 应用 demo。
9. 合规边界。
10. 总结与上板计划。

### 12.3 3 分钟快讲

压缩到 6 页：

1. 作品目标和主指标。
2. 架构图。
3. 时序难点。
4. 优化策略。
5. 实验结果。
6. 合规边界和后续补证。

## 13. 讲稿母版

### 13.1 3 分钟讲稿

各位老师好，我们的作品是一款面向 PYNQ-Z2 FPGA 平台的自研 RV32 五级流水
RISC-V CPU。处理器采用 IF、ID、EX、MEM、WB 五级流水结构，支持寄存器读写、
ALU 运算、访存、分支跳转、数据前递、load-use 处理、分支重定向以及 DCache/BRAM
访问控制。

本轮分赛区材料的主结果是 `impl220` strict 50 MHz 工程候选。该候选在 PYNQ-Z2
post-route implementation 下达到 9965 LUT、6520 FF、32 BRAM Tile、8 DSP；
CoreMark/MHz 为 4.287521；同配置 Dhrystone xsim 为 2.495618 DMIPS/MHz。
在 50 MHz 约束下，Vivado timing report 给出 WNS +0.056 ns、WHS +0.121 ns，
说明当前实现已经完成 post-route 时序闭合。

这个项目的关键难点不是单纯跑通 benchmark，而是在严格同步 BRAM 和 50 MHz FPGA
实现约束下保持性能。FPGA BRAM 是同步读资源，如果在仿真中忽略读延迟，会得到更高但
不可实现的分数。因此我们采用 strict sync-BRAM 口径，把存储延迟纳入 RTL 和 timing。

时序优化的重点是前端 PC 选择路径。历史探索中，MEM/DCache/load-use、redirect-cache、
BHT 更新和 IF 控制容易在同一周期形成长组合扇入，导致 50 MHz 难以闭合。当前 `impl220`
通过 BHT ID-update 可配置化、redirect/fold/next-cache 路径取舍、DCache/load-use
扇入削减，以及 Vivado ExploreArea 和 AdvancedSkewModeling 组合，实现了性能和时序的平衡。

合规方面，我们没有修改 CoreMark 核心算法文件。当前 CoreMark 是工程 short-gate，
不声明为官方 EEMBC 10 秒结果；当前 DMIPS 是同配置 xsim，不声明为板级 UART 结果。
`impl220` bitstream 和 SHA256 已经归档，但 PROGRAM_OK、UART raw log 和视频证据仍待补齐，
因此当前严格表述为 post-route timing-closed engineering candidate。

### 13.2 1 分钟讲稿

我们的作品是在 PYNQ-Z2 上实现的一款自研 RV32 五级流水 RISC-V CPU。当前 `impl220`
strict50 工程候选达到 9965 LUT、4.287521 CoreMark/MHz、2.495618 DMIPS/MHz xsim，
并在 50 MHz post-route implementation 下取得 WNS +0.056 ns、WHS +0.121 ns。

设计亮点是把性能优化和 FPGA 可实现性一起考虑：我们坚持 strict sync-BRAM 口径，
不使用零延迟存储模型换取虚高分数；同时围绕 BHT、redirect/fold、DCache/load-use 和
PC 选择长路径做参数化收敛，使高风险同周期组合扇入得到控制。

当前没有修改 CoreMark 核心算法文件。bitstream 和 SHA256 已归档，后续需要基于同一
bitstream 补齐 PROGRAM_OK、UART raw log 和视频证据，才能提升为 board-proven 结果。

## 14. 评委可能追问与答法

| 问题 | 建议回答 |
|---|---|
| 为什么 CoreMark/MHz 不是历史最高？ | 历史更高分配置没有闭合 strict 50 MHz timing，不能作为 FPGA 原型系统主结果；当前报告采用 post-route timing-closed 的 `impl220`。 |
| strict sync-BRAM 为什么重要？ | FPGA BRAM 是同步读资源，忽略延迟会让仿真分数偏乐观；strict 口径保证 RTL、timing report 和后续上板行为一致。 |
| 有没有修改 CoreMark？ | 没有修改 CoreMark 核心算法文件，优化集中在 RTL、参数配置和 Vivado 实现流程。 |
| 当前是否已经上板？ | 不能这样说。当前 bitstream/SHA256 已归档，PROGRAM_OK、UART raw log、视频待补，因此是 post-route timing-closed engineering candidate。 |
| DMIPS 是板级结果吗？ | 不是。当前 2.495618 DMIPS/MHz 来自 `impl220` 同配置 Dhrystone xsim；板级 DMIPS 需要同一 bitstream 的 UART raw log。 |
| LUT 接近 1 万是否可接受？ | 当前阶段优先满足 strict 50 MHz 和 CoreMark 口径。资源为 9965 LUT，低于此前设定的阶段性 10000 LUT 附近目标，也低于后续放宽的 15000 LUT 上限。 |
| 最大技术难点是什么？ | 前端 PC 选择的长组合路径，尤其是 MEM/DCache/load-use、redirect-cache、BHT 更新和 IF 控制同周期扇入。 |
| 应用程序体现了什么？ | perf demo 覆盖 CRC32、矩阵、内存搬移、分支和 load-use，展示 CPU 对算术、访存和控制流程序的执行能力。 |

## 15. PPT 可直接复制的短句

### 15.1 标题短句

- 自研 RV32 五级流水 RISC-V CPU
- strict sync-BRAM 口径下的 50 MHz FPGA 实现
- post-route timing-closed engineering candidate
- 不修改 CoreMark 核心算法的硬件优化
- 面向 PYNQ-Z2 的可复核实现证据链

### 15.2 技术亮点短句

- 五级流水将取指、译码、执行、访存和写回分离，提高指令吞吐。
- forwarding 和 load-use 控制共同处理数据冒险，减少无谓停顿。
- branch redirect、BHT 和 redirect-cache 改善控制流 workload 的前端效率。
- strict sync-BRAM 让存储延迟真实进入 RTL 和 post-route timing。
- `impl220` 通过减少 MEM/DCache 到 PC 选择的同周期组合扇入实现时序收敛。
- Vivado ExploreArea 与 AdvancedSkewModeling 用于辅助实现阶段收敛。
- 高分但 timing failed 的探索结果只保留为审计记录，不作为当前候选。

### 15.3 合规短句

- CoreMark 核心算法文件未修改。
- 当前 CoreMark 为工程 short-gate，不是官方 EEMBC 10 秒认证结果。
- 当前 DMIPS/MHz 为同配置 xsim evidence，不是板级 UART evidence。
- 当前 `impl220` 尚未 board-proven，PROGRAM_OK、UART 和视频证据待补。

## 16. 证据路径速查

| 需要证明 | 文件/命令 |
|---|---|
| 当前主指标 | `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md` |
| 自动验证指标 | `verify_strict50_impl220_metrics.ps1` |
| 赛题要求对照 | `REGION_REQUIREMENT_MATRIX_20260702.md` |
| 架构图 | `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` |
| 技术报告正文 | `REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md` |
| PPT 分镜 | `REGION_PPT_STORYBOARD_STRICT50_20260702.md` |
| 现场讲稿 | `REGION_DEFENSE_SPEAKER_SCRIPT_STRICT50_20260702.md` |
| 现场 QA | `REGION_DEFENSE_QA_STRICT50_20260702.md` |
| CoreMark summary | `fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt` |
| Dhrystone xsim | `sim220_dhrystone_impl220_strict50_match/` |
| 应用 demo xsim | `strict50_perf_demo_20260702/` |
| bitstream/SHA256 | `board_impl220_bitstream_20260702/` |
| board evidence audit | `audit_strict50_board_evidence.ps1` |
| 打包脚本 | `make_cicc_strict50_package.ps1` |

## 17. 当前文档结论

分赛区材料已经开始写，并且已经具备报告、PPT、讲稿、QA、证据矩阵、架构图、
应用 demo 证据和打包脚本。本文档进一步补齐“作品详细介绍 + PPT 内容母稿”这一层，
后续制作 PPT 时可以直接从第 11 节拆页，从第 13 节抽讲稿，从第 14 节准备问答。

下一步如果要把材料推进到可最终提交，需要继续完成：

| 优先级 | 任务 | 完成标准 |
|---|---|---|
| P0 | 按本文制作/润色最终 PPT | PPT 只使用 `impl220` strict50 当前口径 |
| P0 | 上板 PROGRAM_OK | 证据能绑定 `board_impl220_bitstream_20260702` 中的 bitstream |
| P0 | UART raw log | CoreMark/demo/Dhrystone workload 与当前 bitstream 一致 |
| P0 | 视频证据 | 板卡、下载过程、UART 输出可见 |
| P1 | 技术报告排版 | PDF/DOCX 中边界和指标口径一致 |
| P1 | 最终打包审计 | package dry-run、board audit、metric verify 全部通过 |
