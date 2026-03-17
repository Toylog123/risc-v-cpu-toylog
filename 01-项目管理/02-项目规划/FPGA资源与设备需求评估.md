# FPGA 资源与设备需求评估

> 更新时间：`2026-03-16`
> 适用项目：七星微赛题 `YH_rv_cpu`

## 1. 当前结论

- 当前项目没有现成 FPGA 板卡，下一次和老师沟通时，应该明确提出板卡和调试资源需求。
- 从项目路线看，我们当前不需要 DDR、Linux 或复杂外设，优先选择 `Artix-7` 纯 FPGA 板卡更稳。
- 当前建议的主申请板卡是 `Digilent Nexys A7-100T`。
- 如果经费较紧，可以把 `Basys 3` 作为预算压缩方案，但它不应作为首选。

## 2. 为什么优先申请 `Nexys A7-100T`

### 2.1 与当前项目匹配

- 当前 `YH_rv_cpu` 已有最小 SoC、`UART`、`timer`、`trap` 和 `RV32 / RV64` 共线骨架。
- 当前 FPGA 演示目标是：
  - 串口启动信息
  - 定时器中断
  - 后续的 `CoreMark`
- 这一路线不依赖 PS 侧 ARM，也不依赖 DDR。
- 直接上 `Artix-7` 纯 FPGA 板卡，工程边界更清晰，比赛叙事也更干净。

### 2.2 对上板更友好

- `Nexys A7-100T` 自带 `100MHz` 时钟、`UART/JTAG`、LED、按键，足够支撑当前最小上板闭环。
- Digilent 有公开的参考手册和 Master XDC，后续约束和演示流程更容易标准化。
- 比起 Zynq 板卡，少一层 PS/PL 依赖，队伍当前阶段更适合。

## 3. 当前推荐申请清单

### 3.1 最低可开工配置

| 资源 | 数量 | 用途 | 备注 |
|------|------|------|------|
| `Nexys A7-100T` | `1` | 主开发板 | 最低配置 |
| USB A to Micro-B 线 | `2` | 下载、串口、备用 | 一根工作，一根备份 |
| 稳定供电环境 | `1` | 长时间综合后上板 | 可先用 USB 供电 |

### 3.2 更合理的比赛配置

| 资源 | 数量 | 用途 | 备注 |
|------|------|------|------|
| `Nexys A7-100T` | `2` | 主板 + 备用板 / 并行调试 | 推荐配置 |
| USB A to Micro-B 线 | `3` | 下载、串口、备用 | 避免线材成为阻塞 |
| 逻辑分析/串口观察能力 | `1` | 排查板级问题 | 可由现有仪器替代 |

## 4. 预算粗估

### 4.1 公开价格参考

- Digilent 官网当前 `Nexys A7` 页面显示零售价约为 `$349`。
- Digilent 的 Academic Price 文档给出的 `Nexys A7-100T` 学术价约为 `$224.25`。
- Digilent 的 Academic Price 文档给出的 `Basys 3` 学术价约为 `$111.75`。

### 4.2 会议上建议怎么提

- 如果按最低可开工配置申请：
  - `1` 块 `Nexys A7-100T`
  - `2` 根 USB 线
  - 预算可按 `250 ~ 400 USD` 或等值人民币预估
- 如果按更稳妥的比赛配置申请：
  - `2` 块 `Nexys A7-100T`
  - `3` 根 USB 线
  - 预算可按 `500 ~ 800 USD` 或等值人民币预估

## 5. 当前设计对 FPGA 资源的大致需求

> 这部分应以综合报告为准。当前仓库已补了 Vivado 综合脚本，后续可直接用本地综合结果更新本节。

当前模块构成：

- 五级流水 CPU
- 寄存器堆、ALU、hazard/forwarding
- 最小 `CSR / trap / timer interrupt`
- 最小 SoC
  - `ROM`
  - `RAM`
  - `UART`
  - `DONE`
  - `timer`

从结构复杂度判断：

