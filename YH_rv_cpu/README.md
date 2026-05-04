# YH_rv_cpu

`YH_rv_cpu` 是面向第十届集创赛“七星微”企业命题初赛阶段整理的轻量级 RISC-V CPU 工程。当前正式提交口径以 `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect` 为主，在 PYNQ-Z2 上形成了可复核的仿真、性能、资源、时序、bitstream 和上板下载证据链。

## 当前正式口径

| 项目 | 当前结果 |
|---|---|
| 正式 CoreMark/MHz | `5.162186` |
| CoreMark iterations/s | `516.218555 @ 100MHz simulation tick basis` |
| CoreMark ticks | `1937164` |
| CoreMark completion cycles | `1971888` |
| CoreMark target | `rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv` |
| ISA/RTL 配置 | `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect`，关闭完整 M 除法 |
| Dhrystone/DMIPS | `177430 Dhrystones/s`，`1.009846 DMIPS/MHz`，保守二进制无 `div/rem` |
| PYNQ-Z2 实现 | `4634 LUT / 2317 FF / 4 BRAM / 15 DSP` |
| PYNQ-Z2 时钟 | `50.0 MHz` |
| 实现后时序 | `Setup WNS +0.608 ns`，`Hold WHS +0.121 ns` |
| bitstream | `project/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit` |
| 上板下载 | Vivado Hardware Manager 检出 `xc7z020_1`，`PROGRAM_OK` |

正式材料中只引用同时满足功能回归、CoreMark 测量、Vivado 实现、`LUT < 5000` 和 `Fmax >= 50 MHz` 的路径。探索结果可作为后续优化方向，但不能替代正式分数。

## 历史与探索口径

| 路径 | 结果 | 状态 |
|---|---:|---|
| 当前正式路径：IDBR cmp-cheapALU + JAL early redirect | `5.162186 CoreMark/MHz`，`4634 LUT`，`WNS=+0.608 ns` | 当前初赛冻结候选 |
| IDBR cmp-cheapALU，未开 JAL early redirect | `5.155952 CoreMark/MHz`，`4665 LUT`，`WNS=+0.275 ns` | 已被当前路径替代 |
| no-IDBR Zbc+XThead 路径 | `5.133707 CoreMark/MHz`，`4474 LUT`，`WNS=+0.559 ns` | 已被 IDBR 路径替代 |
| 完整 IDBR score-only 版本 | `5.155979 CoreMark/MHz` | `5004 LUT` 且 `WNS=-3.017 ns`，不作为正式 FPGA 分数 |
| Fast Zba/Zbb/Zbs subset @ 50MHz | `4.133456 CoreMark/MHz`，`3646 LUT` | 面积预算参考 |
| Fast Zba/Zbb/Zbs subset @ 62.5MHz | `4.133456 CoreMark/MHz`，`3792 LUT` | `WNS=-0.029 ns`，不作为正式 62.5MHz 口径 |

后续冲击 `CoreMark/MHz >= 6` 时，必须先把候选优化拆成小开关，再逐项执行：功能回归、CoreMark score、Vivado synthesis/implementation、LUT/时序复核。

## 关键复现命令

```bat
scripts\run_xthead_memidx_test.bat
scripts\run_zmmul_test.bat
scripts\run_bitmanip_test.bat
scripts\run_bitmanip_fast_subset_test.bat
scripts\run_soc_smoke.bat

scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 build\sw\YH_rv_cpu_coremark_idbr_cmp_jal_predict_score_20260430_rerun.summary.txt
scripts\run_dhrystone_score.bat 100000000UL 250000000 build\sw\YH_rv_cpu_dhrystone_idbr_cmp_jal_predict.summary.txt 10 rv32i_zmmul_zba_zbb_zbs

set PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=50000000
set PYNQ_USE_CLK_MMCM_62M5_OVERRIDE=0
set PYNQ_USE_CLK_MMCM_50M_OVERRIDE=1
set PYNQ_ENABLE_M_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE=1
set PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE=1
set PYNQ_ENABLE_IDBR_CMP_CHEAPALU_ONLY_OVERRIDE=1
set PYNQ_ENABLE_JAL_EARLY_REDIRECT_OVERRIDE=1
scripts\build_pynq_z2_project.bat impl
```

## 文档入口

- 当前状态：`doc/CURRENT_STATUS.md`
- 后续任务：`doc/YH_rv_cpu_todo.md`
- 接手说明：`doc/YH_rv_cpu_handoff.md`
- 性能实验记录：`doc/performance_experiment_log.md`
- 回归测试记录：`doc/regression_test_log.md`
