# YH_rv_cpu

## 项目定位

`YH_rv_cpu` 是当前七星微赛题的正式比赛工程。

当前验证基线是自写 `RV32I + Zicsr` 五级流水，目标架构不是停留在单一 `RV32`，而是继续推进到 `RV32 / RV64` 共线演进。

## 首先看哪里

如果要快速看清整体设计、模块边界和后续改动入口，先看：

- `doc/技术文档.md`

这份文档是当前工程的总技术说明，后续应持续维护为“整体设计单一入口”。

## 当前状态

已经完成：

- 五级流水第一版
- 关键数据通路 `XLEN` 参数化骨架
- 最小 SoC
  - `ROM`
  - `RAM`
  - `UART`
  - `DONE`
  - `timer`
- 最小机器态 `CSR / trap`
- machine timer interrupt 最小闭环
- 固件构建链路
- `xsim` SoC / trap / timer irq 烟测
- `xsim` `XLEN=64` 基础烟测
- `riscv-tests` 子集回归脚本和测试平台
- Vivado 本地工程脚手架
- 工具链脚本的本地路径回退
- Vivado 本地综合自动 ASCII 盘符映射
- 本地综合资源/时序报告与检查点导出

当前缺口：

- `RV64` 指令级扩展和专门验证
- `riscv-tests` 全量回归
- `CoreMark`
- 时序优化和正式板级约束
- FPGA 上板闭环

## 目录结构

- `rtl/`
  - CPU、流水级、SoC 和基础功能模块
- `tb/`
  - 基础 CPU 测试平台和 SoC 烟测平台
- `sw/`
  - 裸机程序、trap 入口和链接脚本
- `scripts/`
  - 工具链检查、语法检查、固件构建、烟测和默认同步脚本
- `doc/`
  - 初步设计、交接、修改记录和任务清单
- `fpga/vivado/`
  - Vivado 顶层、约束模板和批处理脚本

## 快速命令

```bat
scripts\check_toolchain.bat
scripts\check_syntax.bat
scripts\build_firmware.bat
scripts\run_soc_smoke.bat
scripts\run_trap_smoke.bat
scripts\run_timer_irq_smoke.bat
scripts\run_xlen64_smoke.bat
scripts\run_riscv_tests_subset.bat rv32 add
scripts\build_vivado_project.bat synth
scripts\build_vivado_project.bat synth100
scripts\build_vivado_project.bat synth50
scripts\\clean_vivado_project.bat
scripts\\open_vivado_project.bat
```

## 当前验证结果

- `check_syntax.bat` 通过
- `build_firmware.bat` 通过
- `run_soc_smoke.bat` 通过
- `run_trap_smoke.bat` 通过
- `run_timer_irq_smoke.bat` 通过
- `run_xlen64_smoke.bat` 通过
- `run_riscv_tests_subset.bat rv32 add` 通过
- `run_riscv_tests_subset.bat rv32` 当前默认子集整组通过
- `check_toolchain.bat` 能识别本机 `xPack` RISC-V 工具链和 `scoop` 安装的 `iverilog`
- `build_vivado_project.bat synth` 通过，并能导出 `project/reports/` 下的综合报告

已知烟测结论：

- `PASS: SoC smoke test completed at PC=00000038 in 102 cycles`
- `PASS: trap smoke test completed at PC=000000ac in 79 cycles`
- `PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`
- `PASS: xlen64 smoke test completed at PC=0000000000000020 in 17 cycles`
- `PASS: riscv-tests finished at PC=0000059c in 495 cycles with tohost=1`
- `riscv-tests rv32` 默认子集当前已整组通过，脚本会把最近一次摘要写到 `build/tests/riscv-tests/rv32/summary.txt`

当前 FPGA 综合结论：

- 当前本地综合默认会临时映射到 `V:`，避开中文路径导致的 Vivado 退出问题
- 当前本地综合默认会挂接 `build/tests/riscv-tests/rv32/simple.hex`，并把 `ROM/RAM` 提升到 `8KB/8KB` 做资源估算
- `xc7a100tcsg324-1` 综合结果：
  - `Slice LUTs = 3445`
  - `Slice Registers = 1962`
  - `LUT as Memory = 1024`
  - `BRAM = 0`
  - `DSP = 0`
- 100MHz 约束下当前 `WNS = -2.405ns`，说明直接跑 `100MHz` 还不稳，但按赛题要求的 `50MHz` 目标仍有较大把握
- 当前 `XDC` 还是模板，报告里仍有 `no_input_delay(1)` 和 `no_output_delay(4)`，正式板卡到位后要补齐

## 当前优先级

1. 在 `XLEN` 骨架和 `xlen64` 烟测基础上继续补 `RV64` 译码、访存和相关语义。
2. 扩大 `riscv-tests` 回归覆盖，并把结果沉淀到文档。
3. 接入并调通 `CoreMark`。
4. 继续做时序收敛，把当前综合从“能出报告”推进到“满足目标频率”。
5. 在拿到板卡后冻结正式 `XDC` 并推进上板。

## 协作要求

- 修改 RTL、脚本、验证或工程内文档后，同步更新：
  - `doc/YH_rv_cpu_handoff.md`
  - `doc/YH_rv_cpu_change_log.md`
  - `doc/YH_rv_cpu_todo.md`
- 源码注释默认使用中文。
- 模块名、脚本名、工具名保留英文。

## 2026-03-17 FPGA 更新