- 当前更像“小中型教学/竞赛 CPU SoC”，而不是高端乱序核
- 对 `Artix-7 100T` 级别板卡，资源压力预计可控
- 对 `Basys 3` 这类更小板卡，是否足够要看综合结果和后续 `CoreMark/调试逻辑` 加入后的增量

### 5.1 当前已经验证到的 FPGA 结论

- Vivado 本地工程脚手架已建立，统一落到根目录 `project/`
- 当前综合评估使用的是 `xc7a100tcsg324-1`
- 之前阻塞综合的关键问题是 `YH_rv_cpu_soc` 的 RAM 写法不适合 FPGA 推断
- 该问题已经被收敛，Vivado 日志里原先的 RAM 推断报错已经消失
- 综合脚本现在会自动临时映射 ASCII 盘符，规避中文路径导致的 Vivado 退出问题
- 当前本地综合会优先挂接 `build/tests/riscv-tests/rv32/simple.hex`，并用 `ROM/RAM = 8KB/8KB` 做资源估算
- 当前已经能稳定导出：
  - `project/reports/synth_utilization.rpt`
  - `project/reports/synth_timing_summary.rpt`
  - `project/YH_rv_cpu_nexys_a7_100_synth.dcp`

### 5.2 当前第一版综合结果

- 综合器件：`xc7a100tcsg324-1`
- 资源结果：
  - `Slice LUTs = 3445`，约 `5.43%`
  - `Slice Registers = 1962`，约 `1.55%`
  - `LUT as Memory = 1024`
  - `BRAM = 0`
  - `DSP = 0`
- 原语统计：
  - `FDCE = 1884`
  - `LUT6 = 1342`
  - `RAMS64E = 1024`
  - `CARRY4 = 90`
- 当前实现说明：
  - `ROM` 还是 LUT 形式
  - `RAM` 当前被推成分布式存储
  - 这说明当前资源量还不是最终优化形态，后续把 `RAM/ROM` 往 BRAM 方向收，会继续下降

### 5.3 当前时序结论

- 当前约束时钟：`sys_clk = 100MHz`
- 当前综合时序结果：
  - `WNS = -2.405ns`
  - `TNS = -1284.798ns`
  - `728` 个 failing endpoints
- 当前结论不是“板子不够”，而是“100MHz 这档时序还没收敛”
- 按当前报告推算，现阶段离 `100MHz` 还有明显差距，但对赛题要求的 `50MHz` 目标仍有较大把握
- 当前模板 `XDC` 还存在：
  - `no_input_delay(1)`
  - `no_output_delay(4)`
  - 这意味着板级正式约束还没有冻结，当前报告更适合做资源和频率趋势判断

### 5.4 这意味着什么

- 现在申请板卡时，可以明确说项目已经进入 FPGA 综合阶段，不是纯文档准备阶段
- 当前更像“时序优化和正式约束还在收尾”，而不是“工程还没开始建”
- 这能支撑我们在会上提出板卡需求，而不是停留在概念讨论
- 从资源角度看，`Nexys A7-100T` 明显足够，甚至不是被资源逼到上限
- 从工程风险角度看，当前真正的重点是：
  - 板卡尽快到位
  - 正式 `XDC` 冻结
  - 时序收敛
  - 上板串口演示

## 6. 当前建议向老师直接提出的说法

可以直接按下面这个口径说：

> 我们当前已经把 CPU 和最小 SoC 跑通，下一阶段必须进入 FPGA 上板闭环。  
> 这条路线不需要 DDR 和 ARM 侧软件，优先申请一块 `Artix-7` 纯 FPGA 开发板更合适。  
> 推荐申请 `Nexys A7-100T`，因为它资源更稳、资料齐、XDC 和参考文档完整，适合我们做七星微赛题的 UART 演示和后续 `CoreMark`。  
> 如果经费允许，最好是 `2` 块，一块主板一块备用；如果只能先批一块，也建议先批 `1` 块 `Nexys A7-100T` 让项目真正进入板级阶段。

## 7. 备选方案

### 7.1 预算压缩方案

