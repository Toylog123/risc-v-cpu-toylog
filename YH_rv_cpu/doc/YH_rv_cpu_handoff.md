# YH_rv_cpu 交接说明

## 1. 项目是什么

`YH_rv_cpu` 是当前比赛提交主线使用的 RISC-V CPU 工程基线。当前目标不是继续做宽泛探索，而是把工程维持在“可复现、可验证、可交接、可继续优化”的提交级状态。

## 2. 当前做到哪一步

- 当前主线冻结基线来自 `2026-04-07` fresh 验证
- 最新已提交的 FPGA pre-board 文档收口提交为 `cd22afc`：`docs: tighten fpga pre-board bring-up SOP`
- CoreMark 正式短跑、RV32/RV64 baseline、`impl50`、FPGA-like probe 均已有 fresh 证据
- strict EEMBC `>=10s` 长跑已完成，strict 口径现已可对外引用

当前冻结结果：

| 项目 | 结果 |
|------|------|
| CoreMark short score | `0.912472 CoreMark/MHz` |
| CoreMark short completion cycles | `11014885` |
| CoreMark strict score | `0.912465 CoreMark/MHz` |
| CoreMark strict completion cycles | `1095991523` |
| CoreMark strict runtime | `10.959325s` |
| CoreMark score 结论 | short path `competition_reportable=yes`；strict path `strict_eembc_10s_compliant=yes` |
| CoreMark smoke | `620530 cycles` |
| RV32 baseline | `33/33` |
| RV64 baseline | `21/21` |
| impl50 | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP` |
| impl50 timing | `WNS = +5.599ns`，`WHS = +0.025ns` |
| FPGA-like probe | `156442 cycles`，`7.728811 CoreMark/MHz` |

## 3. 已完成的关键工作

- 冻结了当前比赛提交主线的 CoreMark score 命令和解释口径
- 保留优化已收敛为：
  - `stall_decode = load_use_hazard`
  - FPGA 默认 `IMEM_OUTPUT_REG=0`
  - FPGA 默认 `DMEM_OUTPUT_REG=0`
- fresh 回归已经证明上述保留优化没有打坏：
  - `scripts\run_riscv_tests_subset.bat rv32` -> `33/33`
  - `scripts\run_riscv_tests_subset.bat rv64` -> `21/21`
  - `scripts\build_vivado_project.bat impl50` -> 通过
- 已完成 FPGA pre-board SOP 收口：
  - 冻结 `impl50` 为比赛面向的比特流构建入口
  - 明确串口口径为 `115200 8N1`
  - 明确板前证据归档路径 `doc/fpga_bringup_evidence/<YYYY-MM-DD>/`
  - 明确 demo firmware staging SOP

## 4. 当前阻塞与风险

- 外部阻塞：
  - 缺实体板卡，无法完成 UART/LED 实板闭环
  - 缺最终板级 I/O delay 约束，`XDC` 仍是 pre-board 版本
- 已明确关闭的高风险方向：
  - 不能简单通过放松 `stall_decode` 去继续做 fetch 前端提分

## 5. 下一步最值得做的 5 项

1. 冻结第二轮优化前基线，并把 strict CoreMark 结果作为正式性能口径写入实验日志
2. 如果继续提分，只能从 `fetch/request/queue` 解耦方向按单变量实验推进
3. 为任何 retained 优化补齐完整 fresh 回归矩阵
4. 板卡到位后按 checklist 完成 UART/LED/boot banner 实板闭环
5. 板卡到位后补正式 I/O delay 约束与实板证据

## 6. 关键文档与命令

关键文档：

- `README.md`
- `doc/技术文档.md`
- `doc/coremark_submission_report.md`
- `doc/performance_experiment_log.md`
- `doc/regression_test_log.md`
- `doc/fpga_bringup_checklist.md`
- `fpga/vivado/README.md`

关键命令：

```bat
scripts\run_coremark_smoke.bat rv32
scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
scripts\run_riscv_tests_subset.bat rv32
scripts\run_riscv_tests_subset.bat rv64
scripts\build_vivado_project.bat impl50
scripts\run_coremark_fpga.bat rv32
```

关键证据位置：

- CoreMark summary: `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt`
- CoreMark raw log: `build/sw/YH_rv_cpu_coremark_rv32_score.log`
- Strict CoreMark summary: `build/sw/YH_rv_cpu_coremark_rv32_strict.summary.txt`
- Strict CoreMark raw log: `build/sw/YH_rv_cpu_coremark_rv32_strict.log`
- FPGA 报告：`project/reports/clk_20p000ns/`
- 100MHz 参考报告：`project/reports/clk_10p000ns/`
- 比特流：`project/YH_rv_cpu_nexys_a7_100_20p000.bit`

## 7. 文档缺口与建议补齐项

- 板卡到位后，需要把 bring-up checklist 从“板前闭环”更新为“实板闭环”
- 如果第二轮性能优化启动，需要把每轮实验完整写入 `doc/performance_experiment_log.md`

## 2026-04-04 Update

- Added directed fetch diagnostic assets:
  - `tb/YH_rv_cpu_fetch_prefetch_tb.v`
  - `scripts/run_fetch_prefetch_diag.bat`
- Completed the first `fetch/request/queue` single-variable trial.
- Trial conclusion: `not retained`.
- Short CoreMark on the trial RTL remained `11014885 cycles` / `0.912472 CoreMark/MHz`.
- Mainline RTL was reverted to the frozen baseline after the experiment.

## 2026-04-07 Update

- Added the new directed `mem-wait overlap` diagnostic:
  - `tb/YH_rv_cpu_memwait_overlap_tb.v`
  - `scripts/run_memwait_overlap_diag.bat`
- Baseline observation is green and purely observational:
  - `mem_wait_cycles=1`
  - `mem_wait_overlap_opportunities=1`
  - `mem_wait_overlap_requests=0`
- The strict red/green entry is now reserved by `+require_overlap` for future use; it currently fails as expected because the frozen RTL does not yet generate an actual overlap request.
- Redirect accounting strict diagnostics are now closed for both `IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`.
- The redirect `pipe-hit` minimal RTL trial was rechecked with the new accounting guardrail; strict diagnostics can pass, but short score delta remains `0`, so the RTL is still rejected.
- The redirect same-cycle request trial also stayed at `0` short-score delta and was reverted in the same round.
- `timer_irq_smoke` is green again after fixing `TIMER_CTRL_ADDR` so a zero write really clears `timer_irq_en_r`.
- `build_vivado_project.bat impl50` now defaults to the frozen `YH_rv_cpu_demo` payload instead of inheriting the last `current.hex` left by regressions.
- Board bring-up is still externally blocked, so the UART/LED closed-loop and final board timing evidence remain pending.
- The `mem_wait overlap` RTL trial was executed and then rejected because the short CoreMark score stayed flat (`11014885 cycles`, `0.912472 CoreMark/MHz`).
