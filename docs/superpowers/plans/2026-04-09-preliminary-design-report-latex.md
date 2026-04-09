# Preliminary Design Report LaTeX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a competition-ready Chinese LaTeX preliminary design report for `YH_rv_cpu`, with real project data, modular section files, and a structure that is easy to extend with figures and appendices.

**Architecture:** The report will live under the competition materials directory and use a `ctexart` modular layout with `main.tex`, split `sections/`, and a `figures/` directory. Content will be sourced from the frozen baseline, fresh validation evidence, FPGA pre-board status, and official Q&A summary so the document can serve as the prelim submission main artifact.

**Tech Stack:** LaTeX (`ctexart`, `geometry`, `graphicx`, `booktabs`, `longtable`, `hyperref`), existing Markdown source documents, Windows PowerShell, Git.

---

### Task 1: Lock report scope and source mapping

**Files:**
- Create: `docs/superpowers/plans/2026-04-09-preliminary-design-report-latex.md`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/2026-04-09-材料更新说明.md`
- Test: source review through repository documents

- [ ] **Step 1: Read the authoritative project sources**

Review:
- `YH_rv_cpu/README.md`
- `YH_rv_cpu/doc/技术文档.md`
- `YH_rv_cpu/doc/coremark_submission_report.md`
- `YH_rv_cpu/doc/regression_test_log.md`
- `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- `YH_rv_cpu/doc/fpga_bringup_checklist.md`
- `01-项目管理/01-赛题要求/七星微赛题答疑整理.md`

- [ ] **Step 2: Map report chapters to source evidence**

Chapter mapping:
- project positioning / prelim scope -> `README.md`, Q&A summary
- architecture / pipeline / SoC -> `技术文档.md`
- validation / performance -> `coremark_submission_report.md`, `regression_test_log.md`
- FPGA pre-board / blockers -> `fpga_bringup_checklist.md`
- handoff / next steps -> `YH_rv_cpu_handoff.md`

- [ ] **Step 3: Update material-tracking note**

Record that the preliminary submission now has a LaTeX main document path and modular structure.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-04-09-preliminary-design-report-latex.md 01-项目管理/05-汇报与提交材料/初赛提交材料/2026-04-09-材料更新说明.md
git commit -m "docs: plan latex preliminary design report"
```

### Task 2: Create the LaTeX report scaffold

**Files:**
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/README.md`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/main.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/00-cover-and-abstract.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/01-project-scope.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/02-architecture.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/03-verification.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/04-fpga-and-delivery.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/05-risks-and-plan.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/appendix-evidence.tex`
- Create: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/figures/README.md`
- Test: `xelatex -interaction=nonstopmode -halt-on-error main.tex`

- [ ] **Step 1: Create the modular ctexart entry**

`main.tex` must include:
- Chinese title page
- table of contents
- consistent packages for tables and hyperlinks
- helper commands for image placeholders
- `\input{sections/...}` layout

- [ ] **Step 2: Create figure-friendly directory structure**

Add `figures/README.md` describing recommended filenames and where to insert architecture/block-diagram screenshots later.

- [ ] **Step 3: Add a local README**

Document compile command, expected TeX engine, and the purpose of each section file.

- [ ] **Step 4: Run compile check**

Run:

```bash
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

Expected:
- PDF generated without fatal errors
- all section files resolve correctly

- [ ] **Step 5: Commit**

```bash
git add 01-项目管理/05-汇报与提交材料/初赛提交材料/latex
git commit -m "docs: scaffold latex preliminary design report"
```

### Task 3: Write the detailed report content

**Files:**
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/00-cover-and-abstract.tex`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/01-project-scope.tex`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/02-architecture.tex`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/03-verification.tex`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/04-fpga-and-delivery.tex`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/05-risks-and-plan.tex`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/sections/appendix-evidence.tex`
- Test: source review and `xelatex` compile

- [ ] **Step 1: Write the prelim-facing narrative**

Cover:
- project name
- competition positioning
- document version/date

Abstract:
- what the CPU is
- what is already complete
- what prelim submission includes

- [ ] **Step 2: Fill architecture and implementation sections**

Include:
- ISA scope and current boundaries
- five-stage pipeline organization
- hazard / forwarding / redirect / trap handling
- SoC memory map and peripherals
- FPGA prototype relationship

- [ ] **Step 3: Fill validation and evidence sections**

Use current true results:
- CoreMark short and strict
- RV32 / RV64 baseline
- RV32 / RV64 full-ui
- impl50 timing / utilization
- FPGA-like probe

- [ ] **Step 4: Fill blockers and future plan**

Clearly separate:
- prelim-ready deliverables
- enhanced evidence
- external blockers such as real board bring-up

- [ ] **Step 5: Run compile check**

Run:

```bash
xelatex -interaction=nonstopmode -halt-on-error main.tex
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

Expected:
- stable table of contents
- no undefined inputs
- final PDF updated

- [ ] **Step 6: Commit**

```bash
git add 01-项目管理/05-汇报与提交材料/初赛提交材料/latex
git commit -m "docs: write detailed latex preliminary design report"
```

### Task 4: Sync management and handoff records

**Files:**
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/README.md`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/初赛提交清单.md`
- Modify: `01-项目管理/05-汇报与提交材料/初赛提交材料/2026-04-09-材料更新说明.md`
- Modify: `01-项目管理/03-过程管理/2026-04-09-工作记录补充.md`
- Modify: `01-项目管理/03-过程管理/2026-04-09-工作交接补充.md`
- Test: manual diff review

- [ ] **Step 1: Add the LaTeX report path to the material index**

Mention the new main entry:
- `01-项目管理/05-汇报与提交材料/初赛提交材料/latex/main.tex`

- [ ] **Step 2: Update prelim checklist and handoff**

Mark the detailed design report as present and explain whether PDF compile was verified locally.

- [ ] **Step 3: Review diffs for consistency**

Run:

```bash
git diff -- 01-项目管理/05-汇报与提交材料/初赛提交材料 01-项目管理/03-过程管理
```

Expected:
- only submission-material and handoff wording changes

- [ ] **Step 4: Commit**

```bash
git add 01-项目管理/05-汇报与提交材料/初赛提交材料 01-项目管理/03-过程管理
git commit -m "docs: sync prelim material index with latex report"
```

### Task 5: Final verification and clean handoff

**Files:**
- Test: `git status --short`
- Test: `git diff --cached --check`
- Test: `xelatex -interaction=nonstopmode -halt-on-error main.tex`

- [ ] **Step 1: Re-run the final LaTeX compile**

From the LaTeX directory:

```bash
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

Expected:
- successful PDF output

- [ ] **Step 2: Check staged content quality**

Run:

```bash
git diff --cached --check
git status --short
```

Expected:
- no whitespace errors in staged changes
- no accidental build trash staged

- [ ] **Step 3: Record compile status in handoff**

If `xelatex` is unavailable, note that source was generated and compile remains to be run on a TeX-equipped machine. If available, record the successful local compile.
