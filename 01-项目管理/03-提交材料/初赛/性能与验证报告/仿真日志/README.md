# 仿真日志说明

更新时间：`2026-04-30`

本目录归档性能与验证报告引用的关键仿真日志，主要用于证明基础指令、扩展指令、流水线优化和 SoC 启动路径均有可追溯的测试结果。

| 文件 | 内容 | 结论 |
|---|---|---|
| `riscv_tests_rv32_summary.txt` | RV32I 基础指令回归摘要，包含算术、逻辑、分支、跳转、访存等 33 个用例 | `33/33 PASS` |
| `YH_rv_cpu_zmmul.log` | Zmmul 定向诊断，覆盖 `mul` 正确性与 `divu` 非支持异常路径 | PASS |
| `source_dir_repro_zmmul_20260430.log` | 从待压缩源码目录直接运行 `scripts/run_zmmul_test.bat` 的最小复现日志 | PASS |
| `YH_rv_cpu_bitmanip.log` | Bitmanip/XThead condmov 定向诊断，覆盖 Zba/Zbb/Zbs/Zbc 与条件移动相关用例 | `23/23 PASS` |
| `xthead_memidx_test.log` | XThead indexed memidx 子集定向诊断 | PASS |
| `id_branch_fast_diag.log` | ID 阶段分支提前跳转诊断，配套波形 `01-id-branch-fast-waveform.png` | PASS |
| `id_jal_fast_diag.log` | `JAL` 提前跳转诊断，配套波形 `02-id-jal-fast-waveform.png` | PASS |
| `load_use_fast_diag.log` | load-use 快路径诊断，配套波形 `03-load-use-fast-waveform.png` | PASS |
| `soc_smoke_20260430_1720.log` | SoC 启动 smoke 测试，包含 `YH_rv_cpu boot` 输出与完成 PC/周期 | PASS |

边界说明：本目录不把 C/RVC、完整硬件除法、XThead auto-inc memidx 写成已验证能力；相关内容只作为后续扩展或能力边界在文档中说明。
