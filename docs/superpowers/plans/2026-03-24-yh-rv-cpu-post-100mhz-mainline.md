# YH_rv_cpu Post-100MHz Mainline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current 100MHz-passing RTL baseline into a stable competition baseline by landing CoreMark, expanding regression coverage, and preparing the board-level closure path.

**Architecture:** Keep the current `100MHz` implementation result as the protected baseline and treat all follow-up work as regression-sensitive. Prioritize verification-chain completeness before new feature growth: first make CoreMark reproducible, then expand `RV64` and `riscv-tests`, and only then freeze board-facing artifacts. Avoid broad RTL refactors unless a failing regression identifies a concrete root cause.

**Tech Stack:** Verilog/SystemVerilog RTL, Vivado/xsim batch scripts, RISC-V GCC toolchain, CoreMark, `riscv-tests`, Nexys A7 Vivado flow

---

## File Map

- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_soc.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_hazard_unit.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_mem_stage.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_rv32_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_rv64_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv64_tb.v`
- Modify: `YH_rv_cpu/scripts/run_coremark_smoke.bat`
- Modify: `YH_rv_cpu/scripts/run_riscv_tests_subset.bat`
- Modify: `YH_rv_cpu/scripts/build_vivado_project.bat`
- Modify: `YH_rv_cpu/fpga/vivado/constraints/nexys_a7_100_template.xdc`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- Modify: `YH_rv_cpu/doc/技术文档.md`

### Task 1: Freeze And Verify The 100MHz Baseline

**Files:**
- Inspect: `project/reports/clk_10p000ns/impl_timing_summary.rpt`
- Inspect: `project/reports/clk_10p000ns/impl_utilization.rpt`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`

- [ ] **Step 1: Re-run the protected baseline checks**

Run:
```bat
cmd /c YH_rv_cpu\scripts\check_syntax.bat
cmd /c YH_rv_cpu\scripts\run_soc_smoke.bat
cmd /c YH_rv_cpu\scripts\run_trap_smoke.bat
cmd /c YH_rv_cpu\scripts\run_timer_irq_smoke.bat
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat impl100
```
Expected:
- All smoke scripts print `PASS`
- `impl_timing_summary.rpt` shows non-negative `WNS`
- `impl_utilization.rpt` matches the current baseline within small tool noise

- [ ] **Step 2: Update the project documents with the fresh baseline**

Record:
- latest `impl100` timing result
- latest utilization
- exact verification commands used
- note that this is now the protected pre-CoreMark baseline

- [ ] **Step 3: Commit the documentation refresh**

Run:
```bat
git add YH_rv_cpu/doc/YH_rv_cpu_handoff.md YH_rv_cpu/doc/YH_rv_cpu_change_log.md YH_rv_cpu/doc/YH_rv_cpu_todo.md
git commit -m "docs: refresh post-100mhz protected baseline"
```

### Task 2: Rebuild A Minimal, Stable CoreMark Reproduction

**Files:**
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_rv32_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_rv64_tb.v`
- Modify: `YH_rv_cpu/scripts/run_coremark_smoke.bat`
- Inspect: `YH_rv_cpu/scripts/build_coremark.bat`
- Inspect: `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32.log`

- [ ] **Step 1: Reproduce the current CoreMark failure without ad-hoc RTL edits**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_coremark_smoke.bat rv32 5 400
```
Expected:
- Command fails or times out
- Log contains the failing PC and cycle count

- [ ] **Step 2: Add only generic debug hooks to the CoreMark TB**

Keep:
- plusargs such as `max_cycles`, `trace_start_cycle`, `trace_end_cycle`
- optional trace file output

Do not keep:
- hardcoded PC watchlists tied to one binary layout
- giant one-off trace dumps that are not reusable

- [ ] **Step 3: Re-run the failing CoreMark command with the new generic hooks**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_coremark_smoke.bat rv32 5 400
```
Expected:
- Failure still reproduces
- trace/log output is enough to identify the next debug boundary

- [ ] **Step 4: Commit the reusable CoreMark reproduction tooling**

Run:
```bat
git add YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v YH_rv_cpu/tb/YH_rv_cpu_coremark_rv32_tb.v YH_rv_cpu/tb/YH_rv_cpu_coremark_rv64_tb.v YH_rv_cpu/scripts/run_coremark_smoke.bat
git commit -m "test: add reusable coremark debug hooks"
```

### Task 3: Fix CoreMark At The Root Cause And Lock It With Regression

**Files:**
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_soc.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_hazard_unit.v`
- Modify: `YH_rv_cpu/rtl/YH_rv_cpu_mem_stage.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v`
- Modify: `YH_rv_cpu/doc/技术文档.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`

- [ ] **Step 1: Write down the current root-cause hypothesis before changing RTL**

Template:
```text
Hypothesis: CoreMark fails because <exact control/data path bug>.
Evidence: <exact failing PC/log/trace observation>.
Boundary: Fix should only affect <named pipeline or memory path>.
```

- [ ] **Step 2: Add the smallest failing regression that captures the symptom**

Options:
- a tighter CoreMark smoke parameter set
- a dedicated micro TB derived from the CoreMark failing sequence

