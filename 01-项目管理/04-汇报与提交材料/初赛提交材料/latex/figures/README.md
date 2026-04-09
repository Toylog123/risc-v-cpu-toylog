# 图片目录说明

本目录用于存放初赛设计说明书中的正式技术图。

## 当前内容

- `system-architecture.tex`：系统总体架构示意图
- `pipeline-control.tex`：五级流水与关键控制通路示意图
- `validation-closure.tex`：验证闭环与正式结果关系图
- `fpga-preboard-flow.tex`：FPGA pre-board 实现与板级边界示意图

## 维护建议

1. 当前图均为 TikZ 源文件，可直接通过 `\input{figures/<name>.tex}` 引入正文。
2. 如果后续改为外部矢量图或截图，请保持线条、字体和配色风格与当前技术图一致。
3. 若新增图面向裁判阅读，应优先突出结构关系、验证路径和证据闭环，而不是内部目录信息。
