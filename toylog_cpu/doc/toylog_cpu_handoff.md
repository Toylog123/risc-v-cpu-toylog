# toylog_cpu 交接说明

## 1. 交接规则

- 只要修改了 `toylog_cpu` 的 RTL、脚本、验证或文档，就同步更新本文件、`toylog_cpu_change_log.md` 和 `toylog_cpu_todo.md`。
- 结论以当前仓库文件和实际脚本结果为准，不靠口头状态。
- 源码注释默认使用中文；模块名、脚本名、工具名保留英文。
- 默认同步范围是 `toylog_cpu`、`04-工具链`、`01-项目管理`。
- 默认暂存脚本是 `scripts/stage_default_sync.bat`。

## 2. 当前状态

- 日期：`2026-03-16`
- 赛题：七星微杯 `RISC-V` 高性能 CPU 设计及 FPGA 验证
- 当前目录：`toylog_cpu/`
- 目标工程名：`YH_rv_cpu`
- 当前验证基线：自写 `RV32I` 五级流水
- 当前架构目标：从 `RV32` 推进到 `RV32 / RV64` 共线支持
- 当前闭环状态：最小 SoC 已经打通，能跑固件并通过 UART 输出 `toylog_cpu boot`

## 3. 已完成能力

- 五级流水基础结构：`IF / ID / EX / MEM / WB`
- 最小机器态 CSR / trap：
  - `mstatus`
  - `mtvec`
  - `mscratch`
  - `mepc`
  - `mcause`
  - `csrrw/csrrs/csrrc`
  - `ecall / ebreak / mret`
- 基础数据前递：`EX/MEM` 和 `MEM/WB`
- 基础 `load-use` 暂停
- 分支 / 跳转重定向
- 最小 SoC 外壳：
  - `ROM`
  - `RAM`
  - `UART`
  - `DONE`
  - `timer`
- 固件构建链路：
  - `.elf`
  - `.dump`
  - `.bin`
  - `.hex`
- `xsim` SoC 烟测
- `xsim` trap 烟测
- `xsim` timer interrupt 烟测

## 4. 本轮关键修复

- 修复了跳转重定向未绑定 `id_ex_valid` 的问题，避免 `JAL` 清空后无效指令持续重定向。
- 给寄存器堆加了写回旁路，解决首次 `lbu` 读取字符串地址时拿不到同周期写回值的问题。
- SoC 侧补齐了 D 侧读取 `ROM` 的路径，确保字符串常量可被 `lbu` 正常访问。
- 烟测脚本改为走 `Vivado/xsim`，不再依赖本机存在问题的 `iverilog + vvp` 运行链。

## 5. 当前验证结果

- `scripts/check_syntax.bat`：通过
- `scripts/build_firmware.bat`：通过
- `scripts/run_soc_smoke.bat`：通过
- `scripts/run_trap_smoke.bat`：通过
- `scripts/run_timer_irq_smoke.bat`：通过
- `xsim` 结果：`PASS: SoC smoke test completed at PC=00000038 in 108 cycles`
- `xsim` 结果：`PASS: trap smoke test completed at PC=000000ac in 79 cycles`
- `xsim` 结果：`PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`

## 6. 关键文件

- CPU 顶层：`rtl/toylog_cpu.v`
- SoC 顶层：`rtl/toylog_cpu_soc.v`
- 测试平台：`tb/toylog_cpu_soc_tb.v`
- 语法检查：`scripts/check_syntax.bat`
- 固件构建：`scripts/build_firmware.bat`
- SoC 烟测：`scripts/run_soc_smoke.bat`
- 初步设计：`doc/toylog_cpu_preliminary_design.md`

## 7. 当前缺口

- 正式工程名还没整体切换为 `YH_rv_cpu`
- `RV32 / RV64` 共线改造还没开始落 RTL
- trap / interrupt 目前已具备最小闭环，但还没接 `riscv-tests`
- `riscv-tests` 还没接
- `CoreMark` 还没接
- 还没有正式 `Vivado` 工程、板卡约束和上板记录
- 两项性能优化还没冻结成最终比赛口径

## 8. 下一步顺序

1. 切换正式工程名到 `YH_rv_cpu`
2. 启动 `RV32 / RV64` 共线改造
3. 接 `riscv-tests`
4. 接 `CoreMark`
5. 建 `Vivado` 工程并完成上板闭环

## 9. 接手时先看

1. `../../01-项目管理/03-过程管理/工作交接.md`
2. `../../01-项目管理/03-过程管理/任务清单.md`
3. `../../README.md`
4. `README.md`
5. `doc/toylog_cpu_preliminary_design.md`
6. `doc/toylog_cpu_change_log.md`
7. `doc/toylog_cpu_todo.md`
