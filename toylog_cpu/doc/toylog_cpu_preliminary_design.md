# toylog_cpu 初步设计

## 1. 项目定位

当前正式工程目录仍为 `toylog_cpu/`，后续会整体切换为 `YH_rv_cpu`。
这个工程面向七星微赛题，目标不是停留在一个能跑的教学核，而是逐步形成可验证、可上板、可交付的比赛工程。

## 2. 当前基线

- 当前验证基线：`RV32I`
- 当前微架构：五级流水
- 当前闭环状态：
  - 最小 SoC 已打通
  - 同步 trap 已打通
  - machine timer interrupt 已打通

当前已经具备：

- `IF / ID / EX / MEM / WB`
- 基础前递
- `load-use` 暂停
- 分支 / 跳转重定向
- 最小机器态 CSR
- `ecall / ebreak / mret`
- `timer interrupt`

## 3. 架构目标

### 3.1 指令集路线

- 当前已验证：`RV32I + Zicsr`
- 下一阶段目标：把工程从单一 `RV32` 推进到 `RV32 / RV64` 共线支持
- 后续可选扩展：`M`

这里的关键不是简单地“换成 64 位寄存器”，而是让工程具备双位宽演进能力：

- 同一套流水线结构
- 同一套控制路径
- 同一套验证框架
- 按 `XLEN=32 / 64` 切换数据通路和部分译码行为

### 3.2 流水线

当前保持五级流水：

1. `IF`：取指与 `PC` 选择
2. `ID`：译码与寄存器读
3. `EX`：运算、地址生成、分支判断、trap / interrupt 判定
4. `MEM`：访存
5. `WB`：写回

### 3.3 Trap / Interrupt

当前已经实现的最小机器态路径：

- CSR：
  - `mstatus`
  - `mie`
  - `mip`
  - `mtvec`
  - `mscratch`
  - `mepc`
  - `mcause`
- 指令：
  - `csrrw / csrrs / csrrc`
  - 立即数 CSR 形式
  - `ecall / ebreak / mret`
- 事件：
  - 同步异常
  - machine timer interrupt

## 4. 最小 SoC

当前 SoC 顶层为 `rtl/toylog_cpu_soc.v`，包含：

- `ROM`
- `RAM`
- `UART`
- `DONE`
- `timer`

当前地址映射：

- `ROM`：`0x0000_0000`
- `RAM`：`0x0000_4000`
- `UART_TX`：`0x1000_0000`
- `DONE`：`0x1000_0004`
- `TIMER_VALUE_LO`：`0x1000_0008`
- `TIMER_VALUE_HI`：`0x1000_000C`
- `TIMER_CMP_LO`：`0x1000_0010`
- `TIMER_CMP_HI`：`0x1000_0014`
- `TIMER_CTRL`：`0x1000_0018`

## 5. 已有验证链路

- `scripts/check_syntax.bat`
- `scripts/build_firmware.bat`
- `scripts/run_soc_smoke.bat`
- `scripts/run_trap_smoke.bat`
- `scripts/run_timer_irq_smoke.bat`

当前已通过的结论：

- SoC 烟测通过
- trap 烟测通过
- timer interrupt 烟测通过

## 6. RV32 / RV64 共线改造路线

这部分是接下来最重要的结构工作。

### 第一步：抽出位宽参数

- 给顶层和关键数据通路增加 `XLEN`
- 把固定 `31:0` 的数据路径逐步改成 `XLEN-1:0`
- 保留地址、指令、CSR 编号等天然 32 位字段

### 第二步：整理译码与立即数生成

- 保留通用 opcode / funct 译码
- 区分 `RV32` 和 `RV64` 在移位、加载扩展、写回截断上的差异
- 为后续 `W` 类指令预留位置

### 第三步：整理 ALU 和访存宽度

- ALU 基本算术逻辑改成随 `XLEN` 扩展
- load/store 路径支持字长差异
- 明确 `byte / half / word / doubleword` 的行为边界

### 第四步：验证拆分

- 保留当前 `RV32` 烟测
- 新增 `RV64` 基础烟测
- 后续接 `riscv-tests` 时按 `rv32` / `rv64` 分开跑

## 7. 当前风险

- 目录和模块名还没整体切换到 `YH_rv_cpu`
- 当前 RTL 仍然以 `RV32` 数据通路为主，`RV64` 只是目标，还没有开始大规模改线宽
- `riscv-tests` 和 `CoreMark` 还没接，验证深度仍然不够
- FPGA 工程还没建立

## 8. 当前最值得做的事

1. 整体切换项目名为 `YH_rv_cpu`
2. 启动 `RV32 / RV64` 共线改造，先从 `XLEN` 参数和数据通路开始
3. 接 `riscv-tests`
4. 接 `CoreMark`
5. 建 `Vivado` 工程并推进上板
