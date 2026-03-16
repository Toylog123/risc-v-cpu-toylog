# toylog_cpu

当前正式工程名待切换为 `YH_rv_cpu`。现阶段目录和模块名仍保留 `toylog_cpu`，目的是先保持当前验证链路稳定，再在独立提交里完成整体改名。

## 项目目标

- 面向七星微赛题做自研 `RISC-V` CPU 实现
- 保持统一的英文工程名和源码名，方便脚本、工具链和队友协作
- 建立可持续扩展的 RTL、验证脚本和设计文档基础
- 先完成初赛可提交的最小闭环，再做性能优化和上板增强
- 架构目标从单一 `RV32` 扩展为 `RV32 / RV64` 共线支持

## 与赛题要求的对应关系

当前工程路线已经按题目要求预留主路径：

- 以 `RV32I` 为当前验证基线，并预留向 `RV64I` 扩展的路线
- 以五级流水为当前微架构
- 以 Verilog 建模、仿真验证和 FPGA 上板为完整路线
- 为两项性能优化预留扩展空间
- 为设计文档、跑分和展示材料预留目录和脚本入口

## 重要说明

本工程为自写实现，不直接复用 `picorv32`、`rocket-chip` 或其他开源 CPU RTL。工作区里的参考项目只作为资料存在，不作为正式工程上游。

## 目录结构

- `rtl/toylog_cpu_defs.vh`：常量定义
- `rtl/toylog_cpu_alu.v`：算术逻辑单元
- `rtl/toylog_cpu_regfile.v`：寄存器堆
- `rtl/toylog_cpu_decoder.v`：`RV32I` 译码器
- `rtl/toylog_cpu_if_stage.v`：取指阶段
- `rtl/toylog_cpu_id_stage.v`：译码阶段
- `rtl/toylog_cpu_ex_stage.v`：执行阶段
- `rtl/toylog_cpu_mem_stage.v`：访存阶段
- `rtl/toylog_cpu_wb_stage.v`：写回阶段
- `rtl/toylog_cpu_hazard_unit.v`：暂停和前递控制
- `rtl/toylog_cpu.v`：CPU 顶层
- `rtl/toylog_cpu_soc.v`：最小 SoC 顶层
- `tb/toylog_cpu_tb.v`：基础 CPU 测试平台
- `tb/toylog_cpu_soc_tb.v`：最小 SoC 烟测平台
- `sw/src`：裸机示例程序
- `sw/linker`：链接脚本
- `doc/toylog_cpu_preliminary_design.md`：初步设计
- `doc/toylog_cpu_handoff.md`：交接说明
- `doc/toylog_cpu_change_log.md`：修改记录
- `doc/toylog_cpu_todo.md`：任务清单
- `scripts/check_toolchain.bat`：工具链检查
- `scripts/check_syntax.bat`：RTL 语法检查
- `scripts/build_firmware.bat`：固件构建
- `scripts/run_soc_smoke.bat`：SoC 烟测
- `fpga/vivado/README.md`：FPGA 阶段说明

## 当前状态

已经完成：

- `RV32I` 五级流水第一版
- 最小机器态 CSR / trap 路径：
  - `mstatus`
  - `mtvec`
  - `mscratch`
  - `mepc`
  - `mcause`
  - `csrrw/csrrs/csrrc` 及其立即数形式
  - `ecall / ebreak / mret`
- 基础 `load-use` 暂停
- `EX/MEM` 和 `MEM/WB` 前递
- 分支 / 跳转重定向
- 最小 SoC：
  - `ROM`
  - `RAM`
  - `UART`
  - `DONE`
  - `timer`
- 固件 `.elf / .dump / .bin / .hex` 构建链路
- `xsim` SoC 烟测
- `xsim` trap 烟测
- `xsim` timer interrupt 烟测

当前缺口：

- `RV32 / RV64` 共线改造
- trap / interrupt 的进一步收口
- `riscv-tests`
- `CoreMark`
- `Vivado` 工程和 FPGA 上板
- 比赛版性能优化和资源统计

## 快速开始

直接在终端运行：

```bat
scripts\check_toolchain.bat
scripts\check_syntax.bat
scripts\build_firmware.bat
scripts\run_soc_smoke.bat
```

## 接手顺序

1. 先看工作区根 `README.md`
2. 再看 `01-项目管理/03-过程管理/工作交接.md`
3. 然后看：
   - `doc/toylog_cpu_handoff.md`
   - `doc/toylog_cpu_change_log.md`
   - `doc/toylog_cpu_todo.md`

## 下一步

1. 把正式工程名切换为 `YH_rv_cpu`
2. 启动 `RV32 / RV64` 共线改造
3. 接 `riscv-tests`
4. 接 `CoreMark`
5. 建 `Vivado` 工程并推进 FPGA 上板

## 协作约定

- 修改 `toylog_cpu` 后，必须同步更新交接、记录和任务清单
- 默认同步时优先使用：

```bat
scripts\stage_default_sync.bat
```
