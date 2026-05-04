# Documentation Layout

This directory now keeps only the minimal engineering-status documents for the
active `perf/coremark-over-1p5` worktree.

## Active files

- `CURRENT_STATUS.md`
  - trusted live snapshot
  - score tiers, hard constraints, active risk, next actions
- `YH_rv_cpu_handoff.md`
  - concise take-over guide for the next work session
- `YH_rv_cpu_todo.md`
  - active execution list only
- `performance_experiment_log.md`
  - retained and rejected performance directions that still matter
- `regression_test_log.md`
  - latest functional regression and FPGA closure evidence
- `README.md`
  - this index

## Ownership rules

- Preliminary-round submission materials are owned outside the worktree:
  `../../../../01-项目管理/03-提交材料/`
- The authoritative technical specification source is:
  `../../../../01-项目管理/03-提交材料/技术说明书/`
- The authoritative performance and verification report source is:
  `../../../../01-项目管理/03-提交材料/性能与验证报告/`
- Official template assets are owned by:
  `../../../../01-项目管理/03-提交材料/官方模板/`
- Do not keep duplicate LaTeX, Word, checklist, or packaging material here.
- If a historical conclusion is still important, fold it into one of the five
  files above and delete the old standalone note.

