# 图 4 FPGA 原型适配路径图

## 最终提示词

```text
请生成一张用于正式初赛设计说明书的 FPGA 原型适配路径图，输出为高分辨率白底 PNG，建议分辨率 2200x1400，横向构图，扁平矢量风，学术技术文档风格，深灰细线边框，浅灰/浅橙/浅蓝/浅绿配色，布局严谨，留白充分，不要海报感，不要 3D，不要复杂背景纹理。

文本规则必须严格遵守：
1. 所有模块名称只能使用以下英文标签，不允许新增任何别的英文词：
RTL
Firmware
Scripts
Vivado impl50
Utilization
Timing
Bitstream
FPGA-like Probe
Pre-board Closure
Future Board Validation
2. 除模块名外，其余图中文字都必须使用以下中文短语，不允许新增任何别的中文句子：
实现输入
输入实现流程
综合与实现
资源结果
时序结果
原型输出
近原型路径观测
收敛原型结论
原型收口证据
依赖实体板与最终约束
3. 禁止出现任何未在以上清单中的漂浮文字、重复标签、乱码、拼写变体。
4. 不允许出现 CoreMark、Smoke、IF、ID、EX、MEM、WB 等与本图无关的词。

构图要求：
- 最左侧并列三个输入模块：RTL、Firmware、Scripts。
- 三个输入模块向中间汇聚到 Vivado impl50。
- 从 Vivado impl50 右侧分出三个结果模块：Utilization、Timing、Bitstream。
- 在右下方单独放置 FPGA-like Probe。
- 再将 Utilization、Timing、Bitstream、FPGA-like Probe 汇聚到一个较大的结果模块：Pre-board Closure。
- 从 Pre-board Closure 向右或向下引出一条虚线到 Future Board Validation，表示后续阶段。

连接关系要求：
- RTL、Firmware、Scripts 到 Vivado impl50 的箭头统一注解：输入实现流程。
- Vivado impl50 的主过程注解：综合与实现。
- 指向 Utilization 的箭头注解：资源结果。
- 指向 Timing 的箭头注解：时序结果。
- 指向 Bitstream 的箭头注解：原型输出。
- 指向 FPGA-like Probe 的箭头注解：近原型路径观测。
- 汇聚到 Pre-board Closure 的箭头注解：收敛原型结论。
- 通往 Future Board Validation 的虚线注解：依赖实体板与最终约束。

版面要求：
- 结构要清楚区分“实现输入”“实现输出”“原型收口”“后续板级验证”四层含义。
- 所有框体严格对齐，箭头尽量横平竖直。
- 图面必须克制、正式，适合直接放进硬件设计说明书。

请确保最终图中只出现允许的英文标签和允许的中文注解。
```

## 负面约束

```text
no photorealistic, no 3d render, no isometric, no futuristic HUD, no dark background, no circuit board texture, no neon glow, no glossy effect, no poster composition, no handwritten text, no gibberish text, no extra floating labels, no duplicated text, no watermark
```

## 推荐输出文件名

`04-fpga-prototype-flow-ai.png`