- 这一轮综合口径已经从“单一 100MHz 报告”补成“双档频率报告”：
  - `project/reports/clk_10p000ns`
  - `project/reports/clk_20p000ns`
- 当前资源结果：
  - `100MHz`：`3450 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`
  - `50MHz`：`3424 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`
- 当前时序结果：
  - `100MHz`：`WNS = -2.487ns`
  - `50MHz`：`WNS = 7.525ns`
- 当前结论：
  - 赛题要求的 `50MHz` 目标已经被本地综合覆盖
  - `100MHz` 仍未收敛，后续重点是继续压关键控制链，并把 `ROM/RAM` 往更适合 FPGA 的存储结构迁移
## 2026-03-17 同步取指补充

- 当前 FPGA 顶层已经切到“同步指令存储”口径：
  - `fpga/vivado/src/YH_rv_cpu_fpga_top.v`
  - `rtl/YH_rv_cpu_soc.v`
  - `rtl/YH_rv_sync_imem_rom.v`
- 固件和测试脚本现在会额外生成 `*.mem32.hex`，用于同步取指 ROM 初始化：
  - `scripts/build_firmware.bat`
  - `scripts/build_coremark.bat`
  - `scripts/run_riscv_tests_subset.bat`
- Vivado 综合脚本现在会优先选择：
  - `build/tests/riscv-tests/current.hex`
  - `build/tests/riscv-tests/current.mem32.hex`
- 映射盘符逻辑也加固了：
  - 会在 `V:/W:/X:/Y:/Z:` 中选择可用 ASCII 盘符
  - 找不到可用盘符时直接失败，不再回退到中文路径
- 最新同步取指综合结果：
  - `100MHz`：`4086 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.468ns`
  - `50MHz`：`4061 LUT / 2040 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.548ns`
- 当前最重要的判断：
  - “同步取指接口已经接上”这件事已经成立
  - 但 `BRAM = 0` 依然成立，说明下一步不能只改属性，还要继续推进真正的同步存储结构
## 2026-03-17 同步数据存储推进

- 当前主线已经补上同步数据访存握手：
  - `rtl/YH_rv_cpu.v` 新增 `DMEM_SYNC`、`dmem_read_req`、`dmem_rvalid`
  - `rtl/YH_rv_cpu_mem_stage.v` 负责把 `load` 请求显式导出为 `dmem_read_req`
  - `rtl/YH_rv_cpu_soc.v` 在 `SYNC_DMEM=1` 时提供一拍延迟的数据返回语义
- 当前 SoC / FPGA 路线已经切到同步数据路径：
  - `tb/YH_rv_cpu_soc_tb.v`
  - `tb/YH_rv_cpu_trap_tb.v`
  - `tb/YH_rv_cpu_timer_irq_tb.v`
  - `tb/YH_rv_cpu_coremark_tb.v`
  - `fpga/vivado/src/YH_rv_cpu_fpga_top.v`
- 本轮实测通过：
  - `scripts/check_syntax.bat`
  - `scripts/run_soc_smoke.bat`
  - `scripts/run_trap_smoke.bat`
  - `scripts/run_timer_irq_smoke.bat`
  - `scripts/run_xlen64_smoke.bat`
  - `scripts/run_riscv_tests_subset.bat rv32`
- 最新综合口径：
  - `50MHz`：`3692 LUT / 2069 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.553ns`
  - `100MHz`：`3713 LUT / 2066 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.475ns`
- 当前结论：
  - 同步数据返回语义已经落地，后面可以继续把底层 RAM/ROM 包装层往真正适合 BRAM 的结构收
  - 当前 `BRAM = 0` 说明底层存储实现还没有改成真正的同步块 RAM 推断写法，不代表同步 `dmem` 路线无效

## 2026-03-17 dmem BRAM 推断成功

- 这一轮已经把 `dmem` 从“同步语义已接入”继续推进到“Vivado 已实际推成块 RAM”。
- 新增底层存储包装模块：
  - `rtl/YH_rv_dmem_ram.v`
- `rtl/YH_rv_cpu_soc.v` 现在不再直接内嵌数据 RAM 数组，而是通过包装层统一接管：
  - 同步读返回
  - 字节写使能
  - 后续 BRAM 化入口
- 本轮重新验证通过：
  - `scripts/check_syntax.bat`
  - `scripts/run_soc_smoke.bat`
  - `scripts/run_trap_smoke.bat`
  - `scripts/run_timer_irq_smoke.bat`
  - `scripts/run_riscv_tests_subset.bat rv32`
  - `scripts/build_vivado_project.bat synth50`
  - `scripts/build_vivado_project.bat synth100`
- 最新综合结果已经更新为：
  - `50MHz`：`2590 LUT / 2033 FF / 2 BRAM / 0 DSP`，`WNS = 7.556ns`
  - `100MHz`：`2611 LUT / 2030 FF / 2 BRAM / 0 DSP`，`WNS = -2.470ns`
- 当前最重要的判断：
  - `dmem` 的 BRAM 路线已经验证成功，资源明显下降，比赛要求的 `50MHz` 口径更稳了。
  - `100MHz` 仍未收敛，但主问题已经更聚焦：
    - `ROM/imem` 仍主要在 LUT
    - `dmem` BRAM 还没有吃到可选输出寄存器
- 下一步最值得继续做的事：
  1. 把 `imem/ROM` 也收成更适合 BRAM 的结构
  2. 评估给 `dmem` BRAM 增加额外输出寄存器，继续压 `100MHz`
  3. 在新资源口径上继续推进 `rv64` 和 `CoreMark`

