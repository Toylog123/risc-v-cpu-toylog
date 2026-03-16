# toylog_cpu 工具链说明

## 作用

这个目录用于记录 `toylog_cpu` 当前采用的比赛工程工具链基线。

它主要承担两个作用：

- 让队伍成员保持一致的最低开发环境
- 把赛题推荐工具映射到当前工程的实际开发流程

## 队伍基线

当前队伍基线是：

- `Git`
- `Vivado 2025.2`
- `xsim`
- `iverilog`
- `riscv-none-elf-gcc`
- `riscv-none-elf-objdump`
- `riscv-none-elf-objcopy`

面向队友的详细安装说明见：

- `04-工具链/toylog_cpu_toolchain/队伍安装清单.md`

## 与赛题建议的对应关系

赛题建议的能力包括：

- 使用 Verilog / VHDL 完成 RTL 设计
- 使用测试平台做仿真
- 完成模块级与系统级验证
- 接入 `riscv-tests`
- 完成 FPGA 实现
- 按需要补充形式验证

当前工程把这些建议映射为：

- 快速语法检查：`iverilog`
- 主仿真路径：`xsim`
- 固件构建：`riscv-none-elf-*`
- FPGA 流程：`Vivado`
- 后续验证：`riscv-tests` 与 `CoreMark`

## 工程脚本

优先使用这些脚本：

- `toylog_cpu/scripts/check_toolchain.bat`
- `toylog_cpu/scripts/check_syntax.bat`
- `toylog_cpu/scripts/build_firmware.bat`

## 工程规则

- 工程不能依赖某台设备的绝对路径
- 本地脚本要能从脚本目录自动定位工程根目录
- 工具优先从 `PATH` 里查找，必要时再回退到已知本地安装路径
- `toylog_cpu` 中源码注释默认使用中文

## 工作区约定

- 不再在当前工作区保留未安装完成的 `riscv-gnu-toolchain` 源码树
- 不再把无关的大型参考仓库放进当前活跃开发流程
- 这个目录只保留工具链说明和面向项目的脚本说明

## 2026-03-16 本机快照

- `iverilog`：已安装
- `rg`（`ripgrep`）：已安装
- `Vivado 2025.2`：已安装
- `xsim`：可用
- `riscv-none-elf-gcc`：已通过 `xPack` 安装
- `riscv-none-elf-objdump`：可用
- `riscv-none-elf-objcopy`：可用
- `vsim`：未安装
