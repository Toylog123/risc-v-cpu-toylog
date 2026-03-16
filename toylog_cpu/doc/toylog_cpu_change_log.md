# toylog_cpu 修改记录

## 记录规则

- 每次有实际修改就追加，不覆盖旧记录
- 每条记录至少包含：日期、改动范围、改动目的、验证结果
- 如果有未验证项，要明确写出来

## 2026-03-16

### 变更 1：建立正式工程骨架

- 范围：
  - 建立 `toylog_cpu` 工程目录
  - 补齐基础 RTL、脚本、软件骨架、初步设计文档
- 目的：
  - 为七星微赛题建立正式、自写、可持续扩展的主工程
- 结果：
  - 形成 `RV32I` 起步版工程骨架
- 验证：
  - 基础语法检查通过

### 变更 2：完成五级流水第一版

- 范围：
  - `rtl/toylog_cpu.v`
  - `rtl/toylog_cpu_if_stage.v`
  - `rtl/toylog_cpu_id_stage.v`
  - `rtl/toylog_cpu_ex_stage.v`
  - `rtl/toylog_cpu_mem_stage.v`
  - `rtl/toylog_cpu_wb_stage.v`
  - `rtl/toylog_cpu_hazard_unit.v`
- 目的：
  - 按七星微题目要求，把核心推进到显式五级流水结构
- 结果：
  - 增加流水级寄存器
  - 增加基础 `load-use` 暂停
  - 增加 EX/MEM、MEM/WB 前递
  - 增加分支/跳转重定向冲刷
- 验证：
  - `scripts/check_syntax.bat` 通过
- 未完成：
  - 长回归未跑
  - `riscv-tests` 未接入

### 变更 3：建立交接、记录与任务清单机制

- 范围：
  - `scripts/check_syntax.bat`
  - `scripts/check_syntax.ps1`
  - `scripts/check_toolchain.bat`
  - `README.md`
  - `doc/toylog_cpu_preliminary_design.md`
  - `doc/toylog_cpu_handoff.md`
  - `doc/toylog_cpu_todo.md`
- 目的：
  - 让不同设备路径下的脚本更稳定，并建立持续交接、修改记录、任务清单管理机制
- 结果：
  - `check_syntax.bat` 改为调用 `PowerShell` 脚本
  - 补齐交接说明 / 修改记录 / 任务清单文档
- 验证：
  - `scripts/check_syntax.bat` 返回 `0`

### 变更 4：正式工程移到根目录

- 范围：
  - `toylog_cpu/`
  - 工作区根 `README.md`
  - `.gitignore`
  - `04-工具链/toylog_cpu_toolchain/README.md`
- 目的：
  - 让正式比赛工程和参考实现分离
- 结果：
  - `toylog_cpu` 独立放到工作区根目录
  - 根目录导航和工具链说明同步更新
- 验证：
  - 新位置 `toylog_cpu/scripts/check_syntax.bat` 通过

### 变更 5：清理不必要的工具链源码目录

- 范围：
  - `04-工具链/riscv-gnu-toolchain`
  - `toylog_cpu/build`
- 目的：
  - 删除未真正安装成可用工具的源码目录
  - 保持工作区只留下当前确实要维护的主工程和说明
- 结果：
  - 删除 `04-工具链/riscv-gnu-toolchain`
  - 删除空目录 `toylog_cpu/build`
- 验证：
  - `04-工具链` 当前只剩 `toylog_cpu_toolchain`

### 变更 6：删除 rocket-chip 并修正 Vivado 安装记录

- 范围：
  - `03-参考实现/CPU设计/rocket-chip`
  - `toylog_cpu/scripts/check_toolchain.bat`
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
  - `04-工具链/toylog_cpu_toolchain/README.md`
- 目的：
  - 删除当前不需要的重型参考仓库
  - 把本机已安装的 Vivado 正确记录下来
- 结果：
  - 删除 `03-参考实现/CPU设计/rocket-chip`
  - `check_toolchain.bat` 增加本地 Vivado 路径识别
- 验证：
  - `03-参考实现/CPU设计` 当前只剩 `picorv32`
  - `scripts/check_toolchain.bat` 报告 Vivado 已找到

### 变更 7：安装 xPack RISC-V GCC 并打通固件编译

- 范围：
  - `toylog_cpu/scripts/check_toolchain.bat`
  - `toylog_cpu/scripts/build_firmware.bat`
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
  - `toylog_cpu/doc/toylog_cpu_todo.md`
  - `04-工具链/toylog_cpu_toolchain/README.md`
