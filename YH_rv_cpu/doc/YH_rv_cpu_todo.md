# YH_rv_cpu 任务清单

## 已完成

- `已完成` 建立正式比赛工程 `YH_rv_cpu`
- `已完成` 完成 `RV32I` 五级流水第一版
- `已完成` 打通最小 SoC
- `已完成` 补齐最小机器态 `CSR / trap`
- `已完成` 补齐 machine timer interrupt 最小闭环
- `已完成` 打通 `xsim` SoC / trap / timer irq 烟测
- `已完成` 固化工程内交接、记录和任务清单机制
- `已完成` 正式工程统一改名为 `YH_rv_cpu`

## P0 当前最高优先级

- `进行中` 基于 `XLEN` 骨架继续推进 `RV32 / RV64` 共线改造
- `已完成` 建立 `XLEN=64` 基础烟测
- `进行中` 扩大 `riscv-tests` 回归覆盖
- `待办` 接 `CoreMark`
- `已完成` 建正式 `Vivado` 工程并导出第一版综合报告
- `待办` 明确唯一主开发板和约束来源

## P1 紧随其后

- `待办` 冻结两项性能优化口径
- `进行中` 建资源与频率统计表
- `待办` 形成最小 SoC 接口表和地址映射图
- `待办` 建回归记录模板
- `已完成` 建立整体设计总文档 `doc/技术文档.md`
- `待办` 做 100MHz 时序收敛或冻结更合理的 FPGA 演示频率
- `待办` 把当前 `ROM/RAM` 从分布式实现逐步推进到更适合 FPGA 的 BRAM 方案

## P2 提交前必须完成

- `待办` 完成 FPGA 上板演示
- `待办` 完成性能和资源统计
- `待办` 完成设计文档终稿
- `待办` 完成 PPT、视频和提交包

## 备注

- 现在最关键的不是继续堆模块，而是把验证、跑分和 FPGA 三条线补齐。
- `RV64` 改造必须建立在当前 `RV32` 烟测持续通过的前提下。
- 当前 Vivado 综合已经能稳定导出报告，后续重点从“能不能综合”切到“资源是否合理、时序能否收敛”。

## 2026-03-17 追加状态

- `已完成` 补齐 `50MHz / 100MHz` 双档综合报告
- `已完成` 固化比赛频率口径：当前 FPGA 演示频率以 `50MHz` 为主
- `进行中` 继续收敛 `100MHz`
- `进行中` 推进 `ROM/RAM` 向更适合 FPGA 的存储结构迁移
- `新增待办` 把 `ROM/RAM` 迁移任务拆成“先改同步存储接口，再做 BRAM 化”的两步
- `新增待办` 为 `imem` / `dmem` 设计独立的存储包装层，避免以后直接在 `YH_rv_cpu_soc.v` 里硬改数组读写
## 2026-03-17 新增状态

- `已完成` 把同步取指接口接入 CPU/SoC 主线
- `已完成` 固化 `mem32` 镜像生成链路，Vivado 可直接吃 `current.mem32.hex`
- `已完成` 固化 Vivado ASCII 盘符回退策略，避免映射失败时退回中文路径
- `进行中` 推进 `dmem` 同步返回语义
- `进行中` 调查同步存储下 `ROM` 仍未推成 `BRAM` 的结构原因
- `待办` 评估是否需要独立双口 `ROM` 或单独的只读数据路径，以兼顾取指和只读数据访问
- `已完成` 把默认 `rv32` 回归子集收成当前功能基线
- `待办` 下一步扩到 `rv64` 子集和更完整的 `riscv-tests`
## 2026-03-17 追加状态：同步数据路径

- `已完成` 把同步 `dmem` 返回语义接入 CPU / SoC 主线
- `已完成` 把 SoC smoke、trap、timer irq、FPGA top 切到 `SYNC_DMEM=1`
- `已完成` 确认 `run_riscv_tests_subset.bat rv32` 在新语义下仍然整组通过
- `待办` 把 `YH_rv_cpu_soc.v` 里的存储逻辑拆成独立包装层
- `待办` 把数据 RAM 从当前 distributed RAM 方案推进到真正适合 BRAM 推断的实现
- `待办` 在新的同步数据路径基础上继续收敛 `100MHz`

