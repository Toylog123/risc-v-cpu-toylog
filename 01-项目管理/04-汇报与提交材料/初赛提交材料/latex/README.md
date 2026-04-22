# 初赛设计说明书 LaTeX 目录

本目录用于维护 `YH_rv_cpu` 初赛提交版设计说明书的 LaTeX 源文件。
当前正在维护的正式稿版本为 `v1.1`，日期为 `2026-04-17`。

## 目录结构

- `main.tex`：主入口，负责封面、目录、公共宏和章节装配
- `sections/`：分章节正文
- `figures/`：技术图目录，包含四张正式技术图的 LaTeX 包装文件与对应 AI 出图提示词

## 推荐编译方式

在当前目录执行：

```bat
xelatex -interaction=nonstopmode -halt-on-error main.tex
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

如果本机安装了 `latexmk`，也可以执行：

```bat
latexmk -xelatex -interaction=nonstopmode -halt-on-error main.tex
```

## 维护规则

1. 说明书中的冻结结果必须和 `YH_rv_cpu/README.md`、`技术文档.md`、`coremark_submission_report.md` 一致。
2. 当前 PDF 默认面向赛事评审，正文不要加入“材料组织方式”“内部支撑材料说明”等内部口径。
3. 任何新增图片优先放在 `figures/`；若引入外部截图或矢量图，应保持与现有技术图风格一致。
4. 如果新的优化实验没有形成保留结果，不要改写说明书中的冻结基线，只在过程记录和实验日志里更新。
5. 当前四张图默认由 `figures/prompts/` 中的提示词重新生成同名 PNG 后再编译；若替换图片，文件名应保持不变。
