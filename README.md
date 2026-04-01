# YH_rv_cpu

## 作者
Toylog

## 版本
v1.0

## 功能概述
YH_rv_cpu 是一款面向七星微杯《基于 RISC-V 的高性能 CPU 设计及 FPGA 验证》竞赛的 RISC-V 处理器实现。项目基于 RV32I + Zicsr 架构，采用五级流水线设计，已完成最小 SoC 系统搭建、RTL 仿真验证和 Vivado FPGA 综合链路，目标实现 RV32/RV64 双架构共线演进。

## 目录结构

```
icdc_workspace/
├── YH_rv_cpu/                    # 正式比赛工程
│   ├── rtl/                      # RTL 源代码
│   │   ├── YH_rv_cpu.v           # CPU 顶层模块
│   │   ├── YH_rv_cpu_defs.vh     # 宏定义（ISA/CSR/trap）
│   │   ├── YH_rv_cpu_if_stage.v  # 取指级
│   │   ├── YH_rv_cpu_id_stage.v  # 译码级
│   │   ├── YH_rv_cpu_decoder.v   # 指令译码器
│   │   ├── YH_rv_cpu_ex_stage.v  # 执行级
│   │   ├── YH_rv_cpu_mem_stage.v  # 访存级
│   │   ├── YH_rv_cpu_wb_stage.v  # 写回级
│   │   ├── YH_rv_cpu_alu.v       # 算术逻辑单元
│   │   ├── YH_rv_cpu_regfile.v   # 通用寄存器堆
│   │   ├── YH_rv_cpu_hazard_unit.v  # 冒险检测与前递
│   │   ├── YH_rv_cpu_soc.v       # SoC 顶层
│   │   ├── YH_rv_dmem_ram.v      # 数据存储器（BRAM）
│   │   ├── YH_rv_sync_imem_rom.v # 指令 ROM
│   │   └── YH_rv_sync_rom32.v    # ROM 组件
│   │
│   ├── tb/                       # 测试平台
│   │   ├── YH_rv_cpu_tb.v        # 基础 CPU 测试平台
│   │   ├── YH_rv_cpu_soc_tb.v    # SoC 烟测
│   │   ├── YH_rv_cpu_trap_tb.v   # trap 烟测
│   │   ├── YH_rv_cpu_timer_irq_tb.v  # 定时器中断烟测
│   │   ├── YH_rv_cpu_xlen64_tb.v # XLEN=64 烟测
│   │   ├── YH_rv_cpu_riscv_tests*.v  # riscv-tests 平台
│   │   └── YH_rv_cpu_coremark*.v    # CoreMark 平台
│   │
│   ├── sw/                       # 固件与软件
│   │   ├── src/                  # 源代码
│   │   │   ├── main.c            # 主程序
│   │   │   ├── crt0.S            # 启动代码
│   │   │   ├── trap_entry.S      # trap 入口
│   │   │   └── timer_irq_entry.S # 定时器中断入口
│   │   ├── linker/               # 链接脚本
│   │   │   ├── YH_rv_cpu.ld
│   │   │   ├── YH_rv_cpu_coremark.ld
│   │   │   └── YH_rv_cpu_riscv_tests.ld
│   │   └── coremark_port/        # CoreMark 移植
│   │
│   ├── scripts/                  # 构建与测试脚本
│   │   ├── check_toolchain.bat   # 检查工具链
│   │   ├── check_syntax.bat      # 语法检查
│   │   ├── build_firmware.bat    # 构建固件
│   │   ├── run_soc_smoke.bat     # SoC 烟测
│   │   ├── run_trap_smoke.bat    # trap 烟测
│   │   ├── run_timer_irq_smoke.bat  # 定时器中断烟测
│   │   ├── run_xlen64_smoke.bat  # XLEN=64 烟测
│   │   ├── run_riscv_tests_subset.bat  # riscv-tests 子集
│   │   ├── build_vivado_project.bat  # Vivado 综合
│   │   └── clean_vivado_project.bat   # 清理工程
│   │
│   ├── fpga/vivado/              # FPGA 相关
│   │   ├── src/                  # FPGA 顶层
│   │   │   ├── YH_rv_cpu_fpga_top.v
│   │   │   └── YH_rv_uart_tx.v
│   │   ├── constraints/          # 约束文件
│   │   │   └── nexys_a7_100_template.xdc
│   │   ├── scripts/              # Tcl 脚本
│   │   │   └── build_nexys_a7_100_project.tcl
│   │   └── README.md
│   │
│   └── doc/                      # 技术文档
│       ├── 技术文档.md            # 整体设计总览
│       ├── YH_rv_cpu_preliminary_design.md  # 初步设计
│       ├── YH_rv_cpu_handoff.md  # 交接文档
│       ├── YH_rv_cpu_change_log.md  # 变更日志
│       ├── YH_rv_cpu_todo.md     # 任务清单
│       └── 项目结构说明.md
│
├── 01-项目管理/                   # 项目管理文档
│   ├── 01-赛题要求/
│   ├── 02-项目规划/
│   ├── 03-过程管理/
│   └── 04-资料索引/
│
└── 04-工具链/                    # 工具链配置
    └── YH_rv_cpu_toolchain/
```

## 技术规格

### 处理器架构
| 参数 | 值 |
|------|-----|
| ISA | RV32I + Zicsr |
| 流水线 | 五级流水 (IF/ID/EX/MEM/WB) |
| XLEN | 参数化 (32/64) |
| 寄存器数量 | 32 个通用寄存器 |
| CSR 数量 | 8 个机器态 CSR |

