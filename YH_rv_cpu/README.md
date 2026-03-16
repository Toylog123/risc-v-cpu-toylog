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
scripts\clean_vivado_project.bat
```

## 当前验证结果

- `check_syntax.bat` 通过
- `build_firmware.bat` 通过
- `run_soc_smoke.bat` 通过
- `run_trap_smoke.bat` 通过
- `run_timer_irq_smoke.bat` 通过
- `run_xlen64_smoke.bat` 通过
- `run_riscv_tests_subset.bat rv32 add` 通过
- `check_toolchain.bat` 能识别本机 `xPack` RISC-V 工具链和 `scoop` 安装的 `iverilog`
- `build_vivado_project.bat synth` 通过，并能导出 `project/reports/` 下的综合报告

已知烟测结论：

- `PASS: SoC smoke test completed at PC=00000038 in 102 cycles`
- `PASS: trap smoke test completed at PC=000000ac in 79 cycles`
- `PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`
- `PASS: xlen64 smoke test completed at PC=0000000000000020 in 17 cycles`
- `PASS: riscv-tests finished at PC=0000059c in 495 cycles with tohost=1`

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
