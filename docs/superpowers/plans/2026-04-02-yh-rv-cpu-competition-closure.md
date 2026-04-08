# YH_rv_cpu Competition Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current `YH_rv_cpu` baseline into a submission-grade competition baseline by formalizing CoreMark, completing regression and FPGA closure artifacts, and then executing only evidence-driven performance optimization.

**Architecture:** Treat the current `RV32I + Zicsr` five-stage pipeline as the protected baseline. First separate "smoke/debug" and "formal score/report" paths for CoreMark, then freeze reproducible regression and board-facing deliverables, and only after that allow RTL performance work. Keep all later optimization work gated by fresh regression, timing, and documentation updates.

**Tech Stack:** Verilog/SystemVerilog RTL, Vivado 2025.2, xsim batch scripts, xPack RISC-V GCC, CoreMark, `riscv-tests`, Nexys A7-100T bring-up flow, Markdown project docs

---

## 2026-04-08 Status Update

- Phase A is effectively closed:
  - CoreMark short path frozen
  - strict `>=10s` path available
  - command/report/doc split already in place
- Phase B is partially closed:
  - pre-board FPGA flow is frozen
  - real-board closure remains externally blocked and is not the active priority
- Phase C front-end quick-screen rounds are closed through `FQ-05`, all rejected
  for no retainable gain or early guardrail failure
- Current active closure task is no longer "invent another optimization"; it is
  "expand `riscv-tests` coverage, close the `fence_i` ISA/march ambiguity, then
  rerun fresh regression and sync docs"
- Current fresh active evidence:
  - `rv32 full-ui = 41/42`
  - `ma_data = PASS`
  - only current open item is `fence_i`, blocked by `zifencei` ISA/march scope

Treat the rest of this plan as historical execution guidance plus a checklist
for anything that still remains incomplete.

## Scope And Guardrails

- The first phase is not "make the score look better"; it is "make the score reproducible, explainable, and submission-safe".
- Keep `coremark smoke` and `coremark score` as two distinct paths. Do not overload one script with both responsibilities.
- Do not silently change benchmark workload, timer frequency assumption, and report formulas in the same commit.
- Do not start risky RTL optimization until CoreMark, `riscv-tests`, and FPGA flow each have a frozen baseline and matching documentation.
- Treat `RV32I + Zicsr` as the competition baseline unless the rules are clarified to allow a broader ISA. In particular, do not start `M`-extension work before a rules check is documented.

## Decision Baseline

- Competition hard requirements already frozen in local docs:
  - `01-项目管理/01-赛题要求/七星微赛题要求.md`
  - `01-项目管理/01-赛题要求/七星微赛方答疑整理.md`
- Current engineering baseline already confirmed:
  - `YH_rv_cpu/scripts/build_coremark.bat` can build a valid full CoreMark ELF
  - `YH_rv_cpu/build/sw/full_probe_exec0_i10_d2000.log` shows a reproducible full-algorithm run
  - `YH_rv_cpu/scripts/run_riscv_tests_subset.bat` already passes current `rv32`/`rv64` subsets
  - `YH_rv_cpu/scripts/build_vivado_project.bat` already supports local `synth/impl` flows

## File Map

