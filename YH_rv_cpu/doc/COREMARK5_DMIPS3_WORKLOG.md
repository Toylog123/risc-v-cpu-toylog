# CoreMark 5+ / DMIPS 3+ Exploration Worklog

## 目标

- 冻结基线：`freeze/prelim-submit-20260506-2330`，提交点 `634c400`。
- 新优化分支：`opt/coremark5-dmips3-20260506`。
- CoreMark 目标：稳定复验 `CoreMark/MHz > 5.0`。
- Dhrystone 目标：稳定复验 `DMIPS/MHz > 3.0`，优先向 `3.0+` 推进。
- FPGA 约束：PYNQ-Z2，CPU `50 MHz`；LUT 可放宽到约 `6000`，但仍坚持低功耗、低面积、低复杂度导向。
- 工程要求：每个候选路径必须保留测试命令、日志、资源/时序数据和 git 节点，避免污染初赛冻结提交材料。

## 当前基线

| 项目 | 冻结提交路径 |
| --- | --- |
| Git tag | `freeze/prelim-submit-20260506-2330` |
| CoreMark/MHz | `4.137461` |
| DMIPS/MHz | `2.908287` |
| FPGA | PYNQ-Z2 `50 MHz` |
| 资源/时序 | `4934 LUT`，`WNS +0.440 ns`，`WHS +0.151 ns` |
| 特性 | `RV32I + Zmmul + Zba/Zbb/Zbs + JAL early redirect` |

## 已知高分候选

| 候选 | CoreMark/MHz | DMIPS/MHz | FPGA 记录 | 备注 |
| --- | ---: | ---: | --- | --- |
| `perf/coremark-over-1p5` 提交路径 | `5.162186` | `1.009846` 或文档另记 `2.986101` | `4634 LUT / WNS +0.608 ns` 或历史另记 `6147 LUT / WNS -0.801 ns` | 需要在新节点重新复验，消除旧文档口径差异 |

## 实验原则

1. 先迁移已经提交的高分 RTL/脚本变更，再进行本地复验。
2. 每次只改变一个主要变量：ISA 扩展、前端控制、Dhrystone 构建参数、TestBench 配置或 FPGA 约束。
3. CoreMark 与 DMIPS 均以脚本输出的 ticks、迭代数、CRC/校验和和解析脚本结果为准。
4. 超过目标后仍需跑语法、定向指令、性能基准、Vivado 实现和资源/时序核对，才允许冻结新节点。

## 实验记录

| 时间 | 实验 | 命令/配置 | 结果 | 结论 |
| --- | --- | --- | --- | --- |
| 2026-05-06 | 建立优化节点 | `opt/coremark5-dmips3-20260506` from `634c400` | 待测 | 作为 CoreMark 5+ / DMIPS 3+ 独立探索节点 |
| 2026-05-06 | 导入高分候选工程路径 | 迁移 `perf/coremark-over-1p5` 的 `rtl/tb/scripts/sw/fpga` 工程层 | `check_toolchain.bat` PASS，`check_syntax.bat` PASS | 初赛冻结提交材料未迁移旧版本，优化在隔离节点进行 |
| 2026-05-06 | 高分候选定向回归 | `run_zmmul_test.bat`、`run_bitmanip_fast_subset_test.bat`、`run_xthead_memidx_test.bat`、`run_id_branch_fast_diag.bat`、`run_id_jal_fast_diag.bat`、`run_load_use_fast_diag.bat`、`run_sync_dmem_fast_diag.bat`、`run_branch_predict_diag.bat` | 全部 PASS | `Zmmul/Bitmanip/XThead/IDBR/JAL early redirect/load-use` 基础功能可用 |
| 2026-05-06 | CoreMark 5+ 复验 | `scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 build\sw\coremark5_recheck_20260506.summary.txt` | `5.162186 CoreMark/MHz`，`1937164 ticks`，`1971888 cycles` | CoreMark 目标已达到，仍需与 DMIPS、FPGA 资源一起冻结 |
| 2026-05-06 | Dhrystone 冻结口径复验 | `DHRYSTONE_OPT_LEVEL=-O3`，`DHRYSTONE_EXTRA_CFLAGS=-flto -fwhole-program`，`DHRYSTONE_STRIP_NOINLINE=1`，target `rv32i_zmmul_zba_zbb_zbs` | `2.908287 DMIPS/MHz`，`510986 Dhrystones/s`，`44228 cycles` | 与初赛冻结材料口径一致 |
| 2026-05-06 | Dhrystone `Zbc/XThead/IDBR` 初跑 | 同一 Dhrystone 优化口径，target `rv32i_zmmul_zba_zbb_zbs_zbc_xthead_idbr` | 10 分钟未收敛；短跑定位 `PC=0x000000e4` 反复 `sync_trap`，`mepc=0x000000dc` | 根因是编译器生成 `th.lwib`，decoder 未覆盖 `funct7[6:2]=5'h09` |
| 2026-05-07 | 补齐 `th.lwib` before-update word load | directed test 新增 `th.lwib x15,(x14),4,0`；decoder 增加 `5'h09` load word before-update | `run_xthead_memidx_test.bat` PASS，`cycles=22` | 修复 XThead memidx Dhrystone 卡死根因 |
| 2026-05-07 | DMIPS 3+ 复验 | 同一 Dhrystone 优化口径，target `rv32i_zmmul_zba_zbb_zbs_zbc_xthead_idbr` | `3.134092 DMIPS/MHz`，`550660 Dhrystones/s`，`44078 cycles` | DMIPS 目标已达到 |
| 2026-05-07 | CoreMark 补丁后复验 | `scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 build\sw\coremark5_after_lwib_20260507.summary.txt` | `5.162186 CoreMark/MHz`，`1937164 ticks` | `th.lwib` 补丁未造成 CoreMark 回退 |
| 2026-05-07 | PYNQ-Z2 FPGA 实现 | `50 MHz`，`Zmmul/Zba/Zbb/Zbs/Zbc/XThead/IDBR` 打开，完整 `M`/`Zicond`/`Zbkb` 关闭 | `5918 LUT`，`2382 FF`，`4 BRAM`，`15 DSP`，`WNS +0.358 ns`，`WHS +0.126 ns`，bitstream 生成 | 满足约 `6000 LUT` 放宽边界与 `50 MHz` 时序；可作为高分候选冻结点 |
| 2026-05-07 | 高分候选材料备份 | `artifacts/coremark5_dmips3_20260507/` | 已复制 bitstream、CoreMark/Dhrystone 日志、综合/实现报告 | 便于明天验收和后续板级复测 |
