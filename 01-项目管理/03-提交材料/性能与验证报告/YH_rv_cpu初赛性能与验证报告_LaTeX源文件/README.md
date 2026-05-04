# 初赛性能与验证报告 LaTeX 源文件

本目录维护独立的验证报告，专门对应初赛附件 1 中“验证报告”的六项要求。

## 生成方式

在当前目录执行：

```powershell
xelatex -interaction=nonstopmode -halt-on-error main.tex
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

生成后将 `main.pdf` 覆盖到上一级目录的 `YH_rv_cpu初赛性能与验证报告-2026-04-30.pdf`。

## 当前报告必须包含

1. 仿真与 FPGA 测试数据
2. 指令覆盖率
3. 分支预测准确率
4. DMIPS/MHz
5. 资源占用率
6. 优化前后的性能差异对比

当前正式指标为 `4.137461 CoreMark/MHz`、`2.908287 DMIPS/MHz`、`4934 LUT`，所有数据以脚本日志、仿真输出和 Vivado 报告为准。