- Modify: `YH_rv_cpu/scripts/build_coremark.bat`
- Modify: `YH_rv_cpu/scripts/run_coremark_smoke.bat`
- Create: `YH_rv_cpu/scripts/run_coremark_score.bat`
- Create: `YH_rv_cpu/scripts/report_coremark_result.py`
- Modify: `YH_rv_cpu/sw/coremark_port/core_portme.h`
- Inspect: `YH_rv_cpu/sw/coremark_port/core_portme.c`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v`
- Modify: `YH_rv_cpu/README.md`
- Modify: `YH_rv_cpu/doc/技术文档.md`
- Modify: `YH_rv_cpu/doc/regression_test_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Create: `YH_rv_cpu/doc/coremark_submission_report.md`
- Modify: `06-汇报材料/项目进展汇报-2026-04-01.md`
- Modify: `06-汇报材料/汇报摘要.md`
- Modify: `YH_rv_cpu/scripts/run_riscv_tests_subset.bat`
- Create: `YH_rv_cpu/scripts/riscv_tests_rv32_baseline.txt`
- Create: `YH_rv_cpu/scripts/riscv_tests_rv64_baseline.txt`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv32_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv64_tb.v`
- Modify: `YH_rv_cpu/scripts/build_vivado_project.bat`
- Modify: `YH_rv_cpu/scripts/open_vivado_project.bat`
- Modify: `YH_rv_cpu/fpga/vivado/README.md`
- Modify: `YH_rv_cpu/fpga/vivado/constraints/nexys_a7_100_template.xdc`
- Modify: `YH_rv_cpu/fpga/vivado/scripts/build_nexys_a7_100_project.tcl`
- Create: `YH_rv_cpu/doc/fpga_bringup_checklist.md`
- Create: `YH_rv_cpu/doc/performance_experiment_log.md`

## Phase Exit Criteria

### Phase A Exit: CoreMark Submission Path

- One command builds and runs a full CoreMark score path with `EXEC_MASK=0`
- Raw log, parsed summary, and report document all match each other
- Timer assumption and score formula are documented explicitly
- README, technical docs, regression log, and report materials no longer contain stale or contradictory CoreMark claims

### Phase B Exit: Regression And FPGA Closure

- `rv32` and `rv64` formal baselines have explicit manifests and reproducible summary logs
- `50MHz` competition FPGA flow is frozen with current reports and documented bring-up steps
- Board-arrival checklist exists and can be executed without relying on tribal knowledge

### Phase C Exit: Optimization Readiness

- There is a frozen pre-optimization baseline table for CoreMark, regression, timing, and resources
- Optimization backlog is ranked by expected gain, risk, and rule status
- At least one low-risk optimization lane is selected with explicit acceptance criteria

---

## Phase A: CoreMark Submission Path

### Task 1: Freeze The Official CoreMark Submission Decision

**Files:**
- Modify: `YH_rv_cpu/doc/coremark_submission_report.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`

- [ ] **Step 1: Write down the competition scoring stance before changing scripts**

Document:
- formal score path uses full workload: `EXEC_MASK=0`
- smoke path remains fast and non-authoritative
- report must distinguish "competition submission metric" from "strict EEMBC-valid run"
- current baseline ISA is `RV32I + Zicsr`

- [ ] **Step 2: Record the current known-good raw evidence**

Reference:
- `YH_rv_cpu/build/sw/full_probe_exec0_i10_d2000.log`

Capture:
- `CoreMark Size`
- `Total ticks`
- `Iterations`
- validation line
- cycle count from TB pass line

- [ ] **Step 3: Define the report formula explicitly**

Write down:
- input clock assumption in Hz
- `Iterations/Sec = iterations * timer_hz / total_ticks`
- `CoreMark/MHz = Iterations/Sec / (timer_hz / 1_000_000)`
- whether the current chosen iteration count satisfies the 10-second EEMBC rule

- [ ] **Step 4: Commit the decision document**

Run:
```bat
git add YH_rv_cpu/doc/coremark_submission_report.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md YH_rv_cpu/doc/YH_rv_cpu_todo.md
git commit -m "docs: freeze coremark submission decision"
```

### Task 2: Split Smoke And Formal Score Scripts

**Files:**
- Modify: `YH_rv_cpu/scripts/run_coremark_smoke.bat`
- Create: `YH_rv_cpu/scripts/run_coremark_score.bat`
- Inspect: `YH_rv_cpu/scripts/build_coremark.bat`

- [ ] **Step 1: Confirm the current gap**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_coremark_smoke.bat rv32
```
Expected:
- script passes smoke
- it does not yet produce a submission-grade score summary for full CoreMark

- [ ] **Step 2: Define the formal score script interface**

Required arguments:
- `target`
- `iterations`
- `data_size`
- `timer_hz`
- `max_cycles`
- optional output path for summary

Required defaults:
- full run uses `EXEC_MASK=0`
- score script writes both raw log and parsed summary

- [ ] **Step 3: Implement the dedicated score script**

Behavior:
- call `build_coremark.bat` with `EXEC_MASK=0`
- compile/elaborate/run the existing CoreMark TB
- write raw xsim log under `build/sw/`
- fail if validation line or completion line is missing

- [ ] **Step 4: Verify the score script on the current baseline**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
```
Expected:
- log contains `2K performance run parameters for coremark.`
- log contains `Correct operation validated.`
- script exits `0`

- [ ] **Step 5: Commit the script split**

Run:
```bat
git add YH_rv_cpu/scripts/run_coremark_smoke.bat YH_rv_cpu/scripts/run_coremark_score.bat
git commit -m "build: split coremark smoke and score paths"
```

### Task 3: Make Timing Semantics And Output Parsing Submission-Safe

**Files:**
- Modify: `YH_rv_cpu/sw/coremark_port/core_portme.h`
- Inspect: `YH_rv_cpu/sw/coremark_port/core_portme.c`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v`
- Create: `YH_rv_cpu/scripts/report_coremark_result.py`

