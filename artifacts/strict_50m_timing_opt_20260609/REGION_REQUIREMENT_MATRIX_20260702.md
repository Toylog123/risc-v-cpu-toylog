# 分赛区赛题要求对照表 2026-07-02

依据：`01-项目管理/01-赛题要求/赛题/七星微赛题详细要求.md`。

结论：当前 `impl220` 已满足 strict 50 MHz post-route timing-closed 的实现证据要求，
并补齐同配置 Dhrystone/DMIPS xsim 证据；但尚未完成板级 PROGRAM_OK、UART 和视频证据，
因此只能作为 implementation-evidence candidate，不应表述为 board-proven。

## 核心目标对照

| 赛题要求 | 当前状态 | 证据 | 缺口/边界 |
|---|---|---|---|
| 支持 RV32I 或 RV64I 基础整数 ISA | 支持 RV32 参数化路径，当前 SoC 默认 `XLEN=32` | `YH_rv_cpu/rtl/YH_rv_cpu.v`, `YH_rv_cpu/rtl/YH_rv_cpu_soc.v` | 需要在最终报告中只声明已验证配置，不扩张到未验证 RV64 |
| 五级流水 CPU | 已按 IF/ID/EX/MEM/WB 结构组织，含 hazard/redirect 控制 | RTL 模块、`REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` | 架构图已补，可直接进入 PPT/报告 |
| 解决数据/结构/控制冒险 | 有 forwarding、load-use、redirect/fold、branch/BHT 等参数化控制 | RTL 参数与 strict50 优化 ledger | 分支准确率不应泛化为复杂动态预测准确率 |
| 至少 2 种性能优化技术 | 有 redirect-cache/fold 控制、BHT/branch 控制、DCache/load-use 相关控制、Vivado implementation directive 优化 | `REGION_REPORT_STRICT50_SECTION_20260701.md`, `RESULTS_20260611.md` | 报告中应强调进入当前候选的安全配置，不把 rejected 高分路径包装为候选 |
| FPGA 原型系统时钟不低于 50 MHz | `impl220` post-route 50 MHz timing closed | `impl220.../reports_cpu50/impl_timing_summary.rpt`，WNS +0.056 ns / WHS +0.121 ns | 板级下载证据未完成 |
| FPGA 资源占用统计 | 已有 LUT/FF/BRAM/DSP | `impl220.../reports_cpu50/impl_utilization.rpt`, `FREEZE_STRICT50_IMPL220_20260701.md` | 可后续补 power report |
| CoreMark 性能量化 | 已有 4.287521 CoreMark/MHz，CRC `0xfcaf` | `fast210.../coremark50_fast_gate_iter10.summary.txt` | 工程 short-gate，不是官方 EEMBC 10 秒 |
| DMIPS/MHz | 2.495618，`impl220` 同配置 xsim host-parsed | `STRICT50_DHRYSTONE_EVIDENCE_20260702.md`, `sim220_dhrystone_impl220_strict50_match/` | 这是仿真证据，不是板级 UART 证据 |
| 应用程序演示 | strict50 perf demo 已有 xsim 证据；strict50 bitstream 已生成；上板演示未完成 | `strict50_perf_demo_20260702/`, `board_impl220_bitstream_20260702/` | 仍需 PROGRAM_OK、UART、视频 |
| bitstream 与调试日志 | strict50 当前已有 implementation log/report、bitstream、SHA256 和 bitstream 生成日志 | `impl220.../logs/`, `reports_cpu50/`, `board_impl220_bitstream_20260702/` | PROGRAM_OK、UART、视频待补 |
| 源码与 TestBench | 当前仓库包含 RTL、TB、脚本 | `YH_rv_cpu/rtl`, `YH_rv_cpu/tb`, `YH_rv_cpu/scripts` | 分赛区提交包需重新按 CICC 命名打包 |
| 不直接复用开源 CPU | 项目是自研 YH_rv_cpu 线 | 本地 RTL/文档 | 最终文档可补引用和原创声明 |

## 当前可报告项

2026-07-02 update: strict50 application-demo xsim evidence is available in
`strict50_perf_demo_20260702/`. The demo uses `baseline=strict50 impl220
cpu_clk=50MHz`, exercises CRC32, MATMUL8, MEMCPYFILL, BRANCH, and LOADUSE, and
ends with `PERF_DEMO PASS checksum=0xe727358b`. This is application-demo
simulation evidence, not board UART/video evidence.

| 项目 | 可报告表述 |
|---|---|
| 50 MHz 时序 | `impl220` 在 PYNQ-Z2 post-route implementation 下 WNS +0.056 ns / WHS +0.121 ns |
| 性能 | 4.287521 CoreMark/MHz，CRC `0xfcaf`，工程 short-gate |
| DMIPS | 2.495618 DMIPS/MHz，同配置 Dhrystone xsim，host-parsed from UART log |
| 资源 | 9965 LUT / 6520 FF / 32 BRAM Tile / 8 DSP |
| 技术优化 | 参数化前端 redirect、BHT ID-update 控制、DCache/load-use/fold 路径取舍、Vivado ExploreArea + AdvancedSkewModeling |
| 合规边界 | CoreMark 核心算法文件未修改；当前不是 board-proven；不是官方 10 秒 EEMBC |

## 当前不可报告项

| 项目 | 原因 |
|---|---|
| `impl220` board-proven | 尚无 PROGRAM_OK、UART、视频 |
| `impl220` 板级 DMIPS/MHz | 当前 DMIPS 是 xsim 证据，尚无板级 UART raw log |
| `fast201` 4.569338 作为候选 | `synth224` synthesis WNS -11.786 ns |
| 旧 6872 / 5918 / 11182 行作为当前基线 | timing-failed、demo-ROM 或历史 audit，不是当前 strict50 routed candidate |
| 官方 EEMBC 10 秒合规 | 当前 CoreMark 是工程 short-gate |

## 建议补齐顺序

| 优先级 | 动作 | 输出 |
|---|---|---|
| P0 | `impl220` bitstream/SHA256 | 已完成：`.bit` 路径、SHA256、生成日志 |
| P0 | 上板 PROGRAM_OK + UART + 视频 | 填写 `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` |
| P1 | 如需板级 DMIPS，跑 `impl220` 上板 Dhrystone | board UART raw log + DMIPS summary |
| P1 | 整理分赛区提交包 | 源码包、技术报告、性能报告、PPT、视频清单 |
| P2 | 补 power report | 架构图已补；后续可补功耗报告增强答辩材料完整度 |