### 已实现指令集
- **整数计算指令**: ADD, SUB, SLT, SLTU, XOR, OR, AND, SLL, SRL, SRA
- **访存指令**: LB, LBU, LH, LHU, LW, SB, SH, SW
- **分支指令**: BEQ, BNE, BLT, BGE, BLTU, BGEU
- **跳转指令**: JAL, JALR
- **上位指令**: AUIPC, LUI
- **CSR 指令**: CSRRW, CSRRS, CSRRC 及其立即数变体
- **系统指令**: ECALL, EBREAK, MRET

### 已实现 CSR 寄存器
| 地址 | 名称 | 描述 |
|------|------|------|
| 0x300 | mstatus | 机器状态寄存器 |
| 0x304 | mie | 机器中断使能寄存器 |
| 0x305 | mtvec | 机器陷阱向量寄存器 |
| 0x340 | mscratch | 机器临时寄存器 |
| 0x341 | mepc | 机器异常程序计数器 |
| 0x342 | mcause | 机器异常原因寄存器 |
| 0x344 | mip | 机器中断挂起寄存器 |

### SoC 地址映射
| 地址范围 | 设备 | 描述 |
|----------|------|------|
| 0x0000_0000 | ROM | 指令存储器 |
| 0x0000_4000 | RAM | 数据存储器 |
| 0x1000_0000 | UART_TX | 串口发送 |
| 0x1000_0004 | DONE | 完成标志 |
| 0x1000_0008 ~ 0x1000_0018 | TIMER | 定时器 |

## 快速开始

### 环境要求
- Windows 操作系统
- Vivado (用于 FPGA 综合)
- xPack RISC-V 工具链
- Icarus Verilog (用于仿真)
- Python 3.x

### 快速验证流程

```bat
:: 1. 检查工具链
scripts\check_toolchain.bat

:: 2. 检查语法
scripts\check_syntax.bat

:: 3. 构建固件
scripts\build_firmware.bat

:: 4. 运行烟测
scripts\run_soc_smoke.bat
scripts\run_trap_smoke.bat
scripts\run_timer_irq_smoke.bat

:: 5. 运行 riscv-tests 子集
scripts\run_riscv_tests_subset.bat rv32 add
```

### FPGA 综合流程

```bat
:: 综合 (50MHz)
scripts\build_vivado_project.bat synth50

:: 综合 (100MHz)
scripts\build_vivado_project.bat synth100

:: 清理工程
scripts\clean_vivado_project.bat

:: 打开工程
scripts\open_vivado_project.bat
```

## 验证结果

### 仿真测试
| 测试项 | 状态 | 周期数 |
|--------|------|--------|
| SoC smoke | PASS | 102 cycles |
| trap smoke | PASS | 79 cycles |
| timer irq smoke | PASS | 125 cycles |
| xlen64 smoke | PASS | 17 cycles |
| riscv-tests rv32 (子集) | PASS | 495 cycles |

### FPGA 综合结果 (xc7a100tcsg324-1)

| 频率 | LUT | FF | LUTRAM | BRAM | DSP | WNS |
|------|-----|-----|--------|------|-----|-----|
| 50MHz | 3692 | 2069 | 1024 | 2 | 0 | +7.553ns |
| 100MHz | 3713 | 2066 | 1024 | 2 | 0 | -2.475ns |

> 注：50MHz 目标已满足，100MHz 正在优化中

## 微架构详情

### 五级流水线

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   IF    │───▶│   ID    │───▶│   EX    │───▶│   MEM   │───▶│   WB    │
│ 取指级  │    │ 译码级  │    │ 执行级  │    │ 访存级  │    │ 写回级  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     ▼              ▼              ▼              ▼              ▼
   PC更新        寄存器读       ALU运算       数据访存       写回寄存器
   取指          立即数生成     分支判断      Load数据整理    选择结果
                               访存地址                      (ALU/MEM/PC4)
                               Store发送
```

### 冒险处理
- **Load-Use 冒险**: 暂停流水线
- **前递路径**: EX/MEM → ID, MEM/WB → ID
- **分支冒险**:  Flush IF/ID

### 中断与异常
- 支持 machine timer interrupt
- 支持 ecall/ebreak 异常
- 支持 illegal instruction 异常
- 支持 misaligned 地址异常

## 项目路线图

### 已完成
- [x] 五级流水基线 (RV32I)
- [x] XLEN 参数化骨架
- [x] 最小 SoC (ROM/RAM/UART/DONE/timer)
- [x] CSR/trap 机制
- [x] machine timer interrupt
- [x] riscv-tests 子集回归
- [x] Vivado 综合链路 (50MHz)

### 进行中
- [ ] RV64 指令扩展
- [ ] riscv-tests 全量回归
- [ ] CoreMark 跑通
- [ ] 100MHz 时序收敛

### 待完成
- [ ] FPGA 板级闭环
- [ ] 性能优化
- [ ] 完整文档

## 协作规范

### 提交前检查
修改任何文件后，必须同步更新：
- `doc/YH_rv_cpu_handoff.md` - 交接文档
- `doc/YH_rv_cpu_change_log.md` - 变更日志
- `doc/YH_rv_cpu_todo.md` - 任务清单

### 代码规范
- 源码注释使用中文
- 模块名、信号名、脚本名保留英文
- 代码注释率不低于 30%

## 比赛信息

- **赛事**: 七星微杯《基于 RISC-V 的高性能 CPU 设计及 FPGA 验证》
- **报名截止**: 2026-03-31
- **初赛提交**: 2026-05-07
- **分赛区决赛**: 2026-06 ~ 2026-07
- **全国总决赛**: 2026-07 下旬

## 参考资料

- 集创赛报名页: https://www.saikr.com/vse/univ/ciciec/10
- RISC-V 官方规范: https://riscv.org/technical/specifications/
