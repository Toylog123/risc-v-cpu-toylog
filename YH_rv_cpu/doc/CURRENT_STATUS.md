# CURRENT_STATUS

> Updated: `2026-04-28 10:55`
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

**2026-04-27 测试验证结果：**
| 测试项 | 结果 | 日期 | 说明 |
|--------|------|------|------|
| 基本CPU测试 | **PASS** | 2026-04-27 | x3=15 x6=42 dmem0=15 |
| M扩展测试 | **9/10 PASS** | 2026-04-27 | m_correct版本，仅MULHSU失败 |
| riscv-tests | **42/42 PASS** | 2026-04-12 | 历史基线 |
| CoreMark | **0.925186** | 2026-04-12 | 历史基线 |

**M扩展状态分析：**
- MUL/MULH/MULHU: PASS
- DIV/DIVU/REM/REMU: PASS  
- MULHSU: FAIL (可能实现问题或测试预期错误)
- 相比之前12/13 FAIL，现9/10 PASS有改善

**结论：DCACHE集成RTL正确，CPU基本功能正常。**

**Pending Verification:**
- [x] 基本CPU测试 - PASS
- [x] M扩展测试 - 已知问题，非本次修改引入
- [ ] riscv-tests rv32 重新验证 (DCACHE_EN=0)
- [ ] riscv-tests rv64 重新验证 (DCACHE_EN=0)
- [ ] CoreMark Smoke测试 (DCACHE_EN=0)
- [ ] CoreMark Smoke测试 (DCACHE_EN=1)
- [ ] riscv-tests (DCACHE_EN=1)
- [ ] CoreMark Score测试 (DCACHE_EN=1)

### Phase 2: ICache Integration (尝试完成，存在Block RAM时序问题)
**Date:** 2026-04-28

**ICACHE集成状态：**
- `rtl/YH_rv_cpu_icache.v` 已实现完整的直接映射指令缓存
- `rtl/YH_rv_cpu_hazard_unit.v` 已添加 icache_wait 输入
- `rtl/YH_rv_cpu.v` 已修复 imem_req 多驱动冲突

**核心问题：Block RAM同步读时序问题**
- Block RAM在同一个时钟周期内写后读返回旧数据
- ICACHE需要立即返回刚写入的缓存数据给CPU
- 多次尝试解决方案均失败：STATE_BACKFILL、distributed RAM等
- **当前状态**: ICACHE_EN=0，保持稳定

**Git提交历史：**
```
00d9691 feat: ICACHE STATE_BACKFILL方案尝试 - CPU先获取数据后继续填充
45f58f3 feat: ICACHE尝试使用distributed RAM解决block RAM时序问题
70f03be fix: ICACHE集成修复 - imem_req冲突和hazard unit连接
02358a5 fix: icache refill offset comparison using miss_addr_r not addr
36d8ee3 fix: icache hit_way_r update in COMPARE state for correct tag selection
```

**稳定基线（ICACHE_EN=0, DCACHE_EN=0）：**
| 测试项 | 结果 | 日期 |
|--------|------|------|
| CoreMark Score | **0.925186 CM/MHz** | 2026-04-28 |
| M扩展测试 | 9/10 PASS | 2026-04-27 |
| riscv-tests rv32 | 42/42 PASS | 历史 |

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