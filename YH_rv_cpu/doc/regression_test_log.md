# YH_rv_cpu 回归测试记录

## 当前有效记录

本文件只保留当前仍可直接引用的 fresh 回归结果。更早的阶段性记录请看 `git history` 和 `doc/performance_experiment_log.md`，不要再把旧分数或旧时序当作当前口径引用。

## 2026-04-03 - Frozen Baseline Refresh

### 测试环境

- GCC: `15.2.0`
- Vivado: `2025.2`
- branch: `main`
- target device: `xc7a100tcsg324-1`
- frozen retained optimizations:
  - `stall_decode=load_use_hazard`
  - `IMEM_OUTPUT_REG=0`
  - `DMEM_OUTPUT_REG=0`

### 实际命令

```bat
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64
scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
```

### 仿真 / 回归结果

| 项目 | 结果 | 备注 |
|------|------|------|
| RV32 riscv-tests | 通过 | baseline manifest `33/33` |
| RV64 riscv-tests | 通过 | baseline manifest `21/21` |
| CoreMark smoke | 通过 | `620530 cycles` |
| CoreMark score short | 通过 | `11014885 cycles`，`CoreMark/MHz = 0.912472` |
| CoreMark score strict | 通过 | `1095991523 cycles`，`CoreMark/MHz = 0.912465`，`10.959325s` |
| CoreMark score validity | 通过 | short path `competition_reportable=yes`；strict path `strict_eembc_10s_compliant=yes` |
| FPGA-like probe | 通过 | `156442 cycles`，`CoreMark/MHz = 7.728811` |

### impl50 结果

| 项目 | 结果 |
|------|------|
| Setup WNS | `+5.822 ns` |
| Hold WHS | `+0.057 ns` |
| Slice LUTs | `2555` |
| Slice Registers | `2170` |
| BRAM | `4` |
| DSP | `0` |
| bitstream | `project/YH_rv_cpu_nexys_a7_100_20p000.bit` |

### 100MHz 参考实现

下列结果仅作为当前顶层 `100MHz` 参考实现，不是比赛冻结提交口径：

| 项目 | 结果 |
|------|------|
| Setup WNS | `+0.062 ns` |
| Hold WHS | `+0.048 ns` |
| Slice LUTs | `2598` |
| Slice Registers | `2240` |
| BRAM | `4` |

### 当前结论

- [x] 当前冻结主线可回归
- [x] 当前保留优化无 RV32 / RV64 / impl50 回归
- [x] strict EEMBC `>=10s` CoreMark 长跑证据已补齐
- [ ] 实板 bring-up 证据仍需等待板卡

### 当前风险

- `impl50` 报告中仍存在 `no_input_delay(1)` / `no_output_delay(4)`，板级 signoff 仍需补正式 I/O delay 约束

### 2026-04-04 Fetch Diagnostic

- Command: `scripts\run_fetch_prefetch_diag.bat`
- Result: `PASS`
- Observation: `83 cycles`, `stall_cycles=6`, `opportunities=6`, frozen baseline `prefetch_seen=0`
