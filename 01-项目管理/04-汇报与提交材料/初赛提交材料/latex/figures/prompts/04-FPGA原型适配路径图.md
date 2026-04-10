# 图 4 FPGA 原型适配路径图

## 最终提示词

```text
请生成一张正式技术说明书风格的 FPGA 原型适配流程图。
整体风格必须统一为：白底、扁平矢量、学术技术文档风格、深灰细线边框、浅灰浅橙浅红点缀、结构严谨、模块对齐、留白充分、无装饰背景、无炫技效果。

文本规则必须严格遵守：
1. 所有模块名字使用英文。
2. 所有流程说明、阶段含义、注解文字使用中文。
3. 不要生成长句，不要长段文字。
4. 不要生成乱码，不要手写体，不要花哨字体。

请绘制一个 FPGA 原型适配路径图。
主流程从左到右依次为：
RTL / Scripts -> Vivado impl50 -> Reports -> FPGA-like Probe

下方放两个阶段结果模块：
Prototype Adaptation
Future Board Validation

请用箭头关系和中文注解表达：
RTL 和脚本进入综合实现流程
Vivado impl50 产生资源、时序和 bitstream 相关输出
Reports 与 FPGA-like Probe 共同支撑原型适配结果
Future Board Validation 表示依赖实体板卡和 I/O 约束的后续工作

整体图必须像正式 FPGA 工程文档中的流程图，结构清晰、专业、克制。
不要海报化，不要科幻风，不要电路背景，不要立体效果。
```

## 负面约束

```text
no photorealistic, no 3d render, no isometric, no futuristic HUD, no neon glow, no dark background, no circuit board background, no excessive gradient, no poster style, no glossy effect, no icon clutter, no handwritten text, no gibberish text, no watermark, no shadow-heavy composition
```

## 推荐输出文件名

`fpga-prototype-flow-ai.png`
