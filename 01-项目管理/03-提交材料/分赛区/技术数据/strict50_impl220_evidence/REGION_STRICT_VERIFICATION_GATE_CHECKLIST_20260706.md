# 分赛区 strict50 严格验证门禁清单 2026-07-06

本文档用于约束分赛区 PPT、技术报告、提交包和上板证据的最终口径。所有对外材料必须先通过
本文列出的 P0 门禁，再进入最终提交包。本文只适用于当前
`impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`
候选。

当前允许报告的主指标：

| 项目 | 当前值 | 证据等级 |
|---|---:|---|
| FPGA 平台 | PYNQ-Z2 / xc7z020 | 设计目标和 Vivado 工程口径 |
| CPU 时钟 | 50 MHz | post-route timing report |
| Slice LUT | 9965 | implementation utilization report |
| Slice FF | 6520 | implementation utilization report |
| BRAM Tile | 32 | implementation utilization report |
| DSP | 8 | implementation utilization report |
| CoreMark/MHz | 4.287521 | 工程 short-gate summary |
| DMIPS/MHz | 2.495618 xsim | 同配置 Dhrystone xsim |
| WNS / WHS | +0.056 ns / +0.121 ns | post-route timing report |
| 当前状态 | implementation timing-closed candidate | board evidence pending |

## 1. 最终材料硬原则

| ID | 原则 | 必须满足 |
|---|---|---|
| R01 | 不修改 CoreMark 核心算法 | `core_list_join.c`、`core_matrix.c`、`core_state.c`、`core_util.c`、`core_main.c` 对本轮无 diff |
| R02 | 只使用当前 strict50 主指标 | PPT、报告、README、提交包不得混入历史 6872、5918、11182、4961 等旧口径作为当前结果 |
| R03 | 不夸大证据等级 | PROGRAM_OK、UART raw log、视频未齐全前，不得写 board-proven 或已上板验证通过 |
| R04 | 区分 benchmark 和 demo | CoreMark、Dhrystone、perf demo 证据分别陈述，不互相替代 |
| R05 | 区分 xsim 和 board | 当前 DMIPS/MHz 是 xsim 证据，不得写为板级 DMIPS |
| R06 | 区分 short-gate 和官方认证 | 当前 CoreMark 不得写成官方 EEMBC 10 秒认证结果 |
| R07 | 所有数字可追溯 | 每个对外数字必须能追到原始 log/report/summary 或复核脚本 |
| R08 | 提交包白名单化 | 不打包 DCP、历史 scratch 目录、中文旧提交材料目录和已知无关脏文件 |

## 2. P0 严格验证门禁

P0 是最终 PPT/报告/提交包前必须完成或明确标注 pending 的项目。未通过的项目不能被写成完成。

| ID | 验证项 | 当前状态 | 复核方式 | 通过标准 | 未通过时允许写法 |
|---|---|---|---|---|---|
| G01 | 当前指标一致性 | 已有 evidence | `verify_strict50_impl220_metrics.ps1` | 输出 `verification_status=PASS`，且 LUT/CoreMark/WNS/WHS 与主指标一致 | 不得更新主指标 |
| G02 | 50 MHz post-route timing | 已通过 | `impl220.../reports_cpu50/impl_timing_summary.rpt` | `timing_closed=True`，WNS/WHS 为正 | 不得写满足 50 MHz |
| G03 | 资源利用率 | 已通过 | `impl220.../reports_cpu50/impl_utilization.rpt` | LUT=9965、FF=6520、BRAM=32、DSP=8 | 不得写当前资源数字 |
| G04 | CoreMark summary | 已通过 | `fast210.../coremark50_fast_gate_iter10.summary.txt` | `coremark_per_mhz=4.287521`、`crcfinal=0xfcaf`、`acceptance_pass=yes` | 只能写待复核 |
| G05 | CoreMark 源码未改 | 需每次提交前复核 | `git diff -- core_list_join.c ... core_main.c` | 无输出 | 不得提交或报告 |
| G06 | Dhrystone xsim | 已通过 | `audit_strict50_dhrystone_evidence.ps1` | 输出 `strict50_dhrystone_audit_status=PASS` | 不得写 DMIPS/MHz |
| G07 | perf demo xsim | 已通过 | `audit_strict50_demo_evidence.ps1` | 输出 `strict50_demo_audit_status=PASS` | 不得写应用 demo 已通过 |
| G08 | bitstream/SHA256 | 已完成 | `audit_strict50_board_evidence.ps1` | `bitstream_count=1` 且 SHA256 与 manifest 一致 | 不得进入上板补证 |
| G09 | PROGRAM_OK | pending | `audit_strict50_board_evidence.ps1 -RequireComplete` | 扫描到 PROGRAM_OK 证据 | 只能写 PROGRAM_OK 待补 |
| G10 | UART raw log | pending | `audit_strict50_board_evidence.ps1 -RequireComplete` | 扫描到当前 bitstream 对应 UART raw log | 只能写 board UART 待补 |
| G11 | board video | pending | `audit_strict50_board_evidence.ps1 -RequireComplete` | 扫描到视频或 video manifest | 只能写上板视频待补 |
| G12 | PPT/报告禁用口径 | 需每次发布前复核 | `rg` 关键词审计 | 不出现误称已上板、board-proven、官方 EEMBC 等说法 | 必须修改材料 |
| G13 | 提交包白名单 | 已通过 dry-run | `make_cicc_strict50_package.ps1` | `package_status=PASS`、`dcp_entry_count=0`、`forbidden_entry_count=0` | 不得正式打包 |
| G14 | staged 文件边界 | 需每次提交前复核 | `git diff --cached --name-only` + forbidden rg | 不包含 DCP、旧提交目录、CoreMark 核心文件、`resolve_python.bat` | 取消 stage 后重做 |

