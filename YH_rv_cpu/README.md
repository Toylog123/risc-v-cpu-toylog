# YH_rv_cpu

## 项目定位

`YH_rv_cpu` 是当前七星微赛题的正式比赛工程。

当前验证基线是自写 `RV32I + Zicsr` 五级流水，目标架构不是停留在单一 `RV32`，而是继续推进到 `RV32 / RV64` 共线演进。

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

当前缺口：

- `RV64` 指令级扩展和专门验证
- `riscv-tests` 全量回归
- `CoreMark`
- 正式资源报告和时序报告
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

已知烟测结论：

- `PASS: SoC smoke test completed at PC=00000038 in 102 cycles`
- `PASS: trap smoke test completed at PC=000000ac in 79 cycles`
- `PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`
- `PASS: xlen64 smoke test completed at PC=0000000000000010 in 13 cycles`
- `PASS: riscv-tests finished at PC=0000059c in 495 cycles with tohost=1`

## 当前优先级

1. 在 `XLEN` 骨架和 `xlen64` 烟测基础上继续补 `RV64` 译码、访存和相关语义。
2. 扩大 `riscv-tests` 回归覆盖，并把结果沉淀到文档。
3. 接入并调通 `CoreMark`。
4. 继续收口 Vivado 资源报告与时序报告。
5. 在拿到板卡后冻结正式 `XDC` 并推进上板。

## 协作要求

- 修改 RTL、脚本、验证或工程内文档后，同步更新：
  - `doc/YH_rv_cpu_handoff.md`
  - `doc/YH_rv_cpu_change_log.md`
  - `doc/YH_rv_cpu_todo.md`
- 源码注释默认使用中文。
- 模块名、脚本名、工具名保留英文。
