# 性能日志说明

本目录归档性能与验证报告引用的原始摘要和仿真日志，便于提交前复核与答辩查证。

## 最终冻结口径

最终冻结硬件配置为 `RV32I + Zmmul + Zba/Zbb/Zbs`，PYNQ-Z2 CPU 时钟 `50.0 MHz`，实现资源 `4961 LUT`，满足赛题 `LUT < 5000` 硬约束。该配置对应的性能日志如下。

| 文件 | 内容 |
|---|---|
| `coremark_zmmul_bitmanip_noidbr_final_20260430.summary.txt` | 最终冻结硬件配置 CoreMark 摘要，报告值为 `4.137461 CoreMark/MHz` |
| `coremark_zmmul_bitmanip_noidbr_final_20260430.log` | 最终冻结硬件配置 CoreMark XSim 原始日志，CRC 与预期匹配，短运行提示已保留 |
| `dhrystone_zmmul_bitmanip_noidbr_o3_lto_noinlineoff_str8_20260430.summary.txt` | 最终冻结硬件配置 Dhrystone/DMIPS 优化构建摘要，报告值为 `2.908287 DMIPS/MHz` |
| `YH_rv_cpu_dhrystone_zmmul_bitmanip_noidbr.log` | 最终冻结硬件配置 Dhrystone XSim 原始日志 |
| `YH_rv_cpu_coremark_rv32im_async_refill_score.summary.txt` | 优化前参考路径 CoreMark 摘要，报告值为 `4.060276 CoreMark/MHz` |
| `YH_rv_cpu_coremark_rv32im_async_refill_score.log` | 优化前参考路径 CoreMark XSim 原始日志 |

## 探索路径与历史复验

以下日志用于说明优化探索过程和性能上限，不作为最终冻结 bitstream 的正式板级口径。

| 文件 | 内容 |
|---|---|
| `YH_rv_cpu_coremark_idbr_cmp_jal_predict_score_20260430_rerun.summary.txt` | 高性能探索路径 CoreMark 摘要，`5.162186 CoreMark/MHz` |
| `YH_rv_cpu_coremark_idbr_cmp_jal_predict_score_20260430_rerun.log` | 高性能探索路径 CoreMark XSim 原始日志 |
| `coremark_recheck_20260430_1711.summary.txt` | 高性能探索路径当日复验摘要 |
| `YH_rv_cpu_coremark_zmmul_zbc_xthead_memidx_idbr_score.summary.txt` | 早期面积超预算对照路径 CoreMark 摘要 |
| `dhrystone_zbc_xthead_nomemidx_idbr_20260430.summary.txt` | 早期 Dhrystone 摘要，`1.015253 DMIPS/MHz` |
| `dhrystone_zmmul_zbc_xthead_idbr_o3_lto_noinlineoff_str8_final_recheck_20260430.summary.txt` | 高性能探索路径 Dhrystone 摘要，`2.986101 DMIPS/MHz` |

CoreMark 摘要中的 `strict_eembc_10s_compliant=no` 表示本次为可复现实验短运行口径，报告值由 raw ticks 和固定时钟参数解析得到；CRC 字段保留在原始日志中。Dhrystone 优化构建使用 `-O3 -flto -fwhole-program`，并仅在生成构建副本中去除基准源内 `no-inline` 优化限制，原始基准源文件不被改写。
