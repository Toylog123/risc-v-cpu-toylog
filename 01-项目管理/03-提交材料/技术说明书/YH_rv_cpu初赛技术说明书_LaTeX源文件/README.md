# 初赛技术说明书 LaTeX 源文件

本目录只保留一套权威 LaTeX 源文件，正文统一维护在 `main.tex` 中。

## 生成方式

在当前目录执行：

```powershell
xelatex -interaction=nonstopmode -halt-on-error main.tex
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

生成后将 `main.pdf` 覆盖到上一级目录的 `YH_rv_cpu初赛技术说明书-2026-04-30.pdf`。

## 维护规则

1. 内容优先对齐初赛设计文档要求，而不是内部工作日志写法。
2. 英文正文使用 `Times New Roman`，中文正文使用常见宋体口径。
3. 当前正式板级口径为 PYNQ-Z2、`4.137461 CoreMark/MHz`、`2.908287 DMIPS/MHz`、`4934 LUT`。
4. 插图当前采用“结构说明 + 绘制提示词”的轻量形式，便于后续人工统一绘制。
5. 不维护 Word 版本，最终提交以 PDF 为准。
