# 分赛区 strict50 交付包总入口 2026-07-02

本目录是当前 strict 50 MHz 工程候选的分赛区材料入口。旧初赛提交目录
`01-项目管理/03-提交材料` 不在本轮修改范围内；其中的旧答辩口径与当前
`impl220` strict50 候选不同，不能直接混用。

## 当前推荐口径

| 项目 | 当前值 |
|---|---|
| 冻结 tag | `freeze-strict50-impl220-20260701` |
| 冻结 commit | `ae648ca` |
| 候选版本 | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| FPGA 平台 | PYNQ-Z2 / xc7z020 |
| CPU 时钟 | 50 MHz |
| Slice LUT | 9965 |
| Slice FF | 6520 |
| BRAM Tile | 32 |
| DSP | 8 |
| CoreMark/MHz | 4.287521 |
| post-route timing | WNS +0.056 ns / WHS +0.121 ns |
| DMIPS/MHz | 2.495618（`impl220` 同配置 xsim，host-parsed） |
| 证据等级 | post-route implementation timing-closed + xsim Dhrystone/应用演示，尚未 board-proven |

一句话版本：

`当前 strict50 候选为 9965 LUT / 4.287521 CoreMark/MHz / 2.495618 DMIPS/MHz xsim / 50 MHz / WNS +0.056 ns / WHS +0.121 ns；CoreMark 核心算法未修改，板级 PROGRAM_OK、UART 和视频证据待补。`

## 评委可读材料

| 文件 | 用途 |
|---|---|
| `REGION_REPORT_STRICT50_SECTION_20260701.md` | 可直接放入技术报告或答辩稿的中文段落 |
| `REGION_REQUIREMENT_MATRIX_20260702.md` | 按赛题要求逐条对照当前证据与缺口 |
| `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md` | 当前主指标到原始报告的证据追踪表 |
| `verify_strict50_impl220_metrics.ps1` | 自动解析归档报告并验证当前指标线 |
| `REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md` | PPT、报告、提交包和上板证据的严格验证门禁清单 |
| `REGION_DEFENSE_QA_STRICT50_20260702.md` | 分赛区现场问答口径 |
| `REGION_DEFENSE_SPEAKER_SCRIPT_STRICT50_20260702.md` | 分赛区 3 分钟/1 分钟现场讲稿 |
| `REGION_SUBMISSION_WORKPLAN_20260702.md` | 分赛区提交包、PPT、上板证据和后续任务清单 |
| `REGION_REPORT_OUTLINE_STRICT50_20260702.md` | 分赛区技术报告章节大纲 |
| `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` | 报告/PPT 可用的五级流水、时序热点、证据链 Mermaid 图 |
| `REGION_WORK_INTRO_AND_PPT_MASTER_STRICT50_20260706.md` | 作品详细介绍与 PPT 内容母稿，可直接拆页制作答辩材料 |
| `REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md` | 分赛区技术报告正文草稿 |
| `REGION_FINAL_PACKAGE_MANIFEST_20260702.md` | 最终提交包清单和打包边界 |
| `CICC_STRICT50_PACKAGE_RUNBOOK_20260702.md` | CICC strict50 提交包 dry-run/build 说明 |
| `CICC_STRICT50_PACKAGE_DRYRUN_20260702.md` | 最近一次提交包 dry-run 结果 |
| `CICC_STRICT50_PACKAGE_DRYRUN_20260702.tsv` | dry-run 白名单文件列表 |
| `make_cicc_strict50_package.ps1` | 白名单打包脚本，排除 DCP 和禁止路径 |
| `STRICT50_BOARD_EVIDENCE_AUDIT_20260702.md` | `impl220` 上板证据缺口审计 |
| `audit_strict50_board_evidence.ps1` | 自动扫描 bitstream、PROGRAM_OK、UART、视频、DMIPS 证据 |
| `STRICT50_APP_DEMO_EVIDENCE_20260702.md` | strict50 应用演示 xsim 证据、复现命令和口径边界 |
| `audit_strict50_demo_evidence.ps1` | 自动检查 demo 身份和 `impl220` 匹配参数 |
| `STRICT50_DHRYSTONE_EVIDENCE_20260702.md` | `impl220` 同配置 Dhrystone/DMIPS xsim 证据 |
| `audit_dhrystone_timer_clock_consistency.ps1` | 自动检查 Dhrystone 计时宏与 50 MHz clock 口径一致性 |
| `audit_strict50_dhrystone_evidence.ps1` | 自动检查正式 Dhrystone summary/log/stdout 和关键硬件参数 |
| `REGION_PPT_STORYBOARD_STRICT50_20260702.md` | 答辩 PPT 分镜和讲稿要点 |
| `REGION_PPT_DRAFT_MANIFEST_20260702.md` | PPT 草稿 SHA256、页码用途和 QA 记录 |
| `CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx` | 可编辑答辩 PPT 草稿 |
| `REGION_STRICT50_UPDATE_20260701.md` | 当前 strict50 结果口径与附近审计结果 |

