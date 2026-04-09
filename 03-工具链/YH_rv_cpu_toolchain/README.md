# YH_rv_cpu 工具链说明

## 作用

这个目录用于记录 `YH_rv_cpu` 当前采用的比赛工程工具链基线。

它主要承担两件事：

- 让队友保持一致的最低可工作环境
- 把赛题建议工具映射到当前工程的实际开发流程

## 当前团队基线

- `Git`
- `Vivado 2025.2`
- `xsim`
- `iverilog`
- `riscv-none-elf-gcc`
- `riscv-none-elf-objdump`
- `riscv-none-elf-objcopy`

面向队友的安装说明见：

- `04-工具链/YH_rv_cpu_toolchain/队伍安装清单.md`

## 当前工程里的对应入口

- 工具链检查：`YH_rv_cpu/scripts/check_toolchain.bat`
- RTL 语法检查：`YH_rv_cpu/scripts/check_syntax.bat`
- 固件构建：`YH_rv_cpu/scripts/build_firmware.bat`

## 当前约定

- 系统级仿真统一走 `xsim`
- `iverilog` 主要用于快速语法检查
- 工程内源码注释默认使用中文
- 模块名、脚本名、工具名保留英文
