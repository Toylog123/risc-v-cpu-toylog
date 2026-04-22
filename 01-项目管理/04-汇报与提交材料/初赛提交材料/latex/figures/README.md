# 图片目录说明

本目录用于存放初赛设计说明书中的正式技术图。
当前技术图采用“`.tex` 包装文件 + 外部 PNG 图面 + prompts 提示词”的维护方式。
现在同时保留 `draw.io` 源文件，优先以 `.drawio` 为主稿维护，再导出覆盖 PNG。

## 当前内容

- `system-architecture.tex`：系统总体架构与模块关系图
- `pipeline-control.tex`：五级流水与关键控制通路示意图
- `validation-closure.tex`：验证矩阵与证据闭环示意图
- `fpga-preboard-flow.tex`：FPGA 原型适配路径与板级边界示意图
- `prompts/`：AI 出图提示词包，可用于逐张生成替换版图片

## 维护建议

1. 当前图以 `*.tex` 包装文件引入正文，图面主体目前使用外部 PNG 成品图。
2. 如果后续替换为手绘矢量图、外部矢量图或截图，请保持线条、字体和配色风格与当前技术图一致。
3. 若新增图面向裁判阅读，应优先突出结构关系、验证路径和证据闭环，而不是内部目录信息。
4. 若使用 AI 重新生成图片，必须严格限制图中文字，只允许 prompt 中列出的标签，不要保留任何漂浮多余文字。
5. 建议输出高分辨率白底 PNG，并沿用现有文件名，避免修改正文引用路径。

## 当前 PNG 文件名

- `01-system-architecture-ai.png`
- `02-pipeline-control-ai.png`
- `03-validation-closure-ai.png`
- `04-fpga-prototype-flow-ai.png`

## 当前 draw.io 源文件

- `01-system-architecture.drawio`
- `02-pipeline-control.drawio`
- `03-validation-closure.drawio`
- `04-fpga-prototype-flow.drawio`

## 本机 draw.io 导出

- 当前本机已安装 `draw.io`，可执行文件路径为 `C:\Program Files\draw.io\draw.io.exe`
- 批量导出脚本：`export-drawio.ps1`
- 在本目录执行：
  `powershell -ExecutionPolicy Bypass -File .\export-drawio.ps1`
