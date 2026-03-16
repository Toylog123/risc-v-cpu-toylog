# toylog_cpu 交接说明

## 1. 交接规则

- 每次对 `toylog_cpu` 有实际修改，必须同步更新本文件、`toylog_cpu_change_log.md` 和 `toylog_cpu_todo.md`
- 交接时优先说明当前可运行状态、当前阻塞、下一步最值得做的事情
- 所有结论以当前工作区文件和实际脚本结果为准
- `toylog_cpu` 内源码注释默认使用中文
- 默认同步范围固定为：`toylog_cpu`、`04-工具链`、`01-项目管理`
- 其他目录只在目录结构变更、删除大体积资料、或确实影响团队协作时再同步
- 默认暂存脚本：`scripts/stage_default_sync.bat`
- Git 仓库默认跟踪 `toylog_cpu`、`04-工具链` 和 `01-项目管理`；`02-官方与规范`、`03-参考实现`、`05-验证测试` 默认只保留本地

## 2. 当前状态

- 日期：`2026-03-16`
- 项目名：`toylog_cpu`
- 当前目录：工作区根目录下 `toylog_cpu/`
- 赛题方向：七星微 `RISC-V` 高性能 CPU 设计及 FPGA 验证
- 当前基线：自写 `RV32I` 五级流水第一版
- 当前结构：`IF / ID / EX / MEM / WB`

## 3. 当前已具备能力

- 基础算术逻辑运算
- 分支与跳转基础控制
- 访存地址生成与字节写使能
- 基础 `load-use` 冒险暂停
- EX/MEM 与 MEM/WB 前递
- 独立指令/数据存储接口

## 4. 关键文件

- 顶层：`rtl/toylog_cpu.v`
- 流水级模块：
  - `rtl/toylog_cpu_if_stage.v`
  - `rtl/toylog_cpu_id_stage.v`
  - `rtl/toylog_cpu_ex_stage.v`
  - `rtl/toylog_cpu_mem_stage.v`
  - `rtl/toylog_cpu_wb_stage.v`
- 冒险处理：`rtl/toylog_cpu_hazard_unit.v`
- 基础模块：
  - `rtl/toylog_cpu_decoder.v`
  - `rtl/toylog_cpu_alu.v`
  - `rtl/toylog_cpu_regfile.v`
- 验证入口：`tb/toylog_cpu_tb.v`
- 工具脚本：
  - `scripts/check_toolchain.bat`
  - `scripts/check_syntax.bat`
  - `scripts/build_firmware.bat`

## 5. 当前验证结论

- `scripts/check_toolchain.bat`：通过
- `scripts/check_syntax.bat`：通过
- `scripts/build_firmware.bat`：通过
- 当前未完成：
  - `riscv-tests` 未接入
  - `CoreMark` 未接入
  - `SoC 封装顶层` 未完成
  - FPGA 工程未建立

## 6. 团队协作最低环境

这部分以“赛题推荐 + 当前工程路线”为准，不等同于某一台机器的个人安装快照。

- `Git`
- `Vivado 2025.2`
- `xsim`
- `iverilog`
- `riscv-none-elf-gcc`
- `riscv-none-elf-objdump`
- `riscv-none-elf-objcopy`

队友安装说明见：

- `../../04-工具链/toylog_cpu_toolchain/队伍安装清单.md`

## 7. 当前本机快照

- `iverilog`：已安装
- `rg`：已安装
- `Vivado 2025.2`：已安装
- `xsim`：可用
- `riscv-none-elf-gcc`：已安装
- `riscv-none-elf-objdump`：可用
- `riscv-none-elf-objcopy`：可用
- `vsim`：未安装

## 8. 工作区清理状态

- 已删除 `04-工具链/riscv-gnu-toolchain`
- 已删除 `03-参考实现/CPU设计/rocket-chip`
- 当前保留的轻量参考实现：`03-参考实现/CPU设计/picorv32`

## 9. 下一步建议顺序

1. 增加 `CSR / timer / trap`
2. 建立最小 `SoC 封装顶层`
3. 接入 `riscv-tests`
4. 接入 `CoreMark`
5. 建立 Vivado 工程和板级约束

## 10. 接手时先看什么

1. `../../01-项目管理/03-过程管理/工作交接.md`
2. `../../01-项目管理/03-过程管理/任务清单.md`
3. `../../README.md`
4. `README.md`
5. `doc/toylog_cpu_preliminary_design.md`
6. `doc/toylog_cpu_handoff.md`
7. `doc/toylog_cpu_change_log.md`
8. `doc/toylog_cpu_todo.md`
9. `../../04-工具链/toylog_cpu_toolchain/队伍安装清单.md`
