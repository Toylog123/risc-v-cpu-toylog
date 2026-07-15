# impl136 Freeze and Handoff Record

> Frozen at: `2026-07-15 08:03:17 +08:00`
> Freeze ID: `impl136-20260715`
> Worktree: `D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508`
> Branch: `codex/syncbram-h22-20260514`
> Freeze tag: `freeze-impl136-20260715` (created after the scoped freeze commit and pushed with the branch)

## 1. 项目是什么

本冻结记录覆盖 PYNQ-Z2 的 `impl136` 严格 50 MHz exact-CoreMark-ROM 候选：
`impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017`。
目标是保存可复核的路由 DCP、bitstream、严格 10 秒 xsim 证据，以及板级闭环所需的可执行脚本和缺口。

## 2. 当前做到哪一步

- 已具备 bitstream、时序闭合和严格 10 秒 xsim 证据；`impl136` 是 bitstream-backed。
- 不是板级已验证结果：未归档 `PROGRAM_OK`、UART 原始日志、UART 标记状态或板级视频。
- 2026-07-13 的非侵入探测记录 `HW_PROBE_RESULT=connect_hw_server_failed`；`cs_server` 未能连接 `localhost:9315`。
- 本机上不存在运行中的 `vivado`、`hw_server` 或 `cs_server` 进程。Vivado 2025.2 工具位于 `D:\Vivado\2025.2\Vivado\bin\`。

## 3. 已完成的关键工作

- Bitstream：`impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit`，长度 `4045694` 字节，SHA256 `ba83976a59f8596faf6f2bd9eb015188fbf96bed59c427effd4403f347d3c4d3`。
- Bitgen 日志 `vivado_write_bitstream_impl136.log` 含 `DRC finished with 0 Errors`、`Bitgen Completed Successfully` 和 `write_bitstream completed successfully`。
- 时序报告 `bitstream_from_dcp_timing_summary.rpt`：WNS `+0.017 ns`、WHS `+0.155 ns`、所有用户时序约束满足。
- 严格 10 秒 xsim：`../strict10s_impl136_20260709/iter2150_cpu50timer/coremark50_fast_gate_iter2150_cpu50timer.summary.txt`，`clock_hz=50000000`、`iterations=2150`、`total_seconds=10.029656`、`coremark_per_mhz=4.287286`、`crcfinal=0xea58`、`validation_clean=yes`、`strict_eembc_10s_compliant=yes`、`acceptance_pass=yes`。
- 2026-07-15 冻结前复核：`refresh_impl136_sha256sums.ps1` 成功；`verify_impl136_evidence.ps1` 返回 `VERIFY_RESULT=pass`。
- 板级 runner 已在退出前刷新 `SHA256SUMS.txt`；编程脚本要求恰好一个 `xc7z020`，UART 脚本会生成原始日志和标记状态。

## 4. 当前阻塞与风险

- 板级必需验证在 2026-07-15 返回 `VERIFY_RESULT=fail`（预期）：缺失 `PROGRAM_OK`、`UART_RESULT=markers_found`、`uart_impl136_raw.log` 的预期 CoreMark 标记，以及 `board_video_impl136.[mp4|mov|mkv|avi|webm]`。
- 现有探测失败属于环境/连通性阻塞，证据见 `hw_probe_impl136.status.txt`、`vivado_hw_probe_impl136.log`、`board_evidence_run_impl136.status.txt`；不应据此宣称板上运行。
- 验证器状态文件包含本机绝对路径；在其他主机或 checkout 路径运行验证器后，必须再次刷新 `SHA256SUMS.txt`，再用 `-CheckOnly` 确认同步。
- 当前工作树共有大量无关改动和未跟踪文件。此冻结只打包本目录、`../strict10s_impl136_20260709/` 和列出的四份状态文档；不包含用户正在进行的 RTL 或其他实验改动。
- `impl136` bitstream 的 CoreMark ROM 是 10-iteration fast gate；严格 10 秒结果仅为 xsim 证据，不是严格 10 秒板级证据。

## 5. 下一步最值得做的事项

1. 连接并上电 PYNQ-Z2，确认 JTAG 可见；从本目录运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\probe_hw_targets_impl136.tcl` 或通过 runner 触发探测。
2. 仅当检测到恰好一个 `xc7z020` 后，运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\run_impl136_board_evidence.ps1 -PortName COMx`。
3. 保存 `board_video_impl136.mp4`（或允许扩展名），检查 `uart_impl136.status.txt` 与 `uart_impl136_raw.log`。
4. 运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1`，再运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_impl136_evidence.ps1 -RequireBoardEvidence`；只有返回 `VERIFY_RESULT=pass` 才可声明板级已验证。

## 6. 关键文档与命令

- 当前状态：`YH_rv_cpu/doc/CURRENT_STATUS.md`
- 冻结基线：`../FREEZE_BEST_STRICT50_IMPL136_20260625.md`
- 上一份交接：`../HANDOFF_20260617.md`
- 本候选说明：`README.md`
- 板级证据模板：`BOARD_EVIDENCE_TEMPLATE.md`
- 校验清单：`SHA256SUMS.txt`
- 离线验证：`powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_impl136_evidence.ps1`
- 板级门禁：`powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_impl136_evidence.ps1 -RequireBoardEvidence`
- 哈希刷新：`powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1`
- 验证后同步确认：`powershell -NoProfile -ExecutionPolicy Bypass -File .\refresh_impl136_sha256sums.ps1 -CheckOnly`

分发状态：本记录以 `freeze-impl136-20260715` 标注本次 scoped freeze commit；推送后应能从 `origin/codex/syncbram-h22-20260514` 和同名 tag 恢复。冻结基线提交为 `1c76ed4d5b2312f1dceb6876cc91f31c3cf68022`；本次 commit hash 和实际推送结果由 Git 事务完成后记录在交接输出中。

## 7. 文档缺口与建议补齐项

- 缺少真实板级证据产物：PROGRAM 状态、UART 原始日志、UART 标记状态和视频。
- `BOARD_EVIDENCE_TEMPLATE.md` 保持 `TODO/pending`，直至板级门禁通过。
- 如需把严格 10 秒结果用于板级声明，必须新增独立的 >=10 秒板上运行、UART/视频和哈希覆盖；当前 xsim 证据不能替代它。
