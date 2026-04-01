# YH_rv_cpu 回归测试记录

## 模板说明
本文档用于记录每次回归测试的结果。每次测试前请更新日期和测试人。

---

## 测试记录

### YYYY-MM-DD - 测试人

**测试环境：**
- 工具链版本：GCC x.x.x
- Vivado 版本：2025.2
- 测试分支：main

**综合配置：**
- 目标器件：xc7a100tcsg324-1
- 目标频率：100MHz

**仿真测试结果：**

| 测试项 | 结果 | 周期数 | 备注 |
|--------|------|--------|------|
| RV32 SoC 烟测 | 通过/失败 | - | |
| RV32 Trap 烟测 | 通过/失败 | - | |
| RV32 Timer IRQ 烟测 | 通过/失败 | - | |
| RV32 riscv-tests | 通过/失败 | - | |
| RV64 riscv-tests | 通过/失败 | - | |
| CoreMark | 通过/失败 | - | |

**综合结果：**

| 指标 | 结果 |
|------|------|
| Setup WNS | +X.XXX ns |
| Hold WHS | +X.XXX ns |
| Slice LUTs | X,XXX |
| Slice Registers | X,XXX |
| BRAM | X |

**测试结论：**
- [ ] 通过 - 可以合并
- [ ] 失败 - 需要修复

**问题记录：**
- 问题 1：描述

---

### 2026-04-01 - Toylog

**测试环境：**
- 工具链版本：GCC 13.2.0
- Vivado 版本：2025.2
- 测试分支：main

**综合配置：**
- 目标器件：xc7a100tcsg324-1
- 目标频率：100MHz

**仿真测试结果：**

| 测试项 | 结果 | 周期数 | 备注 |
|--------|------|--------|------|
| RV32 SoC 烟测 | 通过 | - | |
| RV32 Trap 烟测 | 通过 | - | |
| RV32 Timer IRQ 烟测 | 通过 | - | |
| RV32 riscv-tests | 通过 | - | add/addi 等 21 个测试 |
| RV64 riscv-tests | 通过 | - | add/addi 等 21 个测试 |
| CoreMark | 通过 | 200 次迭代 | CRC 不匹配(soft-float 预期) |

**综合结果：**

| 指标 | 结果 |
|------|------|
| Setup WNS | +2.481 ns |
| Hold WHS | +0.602 ns |
| Slice LUTs | 2,598 |
| Slice Registers | 2,240 |
| BRAM | 4 |

**测试结论：**
- [x] 通过 - 可以合并

**问题记录：**
- 无

---
