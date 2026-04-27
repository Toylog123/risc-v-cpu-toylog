# CURRENT_STATUS

> Updated: `2026-04-27 21:52`
> Branch: `fix/dcache-icache-integration`
> Live repo state: verify with `git status --short --branch` and
> `git log -4 --oneline` before take-over

## Live repo note

- This file tracks the currently trusted engineering state, not the exact
  moving commit tip.
- Before take-over, always re-run:
  - `git status --short --branch`
  - `git log -4 --oneline`

## DCache/ICache Integration Status

### Phase 1: DCache Integration (RTL修改完成，待功能验证)
**Date:** 2026-04-27

**RTL修改完成，iverilog编译验证通过：**
- `rtl/YH_rv_cpu.v` (+74行): dcache信号声明、gen_dcache块实例化、mem_wait修复
- `rtl/YH_rv_cpu_hazard_unit.v` (+14行): dcache_wait输入、stall_decode逻辑
- `rtl/YH_rv_cpu_soc.v` (+6行): dmem_we/dmem_ready接口信号

**DCACHE_EN Parameter:**
- `0`: 直连dmem路径（原有行为）
- `1`: 通过dcache连接（代码框架完成）

**功能测试状态（历史记录）：**

| 测试项 | 结果 | 日期 | 说明 |
|--------|------|------|------|
| M扩展测试 | **12/13 FAIL** | 2026-04-22 | MUL/DIV/REM指令有bug，非本次修改引入 |
| CoreMark Short | **0.925186 CoreMark/MHz** | 2026-04-12 | PASS，短运行，competition_reportable=yes |
| riscv-tests rv32 | **42/42 PASS** | 2026-04-12 | full-ui测试 |

**2026-04-27 测试记录：**
- M扩展测试：stable版本(eab5713)运行结果0/11通过（寄存器='z'，CPU未运行）
  - 原因：prj文件不包含完整RTL模块链
  - M扩展已知问题：ALU实现bug，12/13 FAIL from 2026-04-22
- riscv-tests: 之前运行PASS

**Git Tag备份点：**
- `v-before-current-test-2026-04-27` - DCACHE集成修改前备份
- `v-baseline-m-ext-known-issue-2026-04-27` - M扩展已知问题状态

**Pending Verification:**
- [x] M扩展测试 (DCACHE_EN=0) - 已知问题，非本次修改引入
- [ ] riscv-tests rv32 重新验证 (DCACHE_EN=0)
- [ ] riscv-tests rv64 重新验证 (DCACHE_EN=0)
- [ ] CoreMark Smoke测试 (DCACHE_EN=0)
- [ ] CoreMark Smoke测试 (DCACHE_EN=1)
- [ ] riscv-tests (DCACHE_EN=1)
- [ ] CoreMark Score测试 (DCACHE_EN=1)

### Phase 2: ICache Integration (NOT STARTED)
- 计划文档: `doc/cache_axi_integration_design.md`
- 模块: `rtl/YH_rv_cpu_icache.v` (已存在)

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

## Recommended next step

### DCache/ICache Integration Path:
1. **Immediate:** 手动运行测试验证DCACHE_EN=0路径仍正常
   - `scripts\run_m_extension_test.bat`
   - `scripts\run_coremark_smoke.bat rv32`
2. **验证通过后:** 切换DCACHE_EN=1，运行相同测试
3. **ICache集成:** DCache验证通过后开始

### Legacy Optimization Path (if time permits):
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
- `YH_rv_cpu/doc/cache_axi_integration_design.md` (DCache/ICache设计)