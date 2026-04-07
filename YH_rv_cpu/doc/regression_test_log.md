# YH_rv_cpu 回归测试记录

## 当前有效记录

本文档只保留当前仍可直接引用的 fresh 回归结果。更早的阶段性记录请看 `git history` 和 `doc/performance_experiment_log.md`，不要再把旧分数或旧时序当作当前口径引用。

## 2026-04-07 - Frozen Baseline Refresh

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

### 仿真 / 回归结果

| 项目 | 结果 | 备注 |
|------|------|------|
| SoC smoke | 通过 | `PASS` at `PC=00000038` in `164 cycles` |
| trap smoke | 通过 | `PASS` at `PC=000000ac` in `89 cycles` |
| timer_irq smoke | 通过 | `PASS` at `PC=000000e4` in `136 cycles` |
| xlen64 smoke | 通过 | `PASS` at `PC=0000000000000020` in `17 cycles` |
| RV32 riscv-tests | 通过 | baseline manifest `33/33` |
| RV64 riscv-tests | 通过 | baseline manifest `21/21` |
| CoreMark smoke | 通过 | `620530 cycles` |
| CoreMark score short | 通过 | `11014885 cycles`，`CoreMark/MHz = 0.912472` |
| CoreMark score strict | 通过 | `1095991523 cycles`，`CoreMark/MHz = 0.912465`，`10.959325s` |
| CoreMark score validity | 通过 | short path `competition_reportable=yes`，strict path `strict_eembc_10s_compliant=yes` |
| FPGA-like probe | 通过 | `156442 cycles`，`CoreMark/MHz = 7.728811` |

### impl50 结果

| 项目 | 结果 |
|------|------|
| Setup WNS | `+5.599 ns` |
| Hold WHS | `+0.025 ns` |
| Slice LUTs | `2556` |
| Slice Registers | `2170` |
| BRAM | `4` |
| DSP | `0` |
| bitstream | `project/YH_rv_cpu_nexys_a7_100_20p000.bit` |

Notes:

- `scripts\build_vivado_project.bat impl50` 现在默认绑定冻结的 `YH_rv_cpu_demo` ROM 镜像。
- `current.hex` / `current.mem32.hex` 不再是 `impl50` 的隐式冻结基线来源。

### 当前结论

- [x] 当前冻结主线可回归
- [x] 当前保留优化无 RV32 / RV64 / impl50 / FPGA-like probe 回归
- [x] strict EEMBC `>=10s` CoreMark 长跑证据已补齐
- [x] `timer_irq_smoke` 本机回归已修复
- [ ] 实板 bring-up 证据仍需等待板卡

### 当前风险

- `impl50` 报告中仍存在 `no_input_delay(1)` / `no_output_delay(4)`，板级 signoff 仍需补正式 I/O delay 约束。

## 2026-04-07 Diagnostics and Runtime Isolation

### 测试环境

- GCC: `15.2.0`
- Vivado: `2025.2`
- branch: `main`
- runtime isolation: `scripts\prepare_xsim_runtime.bat`

### 实际命令

```bat
scripts\run_coremark_profile.bat rv32
scripts\run_fetch_redirect_reuse_diag.bat
scripts\run_fetch_redirect_reuse_diag.bat require_pipe_hit
scripts\run_memwait_overlap_diag.bat
scripts\run_memwait_overlap_diag.bat require_overlap
```

### 结果摘要

| Item | Result | Notes |
|------|------|------|
| CoreMark profile | PASS | `12516421 cycles`, `stall_decode_cycles=207474`, `mem_wait_cycles=553215`, `ex_fetch_redirect_valid_cycles=1504970`, `fetch_queue_empty_cycles=1504970` |
| Redirect reuse diag | PASS | `21 cycles`, `stall_cycles=2`, `redirects=2`, `overlaps=1` |
| Redirect reuse strict | FAIL | `require_pipe_hit` currently trips because `fetch_redirect_pipe_hit` is still disabled in RTL |
| Memwait overlap diag | PASS | `21 cycles`, `mem_wait_cycles=1`, `opportunities=1`, `overlap_requests=0` |
| Memwait overlap strict | FAIL | `require_overlap` currently trips because the baseline does not yet issue an overlap-time request |

### 结论

- 这轮补了一个 CoreMark profiling 入口，方便把 `stall_decode` / `mem_wait` / redirect 的负载分布单独拿出来看。
- `fetch_redirect_reuse` 和 `memwait_overlap` 两个 directed test 都已经有默认绿路径和严格红绿入口，后续 RTL 打开对应 reuse 行为时可以直接复用。
- `prepare_xsim_runtime.bat` 解决了并行 worker 共用 `xsim.dir` 的冲突问题，现在这些仿真脚本可以安全落在独立 runtime 目录里。

## 2026-04-07 Redirect Accounting Diagnostic

### 测试环境

- target: `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting`
- strict coverage: `IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`

### 结果摘要

| Item | Result | Notes |
|------|------|------|
| IMEM_OUTPUT_REG=0 strict | PASS | `run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` passed in 21 cycles with strict checks enabled. |
| IMEM_OUTPUT_REG=1 strict | PASS | `run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` passed in 21 cycles; drop accounting checks were active. |

### 结论

- strict redirect accounting diagnostic 已完成双变体验证：`IMEM_OUTPUT_REG=0` 与 `IMEM_OUTPUT_REG=1` 均为 fresh `PASS`，且脚本已改为编译期参数切换，避免把 `imem_output_reg` 误传为运行时 plusarg。

## 2026-04-07 Post-Accounting Fresh Recheck

### 实际命令

```bat
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64
scripts\build_vivado_project.bat impl50
```

### 结果摘要

| Item | Result | Notes |
|------|------|------|
| CoreMark smoke | PASS | `620530 cycles` |
| CoreMark score short | PASS | `11014885 cycles`, `CoreMark/MHz = 0.912472` |
| RV32 riscv-tests | PASS | `33/33` |
| RV64 riscv-tests | PASS | `21/21` |
| impl50 | PASS | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS = +5.599ns`, `WHS = +0.025ns` |

### 结论

- Redirect accounting 收口后，主线关键矩阵仍保持 frozen baseline 数值，无新回归。
## 2026-04-07 Final Fresh Recheck (After FQ-05 Closure)

### Commands

```bat
scripts\run_fetch_redirect_reuse_diag.bat
scripts\run_coremark_profile.bat rv32
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64
scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt
```

### Result Snapshot

| Item | Result | Notes |
|------|------|------|
| Redirect diagnostic | PASS | `21 cycles` (`IMEM_OUTPUT_REG=0` default diagnostic) |
| CoreMark profile | PASS | `12516421 cycles`, `stall_decode=207474`, `mem_wait=553215`, `redirect=1504970`, `fetch_queue_empty=1504970` |
| CoreMark smoke | PASS | `620530 cycles` |
| CoreMark short | PASS | `11014885 cycles`, `0.912472 CoreMark/MHz` |
| RV32 subset | PASS | `33/33` |
| RV64 subset | PASS | `21/21` |
| impl50 | PASS | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS=+5.599ns`, `WHS=+0.025ns` |
| FPGA-like probe | PASS | `156442 cycles`, `7.728811 CoreMark/MHz` |
| strict `>=10s` rerun | NOT COMPLETED | command exceeded local runtime budget (`7200s` timeout); run was manually stopped after progress beyond `CYCLE=610000000` |

### Notes

- This round confirms the frozen short-path baseline and implementation baseline remain unchanged after all FQ-05 trial reverts.
- The authoritative strict summary currently remains the last completed one:
  `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt` (timestamp `2026-04-04 01:54:09`).
