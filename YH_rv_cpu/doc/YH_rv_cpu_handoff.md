# YH_rv_cpu 交接说明

## 交接规则

- 只要修改了 `YH_rv_cpu` 的 RTL、脚本、验证或文档，就同步更新本文件、`YH_rv_cpu_change_log.md` 和 `YH_rv_cpu_todo.md`。
- 结论以当前仓库文件和脚本实测结果为准，不靠口头状态。
- 默认同步范围是 `YH_rv_cpu`、`04-工具链`、`01-项目管理`。
- 默认交接完成后继续执行 `commit + push`，除非明确说明这次只保留本地、不推远端。

## 当前状态

- 日期：`2026-03-16`
- 正式工程名：`YH_rv_cpu`
- 当前验证基线：自写 `RV32I + Zicsr` 五级流水
- 当前目标架构：向 `RV32 / RV64` 共线推进
- 当前 SoC 状态：最小 SoC 已打通，可通过 UART 输出 `YH_rv_cpu boot`
- 当前 Vivado 状态：本地综合链已打通，资源/时序报告可导出到根目录 `project/reports/`
- 当前整体设计总入口：`doc/技术文档.md`

## 已完成能力

- 五级流水结构：`IF / ID / EX / MEM / WB`
- 关键数据通路 `XLEN` 参数化骨架
- 基础前递：`EX/MEM`、`MEM/WB`
- 基础 `load-use` 暂停
- 分支和跳转重定向
- 最小机器态 `CSR / trap`
  - `mstatus`
  - `mie`
  - `mip`
  - `mtvec`
  - `mscratch`
  - `mepc`
  - `mcause`
  - `csrrw/csrrs/csrrc`
  - `ecall / ebreak / mret`
- machine timer interrupt 最小闭环
- `XLEN=64` 基础烟测
- 最小 SoC
  - `ROM`
  - `RAM`
  - `UART`
  - `DONE`
  - `timer`

## 当前验证结果

- `scripts/check_syntax.bat`：通过
- `scripts/build_firmware.bat`：通过
- `scripts/run_soc_smoke.bat`：通过
- `scripts/run_trap_smoke.bat`：通过
- `scripts/run_timer_irq_smoke.bat`：通过
- `scripts/run_xlen64_smoke.bat`：通过
- `scripts/run_riscv_tests_subset.bat rv32 add`：通过
- `scripts/build_vivado_project.bat synth`：通过

关键结果：

- `PASS: SoC smoke test completed at PC=00000038 in 102 cycles`
- `PASS: trap smoke test completed at PC=000000ac in 79 cycles`
- `PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`
- `PASS: xlen64 smoke test completed at PC=0000000000000020 in 17 cycles`
- `PASS: riscv-tests finished at PC=0000059c in 495 cycles with tohost=1`
- Vivado 综合结果：`Slice LUTs = 3445`，`Slice Registers = 1962`，`LUT as Memory = 1024`
- Vivado 时序结果：`sys_clk = 100MHz` 时 `WNS = -2.405ns`

## 当前缺口

- `RV64` 指令级扩展和专门验证还没落地
- `riscv-tests` 还没扩大到更高覆盖率
- `CoreMark` 还没接稳
- 正式板卡约束还没建
- FPGA 上板记录还没有形成
- 100MHz 时序还没收敛，当前需要继续做时序优化

## 现在最值得继续做的事

1. 在 `XLEN` 骨架和 `xlen64` 烟测基础上继续补 `RV64` 译码、访存和相关语义。
2. 接 `riscv-tests`，形成第一版回归。
3. 接 `CoreMark`，形成可复现跑分链路。
4. 继续做时序收敛，并准备正式板卡 `XDC`。

## 关键文件

- CPU 顶层：`rtl/YH_rv_cpu.v`
- SoC 顶层：`rtl/YH_rv_cpu_soc.v`
- 总技术文档：`doc/技术文档.md`
- 初步设计：`doc/YH_rv_cpu_preliminary_design.md`
- 修改记录：`doc/YH_rv_cpu_change_log.md`
- 任务清单：`doc/YH_rv_cpu_todo.md`
- FPGA 说明：`fpga/vivado/README.md`