- `Basys 3`
- 优点：价格更低、资料多、入门快
- 风险：后续留给 `RV64`、调试逻辑、性能测评的余量更紧

### 7.2 不建议当前优先申请的方案

- `Zybo / ZedBoard / PYNQ-Z2`
- 原因：这些板子更适合 PS/PL 协同路线
- 当前项目主线是自写 RISC-V CPU + 纯 FPGA 闭环，先上纯 FPGA 板卡更直接

## 8. 本文档后续怎么更新

- 下一步不再是“有没有综合结果”，而是继续更新：
  - 100MHz 时序优化前后的对比
  - `RAM/ROM` 往 BRAM 迁移后的资源变化
  - 正式板卡 `XDC` 冻结后的报告
- 一旦老师确认板卡，立刻把“建议板卡”改成“已确定板卡”
- 一旦拿到板卡，把正式 XDC 来源、bitstream 结果和串口演示日志补进来

## 2026-03-17 最新综合更新

- 当前报告入口改成双档目录：
  - `project/reports/clk_10p000ns/synth_utilization.rpt`
  - `project/reports/clk_10p000ns/synth_timing_summary.rpt`
  - `project/reports/clk_20p000ns/synth_utilization.rpt`
  - `project/reports/clk_20p000ns/synth_timing_summary.rpt`
- 当前检查点：
  - `project/YH_rv_cpu_nexys_a7_100_10p000_synth.dcp`
  - `project/YH_rv_cpu_nexys_a7_100_20p000_synth.dcp`
- 最新综合结论：
  - `100MHz`：`3450 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.487ns`
  - `50MHz`：`3424 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.525ns`
- 这意味着：
  - 资源仍然不是当前主风险
  - 比赛要求的 `50MHz` 已经有明确综合余量
  - 后续设备申请口径可以更明确地说成“需要板卡推进上板与正式约束”，而不是“先证明能不能综合”
- 另外补一条对会前讨论很重要的判断：
  - 当前 `BRAM = 0` 不是单纯因为约束或属性没写对
  - 更根本的原因是当前 `ROM/RAM` 仍采用零等待、组合读出的 SoC 接口
  - 所以后续如果要把存储改成更像正式 FPGA 方案，必须先接受同步读和一拍返回带来的接口变化
## 2026-03-17 同步取指更新

- 这轮 FPGA 口径已经进一步推进到“同步取指已接入”：
  - `rtl/YH_rv_cpu.v`
  - `rtl/YH_rv_cpu_soc.v`
  - `rtl/YH_rv_sync_imem_rom.v`
- 脚本链路现在会额外生成 `mem32` 镜像，Vivado 可直接挂接：
  - `build/tests/riscv-tests/current.hex`
  - `build/tests/riscv-tests/current.mem32.hex`
- 最新综合结果：
  - `100MHz`：`4086 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.468ns`
  - `50MHz`：`4061 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.548ns`
- 这说明：
  - 比赛要求的 `50MHz` 口径依然稳定
  - 同步取指本身没有破坏工程闭环
  - 但 `BRAM` 依旧没有出来，后续设备申请和会前汇报里仍应把“存储结构继续优化”作为明确工作项
## 2026-03-17 追加：同步 dmem 路径后的综合结果

- 本轮改动后，FPGA 顶层已经切到同步 `dmem` 路线，综合数字需要以这一版为准。
- `50MHz`
  - `Slice LUTs = 3692`
  - `Slice Registers = 2069`
  - `LUT as Memory = 1024`
  - `BRAM = 0`
  - `DSP = 0`
  - `WNS = 7.553ns`
- `100MHz`
  - `Slice LUTs = 3713`
  - `Slice Registers = 2066`
  - `LUT as Memory = 1024`
  - `BRAM = 0`
  - `DSP = 0`
  - `WNS = -2.475ns`
- 当前判断：
  - 板卡资源仍然足够，不是当前主风险
  - 风险仍在于 `100MHz` 时序和 `BRAM` 还没推出来
  - 因此向老师提需求时，重点仍应放在“有一块稳定可用的 7 系列 FPGA 板卡”，而不是担心资源装不下