## 3. 严格验证命令组

在 worktree 根目录运行：

```powershell
git status --short --branch --untracked-files=no
```

指标与实现证据：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\verify_strict50_impl220_metrics.ps1
```

预期关键输出：

```text
verification_status=PASS
timing_closed=True
lut=9965
coremark_per_mhz=4.287521
wns_ns=0.056
whs_ns=0.121
```

Dhrystone xsim 证据：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_strict50_dhrystone_evidence.ps1
```

预期关键输出：

```text
dhrystone_timer_clock_consistency=PASS
strict50_dhrystone_audit_status=PASS
```

应用 demo xsim 证据：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_strict50_demo_evidence.ps1
```

预期关键输出：

```text
strict50_demo_audit_status=PASS
```

board evidence 当前审计：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_strict50_board_evidence.ps1
```

当前预期关键输出：

```text
board_evidence_complete=False
submission_evidence_complete=False
board_missing=program_ok
board_missing=uart_raw_log
board_missing=board_video
```

上板证据补齐后，最终门禁命令改为：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\audit_strict50_board_evidence.ps1 -RequireComplete
```

提交包 dry-run：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts\strict_50m_timing_opt_20260609\make_cicc_strict50_package.ps1
```

预期关键输出：

```text
package_status=PASS
missing_count=0
dcp_entry_count=0
forbidden_entry_count=0
```

CoreMark 核心算法文件检查：

```powershell
git diff -- YH_rv_cpu\sw\coremark\core_list_join.c YH_rv_cpu\sw\coremark\core_matrix.c YH_rv_cpu\sw\coremark\core_state.c YH_rv_cpu\sw\coremark\core_util.c YH_rv_cpu\sw\coremark\core_main.c
```

预期：无输出。

PPT/报告禁用口径关键词审计：

```powershell
rg -n "已上板验证通过|已经上板|已完成上板|board evidence complete=True|submission_evidence_complete=True|官方 EEMBC|EEMBC 10 秒认证|板级 DMIPS|board-proven" artifacts\strict_50m_timing_opt_20260609 -S -g "*.md" -g "*.ps1"
```

允许出现的位置：

- 禁止说法列表。
- 边界说明。
- pending 或待补语句。

不允许出现的位置：

- 当前主结果页。
- PPT 正文结论。
- 报告摘要。
- README 当前推荐口径。

## 4. PPT 发布前逐页检查

| 页类 | 必查项 | 通过标准 |
|---|---|---|
| 标题页 | 主指标和证据等级 | 写 `post-route timing-closed engineering candidate`，不写 board-proven |
| 赛题要求页 | 50 MHz 和应用演示 | 50 MHz 写 post-route closed；应用演示写 xsim pass |
| 架构页 | 自研 RV32 五级流水 | 不扩张到未验证 RV64 或复杂预测器 |
| strict BRAM 页 | 同步 BRAM 口径 | 明确零延迟模型不可作为当前主结果 |
| 优化页 | RTL/配置/实现流程 | 不写修改 CoreMark |
| 实验结果页 | 数字 | 只使用 9965 / 4.287521 / 2.495618 xsim / +0.056 / +0.121 |
| CoreMark 页 | 合规边界 | 写 short-gate；不写官方 10 秒认证 |
| Dhrystone 页 | xsim 边界 | 写 xsim host-parsed；不写板级 DMIPS |
| 应用 demo 页 | 演示状态 | 写 xsim PASS；不写上板 demo 已完成 |
| 证据链页 | board 节点 | board evidence 节点必须标 pending |
| 总结页 | 当前结论 | 总结为 strict50 post-route timing-closed candidate |

