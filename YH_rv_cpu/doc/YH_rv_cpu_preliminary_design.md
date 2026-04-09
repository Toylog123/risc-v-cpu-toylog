# YH_rv_cpu 初步设计

## 1. 项目定位

`YH_rv_cpu` 面向比赛提交，目标不是做一个能跑的教学核，而是逐步形成可验证、可上板、可交接、可继续优化的正式工程。

说明：

- 本文档是设计背景与架构说明，不是当前结果口径的权威来源
- 当前冻结结果请以 `README.md`、`doc/技术文档.md`、`doc/regression_test_log.md` 为准
- 截至 `2026-04-08`，普遍 `riscv-tests` 扩展验证已经闭环；`rv32 full-ui = 42/42`、`rv64 full-ui = 54/54`，`fence_i` 已在扩展 `zifencei` 覆盖矩阵下通过

## 2. 当前设计基线

- 当前主线 ISA：`RV32I + Zicsr`
- 当前共线验证：`RV64` baseline regression
- 当前微架构：五级流水
- 当前 SoC：最小可运行系统
- 当前异常与中断：最小 machine-mode trap + machine timer interrupt

当前已打通：

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

当前已实现的最小 machine-mode 路径：

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

## 6. 当前验证状态与设计边界

- 当前冻结基线已经验证：
  - CoreMark short
  - strict `>=10s` CoreMark
  - RV32 baseline
  - RV64 baseline
  - impl50
  - FPGA-like probe
- 更广覆盖的 `riscv-tests` 扩展验证已在 `2026-04-08` 完成收口
- 当前设计边界仍然是 `RV32I + Zicsr`，因此任何 `zifencei` 相关结论都必须明确写清是否纳入口径