## 接手顺序

1. `../../01-项目管理/03-过程管理/工作交接.md`
2. `../../01-项目管理/03-过程管理/任务清单.md`
3. `../../README.md`
4. `README.md`
5. `doc/技术文档.md`
6. `doc/YH_rv_cpu_preliminary_design.md`
7. `doc/YH_rv_cpu_change_log.md`
8. `doc/YH_rv_cpu_todo.md`

## 2026-03-17 最新补充

- Vivado 综合现在按双档口径输出：
  - `100MHz`：`project/reports/clk_10p000ns`
  - `50MHz`：`project/reports/clk_20p000ns`
- 最新结果覆盖此前那版单一 100MHz 结论：
  - `100MHz`：`3450 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.487ns`
  - `50MHz`：`3424 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.525ns`
- 当前最重要的判断：
  - 比赛要求的 `50MHz` 已经有综合余量
  - 后续 FPGA 主任务变成“继续收敛 100MHz + 推进 BRAM 化 + 等板卡到位后冻结正式 XDC”
- 这一天额外试过一轮“拆流水寄存器使能链”的 RTL 方向，但 100MHz 最差结果一度变到 `-3.139ns`，说明这条小修方向收益不够，已经回退，不在主线上保留
- 当前对 BRAM 的真实结论是：
  - 现在的 `ROM/RAM` 之所以还是 LUT / distributed RAM，不是单纯属性没写对
  - 根因是当前 SoC 还采用零等待、组合读出的存储接口
  - 后续要上 BRAM，先改 `imem/dmem` 的同步返回语义，再改底层存储实现
## 2026-03-17 继续推进：同步取指已接入主线

- 这轮已经把同步指令存储接口接入主线：
  - `rtl/YH_rv_cpu.v` 增加了 `IMEM_SYNC` 和 `imem_rvalid`
  - `rtl/YH_rv_cpu_soc.v` 增加了同步取指路径
  - 新增 `rtl/YH_rv_sync_imem_rom.v`
- 当前仿真回归仍然通过：
  - `run_soc_smoke.bat`
  - `run_trap_smoke.bat`
  - `run_timer_irq_smoke.bat`
  - `run_xlen64_smoke.bat`
  - `run_riscv_tests_subset.bat rv32 add`
  - `run_riscv_tests_subset.bat rv32`
- Vivado 现在已经能正确绑定 `current.mem32.hex`，不再是空参数。
- 最新综合结果覆盖此前那版口径：
  - `100MHz`：`4086 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.468ns`
  - `50MHz`：`4061 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.548ns`
- 当前新的真实结论：
  - 同步取指已经不是待设计事项，而是已落地事项
  - 但数据侧和只读数据访问仍沿用原 SoC 存储语义，所以 `BRAM` 还没有被真正推出来
  - 下一步最值的是推进 `dmem` 同步返回语义和独立存储包装层
  - 当前默认 `rv32` 回归子集已经整组通过，可以作为新的功能基线

## 2026-03-17 回归基线补充

- 当前 `run_riscv_tests_subset.bat rv32` 默认子集已经整组通过。
- 这意味着当前 `RV32I + Zicsr` 的主线不再只是“单个 add 用例通过”，而是已经有一组更完整的整数指令回归基线。
- 脚本现在会在每次运行后生成摘要文件：
  - `build/tests/riscv-tests/rv32/summary.txt`
- 后续交接时，如果要先确认功能基线，优先看这个摘要文件和对应日志目录。
## 2026-03-17 当前解读

### 一句话结论

`YH_rv_cpu` 现在已经不是“只有五级流水 CPU 骨架”的阶段，而是已经进入“同步取指开始落地、验证链稳定、FPGA 综合口径清楚，但存储结构还需要继续收口”的阶段。

### 当前真实状态

- CPU/SoC 主线是稳定的。
- `SoC smoke`、`trap smoke`、`timer irq smoke`、`xlen64 smoke`、`riscv-tests rv32 add` 这几条基础回归都通过。
- FPGA 综合链已经稳定，Vivado 可以直接吃当前测试镜像：
  - `current.hex`
  - `current.mem32.hex`
