# Root Directory Reorganization Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the repository root and `01-项目管理/` tree into the approved structure, move current files into their new homes, and sync active documentation links to the new paths.

**Architecture:** Keep `YH_rv_cpu/` as the only formal engineering directory; fold project planning and process tracking into `01-项目管理/02-执行管理/`; shift `04-资料索引` and `05-汇报与提交材料` forward to `03` and `04`; make `初赛提交材料/` submission-only and move support docs into `内部支撑材料/`.

**Tech Stack:** PowerShell file moves, Markdown doc updates, Git rename tracking.

---

### Task 1: Create the target directory skeleton

**Files:**
- Create: `01-项目管理/02-执行管理/`
- Create: `01-项目管理/03-资料索引/`
- Create: `01-项目管理/04-汇报与提交材料/`
- Delete after migration: `01-项目管理/02-项目规划/`
- Delete after migration: `01-项目管理/03-过程管理/`
- Delete after migration: `01-项目管理/04-资料索引/`
- Delete after migration: `01-项目管理/05-汇报与提交材料/`
- Delete after migration: `06-汇报材料/`

- [ ] Create the new target directories explicitly.
- [ ] Ensure the target directories exist before moving any files.

### Task 2: Move files into the new structure

**Files:**
- Move planning and process files into `01-项目管理/02-执行管理/`
- Move index files into `01-项目管理/03-资料索引/`
- Move report material files into `01-项目管理/04-汇报与提交材料/`

- [ ] Move `项目总体规划.md` to `01-项目管理/02-执行管理/01-总体规划.md`.
- [ ] Move stage plan files into `01-项目管理/02-执行管理/02-阶段计划/`.
- [ ] Move task list into `01-项目管理/02-执行管理/03-任务清单.md`.
- [ ] Move work log files into `01-项目管理/02-执行管理/04-工作记录/`.
- [ ] Move handoff files into `01-项目管理/02-执行管理/05-工作交接/`.
- [ ] Move historical planning files into `01-项目管理/02-执行管理/99-历史归档/`.
- [ ] Move report files into `01-项目管理/04-汇报与提交材料/`.
- [ ] Move support docs from `初赛提交材料/` into `内部支撑材料/`.
- [ ] Delete the obsolete `06-汇报材料/` directory.

### Task 3: Sync active documentation

**Files:**
- Modify: `README.md`
- Modify: `01-项目管理/README.md`
- Modify: `01-项目管理/03-资料索引/README.md`
- Modify: `01-项目管理/04-汇报与提交材料/README.md`
- Modify: `YH_rv_cpu/README.md`
- Modify: `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- Modify: active report/support docs that mention old paths

- [ ] Update the root README to the new root tree.
- [ ] Update project-management readmes and index docs to the new numbering.
- [ ] Update active engineering docs that point to old `01-项目管理/05-*` paths.
- [ ] Update LaTeX source references that mention the old report-material path.

### Task 4: Verify and hand off

**Files:**
- Test: `git status --short`
- Test: `rg` path scan over active docs

- [ ] Scan for leftover active references to removed directory names.
- [ ] Confirm the final tree matches the approved layout.
- [ ] Leave unrelated profiling/RTL modifications untouched.
