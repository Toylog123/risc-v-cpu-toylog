# 分赛区最终提交包清单 strict50 2026-07-02

本文档用于最终打包前逐项核对材料。当前状态仍是 implementation evidence complete、
board evidence pending。

## 当前可纳入提交包的材料

| 类别 | 文件/目录 | 状态 | 用途 |
|---|---|---|---|
| 主入口 | `README.md` | ready | strict50 evidence archive 总入口 |
| 分赛区入口 | `REGION_DELIVERY_INDEX_20260702.md` | ready | 当前口径、材料索引、缺口 |
| 要求对照 | `REGION_REQUIREMENT_MATRIX_20260702.md` | ready | 赛题要求逐项对照 |
| 指标追踪 | `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md` | ready | 主指标到原始证据的可复核链路 |
| 验证脚本 | `verify_strict50_impl220_metrics.ps1` | ready | 自动解析 timing/utilization/CoreMark summary |
| 严格验证门禁 | `REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md` | ready | PPT、报告、提交包和 board evidence 的发布前门禁 |
| 上板审计脚本 | `audit_strict50_board_evidence.ps1` | ready | 自动扫描 bitstream、PROGRAM_OK、UART、视频、DMIPS 证据 |
| 上板审计记录 | `STRICT50_BOARD_EVIDENCE_AUDIT_20260702.md` | ready | 当前 board evidence incomplete 的可复核记录 |
| 应用演示证据 | `STRICT50_APP_DEMO_EVIDENCE_20260702.md` | ready | strict50 perf demo xsim 证据和口径边界 |
| 应用演示审计 | `audit_strict50_demo_evidence.ps1` | ready | 自动检查 demo 身份和 `impl220` 匹配参数 |
| Dhrystone 证据 | `STRICT50_DHRYSTONE_EVIDENCE_20260702.md` | ready | `impl220` 同配置 Dhrystone/DMIPS xsim 证据 |
| Dhrystone 计时审计 | `audit_dhrystone_timer_clock_consistency.ps1` | ready | 自动检查 Dhrystone timer Hz 与 50 MHz 口径一致 |
| Dhrystone 证据审计 | `audit_strict50_dhrystone_evidence.ps1` | ready | 自动检查 summary/log/stdout 和关键硬件参数 |
| 打包 runbook | `CICC_STRICT50_PACKAGE_RUNBOOK_20260702.md` | ready | 提交包 dry-run/build 说明 |
| 打包脚本 | `make_cicc_strict50_package.ps1` | ready | 白名单生成提交包草稿 |
| 报告正文 | `REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md` | draft ready | 技术报告正文草稿 |
| 报告段落 | `REGION_REPORT_STRICT50_SECTION_20260701.md` | ready | 可插入报告/答辩稿的短段落 |
| 架构与时序图 | `REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md` | ready | 报告/PPT 可用 Mermaid 图和讲解口径 |
| 作品介绍/PPT 母稿 | `REGION_WORK_INTRO_AND_PPT_MASTER_STRICT50_20260706.md` | ready | 可直接拆页制作分赛区 PPT 和讲稿 |
| PPT 草稿 | `CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx` | draft ready | 可编辑答辩 PPT |
| PPT 清单 | `REGION_PPT_DRAFT_MANIFEST_20260702.md` | ready | PPT SHA256、QA、页码说明 |
| QA 口径 | `REGION_DEFENSE_QA_STRICT50_20260702.md` | ready | 现场问答边界 |
| 工作计划 | `REGION_SUBMISSION_WORKPLAN_20260702.md` | ready | 后续补证和提交任务 |
| 上板 runbook | `STRICT50_BOARD_DEMO_RUNBOOK_20260702.md` | ready | bitstream/PROGRAM_OK/UART/video 执行步骤 |
| 上板模板 | `STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` | pending fill | 上板证据待填 |
| 冻结说明 | `FREEZE_STRICT50_IMPL220_20260701.md` | ready | 当前 impl220 freeze 边界 |
| 实现证据 | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50/` | ready | timing/utilization/route/log |
| CoreMark summary | `fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt` | ready | CoreMark/MHz 与 CRC |
| 应用演示 xsim | `strict50_perf_demo_20260702/` | ready | `PERF_DEMO PASS` xsim log 与 SHA256 |
| Dhrystone xsim | `sim220_dhrystone_impl220_strict50_match/` | ready | `2.495618 DMIPS/MHz` xsim summary/log/stdout 与 SHA256 |

## 当前不能作为完成项的材料

| 项 | 当前状态 | 处理方式 |
|---|---|---|
| `impl220` bitstream | complete | `board_impl220_bitstream_20260702/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit`，SHA256 已记录 |
| PROGRAM_OK | pending | 上板后记录 Hardware Manager log/screenshot |
| UART raw log | pending | 按 workload 分类归档 |
| board video | pending | 记录视频路径、时长、内容 |
| `impl220` 板级 DMIPS/MHz | pending | xsim DMIPS 已补；板级 DMIPS 需上板 UART raw log 后再写 |
| 官方 EEMBC 10 秒 CoreMark | pending | 未完成前不能宣称 |

当前 board evidence 审计命令：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/audit_strict50_board_evidence.ps1
```