- 同步取指已经接入主线，不再只是文档上的后续计划。

### 现在应该怎么理解综合结果

- `50MHz` 口径已经稳，当前可以作为比赛阶段的可交付频率口径。
- `100MHz` 仍未收敛，但没有继续恶化到不可控状态，仍然是“优化目标”，不是“当前必须马上达成的门槛”。
- 最新综合结果以当前测试镜像口径为准：
  - `100MHz`：`4086 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.468ns`
  - `50MHz`：`4061 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.548ns`

### 对 BRAM 结果的正确解读

- 现在 `BRAM = 0`，不能解读成“同步取指没接上”。
- 更准确的解读是：
  - `imem` 的同步返回已经接上了
  - 但 SoC 里旧的 ROM 数据访问语义还在
  - `dmem` 侧仍是零等待、组合读返回
  - 因此工具仍然更倾向把相关存储实现成 LUT / distributed RAM
- 也就是说，当前问题已经从“能不能接同步取指”变成了“怎么把整套存储语义继续推进到真正适合 BRAM 的结构”。

### 现在最值得继续做的事

1. 先推进 `dmem` 的同步返回语义。
2. 把 `imem/dmem` 拆成独立的存储包装层。
3. 再评估双口 `ROM` 或单独的只读数据访问路径。
4. 在此基础上继续推进 `BRAM` 推断和 `100MHz` 时序收敛。

### 不要误判的地方

- 不要把“`100MHz` 还没过”误判成“FPGA 路线卡死”。
- 不要把“`BRAM = 0`”误判成“同步取指没有意义”。
- 不要再回到只做小范围 `flush/stall/CE` 试探的路线，那条线已经验证过收益有限。
## 2026-03-17 同步 dmem 已接入主线

- 这轮的核心变化不是新功能堆叠，而是把数据访存语义往 FPGA 友好的方向推进了一步。
- 当前已经落地：
  - `YH_rv_cpu` 支持 `DMEM_SYNC`
  - `YH_rv_cpu_mem_stage` 会显式给出 `dmem_read_req`
  - `YH_rv_cpu_soc` 在 `SYNC_DMEM=1` 时提供一拍延迟的读返回
  - SoC smoke、trap、timer irq、FPGA top 都已经切到同步数据路径
- 当前通过的验证：
  - `run_soc_smoke.bat`
  - `run_trap_smoke.bat`
  - `run_timer_irq_smoke.bat`
  - `run_xlen64_smoke.bat`
  - `run_riscv_tests_subset.bat rv32`
- 当前最重要的判断：
  - 这说明 CPU 主线已经能承受同步 `dmem` 负载，不再依赖纯组合读返回
  - 但底层 `RAM/ROM` 还没有真正改成块 RAM 推断风格，所以综合结果仍然是 `0 BRAM`
- 最新 FPGA 口径：
  - `50MHz`：`3692 LUT / 2069 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.553ns`
  - `100MHz`：`3713 LUT / 2066 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.475ns`
- 下一步最值得继续做的事：
  1. 把 `YH_rv_cpu_soc.v` 里的 RAM/ROM 访问拆成独立包装层
  2. 把数据 RAM 改成真正的同步存储实现，推动 BRAM 推断
  3. 在此基础上再继续压 `100MHz` 时序

## 2026-03-17 dmem BRAM 已推断成功

- 这一轮已经把“同步 `dmem` 语义”继续推进成“`dmem` 底层包装层 + Vivado BRAM 推断成功”。
- 关键变更：
  - 新增 `rtl/YH_rv_dmem_ram.v`
  - `rtl/YH_rv_cpu_soc.v` 改成通过 `u_dmem_ram` 统一承接数据 RAM 访问
  - 同步分支去掉异步复位，改成更符合 Vivado 块 RAM 推断模板的写法