- [ ] **Step 1: Reproduce the current accounting mismatch**

Inspect and note:
- `HAS_FLOAT=0`
- `YH_COREMARK_TIMER_HZ=1000UL`
- SoC timer increments once per cycle

Reference files:
- `YH_rv_cpu/sw/coremark_port/core_portme.h`
- `YH_rv_cpu/rtl/YH_rv_cpu_soc.v`

- [ ] **Step 2: Choose the formal reporting strategy**

Recommended strategy:
- keep benchmark binary lean
- do not rely on in-program float formatting for submission
- parse `Total ticks` and `Iterations` host-side
- compute `Iterations/Sec` and `CoreMark/MHz` in `report_coremark_result.py`

- [ ] **Step 3: Normalize testbench success wording**

Update:
- PASS banner should say generic `coremark completed`
- do not label a formal full run as `smoke test`

- [ ] **Step 4: Implement the host-side parser**

Parse from raw log:
- `CoreMark Size`
- `Total ticks`
- `Iterations`
- validation line
- completion cycle count

Emit:
- `.summary.txt`
- clearly labeled derived metrics
- whether run is "competition-usable" and whether it is "EEMBC 10s compliant"

- [ ] **Step 5: Verify parser output**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
python YH_rv_cpu\scripts\report_coremark_result.py YH_rv_cpu\build\sw\YH_rv_cpu_coremark_rv32_score.log 100000000
```
Expected:
- summary file is generated
- derived metric is stable across repeated runs

- [ ] **Step 6: Commit timing/reporting cleanup**

Run:
```bat
git add YH_rv_cpu/sw/coremark_port/core_portme.h YH_rv_cpu/tb/YH_rv_cpu_coremark_tb.v YH_rv_cpu/scripts/report_coremark_result.py
git commit -m "test: formalize coremark timing and report parsing"
```

### Task 4: Sync All Project Documentation To The New CoreMark Baseline

**Files:**
- Modify: `YH_rv_cpu/README.md`
- Modify: `YH_rv_cpu/doc/技术文档.md`
- Modify: `YH_rv_cpu/doc/regression_test_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- Modify: `06-汇报材料/项目进展汇报-2026-04-01.md`
- Modify: `06-汇报材料/汇报摘要.md`
- Modify: `YH_rv_cpu/doc/coremark_submission_report.md`

- [ ] **Step 1: Remove stale CoreMark claims**

Find and replace:
- old `IPC=...` wording
- old "200 iterations" claims without raw log evidence
- old "CRC mismatch is expected" lines if the current run validates cleanly

- [ ] **Step 2: Add the new reproducible reporting block**

Include:
- exact command
- exact raw log path
- exact summary path
- current measured `CoreMark/MHz`
- caveat about strict EEMBC 10-second compliance if still not met

- [ ] **Step 3: Update regression log with dated entry**

Record:
- toolchain version
- Vivado version
- CoreMark command
- pass/fail
- raw metrics
- whether the result is validation-clean

- [ ] **Step 4: Verify docs no longer contradict each other**

Run:
```bat
rg -n "IPC=|CRC 不匹配|200 次迭代|coremark smoke test completed" d:\BaiduSyncdisk\icdc_workspace\YH_rv_cpu d:\BaiduSyncdisk\icdc_workspace\06-汇报材料
```
Expected:
- only current, intentional wording remains

- [ ] **Step 5: Commit the documentation sync**

Run:
```bat
git add YH_rv_cpu/README.md YH_rv_cpu/doc/技术文档.md YH_rv_cpu/doc/regression_test_log.md YH_rv_cpu/doc/YH_rv_cpu_change_log.md 06-汇报材料/项目进展汇报-2026-04-01.md 06-汇报材料/汇报摘要.md YH_rv_cpu/doc/coremark_submission_report.md
git commit -m "docs: align coremark submission baseline"
```

---

## Phase B: Regression And FPGA Closure

### Task 5: Freeze Formal `riscv-tests` Baseline Manifests

**Files:**
- Modify: `YH_rv_cpu/scripts/run_riscv_tests_subset.bat`
- Create: `YH_rv_cpu/scripts/riscv_tests_rv32_baseline.txt`
- Create: `YH_rv_cpu/scripts/riscv_tests_rv64_baseline.txt`

- [ ] **Step 1: Extract current in-script subsets into manifest files**

Move:
- current `rv32` list into `riscv_tests_rv32_baseline.txt`
- current `rv64` list into `riscv_tests_rv64_baseline.txt`

- [ ] **Step 2: Update the runner to consume manifests by default**