## 工程证据材料

| 文件/目录 | 内容 |
|---|---|
| `FREEZE_STRICT50_IMPL220_20260701.md` | `impl220` 冻结说明、指标和边界 |
| `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/` | `impl220` timing、utilization、route status 和 Vivado 日志 |
| `fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt` | CoreMark/MHz、CRC 和 acceptance summary |
| `strict50_perf_demo_20260702/` | strict50 perf demo xsim log、SHA256 和应用演示证据 |
| `sim220_dhrystone_impl220_strict50_match/` | `impl220` 同配置 Dhrystone xsim log、summary、stdout 和 SHA256 |
| `impl223_impl200_optExploreArea_routeHigherDelayCost_postAggressive_cpu50/` | timing-closed 但未提升的邻近实现审计 |
| `synth224_defaultfast_foldnext0_cpu50/` | 高分 fast 配置被 synthesis timing 拒绝的证据 |
| `RESULTS_20260611.md` | strict50 优化过程总 ledger |
| `HANDOFF_20260617.md` | 当前交接和下一步技术目标 |

## 上板证据模板

| 文件 | 状态 |
|---|---|
| `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` | 已预填 bitstream/SHA256，等待 PROGRAM_OK、UART、视频证据 |
| `STRICT50_BOARD_DEMO_RUNBOOK_20260702.md` | 已准备执行步骤，等待真实上板补证 |
| `STRICT50_BOARD_EVIDENCE_AUDIT_20260702.md` | 已记录当前审计结论：board evidence incomplete |
| `audit_strict50_board_evidence.ps1` | 可复跑；当前预期 `board_evidence_complete=False`、`submission_evidence_complete=False`，但 `impl220_dmips_count>0` |

上板前不能写成 board-proven。允许写：

`impl220 是 strict 50 MHz post-route timing-closed engineering candidate；board evidence pending。`

## 不能混用的旧材料

| 旧材料 | 使用限制 |
|---|---|
| `artifacts/region_baseline_6872_20260602/` | 可作为历史低资源/CPU25 fallback 记录，不代表当前 strict50 候选 |
| `01-项目管理/04-答辩准备/QA/` | 旧初赛提交口径，指标是 4961 LUT / 4.137461 / board-proven，不能直接用于 `impl220` |
| `5918 LUT / 5.162186` 相关记录 | demo/default-ROM timing evidence，不是 strict CoreMark-ROM 当前候选 |
| `fast201` / `synth224` | fast score 高，但 synthesis WNS -11.786 ns，不能作为报告候选 |

## 当前缺口

| ID | 缺口 | 影响 | 下一步 |
|---|---|---|---|
| G01 | `impl220` bitstream/SHA256 已归档 | 可用于后续上板补证 | 使用 `board_impl220_bitstream_20260702/` 中的 `.bit`，不要换用旧 bitstream |
| G02 | PROGRAM_OK / UART / 视频未完成 | 不能称为 board-proven | 按 `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` 补证 |
| G03 | `impl220` 同配置 DMIPS 已有 xsim 证据 | 可报告为 simulation evidence，不能当作 board UART 证据 | 最终上板后如需板级 DMIPS，再补 UART raw log |
| G04 | 官方 EEMBC 10 秒 CoreMark 未完成 | 不能称官方 10 秒合规 | 如需公开强合规，补 >=10 秒运行证据 |
| G05 | strict50 应用演示已有 xsim 证据但尚无板级 UART/视频 | 可说明应用程序仿真通过，不能称上板演示完成 | 基于已归档 bitstream 按同一 demo 补 board UART 和视频 |
| G06 | 最终 PPT/报告仍需严格验证 | 防止误写 board-proven、板级 DMIPS、官方 EEMBC 等口径 | 按 `REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md` 逐项检查 |

当前审计命令：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/audit_strict50_board_evidence.ps1
```

当前审计摘要：`board_evidence_complete=False`，上板侧缺少 `program_ok`、`uart_raw_log`、`board_video`；
`submission_evidence_complete=False`；`impl220_dmips` 已由 xsim evidence 补齐，
`impl220` bitstream 和 bitstream SHA256 已归档。
