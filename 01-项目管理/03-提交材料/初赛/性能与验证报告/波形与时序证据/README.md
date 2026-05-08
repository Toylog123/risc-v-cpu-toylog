# 波形与时序证据说明

本目录保存初赛验证报告可引用的关键波形底稿与对应 VCD 文件。

波形图中，总线信号使用浅色保持区、竖线和值标签表示稳定区间；标量信号的水平线表示该信号在对应时间窗口内保持低电平或高电平，不是额外插入的参考线。

## 文件说明

- `01-id-branch-fast-waveform.png`  
  展示 ID 阶段分支快速重定向诊断。可观察到 `Fetch Redirect` 触发而 `EX Redirect` 保持为低，说明该用例中的分支在前端被提前处理。

- `02-id-jal-fast-waveform.png`  
  展示 JAL 快速重定向诊断。可观察到前端 `Fetch Redirect` 拉高且 `EX Redirect` 保持为低，说明 `jal x0` 跳转未回落到 EX 阶段再重定向。

- `03-load-use-fast-waveform.png`  
  展示 load-use 快速路径诊断。可观察到 `DMEM Read Req` 与 `DMEM Rvalid` 的握手关系，以及 `Stall Decode` 未被拉高，说明当前快路径下未引入额外译码停顿。

## 原始波形

`vcd/` 子目录保存可复查的原始波形：

- `vcd/01-id-branch-fast.vcd`
- `vcd/02-id-jal-fast.vcd`
- `vcd/03-load-use-fast.vcd`

## 生成方式

1. 运行定向诊断脚本并附加 `dump_vcd` 参数：
   - `scripts/run_id_branch_fast_diag.bat debug_trace dump_vcd`
   - `scripts/run_id_jal_fast_diag.bat debug_trace dump_vcd`
   - `scripts/run_load_use_fast_diag.bat debug_trace dump_vcd`
2. 使用 `scripts/render_vcd_waveform_png.py` 从 VCD 生成 PNG 波形图。