Behavior:
- no positional override means "run the formal baseline manifest"
- optional override still works for local debugging

- [ ] **Step 3: Run the frozen baselines**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv32
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv64
```
Expected:
- both commands produce `summary.txt`
- pass counts are explicit and reproducible

- [ ] **Step 4: Commit the baseline manifests**

Run:
```bat
git add YH_rv_cpu/scripts/run_riscv_tests_subset.bat YH_rv_cpu/scripts/riscv_tests_rv32_baseline.txt YH_rv_cpu/scripts/riscv_tests_rv64_baseline.txt
git commit -m "test: freeze riscv-tests baseline manifests"
```

### Task 6: Strengthen Regression Reporting And TB Diagnostics

**Files:**
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv32_tb.v`
- Modify: `YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv64_tb.v`
- Modify: `YH_rv_cpu/doc/regression_test_log.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`

- [ ] **Step 1: Audit current pass/fail visibility**

Check:
- timeout banner quality
- test name visibility
- whether `tohost`/PC/cycle info is logged on failure

- [ ] **Step 2: Add bounded diagnostic improvements**

Keep:
- clear failing test name
- failing PC
- cycle count
- optional debug plusargs

Avoid:
- giant always-on traces
- per-test custom hacks

- [ ] **Step 3: Re-run `rv32` and `rv64` baselines**

Run:
```bat
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv32
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv64
```
Expected:
- summaries stay green
- failure messages are improved if anything regresses later

- [ ] **Step 4: Commit the regression reporting polish**

Run:
```bat
git add YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_tb.v YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv32_tb.v YH_rv_cpu/tb/YH_rv_cpu_riscv_tests_rv64_tb.v YH_rv_cpu/doc/regression_test_log.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md
git commit -m "test: improve riscv-tests regression reporting"
```

### Task 7: Freeze The Pre-Board FPGA Flow

**Files:**
- Modify: `YH_rv_cpu/scripts/build_vivado_project.bat`
- Modify: `YH_rv_cpu/scripts/open_vivado_project.bat`
- Modify: `YH_rv_cpu/fpga/vivado/scripts/build_nexys_a7_100_project.tcl`
- Modify: `YH_rv_cpu/fpga/vivado/README.md`
- Create: `YH_rv_cpu/doc/fpga_bringup_checklist.md`

- [ ] **Step 1: Verify current `project/synth/impl` modes from a clean workspace**

Run:
```bat
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat project
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat synth50
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat impl50
```
Expected:
- project opens cleanly
- reports land in predictable locations
- `50MHz` timing is non-negative

- [ ] **Step 2: Decide whether a `bitstream` mode is missing**

If missing:
- add a dedicated `bit` or `bit50` mode
- keep it disabled in docs until the board and final XDC are ready

- [ ] **Step 3: Create the bring-up checklist**

Checklist must include:
- required board
- Vivado version
- bitstream path
- UART terminal settings
- reset behavior
- expected LED/UART output
- evidence capture requirements for submission

- [ ] **Step 4: Commit the pre-board closure flow**

Run:
```bat
git add YH_rv_cpu/scripts/build_vivado_project.bat YH_rv_cpu/scripts/open_vivado_project.bat YH_rv_cpu/fpga/vivado/scripts/build_nexys_a7_100_project.tcl YH_rv_cpu/fpga/vivado/README.md YH_rv_cpu/doc/fpga_bringup_checklist.md
git commit -m "build: freeze pre-board fpga closure flow"
```

### Task 8: Prepare The Board-Arrival Execution Pack