- 目的：
  - 安装可直接用于当前 `toylog_cpu` 工程的交叉编译器
  - 让脚本兼容 `xPack` 的 `riscv-none-elf-*` 命名
- 结果：
  - 安装 `@xpack-dev-tools/riscv-none-elf-gcc@15.2.0-1.1`
  - `check_toolchain.bat` 支持识别 `riscv-none-elf-gcc/objdump/objcopy`
  - `build_firmware.bat` 支持直接使用 `riscv-none-elf-*`
- 验证：
  - `scripts/check_toolchain.bat` 通过
  - `scripts/build_firmware.bat` 成功生成 `.elf`、`.dump`、`.bin`

### 变更 8：补充队伍安装清单

- 范围：
  - `04-工具链/toylog_cpu_toolchain/队伍安装清单.md`
  - `04-工具链/toylog_cpu_toolchain/README.md`
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
- 目的：
  - 给队友提供一份可直接转发的安装目录和统一口径
- 结果：
  - 新增必须安装、建议安装、暂时不装、自检命令、统一口径
- 验证：
  - 清单内容与当前工程工具链一致

### 变更 9：改成按赛题推荐维护安装清单，并统一源码注释语言

- 范围：
  - `04-工具链/toylog_cpu_toolchain/队伍安装清单.md`
  - `04-工具链/toylog_cpu_toolchain/README.md`
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
  - `toylog_cpu/doc/toylog_cpu_todo.md`
  - `toylog_cpu/tb/toylog_cpu_tb.v`
- 目的：
  - 把安装清单从“本机已装快照”改成“按赛题推荐整理的团队最低协作环境”
  - 统一 `toylog_cpu` 源码注释默认使用中文
- 结果：
  - 安装清单改为围绕 `Git + Vivado + xsim + iverilog + riscv-none-elf-*`
  - `tb/toylog_cpu_tb.v` 里的现有英文注释已改为中文
  - 交接文档增加“源码注释默认中文”规则
- 验证：
  - `scripts/check_syntax.bat` 通过

### 变更 10：固化默认同步范围

- 范围：
  - `toylog_cpu/scripts/stage_default_sync.bat`
  - `toylog_cpu/scripts/stage_default_sync.ps1`
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
  - `toylog_cpu/doc/toylog_cpu_todo.md`
  - `01-项目管理/03-资料索引/Git同步约定.md`
- 目的：
  - 把后续默认同步范围固定为正式工程、工具链和少量索引文档
  - 减少提交时误带无关目录的概率
- 结果：
  - 新增默认暂存脚本
  - 新增同步约定文档
  - 交接文档补充同步范围规则
- 验证：
  - `scripts/stage_default_sync.bat --dry-run` 通过

### 变更 11：仓库跟踪范围收口

- 范围：
  - 工作区根 `README.md`
  - 工作区根 `.gitignore`
  - `toylog_cpu/scripts/stage_default_sync.ps1`
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
  - `toylog_cpu/doc/toylog_cpu_todo.md`
  - `01-项目管理/03-资料索引/Git同步约定.md`
- 目的：
  - 把 Git 仓库收口到正式工程、工具链、项目计划和资料索引
  - 让 `02-官方与规范`、`03-参考实现`、`05-验证测试`、`01-项目管理/01-赛题分析` 只保留本地
- 结果：
  - 默认同步范围扩展为 `01-项目管理/02-项目计划`
  - 根说明改为“Git 跟踪范围”
  - 本地资料目录加入忽略规则
- 验证：
  - `scripts/stage_default_sync.bat --dry-run` 应输出新的 4 个同步路径

### 变更 12：当前说明文档统一为中文

- 范围：
  - `toylog_cpu/README.md`
  - `toylog_cpu/doc/toylog_cpu_preliminary_design.md`
  - `toylog_cpu/fpga/vivado/README.md`
  - `04-工具链/toylog_cpu_toolchain/README.md`
  - `04-工具链/toylog_cpu_toolchain/队伍安装清单.md`
  - `01-项目管理/03-资料索引/Git同步约定.md`
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
  - `toylog_cpu/doc/toylog_cpu_change_log.md`
  - `toylog_cpu/doc/toylog_cpu_todo.md`
- 目的：
  - 统一当前仓库说明文档的语言，方便中文环境下的团队协作与交接
- 结果：
  - 说明文档的标题、段落和解释性文字统一改成中文
  - 状态词和协作文档中的说明性英文术语一并改成中文
  - 仅保留工程名、脚本名和必要术语的英文标识
- 验证：
  - 文档检索不再出现成段英文说明