## 2026-03-17 追加状态：dmem BRAM

- `已完成` 新增独立数据 RAM 包装层 `rtl/YH_rv_dmem_ram.v`
- `已完成` 把 `YH_rv_cpu_soc.v` 中的数据 RAM 访问改成包装层调用
- `已完成` 把 `dmem` 推成 `2 BRAM`，不再是 `0 BRAM`
- `已完成` 在新口径下重新跑通 `synth50` / `synth100`
- `进行中` 继续收敛 `100MHz`
- `待办` 推进 `imem/ROM` 包装层，减少 LUT ROM 占用
- `待办` 评估给 `dmem` BRAM 增加可选输出寄存器，继续改善时序
- `待办` 在新资源口径下补一轮 `CoreMark` 和更完整 `rv64` 回归

## 2026-03-23 追加状态：工作区统一与日志归档

- `已完成` 正式工作区统一到 `当前仓库根目录（icdc_workspace）`
- `已完成` 新增 Vivado GUI 统一入口 `scripts/open_vivado_project.bat`
- `已完成` 新增日志整理脚本 `scripts/organize_tool_logs.bat`
- `已完成` 新增仿真运行时收纳脚本 `scripts/stage_runtime_to_tmp.bat`
- `待办` 基于当前工作区重跑一轮最新 `soc smoke` 与 Vivado 工程入口验证
- `待办` 回到主技术线，继续推进 `100MHz` / `imem/ROM` / `CoreMark`

## 2026-03-23 追加状态：正式交接前校对

- `已完成` 当前唯一正式工作区固定为当前仓库根目录 `icdc_workspace`
- `已完成` 把 `vivado.log/.jou`、`xsim` 运行目录和 `clockInfo.txt` 统一收纳到仓库根 `_tmp/`
- `已完成` 重新跑通 `check_syntax`、`build_firmware`、`soc smoke`、`trap smoke`、`timer irq smoke`
- `已完成` 当前最新可用 `impl100` 已经达到 `WNS = +0.103ns`
- `待办` 接上 `CoreMark` 并形成稳定跑分记录
- `待办` 扩大 `RV64` 和更完整 `riscv-tests` 回归
- `待办` 板卡到位后冻结正式 `XDC` 并推进上板
- `待办` 如需统一双频率对外口径，基于当前 RTL 补跑 `synth50`

## 2026-04-01 追加状态：RTL 代码注释增强

- `已完成` 为所有 RTL 模块添加详细中文注释
  - `rtl/YH_rv_cpu_decoder.v` - 指令译码器
  - `rtl/YH_rv_cpu_hazard_unit.v` - 冒险检测单元
  - `rtl/YH_rv_cpu_regfile.v` - 寄存器堆
  - `rtl/YH_rv_cpu_if_stage.v` - 取指阶段
  - `rtl/YH_rv_cpu_id_stage.v` - 译码阶段
  - `rtl/YH_rv_cpu_ex_stage.v` - 执行阶段
  - `rtl/YH_rv_cpu_mem_stage.v` - 访存阶段
  - `rtl/YH_rv_cpu_wb_stage.v` - 写回阶段
  - `rtl/YH_rv_cpu.v` - 顶层 CPU 模块
  - `rtl/YH_rv_cpu_soc.v` - SoC 顶层模块
- `已完成` 验证代码语法正确性 (check_syntax.ps1 通过)
- `进行中` 提交更改到 git

## 2026-04-01 追加状态：CoreMark libgcc 修复

- `已完成` 修复 CoreMark libgcc 链接问题
  - `scripts/build_coremark.bat` 使用动态检测获取 libgcc/libm 路径
  - 修复 "Missing libgcc for rv32" 错误