- 本轮确认通过：
  - `check_syntax.bat`
  - `run_soc_smoke.bat`
  - `run_trap_smoke.bat`
  - `run_timer_irq_smoke.bat`
  - `run_riscv_tests_subset.bat rv32`
  - `build_vivado_project.bat synth50`
  - `build_vivado_project.bat synth100`
- 最新 FPGA 口径：
  - `50MHz`：`2590 LUT / 2033 FF / 2 BRAM / 0 DSP`，`WNS = 7.556ns`
  - `100MHz`：`2611 LUT / 2030 FF / 2 BRAM / 0 DSP`，`WNS = -2.470ns`
- 这次最关键的结论：
  - `dmem` BRAM 已经不是“计划项”，而是“已验证成功的主线实现”。
  - 资源压力进一步下降，当前比赛频率口径继续以 `50MHz` 为主是稳的。
  - `100MHz` 还没过，但后续该盯的点已经缩小到：
    1. `ROM/imem` 的存储结构
    2. `dmem` BRAM 输出寄存器与时序
- 接手后优先继续：
  1. 推进 `imem/ROM` 包装层
  2. 评估 `dmem` BRAM 输出寄存器
  3. 再继续压 `100MHz`

## 2026-03-17 当前交接摘要（直接接手版）

### 1. 项目是什么

- 当前正式比赛工程是 `YH_rv_cpu`
- 对应七星微赛题，主线目标是做出可提交、可验证、可综合、可上板推进的 RISC-V CPU 作品

### 2. 当前做到哪一步

- `RV32I + Zicsr` 五级流水主线稳定
- 最小 `SoC`、`trap`、`timer irq`、`xlen64 smoke` 都已经打通
- `riscv-tests rv32` 默认子集已经整组通过
- `dmem` 已经完成独立包装层，并被 Vivado 实际推成 `2 BRAM`
- 当前 FPGA 口径已经稳定到：
  - `50MHz`：`2590 LUT / 2033 FF / 2 BRAM / 0 DSP`，`WNS = 7.556ns`
  - `100MHz`：`2611 LUT / 2030 FF / 2 BRAM / 0 DSP`，`WNS = -2.470ns`

### 3. 已完成的关键工作

- 同步 `imem` 已接入主线
- 同步 `dmem` 已接入主线
- `dmem` BRAM 推断成功
- Vivado `synth50 / synth100` 报告已固化
- 技术文档、修改记录、任务清单、项目管理交接文档都已同步更新

### 4. 当前阻塞与风险

- `100MHz` 仍未收敛，但不影响当前 `50MHz` 比赛口径
- `imem/ROM` 仍主要占用 LUT，存储结构还可以继续优化
- `CoreMark` 还没形成稳定跑分链
- `RV64` 还没扩成稳定回归集
- 正式板卡和正式 `XDC` 还没冻结

### 5. 下一步最值得做的 3 到 5 项

1. 推进 `imem/ROM` 包装层，继续压 LUT 占用
2. 评估 `dmem` BRAM 输出寄存器，继续改善 `100MHz`
3. 在新资源口径下补 `CoreMark`
4. 扩大 `RV64` / 更完整 `riscv-tests` 回归
5. 板卡到位后冻结正式 `XDC` 并推进上板

### 6. 关键文档与命令

- 总体设计先看：`doc/技术文档.md`
- 当前交接先看：`doc/YH_rv_cpu_handoff.md`
- 当前任务先看：`doc/YH_rv_cpu_todo.md`
- 修改历史先看：`doc/YH_rv_cpu_change_log.md`
- 常用命令：
  - `scripts\\check_syntax.bat`
  - `scripts\\run_soc_smoke.bat`
  - `scripts\\run_trap_smoke.bat`
  - `scripts\\run_timer_irq_smoke.bat`
  - `scripts\\run_riscv_tests_subset.bat rv32`
  - `scripts\\build_vivado_project.bat synth50`
  - `scripts\\build_vivado_project.bat synth100`

### 7. 文档缺口与建议补齐项

- 还缺一版板卡到位后的正式 `XDC` 记录
- 还缺 `CoreMark` 稳定跑分记录
- 还缺 `RV64` 扩展后的系统回归摘要
