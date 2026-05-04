# figures 目录说明

`figures/` 目录只放技术说明书正文直接引用的最终图片文件。

当前 LaTeX 文稿引用以下图片文件名：

- `01-system-architecture.png`：由 `PYNQ-Z2 FPGA Prototype.drawio` 导出，对应系统总体架构图。
- `02-pipeline-control.png`：由 `pipeline_hazard_control.drawio` 导出，对应五级流水与关键控制通路图。
- `03-validation-closure.png`：由 `verification_evidence_flow.drawio` 导出，对应验证闭环与证据流图。
- `04-fpga-bringup-flow.png`：由 `vivado_flow_validation.drawio` 导出，对应 FPGA 原型适配路径图。

如图片尚未放入本目录，PDF 中会显示占位框，便于后续替换。

`prompts/` 目录只保存图片提示词与结构说明，不在正文中直接展示。你后续生成或绘制完成后，只需将最终图片按上述文件名放回本目录即可。