Pass condition:
- regression fails on current RTL
- regression passes only after the actual fix

- [ ] **Step 3: Implement one minimal RTL fix**

Guardrails:
- one root-cause fix per attempt
- no broad cleanup in the same commit
- re-use the current `100MHz`-passing structure unless the failing trace proves otherwise

- [ ] **Step 4: Run the full CoreMark verification set**

Run:
```bat
cmd /c YH_rv_cpu\scripts\check_syntax.bat
cmd /c YH_rv_cpu\scripts\run_coremark_smoke.bat rv32 5 400
cmd /c YH_rv_cpu\scripts\run_coremark_smoke.bat rv32
```
Expected:
- short reproduction passes
- default `rv32` CoreMark smoke passes

- [ ] **Step 5: Re-run the protected smoke tests to catch collateral regressions**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_soc_smoke.bat
cmd /c YH_rv_cpu\scripts\run_trap_smoke.bat
cmd /c YH_rv_cpu\scripts\run_timer_irq_smoke.bat
```

- [ ] **Step 6: Re-run implementation timing after the CoreMark fix**

Run:
```bat
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat impl100
```
Expected:
- `WNS >= 0`
- if timing regresses below zero, stop and debug before expanding scope

- [ ] **Step 7: Commit the CoreMark fix and docs**

Run:
```bat
git add YH_rv_cpu/rtl/YH_rv_cpu.v YH_rv_cpu/rtl/YH_rv_cpu_soc.v YH_rv_cpu/rtl/YH_rv_cpu_hazard_unit.v YH_rv_cpu/rtl/YH_rv_cpu_mem_stage.v YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v YH_rv_cpu/doc/技术文档.md YH_rv_cpu/doc/YH_rv_cpu_change_log.md
git commit -m "fix: make coremark regression pass"
```

### Task 4: Expand Regression Coverage To A Real RV32/RV64 Baseline

**Files:**
- Modify: `YH_rv_cpu/scripts/run_riscv_tests_subset.bat`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv64_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_xlen64_tb.v`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`

- [ ] **Step 1: Reconfirm the current rv32 subset baseline**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv32
```
Expected:
- default `rv32` subset passes
- `build/tests/riscv-tests/rv32/summary.txt` records the pass

- [ ] **Step 2: Define and wire the first formal rv64 subset**

Target:
- start with arithmetic, branch, and load/store instructions already supported by the current XLEN path
- avoid claiming unsupported instructions as part of the baseline

- [ ] **Step 3: Add or update the rv64 regression entry point**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_xlen64_smoke.bat
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv64
```
Expected:
- smoke passes
- first formal rv64 subset either passes or produces a bounded TODO list

- [ ] **Step 4: Commit the regression baseline expansion**

Run:
```bat
git add YH_rv_cpu/scripts/run_riscv_tests_subset.bat YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_tb.v YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv64_tb.v YH_rv_cpu/tb/YH_rv_cpu_xlen64_tb.v YH_rv_cpu/doc/YH_rv_cpu_todo.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md
git commit -m "test: expand rv32 and rv64 regression baseline"
```

### Task 5: Freeze The Board-Level Bring-Up Path

**Files:**
- Modify: `YH_rv_cpu/fpga/vivado/constraints/nexys_a7_100_template.xdc`
- Modify: `YH_rv_cpu/fpga/vivado/scripts/build_nexys_a7_100_project.tcl`
- Modify: `YH_rv_cpu/scripts/open_vivado_project.bat`
- Modify: `YH_rv_cpu/doc/技术文档.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`

- [ ] **Step 1: Rebuild the Vivado project on the current stable baseline**

Run:
```bat
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat project
```
Expected:
- `.xpr` opens cleanly from the current workspace
- reports land in `project/reports`

- [ ] **Step 2: Replace template-only board assumptions with the final board-specific constraint set**

Checklist:
- clock pin
- reset input
- UART pins
- any required board I/O for demo

- [ ] **Step 3: Re-run FPGA checks with the frozen XDC**

Run:
```bat
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat synth50
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat synth100
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat impl100
```
Expected:
- `50MHz` remains comfortably clean
- `100MHz` remains non-negative after implementation

- [ ] **Step 4: Commit the board-facing closure**

Run:
```bat
git add YH_rv_cpu/fpga/vivado/constraints/nexys_a7_100_template.xdc YH_rv_cpu/fpga/vivado/scripts/build_nexys_a7_100_project.tcl YH_rv_cpu/scripts/open_vivado_project.bat YH_rv_cpu/doc/技术文档.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md
git commit -m "fpga: freeze board bring-up baseline"
```

## Definition Of Done

- `impl100` remains passing on the current main branch
- `CoreMark rv32` smoke passes with a reproducible command
- `rv32` default `riscv-tests` subset passes
- first formal `rv64` regression subset is defined and runnable
- board-level XDC and Vivado project entry are frozen for bring-up
- handoff docs reflect the true state of verification and timing

## Recommended Execution Order

1. Task 1
2. Task 2
3. Task 3
4. Task 4
5. Task 5