当前审计结果仍应为 `board_evidence_complete=False`、`submission_evidence_complete=False`。
同配置 DMIPS xsim、bitstream 和 bitstream SHA256 已补齐；补齐 PROGRAM_OK、UART、视频后，
再使用 `-RequireComplete` 作为最终硬门禁。

## 最终打包建议结构

建议最终提交包采用 CICC 命名，并避免把历史 scratch 实验目录整体打包：

```text
CICC_YH_RVCPU_Strict50_Submission/
  01_source/
    YH_rv_cpu/
  02_reports/
    technical_report.pdf
    REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md
    REGION_REQUIREMENT_MATRIX_20260702.md
    REGION_WORK_INTRO_AND_PPT_MASTER_STRICT50_20260706.md
    REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md
  03_presentation/
    CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx
    REGION_PPT_DRAFT_MANIFEST_20260702.md
  04_evidence_impl220/
    timing/
    utilization/
    route_status/
    coremark_summary/
    app_demo/
    dhrystone/
  05_board_evidence/
    bitstream_manifest.md
    program_hw.log
    uart_*.log
    video_manifest.md
  06_defense_qa/
    REGION_DEFENSE_QA_STRICT50_20260702.md
```

## 打包前硬性检查

| 检查项 | 通过标准 |
|---|---|
| CoreMark 算法文件 | `core_list_join.c`、`core_matrix.c`、`core_state.c`、`core_util.c`、`core_main.c` 未修改 |
| 当前指标 | 所有主文档只使用 `9965 LUT / 4.287521 CoreMark/MHz / 2.495618 DMIPS/MHz xsim / 50 MHz / WNS +0.056 ns / WHS +0.121 ns` |
| board-proven 口径 | 只有 bitstream、PROGRAM_OK、UART、视频齐全后才能写 |
| 上板证据审计 | `board_evidence_complete=True` 后再提升为 board-proven |
| 提交证据审计 | `audit_strict50_board_evidence.ps1 -RequireComplete` 通过后表示上板证据和同配置 DMIPS 均已补齐 |
| 应用演示审计 | `audit_strict50_demo_evidence.ps1` 通过后表示 demo 身份和 strict50 testbench 参数未混入旧 CPU25 口径 |
| Dhrystone 审计 | `audit_strict50_dhrystone_evidence.ps1` 通过后表示 xsim DMIPS 证据可追溯 |
| DMIPS | 当前只能表述为 xsim host-parsed，不得表述为板级 UART 结果 |
| 高分 rejected 行 | `fast201` / `synth224` 只能作为 rejected audit |
| 旧初赛口径 | `4961 LUT / 4.137461 / board-proven` 不作为当前 strict50 结果 |
| 严格验证门禁 | `REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md` 中 P0 项全部完成或明确 pending |
| 中文提交材料目录 | 不修改 `01-项目管理/03-提交材料`，除非用户明确要求 |
| 历史实验文件 | 不批量 stage 或打包未筛选 DCP/scratch |

## 下一步执行顺序

| 优先级 | 动作 | 输出 |
|---|---|---|
| P0 | `impl220` bitstream 归档 | 已完成：`.bit`、SHA256、log |
| P0 | 上板 PROGRAM_OK | program log/screenshot |
| P0 | UART + 视频 | raw log、video manifest |
| P1 | 如需板级 Dhrystone | board UART raw log + DMIPS/MHz summary |
| P1 | 复跑提交证据审计 | `submission_evidence_complete=True` |
| P1 | 技术报告排版 | PDF 或最终 DOCX/PDF |
| P1 | PPT 人工润色 | 最终答辩 PPT |
