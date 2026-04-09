# Preliminary Design Report Judge-Oriented Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the preliminary LaTeX report into a judge-facing formal design report with clean tables, formal technical figures, and no internal-facing content.

**Architecture:** Keep the current modular LaTeX chapter layout, but rewrite the content around a judge-oriented narrative. Replace overflow-prone tables with resilient layouts, remove internal project-management sections from正文, and add inline technical figures that compile with XeLaTeX.

**Tech Stack:** LaTeX (`ctexart`, `booktabs`, `longtable`, `tikz`, `tabularx`), PowerShell, XeLaTeX, Poppler page rendering for visual review.

---

### Task 1: Freeze Scope And Review Current Report

**Files:**
- Modify: `docs/superpowers/specs/2026-04-09-preliminary-design-report-judge-oriented-redesign.md`
- Modify: `docs/superpowers/plans/2026-04-09-preliminary-design-report-judge-oriented-redesign.md`
- Read: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/main.tex`
- Read: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/*.tex`

- [ ] Confirm the accepted narrative: A as mainline, B/C as support.
- [ ] Record the chapters to keep, rewrite, or remove.
- [ ] Record the known layout defects from rendered PNG inspection.

### Task 2: Rebuild Shared LaTeX Styling

**Files:**
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/main.tex`

- [ ] Add only the packages needed for resilient tables and technical diagrams.
- [ ] Add helper macros/environments for judge-facing technical tables.
- [ ] Remove any wording in metadata that still frames the report as an internal package.

### Task 3: Rewrite Judge-Facing Chapters

**Files:**
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/00-cover-and-abstract.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/01-project-scope.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/02-architecture.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/03-verification.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/04-fpga-and-delivery.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/05-risks-and-plan.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/appendix-evidence.tex`

- [ ] Remove internal project-management framing from正文.
- [ ] Reorder content so评审先读到目标、再读架构、再读证据。
- [ ] Replace path-heavy正文 tables with summary-style technical tables.
- [ ] Keep only a compact附录 for evidence anchors.

### Task 4: Add Formal Technical Figures

**Files:**
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/main.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/02-architecture.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/03-verification.tex`
- Modify: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/sections/04-fpga-and-delivery.tex`

- [ ] Replace architecture placeholder with a formal system architecture figure.
- [ ] Replace pipeline placeholder with a five-stage/pipeline-control figure.
- [ ] Replace verification placeholder with a validation-closure figure.

### Task 5: Compile And Visually Verify

**Files:**
- Output: `01-项目管理/04-汇报与提交材料/初赛提交材料/latex/main.pdf`
- Output: `01-项目管理/04-汇报与提交材料/初赛提交材料/YH_rv_cpu初赛设计说明书.pdf`

- [ ] Run `xelatex -interaction=nonstopmode -halt-on-error main.tex` until stable.
- [ ] Render the PDF into PNGs and inspect defect pages.
- [ ] Fix any remaining overflow, overlap, or awkward page breaks.

### Task 6: Sync Companion Docs And Prepare Commit

**Files:**
- Modify: `01-项目管理/04-汇报与提交材料/README.md`
- Modify: `01-项目管理/04-汇报与提交材料/内部支撑材料/2026-04-09-材料更新说明.md`
- Modify: `01-项目管理/02-执行管理/04-工作记录/2026-04-09-工作记录补充.md`
- Modify: `01-项目管理/02-执行管理/05-工作交接/2026-04-09-工作交接补充.md`

- [ ] Record that the preliminary report has been converted to a judge-facing formal version.
- [ ] Note what changed in structure, figures, and evidence presentation.
- [ ] Keep the update scoped to this report-redesign task only.
