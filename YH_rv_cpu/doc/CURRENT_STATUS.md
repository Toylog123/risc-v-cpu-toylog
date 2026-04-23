# CURRENT_STATUS

> Updated: `2026-04-12`
> Branch: `main`
> Live repo state: verify with `git status --short --branch` and
> `git log -4 --oneline` before take-over

## Live repo note

- This file tracks the currently trusted engineering state, not the exact
  moving commit tip.
- Before take-over, always re-run:
  - `git status --short --branch`
  - `git log -4 --oneline`

## Frozen engineering baseline

- `rv32 full-ui = 42/42`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt`
- `rv64 full-ui = 54/54`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt`
- `rv32 baseline = 33/33`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt`
- `rv64 baseline = 21/21`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt`
- CoreMark short:
  - `11014885 cycles`
  - `0.912472 CoreMark/MHz`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt`
- CoreMark strict:
  - `1095991523 cycles`
  - `10.959325s`
  - `0.912465 CoreMark/MHz`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt`
- `impl50`:
  - `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`
  - `WNS=+5.599ns`
  - `WHS=+0.025ns`
  - `project/reports/clk_20p000ns/`

## ISA positioning

- Competition spec allows CPU baseline on `RV32I` or `RV64I`.
- Current engineering validation already covers `RV32/RV64` dual-XLEN
  baseline and `full-ui`.
- Frozen performance/reportable path still stays on the `RV32I + Zicsr`
  build and CoreMark flow.

## Current optimization status

- Frozen competition baseline is still the `2026-04-08` closure set.
- Current retained worktree change is:
  - decode-stage early redirect for taken `BEQ/BNE`
  - gated by operand-ready checks against pending `ID/EX` and `EX/MEM` writes
- Fresh red/green evidence:
  - baseline `FAIL`: `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_baseline_2026-04-12.log`
  - trial `PASS`: `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_trial_2026-04-12.log`
  - default redirect diag `PASS`: `YH_rv_cpu/build/tests/branch-first/redirect_diag_default_trial_2026-04-12.log`
- Fresh `2026-04-12` validation on the retained RTL:
  - `rv32 full-ui = 42/42`
    - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-12.txt`
  - `rv64 full-ui = 54/54`
    - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-12.txt`
  - `rv32 baseline = 33/33`
    - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-12.txt`
  - `rv64 baseline = 21/21`
    - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-12.txt`
  - CoreMark short `= 10862713 cycles`, `0.925186 CoreMark/MHz`
    - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-12.summary.txt`
    - repeated rerun matched exactly:
      `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_rerun_2026-04-12.summary.txt`
  - CoreMark profile `= 12364249 cycles`
    - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-12.log`
- Measured delta versus the frozen baseline:
  - short cycles: `11014885 -> 10862713` (`-152172`, `-1.3815%`)
  - short score: `0.912472 -> 0.925186` (`+0.012714`, `+1.3934%`)
  - `ex_branch_redirect_cycles`: `1235790 -> 1081457`
  - `ex_fetch_redirect_valid_cycles`: `1504970 -> 1350637`
  - `fetch_queue_empty_cycles`: unchanged at `1504970`
- Interpretation:
  - the retained gain comes from shrinking branch redirect windows
  - the win does not come from reuse activation or lower queue-empty windows
  - `BEQ/BNE pipe-hit-only` and `jal-only` remain historical rejected paths
- Tooling closure from this round:
  - `scripts/run_coremark_score.bat` now derives artifact names from the
    summary path, so short/strict runs no longer clobber each other's
    `score.log` and `score.*`
- Still pending before refreshing the frozen competition tables:
  - fresh strict CoreMark long run
  - fresh `impl50`
  - fresh FPGA-like probe

## 2026-04-23 更新

### dcache 集成完成

- `DCACHE_EN=1` 时 dcache 模块正确插入到 mem_stage 和外部 dmem 之间
- M 扩展测试 **11/11 通过** ✓
  - `YH_rv_cpu/build/tests/dcache_clean3/xsim.log`
- 测试覆盖：MUL, MULH, MULHU, MULHSU, DIV, DIVU, REM, REMU 及除零特殊处理

### icache 集成完成

- `ICACHE_EN=1` 时 icache 模块正确插入到 if_stage 和外部 imem 之间
- riscv-tests 验证通过 ✓
- 参数化设计：`ICACHE_EN` (默认0)、`DCACHE_EN` (默认0)

### 关键修复

- 修复 `DCACHE_EN == 1` 分支中 dcache 未正确驱动外部 `dmem_*` 信号的问题
- 添加 `dmem_read_req`、`dmem_we`、`dmem_wdata`、`dmem_wstrb` 赋值

### 模块新增/更新

| 模块 | 文件 | 状态 |
|------|------|------|
| 数据缓存 | `rtl/YH_rv_cpu_dcache.v` | 已集成 |
| 指令缓存 | `rtl/YH_rv_cpu_icache.v` | 已集成 |
| AXI-Lite接口 | `rtl/YH_rv_cpu_axi_lite_if.v` | 新增 |
| M扩展测试 | `tb/YH_rv_cpu_m_extension_tb.v` | 新增 |

## Recommended next step

- First finish freeze-refresh on the retained RTL:
  - fresh strict CoreMark long run
  - `scripts\build_vivado_project.bat impl50`
  - `scripts\run_coremark_fpga.bat rv32`
- Only after those stay green, refresh the frozen competition tables/docs.
- If another optimization round is started later:
  - do not reopen `jal-only` or `BEQ/BNE pipe-hit-only`
  - add the smallest missing directed tests first
  - keep queue/reuse micro-tuning frozen unless a new result proves it lowers
    `fetch_queue_empty_cycles`

## Primary entry docs

- `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- `YH_rv_cpu/doc/performance_experiment_log.md`