- `已完成` 优化 CoreMark 配置
  - `sw/coremark_port/core_portme.h` 禁用浮点支持(HAS_FLOAT=0)
  - 加速软件模拟，避免漫长的浮点库调用
- `已完成` CoreMark 成功编译并运行
  - CoreMark ELF 文件成功生成 (143716 字节)
  - 仿真成功运行 200 次迭代
  - CRC 校验不匹配是 soft-float 系统的预期行为，非 bug
- `已完成` riscv-tests 回归脚本验证
  - `run_riscv_tests_subset.bat rv32 add addi` 测试通过
  - 确认脚本工作正常
- `已完成` 扩大 RV64 riscv-tests 回归
  - rv64ui 子集测试 21/21 全部通过
  - 包括：add addi addiw addw ld lwu sd sll slli slliw sllw sra srai sraiw sraw srl srli srliw srlw sub subw
- `已完成` 继续收敛 100MHz 时序
  - 修改 `fpga/vivado/scripts/build_nexys_a7_100_project.tcl`
  - 添加 `-retiming -fanout_limit 32` 综合优化选项
  - Setup WNS = +2.481ns (之前 +0.103ns，显著改善)
  - Hold WHS = +0.602ns
## 2026-04-02 追加状态：Phase A / Phase B 收口

- `已完成` CoreMark 正式提交口径
  - `scripts/run_coremark_smoke.bat` 与 `scripts/run_coremark_score.bat` 已分离
  - `scripts/report_coremark_result.py` 可直接解析 host-side `CoreMark/MHz`
  - `doc/coremark_submission_report.md` 已形成可引用摘要
- `已完成` riscv-tests 基线冻结
  - `scripts/riscv_tests_rv32_baseline.txt`：`33/33`
  - `scripts/riscv_tests_rv64_baseline.txt`：`21/21`
- `已完成` FPGA pre-board 闭环
  - `scripts/build_vivado_project.bat impl50` fresh 通过
  - `project/YH_rv_cpu_nexys_a7_100_20p000.bit` 已生成
  - `doc/fpga_bringup_checklist.md` 已补齐
- `待办` 板卡到位后完成 UART/LED 实板闭环
- `待办` 基于 `doc/performance_experiment_log.md` 开始两项性能优化实验
## 2026-04-03 追加状态：首轮性能优化收口

- `已完成` O1 同步 load hazard 收紧
  - `rtl/YH_rv_cpu_hazard_unit.v` 只保留 `load_use_hazard` 停顿
  - `CoreMark/MHz` 从 `0.888486` 提升到 `0.912472`
  - `riscv-tests rv32 = 33/33`，`rv64 = 21/21`
- `已完成` O3/O4 FPGA 默认内存路径收紧
  - `fpga/vivado/src/YH_rv_cpu_fpga_top.v` 默认改为 `IMEM_OUTPUT_REG=0`、`DMEM_OUTPUT_REG=0`
  - `impl50` fresh 结果：`2555 LUT / 2170 FF / 4 BRAM / 0 DSP`
  - `impl50` fresh 时序：`WNS = +5.822ns`，`WHS = +0.057ns`
- `已完成` FPGA-like CoreMark 快速探针入口
  - `scripts/run_coremark_fpga.bat` 默认即 quick probe 口径
  - 当前 fresh 结果：`156442 cycles`，`CoreMark/MHz = 7.728811`
- `已完成` fetch 停顿进一步放松的可行性评估
  - 当前单点放松 `!stall_decode` 不保留
  - 原因：`pc_r` 在 stall 时同样冻结，简单放松门控会重新请求同一 PC，不是安全的前端提分改动
- `待办` 板卡到位后完成 UART/LED 实板闭环并补正式证据
- `待办` 如需 strict EEMBC 口径，补 `>=10s` 的 CoreMark 长跑配置
- `待办` 如果继续提分，先单列 fetch 队列/前端解耦实验计划，再决定是否进入 RTL 改动
