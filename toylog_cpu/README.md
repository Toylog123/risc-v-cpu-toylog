# toylog_cpu

`toylog_cpu` 是七星微赛题正式工程的项目名。

当前目录：工作区根目录 `toylog_cpu/`。

## 项目目标

- 面向七星微赛题的自研 RISC-V CPU 实现
- 保持统一的英文工程名和源码名，便于脚本、工具链和队友协作
- 建立可持续扩展的 RTL、工具脚本和设计文档基础
- 直接收敛到五级流水 `RV32I` 比赛基线

## 与赛题要求的对应关系

当前工程结构已经按题目要求预留好了主干路线：

- 先完成 `RV32I`，后续再按需要扩展到 `RV32M`
- 以五级流水作为目标微架构
- 采用 Verilog 建模、测试平台验证和 FPGA 上板的完整路径
- 为两项必做优化预留了扩展空间
- 为测试程序、构建脚本和比赛文档预留了目录

## 重要说明

本工程为自写实现，不直接复用 `picorv32`、`rocket-chip` 或其他开源 CPU RTL。
工作区里的外部仓库与资料现在只作为参考材料存在，不再作为上游同步仓库参与正式开发。

## 目录结构

- `rtl/toylog_cpu_defs.vh`：本地常量定义
- `rtl/toylog_cpu_alu.v`：算术逻辑单元
- `rtl/toylog_cpu_regfile.v`：`32 x 32` 通用寄存器堆
- `rtl/toylog_cpu_decoder.v`：`RV32I` 译码器
- `rtl/toylog_cpu_if_stage.v`：取指阶段
- `rtl/toylog_cpu_id_stage.v`：译码阶段
- `rtl/toylog_cpu_ex_stage.v`：执行阶段
- `rtl/toylog_cpu_mem_stage.v`：访存阶段
- `rtl/toylog_cpu_wb_stage.v`：写回阶段
- `rtl/toylog_cpu_hazard_unit.v`：暂停与前递控制
- `rtl/toylog_cpu.v`：五级流水顶层核心
- `tb/toylog_cpu_tb.v`：基础冒烟测试平台
- `sw/src`：裸机演示程序源码
- `sw/linker`：链接脚本
- `doc/toylog_cpu_preliminary_design.md`：初步架构设计
- `doc/toylog_cpu_handoff.md`：当前交接状态
- `doc/toylog_cpu_change_log.md`：修改记录
- `doc/toylog_cpu_todo.md`：任务清单
- `scripts/check_toolchain.bat`：工具链检查
- `scripts/check_syntax.bat`：RTL 语法检查
- `scripts/iverilog_sources.f`：语法检查文件列表
- `scripts/build_firmware.bat`：固件构建入口
- `fpga/vivado/README.md`：FPGA 阶段说明

## 当前状态

- 已形成可工作的 `RV32I` 五级流水基线，`IF / ID / EX / MEM / WB` 阶段已拆分
- 已具备基础 `load-use` 暂停和 `EX/MEM`、`MEM/WB` 前递
- 已具备分离的指令存储器和数据存储器接口
- Windows 下的脚本已经尽量做到与工作区根路径无关
- 软件侧和构建链路已有起步版本
- 目前还不是最终比赛提交版 SoC，也不是最终 FPGA 镜像

## 当前完成情况

### 已完成

- `RV32I` 五级流水第一版
- `ALU / regfile / decoder / IF / ID / EX / MEM / WB / hazard unit`
- 基础语法检查脚本
- 固件构建脚本
- 工具链说明、交接说明、修改记录、任务清单

### 当前缺口

- `CSR / timer / trap`
- 最小 SoC 封装顶层
- `riscv-tests`
- `CoreMark`
- Vivado 工程与板级约束
- FPGA 上板稳定性验证

## 快速开始

可以直接在资源管理器或终端里运行这些脚本：

- `scripts\check_toolchain.bat`
- `scripts\check_syntax.bat`
- `scripts\build_firmware.bat`

开始新工作或交接前，优先阅读这些文档：

- `doc\toylog_cpu_handoff.md`
- `doc\toylog_cpu_change_log.md`
- `doc\toylog_cpu_todo.md`

队友第一次接手时，建议按下面顺序操作：

1. 先看工作区根 `README.md`
2. 再看 `01-项目管理/03-过程管理/工作交接.md`
3. 然后运行：

```bat
scripts\check_toolchain.bat
scripts\check_syntax.bat
scripts\build_firmware.bat
```

## 下一步

1. 增加 `CSR`、异常陷入和 `timer` 支持
2. 建立包含 `ROM / RAM / UART / timer` 的最小 SoC 封装顶层
3. 建立稳定的 `riscv-tests` 回归流程
4. 加入第一个比赛优化项：更强的分支处理
5. 加入第二个比赛优化项：预取或轻量级预测
6. 建立 Vivado 工程并推进板级上板与时序收敛

## 协作约定

- 不直接在仓库里维护无关参考工程
- 修改 `toylog_cpu` 后，同步更新交接、记录和任务清单
- 提交前优先使用：

```bat
scripts\stage_default_sync.bat
```
