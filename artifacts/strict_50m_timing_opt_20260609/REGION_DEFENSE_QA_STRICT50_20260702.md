# 分赛区 strict50 答辩 QA 口径 2026-07-02

本文件只适用于 `freeze-strict50-impl220-20260701` strict50 候选。不要与旧初赛
`4961 LUT / 4.137461 / board-proven` QA 口径混用。

## 高频速答

### 1. 当前版本一句话介绍是什么？

我们当前冻结的是一版面向 PYNQ-Z2 的 strict 50 MHz RISC-V CPU 工程候选。
它在 post-route implementation 下达到 9965 LUT、4.287521 CoreMark/MHz、
WNS +0.056 ns、WHS +0.121 ns，Dhrystone xsim 为 2.495618 DMIPS/MHz；
当前证据等级是 implementation timing-closed + xsim benchmark evidence，
板级 PROGRAM_OK、UART 和视频还在补证阶段。

### 2. 这版是否满足赛题 50 MHz 要求？

从 Vivado post-route timing report 看，满足 50 MHz implementation timing：
WNS +0.056 ns，WHS +0.121 ns，报告写明 all user specified timing constraints
are met。上板证明还没有完成，所以不能说 board-proven。

### 3. 为什么不报告更高的 CoreMark/MHz？

更高 fast score 不能自动成为候选。比如 `fast201` 为 4.569338 CoreMark/MHz，
但对应 `synth224` 在 50 MHz synthesis 下 WNS -11.786 ns，远未时序闭合。
我们只报告 post-route timing-closed 的 `impl220`。

### 4. CoreMark 有没有改源码？

没有修改 CoreMark 核心算法文件。优化集中在 RTL 参数、前端控制路径、
BHT/redirect-cache/DCache-load-use 取舍和 Vivado 实现策略。

### 5. DMIPS/MHz 现在怎么报告？

当前 `impl220` 同配置 Dhrystone xsim 已补齐，正式 `timer50` evidence 报告
2.495618 DMIPS/MHz、219240 Dhrystones/s、runs 1000。这个结果可以作为
simulation evidence 报告，但不能写成 PYNQ-Z2 board UART evidence。

### 6. 现在能不能上板演示？

当前已经有 post-route timing-closed 实现证据，但还没有 bitstream/PROGRAM_OK/UART/视频
证据闭环。下一步是生成或确认 `impl220` bitstream，并按
`STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md` 补齐证据。

### 7. 这版主要技术亮点是什么？

主要亮点是严格 sync-BRAM 口径下的时序收敛：通过参数化控制前端重定向、
BHT ID-update、DCache/load-use/fold 路径和实现策略，在保留 4.287521
CoreMark/MHz 的同时闭合 50 MHz。这里强调的是可复现、可审计，而不是使用
timing-failed 高分探索行。

### 8. 如果评委问“为什么 LUT 比旧版多”？

当前目标优先级是严格 50 MHz、CoreMark 高于门槛、结果可复现。旧低 LUT 或高分记录
中有些没有闭合 50 MHz exact-ROM 时序，不能作为当前候选。`impl220` 选择的是
时序闭合且性能达标的一版，LUT 为 9965。

### 9. 分支预测准确率怎么说？

当前不要包装成复杂动态预测器准确率。可以说设计包含参数化 BHT、redirect-cache、
fold/next-cache 等前端控制结构；当前 candidate 的重点是把这些路径做成可控配置，
在 strict 50 MHz 下取舍性能和时序。

### 10. 当前最大风险是什么？

第一是 board evidence 未完成，不能说上板验证通过；第二是当前 DMIPS 仍是 xsim
证据，不是板级 UART 证据；第三是 CoreMark 是工程 short-gate，不是官方 10 秒 EEMBC 合规口径。

## 防守边界

| 追问 | 回答原则 |
|---|---|
| “是不是已经板上跑通？” | 不能这么说。只能说 implementation timing-closed，board evidence pending。 |
| “为什么不用 5.16 或 4.56 的高分？” | 对应路径未闭合 strict 50 MHz timing，不能作为候选。 |
| “DMIPS 是多少？” | 同配置 xsim 为 2.495618 DMIPS/MHz；板级 DMIPS 需另补 UART raw log。 |
| “CoreMark 是否官方认证？” | 不是官方 EEMBC 10 秒认证，是工程 short-gate，CRC 通过。 |
| “能否现场复现？” | 可复现 implementation evidence；现场上板需先生成/确认 bitstream 和连接 UART。 |
