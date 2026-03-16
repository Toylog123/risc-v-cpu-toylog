# YH_rv_cpu 初步设计

## 1. 项目定位

`YH_rv_cpu` 面向七星微赛题，目标不是只做一个能跑的教学核，而是逐步形成可验证、可上板、可提交的正式比赛工程。

当前技术基线是 `RV32I + Zicsr`，后续主线是推进到 `RV32 / RV64` 共线。

## 2. 当前基线

- 当前验证基线：`RV32I + Zicsr`
- 当前微架构：五级流水
- 当前数据通路状态：关键路径已抽出 `XLEN`
- 当前 SoC：最小可运行系统
- 当前异常和中断：最小机器态 trap + machine timer interrupt

已经打通：

- `IF / ID / EX / MEM / WB`
- 基础前递
- `load-use` 暂停
- 分支和跳转重定向
- `CSR / trap`
- `timer interrupt`

## 3. 五级流水结构

1. `IF`
   - 取指和 `PC` 更新
2. `ID`
   - 指令译码、寄存器读取、立即数生成
3. `EX`
   - ALU 运算、分支判断、访存地址生成、trap / interrupt 判定
4. `MEM`
   - 访存和 load 数据整理
5. `WB`
   - 写回寄存器堆

## 4. Trap / Interrupt

当前已实现的最小机器态路径：

- CSR
  - `mstatus`
  - `mie`
  - `mip`
  - `mtvec`
  - `mscratch`
  - `mepc`
  - `mcause`
- 指令
  - `csrrw / csrrs / csrrc`
  - 立即数 CSR 形式
  - `ecall / ebreak / mret`
- 事件
  - 同步 trap
  - machine timer interrupt

## 5. 最小 SoC

当前 SoC 顶层是 `rtl/YH_rv_cpu_soc.v`，包含：

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

## 6. 当前验证链路

- `scripts/check_syntax.bat`
- `scripts/build_firmware.bat`
- `scripts/run_soc_smoke.bat`
- `scripts/run_trap_smoke.bat`
- `scripts/run_timer_irq_smoke.bat`

当前结论：

- SoC smoke：通过
- trap smoke：通过
- timer irq smoke：通过
- xlen64 smoke：通过

## 7. RV32 / RV64 共线改造路线

### 第一步：抽出 `XLEN`

- 给顶层和关键数据通路增加 `XLEN`
- 把固定 `31:0` 的关键数据路径改成 `XLEN-1:0`
- 当前状态：已完成第一版骨架，`RV32` 烟测保持通过

### 第二步：整理译码和立即数

- 统一立即数生成逻辑，按 `XLEN` 做扩展
- 明确 `RV32` 和 `RV64` 在移位、写回和后续 `W` 类指令上的边界
- 当前状态：已补上 `XLEN=64` 下的 6 位移位量基础支持，并有专门烟测

### 第三步：整理 ALU 和访存位宽

- 让 ALU 基本算术逻辑具备按 `XLEN` 工作的能力
- 把当前 `byte / half / word` 路径整理成可继续扩到 `doubleword`

### 第四步：拆分验证

- 继续保留当前 `RV32` 烟测
- 后续新增 `RV64` 基础烟测
- 接 `riscv-tests` 时按 `rv32` / `rv64` 分开管理

## 8. 当前风险

- 当前验证深度还不够，烟测通过不代表 ISA 级稳定
- `RV64` 改造一旦节奏不稳，容易影响当前 `RV32` 基线
- `riscv-tests`、`CoreMark`、FPGA 上板都还没接进主线

## 9. 当前最该做的事

1. 继续补 `RV64` 译码、访存和 `W` 类语义边界
2. 接 `riscv-tests`
3. 接 `CoreMark`
4. 建正式 `Vivado` 工程