## 5. 技术报告发布前检查

| 章节 | 必查项 | 通过标准 |
|---|---|---|
| 摘要 | 结论边界 | 不含 board-proven 和官方 EEMBC 认证 |
| 设计目标 | 赛题对照 | 只声明当前已验证 RV32/PYNQ-Z2/50 MHz |
| 微结构 | 五级流水 | IF/ID/EX/MEM/WB 表述与 RTL 一致 |
| 性能优化 | 技术亮点 | 至少包含 forwarding/load-use、branch redirect/BHT、DCache/BRAM、implementation directive |
| 时序优化 | 热点路径 | 明确 MEM/DCache/load-use/redirect-cache/front-end control 到 PC 选择的长路径 |
| 实验结果 | 数据一致 | 数字与 `REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md` 一致 |
| 应用演示 | demo 边界 | 写 strict50 perf demo xsim PASS，board 待补 |
| 合规性 | 禁止夸大 | 明确 CoreMark 未改、short-gate、DMIPS xsim、board pending |

## 6. 上板证据补齐后的提升条件

只有同时满足以下条件，才能把当前候选从
`post-route timing-closed engineering candidate` 提升为 `board-proven result`：

| ID | 条件 | 证据 |
|---|---|---|
| B01 | 使用当前归档 bitstream | `.bit` 路径和 SHA256 与 `board_impl220_bitstream_20260702` 一致 |
| B02 | PROGRAM_OK | Hardware Manager log 或截图能识别下载成功 |
| B03 | UART raw log | 原始日志能识别 workload、当前配置和 PASS/CRC/summary |
| B04 | 视频 | 能看到板卡、下载环境或下载后状态、UART 输出 |
| B05 | board audit | `audit_strict50_board_evidence.ps1 -RequireComplete` 通过 |
| B06 | 报告同步 | README、PPT、技术报告、board evidence template 全部更新同一口径 |

未同时满足以上条件前，所有材料必须继续使用：

```text
post-route timing-closed engineering candidate; board evidence pending
```

## 7. 最终提交前冻结检查

| ID | 检查 | 命令/动作 | 通过标准 |
|---|---|---|---|
| F01 | worktree 状态 | `git status --short --branch --untracked-files=no` | 没有未提交 tracked 改动 |
| F02 | forbidden staged | `git diff --cached --name-only` | 不含 DCP、旧提交目录、CoreMark 核心文件、`resolve_python.bat` |
| F03 | package dry-run | `make_cicc_strict50_package.ps1` | PASS |
| F04 | metric verify | `verify_strict50_impl220_metrics.ps1` | PASS |
| F05 | board audit | 上板前普通 audit；上板后 `-RequireComplete` | 输出符合当前证据等级 |
| F06 | PPT 人工检查 | 逐页检查 | 所有主指标和边界一致 |
| F07 | 报告人工检查 | 逐章检查 | 不混用历史数据 |
| F08 | commit/tag | `git commit`、必要时 `git tag` | commit message/tag 明确证据等级 |

## 8. 当前结论

截至 2026-07-06，当前 `impl220` strict50 候选已经具备：

- post-route timing closed implementation evidence。
- CoreMark short-gate summary。
- Dhrystone/DMIPS xsim evidence。
- strict50 perf demo xsim evidence。
- bitstream 和 SHA256 归档。
- PPT 内容母稿、技术报告草稿、QA、讲稿和证据索引。

仍未具备：

- PROGRAM_OK。
- board UART raw log。
- board video。
- board-proven 证据链。

因此，当前所有材料必须继续保持严格表述：

```text
9965 LUT / 4.287521 CoreMark/MHz / 2.495618 DMIPS/MHz xsim / 50 MHz /
WNS +0.056 ns / WHS +0.121 ns; post-route timing-closed engineering candidate,
board evidence pending.
```
