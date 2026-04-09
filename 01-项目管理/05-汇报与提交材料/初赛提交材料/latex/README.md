# 初赛设计说明书 LaTeX 目录

本目录用于维护 `YH_rv_cpu` 初赛提交版设计说明书的 LaTeX 源文件。

## 目录结构

- `main.tex`：主入口，负责封面、目录、公共宏和章节装配
- `sections/`：分章节正文
- `figures/`：插图目录，当前先保留命名建议与占位说明

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
2. 任何新增图片优先放在 `figures/`，再把对应章节中的占位图替换为 `\includegraphics`。
3. 如果新的优化实验没有形成保留结果，不要改写说明书中的冻结基线，只在过程记录和实验日志里更新。
