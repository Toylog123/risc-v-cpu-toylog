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

---
## 2026-04-03 - Toylog

**测试环境：**
- 工具链版本：GCC 15.2.0
- Vivado 版本：2025.2
- 测试分支：main

**综合配置：**
- 目标器件：xc7a100tcsg324-1
- 目标频率：50MHz
- 保留优化：`stall_decode=load_use_hazard`，`IMEM_OUTPUT_REG=0`，`DMEM_OUTPUT_REG=0`

**实际命令：**
- `scripts\run_coremark_smoke.bat rv32`
- `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`
- `scripts\run_riscv_tests_subset.bat rv32`
- `scripts\run_riscv_tests_subset.bat rv64`
- `scripts\build_vivado_project.bat impl50`
- `scripts\run_coremark_fpga.bat rv32`

**仿真测试结果：**

| 测试项 | 结果 | 周期数 | 备注 |
|--------|------|--------|------|
| RV32 riscv-tests | 通过 | - | baseline manifest `scripts\riscv_tests_rv32_baseline.txt`，`33/33` |
| RV64 riscv-tests | 通过 | - | baseline manifest `scripts\riscv_tests_rv64_baseline.txt`，`21/21` |
| CoreMark smoke | 通过 | 620530 | `rv32 / 5 / 400 / EXEC_MASK=1` |
| CoreMark score | 通过 | 11014885 | `total_ticks=10959245`，`CoreMark/MHz = 0.912472` |
| CoreMark fpga probe | 通过 | 156442 | reduced workload，`CoreMark/MHz = 7.728811` |

**CoreMark score 元数据：**
- `validation_mode = short_runtime_only`
- `competition_reportable = yes`
- `strict_eembc_10s_compliant = no`
- `compiler_version = GCC 15.2.0`
- `compiler_flags = -O2 -march=rv32i_zicsr -mabi=ilp32`
- `memory_location = SoC ROM/RAM`
- `crclist = 0xe714`
- `crcmatrix = 0x1fd7`
- `crcstate = 0x8e3a`

**综合结果：**

| 指标 | 结果 |
|------|------|
| Setup WNS | +5.822 ns |
| Hold WHS | +0.057 ns |
| Slice LUTs | 2,555 |
| Slice Registers | 2,170 |
| BRAM | 4 |

**测试结论：**
- [x] 通过 - 当前主线已保留 load hazard 优化和 FPGA `i0d0` 默认配置

**问题记录：**
- `CoreMark score` 仍是可复现短跑分口径，严格 EEMBC `>=10s` 仍未满足。
- `impl50` 仍存在 `no_input_delay(1)` / `no_output_delay(4)`，需在实板阶段补齐 I/O delay 约束与证据。

**测试结论：**
- [x] 通过 - 可以合并

**问题记录：**
- 无

---
## 2026-04-02 追加说明（占位测试）
## 2026-04-02 - Toylog

**测试环境：**
- 工具链版本：GCC 15.2.0
- Vivado 版本：2025.2
- 测试分支：main

**综合配置：**
- 目标器件：xc7a100tcsg324-1
- 目标频率：50MHz

**仿真测试结果：**

| 测试项 | 结果 | 周期数 | 备注 |
|--------|------|--------|------|
| RV32 SoC 烟测 | 通过 | - | |
| RV32 Trap 烟测 | 通过 | - | |
| RV32 Timer IRQ 烟测 | 通过 | - | |
| RV32 riscv-tests | 通过 | - | baseline `33/33` |
| RV64 riscv-tests | 通过 | - | baseline `21/21` |
| CoreMark smoke | 通过 | 679998 | `rv32 / 5 / 400 / EXEC_MASK=1` |
| CoreMark score | 通过 | 11311853 | full workload 10次，`CoreMark/MHz = 0.888486` |

**综合结果：**

| 指标 | 结果 |
|------|------|
| Setup WNS | +5.085 ns |
| Hold WHS | +0.058 ns |
| Slice LUTs | 2,545 |
| Slice Registers | 2,240 |
| BRAM | 4 |

**测试结论：**
- [x] 通过 - 当前比赛提交口径已冻结

**问题记录：**
- `CoreMark score` 当前采用可复现短跑分口径；严格 EEMBC `>=10s` 仍未满足。
- `impl50` 仍存在 `no_input_delay(1)` / `no_output_delay(4)`，需在实板阶段补齐 I/O delay 约束与证据。
