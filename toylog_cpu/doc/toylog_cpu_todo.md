# toylog_cpu TODO

## 使用规则

- 状态只用：`TODO`、`DOING`、`DONE`、`BLOCKED`
- 每次进入新任务前先看本文件
- 每次完成任务后同步更新状态和备注

## 已完成

- `DONE` 建立 `toylog_cpu` 正式工程目录
- `DONE` 完成 `RV32I` 五级流水第一版
- `DONE` 建立交接、修改记录、TODO 机制
- `DONE` 将 `toylog_cpu` 移到工作区根目录
- `DONE` 安装 `rg`（`ripgrep`）
- `DONE` 记录本机 `Vivado 2025.2`
- `DONE` 安装 `xPack` RISC-V GCC
- `DONE` 补充队伍安装清单
- `DONE` 删除 `03-参考实现/CPU设计/rocket-chip`
- `DONE` 删除 `04-工具链/riscv-gnu-toolchain`
- `DONE` 将队伍安装清单改成按赛题推荐维护
- `DONE` 将 `toylog_cpu` 现有源码注释统一为中文
- `DONE` 固化默认同步范围并新增暂存脚本
- `DONE` 将 Git 仓库收口到正式工程、工具链、项目计划和资料索引

## P0 当前最优先

- `TODO` 增加 `CSR / timer / trap`
- `TODO` 建立最小 `SoC wrapper`
  - 备注：至少接入 `ROM / RAM / UART / timer`
- `TODO` 接入 `riscv-tests`

## P1 紧随其后

- `TODO` 打通 bare-metal 固件编译闭环
- `TODO` 接入 `CoreMark`
- `TODO` 建立 Vivado 工程
- `TODO` 明确开发板、串口、JTAG、约束文件来源

## P2 性能优化与比赛交付

- `TODO` 确定第 1 个性能优化项
  - 建议：更完整的 forwarding / branch handling
- `TODO` 确定第 2 个性能优化项
  - 建议：轻量级 branch prediction 或 prefetch
- `TODO` 建立资源与频率统计表
- `TODO` 建立比赛文档与演示材料目录

## 当前协作基线

- `DONE` `Git`
- `DONE` `iverilog`
- `DONE` `Vivado 2025.2`
- `DONE` `xsim`
- `DONE` `riscv-none-elf-gcc`
- `DONE` `riscv-none-elf-objdump`
- `DONE` `riscv-none-elf-objcopy`
- `DONE` `rg`
- `TODO` `vsim`（可选）

## 当前备注

- 现在的 `toylog_cpu` 已经不是空骨架，而是五级流水第一版
- 当前最缺的不是继续堆 RTL，而是先把验证链补齐
- 交叉编译器优先采用可直接进入 `PATH` 的预编译工具链
- 安装清单按赛题推荐和团队协作最低环境维护，不按单机快照维护
- 默认同步优先使用 `scripts/stage_default_sync.bat`
- `01-项目管理/01-赛题分析`、`02-官方与规范`、`03-参考实现`、`05-验证测试` 默认只保留本地，不再进入 Git
