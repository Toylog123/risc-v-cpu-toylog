# YH_rv_cpu 回归测试记录

## 使用规则

- `2026-04-07` 条目是当前冻结基线的完整 fresh 记录
- `2026-04-08` 条目是扩展验证中的活跃记录，不应直接当成新的冻结基线引用
- 只有 fresh 命令、fresh 摘要、文档口径一致时，才能把结果升级为新的正式口径

## 2026-04-07 - Frozen Baseline Refresh

### 测试环境

- GCC: `15.2.0`
- Vivado: `2025.2`
- branch: `main`
- target device: `xc7a100tcsg324-1`
- retained optimizations:
  - `stall_decode=load_use_hazard`
  - `IMEM_OUTPUT_REG=0`
  - `DMEM_OUTPUT_REG=0`

### 实际命令

```bat
scripts\check_syntax.bat
scripts\run_soc_smoke.bat
scripts\run_trap_smoke.bat
scripts\run_timer_irq_smoke.bat
scripts\run_xlen64_smoke.bat
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64
scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
```

### 结果快照

| 项目 | 结果 | 备注 |
|------|------|------|
| SoC smoke | PASS | `PC=00000038`, `164 cycles` |
| trap smoke | PASS | `PC=000000ac`, `89 cycles` |
| timer_irq smoke | PASS | `PC=000000e4`, `136 cycles` |
| xlen64 smoke | PASS | `PC=0000000000000020`, `17 cycles` |
| RV32 baseline | PASS | `33/33` |
| RV64 baseline | PASS | `21/21` |
| CoreMark smoke | PASS | `620530 cycles` |
| CoreMark short | PASS | `11014885 cycles`, `0.912472 CoreMark/MHz` |
| CoreMark strict | PASS | `1095991523 cycles`, `0.912465 CoreMark/MHz`, `10.959325s` |
| impl50 | PASS | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS=+5.599ns`, `WHS=+0.025ns` |
| FPGA-like probe | PASS | `156442 cycles`, `7.728811 CoreMark/MHz` |

### 结论

- 当前冻结主线可回归
- 当前保留优化未打坏 RV32 / RV64 / impl50 / FPGA-like probe
- strict EEMBC `>=10s` CoreMark 已有可引用证据
- 板卡与最终 I/O delay 仍是外部阻塞

## 2026-04-08 - Expanded `riscv-tests` Validation (In Progress)

### 目的

这轮不是新的性能优化，而是把 `riscv-tests` 从冻结 baseline 子集扩展到更接近普遍 `rv32ui/rv64ui` 的真实矩阵，并校验当前设计是否存在更广泛的 ISA/异常处理问题。

### 活跃工作区输入

- `scripts\riscv_tests_rv32_ui_all.txt`
- `scripts\riscv_tests_rv64_ui_all.txt`
- `sw\linker\YH_rv_cpu_riscv_tests_large.ld`
- `scripts\run_riscv_tests_subset.bat` 的扩展参数能力
- `sw\riscv-tests-env\riscv_test.h` 的 misaligned trap 软件补偿

### 实际命令

```bat
scripts\run_riscv_tests_subset.bat rv32 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv32_ui_all.txt rv32i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
scripts\run_riscv_tests_subset.bat rv64 - - 120000 YH_rv_cpu\scripts\riscv_tests_rv64_ui_all.txt rv64i_zicsr_zifencei continue YH_rv_cpu\sw\linker\YH_rv_cpu_riscv_tests_large.ld 0x00008000
```

### 结果快照

| 项目 | 结果 | 备注 |
|------|------|------|
| `rv32 full-ui` 总体 | `42/42` | 摘要：`build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt` |
| `rv64 full-ui` 总体 | `54/54` | 摘要：`build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt` |
| `ma_data` | PASS | 说明 misaligned trap 软件补偿已生效 |
| `fence_i` | PASS | 在 `rv32i_zicsr_zifencei` 口径下通过 |
| 口径说明 | `rv32i_zicsr_zifencei` | 该扩展覆盖矩阵用于 general UI 验证；冻结比赛口径仍维持 `RV32I + Zicsr` |
| `rv32 baseline` fresh rerun | `33/33` | 归档：`build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt` |
| `rv64 baseline` fresh rerun | `21/21` | 归档：`build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt` |
| CoreMark smoke fresh rerun | PASS | `620530 cycles` |
| CoreMark short fresh rerun | PASS | `11014885 cycles`，`0.912472 CoreMark/MHz`，摘要：`build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt` |
| CoreMark strict fresh rerun | PASS | `1095991523 cycles`，`0.912465 CoreMark/MHz`，`10.959325s`，摘要：`build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt` |

### 解释

- 这轮结果已经排除了“`ma_data` 只是跑得慢”的假设
- `rv32 full-ui` 已在扩展 UI 覆盖矩阵下闭环
- `rv64 full-ui`、fresh baseline、fresh CoreMark smoke/short/strict 已全部闭环
- 当前预优化收口阶段已完成，后续如继续本机工作可转入 `FQ-06`

### 待补跑项

- freeze post-closure baseline table
- 启动下一轮单变量优化并保持 docs / commit 同步

## 当前风险

- 如果直接把 `fence_i` 当作“功能失败”处理，会误判当前根因为 CPU 设计缺陷
- 如果直接忽略 `fence_i` 又不写清 ISA 边界，会导致文档口径不严谨
- 在扩展矩阵未收口前，不应启动新的高侵入性能优化