**Files:**
- Modify: `YH_rv_cpu/fpga/vivado/constraints/nexys_a7_100_template.xdc`
- Modify: `YH_rv_cpu/doc/fpga_bringup_checklist.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- Modify: `06-汇报材料/汇报摘要.md`

- [ ] **Step 1: Mark current board-blocked items explicitly**

Tag as blocked:
- final XDC pin freeze
- real UART capture
- board photos/video
- final bitstream evidence

- [ ] **Step 2: Write the exact evidence package needed once the board arrives**

Require:
- board photo
- UART terminal screenshot
- bitstream build log
- 50MHz timing report
- short demo script

- [ ] **Step 3: Commit the board-arrival pack**

Run:
```bat
git add YH_rv_cpu/fpga/vivado/constraints/nexys_a7_100_template.xdc YH_rv_cpu/doc/fpga_bringup_checklist.md YH_rv_cpu/doc/YH_rv_cpu_todo.md 06-汇报材料/汇报摘要.md
git commit -m "docs: prepare board-arrival execution pack"
```

---

## Phase C: Performance Optimization After Closure

### Task 9: Build The Optimization Baseline Table

**Files:**
- Create: `YH_rv_cpu/doc/performance_experiment_log.md`
- Modify: `YH_rv_cpu/doc/技术文档.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`

- [ ] **Step 1: Freeze the pre-optimization baseline metrics**

Table must contain:
- CoreMark command and score
- `rv32` regression status
- `rv64` regression status
- `synth50` timing/resources
- `impl50` timing/resources

- [ ] **Step 2: Define comparison rules**

Every optimization candidate must report:
- expected gain
- touched RTL files
- regression commands
- timing/resource comparison
- rollback condition

- [ ] **Step 3: Commit the baseline table**

Run:
```bat
git add YH_rv_cpu/doc/performance_experiment_log.md YH_rv_cpu/doc/技术文档.md YH_rv_cpu/doc/YH_rv_cpu_handoff.md
git commit -m "docs: freeze pre-optimization performance baseline"
```

### Task 10: Run Low-Risk Optimization Wave

**Files:**
- Likely modify: `YH_rv_cpu/rtl/YH_rv_sync_imem_rom.v`
- Likely modify: `YH_rv_cpu/rtl/YH_rv_dmem_ram.v`
- Likely modify: `YH_rv_cpu/rtl/YH_rv_cpu.v`
- Likely modify: `YH_rv_cpu/rtl/YH_rv_cpu_mem_stage.v`
- Likely modify: `YH_rv_cpu/rtl/YH_rv_cpu_hazard_unit.v`

- [ ] **Step 1: Rank low-risk candidates**

Recommended first-wave candidates:
- `imem/ROM` BRAM inference and output register cleanup
- `dmem` optional output register evaluation
- load-use stall tightening
- branch redirect penalty cleanup without ISA expansion

- [ ] **Step 2: Choose exactly one candidate**

Rule:
- do not batch multiple optimizations
- do not mix memory-path and branch-path changes in one attempt

- [ ] **Step 3: Add a before/after benchmark checklist**

Run before and after each candidate:
```bat
cmd /c YH_rv_cpu\scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv32
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv64
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat synth50
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat impl50
```

- [ ] **Step 4: Accept or reject the candidate using hard gates**

Accept only if:
- CoreMark improves or timing/resources improve materially
- no regression suite breaks
- docs are updated with fresh evidence

- [ ] **Step 5: Commit each accepted optimization separately**

Run:
```bat
git add <touched files>
git commit -m "perf: <short optimization name>"
```

### Task 11: Open The High-Impact Optimization Lane Only If Rules Permit

**Files:**
- Modify: `01-项目管理/01-赛题要求/七星微赛方答疑整理.md`
- Modify: `YH_rv_cpu/doc/performance_experiment_log.md`
- Potentially modify many RTL files if approved later

- [ ] **Step 1: Re-check the rule status for `M` extension**

Document:
- source of clarification
- date of clarification
- whether competition baseline may move beyond pure `RV32I`

- [ ] **Step 2: If not clarified, keep this lane blocked**

Record explicitly:
- no multiplier/divider implementation work yet
- current optimization plan remains within allowed baseline assumptions

- [ ] **Step 3: If clarified as allowed, write a separate dedicated plan before implementation**

That future plan must cover:
- ISA scope
- verification expansion
- CoreMark delta expectation
- timing/resource risk

---

## Final Verification Bundle Before Claiming The Plan Is Executed

Run:
```bat
cmd /c YH_rv_cpu\scripts\check_syntax.bat
cmd /c YH_rv_cpu\scripts\run_coremark_smoke.bat rv32
cmd /c YH_rv_cpu\scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv32
cmd /c YH_rv_cpu\scripts\run_riscv_tests_subset.bat rv64
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat synth50
cmd /c YH_rv_cpu\scripts\build_vivado_project.bat impl50
```

Expected:
- all commands exit `0`
- CoreMark raw log and summary match
- regression summaries are fresh
- `50MHz` timing remains non-negative
- all updated docs point at the same commands and numbers

## Deliverables Checklist

- [ ] `run_coremark_score.bat`
- [ ] `report_coremark_result.py`
- [ ] `coremark_submission_report.md`
- [ ] synced README / tech doc / regression log / report deck wording
- [ ] frozen `rv32` / `rv64` baseline manifests
- [ ] stronger regression summaries
- [ ] frozen pre-board FPGA flow
- [ ] board-arrival checklist
- [ ] pre-optimization baseline table
- [ ] ranked optimization backlog
