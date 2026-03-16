# YH_rv_cpu

## 项目定位

`YH_rv_cpu` 是当前七星微赛题的正式比赛工程。

当前验证基线是自写 `RV32I + Zicsr` 五级流水，目标架构不是停留在单一 `RV32`，而是继续推进到 `RV32 / RV64` 共线演进。

## 当前状态

已经完成：

- 五级流水第一版
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

当前缺口：

- `RV32 / RV64` 共线改造
- `riscv-tests`
- `CoreMark`
- 正式 `Vivado` 工程
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
  - Vivado 工程预留目录

## 快速命令

```bat
scripts\check_toolchain.bat
scripts\check_syntax.bat
scripts\build_firmware.bat
scripts\run_soc_smoke.bat
scripts\run_trap_smoke.bat
scripts\run_timer_irq_smoke.bat
```

## 当前验证结果

- `check_syntax.bat` 通过
- `build_firmware.bat` 通过
- `run_soc_smoke.bat` 通过
- `run_trap_smoke.bat` 通过
- `run_timer_irq_smoke.bat` 通过

已知烟测结论：

- `PASS: SoC smoke test completed at PC=00000038 in 108 cycles`
- `PASS: trap smoke test completed at PC=000000ac in 79 cycles`
- `PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`

## 当前优先级

1. 抽出 `XLEN` 基础参数，启动 `RV32 / RV64` 共线改造。
2. 接入 `riscv-tests`。
3. 接入 `CoreMark`。
4. 建立正式 `Vivado` 工程并准备上板。

## 协作要求

- 修改 RTL、脚本、验证或工程内文档后，同步更新：
  - `doc/YH_rv_cpu_handoff.md`
  - `doc/YH_rv_cpu_change_log.md`
  - `doc/YH_rv_cpu_todo.md`
- 源码注释默认使用中文。
- 模块名、脚本名、工具名保留英文。
