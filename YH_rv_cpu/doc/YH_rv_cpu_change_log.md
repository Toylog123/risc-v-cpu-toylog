# YH_rv_cpu 修改记录

## 2026-03-16

### 变更 1：建立正式比赛工程

- 从参考实现中独立出正式比赛工程
- 固化工程内交接、记录和任务清单机制

### 变更 2：完成 `RV32I` 五级流水第一版

- 建立 `IF / ID / EX / MEM / WB`
- 打通基础前递、`load-use` 暂停和跳转重定向

### 变更 3：打通最小 SoC 闭环

- 新增 `ROM / RAM / UART / DONE / timer`
- 打通固件构建链路
- 完成 `xsim` SoC smoke

### 变更 4：补齐最小机器态 `CSR / trap`

- 接入最小机器态 CSR
- 支持 `ecall / ebreak / mret`
- 完成 `xsim` trap smoke

### 变更 5：补齐 machine timer interrupt

- 接入 `mie / mip / MTIE / MTIP`
- 新增 timer irq 烟测程序和测试平台
- 完成 `xsim` timer irq smoke

### 变更 6：正式工程统一改名为 `YH_rv_cpu`

- 根目录工程切换为 `YH_rv_cpu`
- 工具链目录切换为 `04-工具链/YH_rv_cpu_toolchain`
- 路径、脚本和文档入口统一切换

### 变更 7：抽出 `XLEN` 参数化骨架

- 给 CPU 顶层、SoC 顶层、关键流水级、ALU 和寄存器堆增加 `XLEN`
- 当前保持 `XLEN=32`，验证链路继续通过
- 为后续 `RV32 / RV64` 共线改造预留统一数据通路

### 变更 8：建立 `XLEN=64` 基础烟测

- 补上 `RV64` 下 6 位移位量的立即数译码基础支持
- 新增 `tb/YH_rv_cpu_xlen64_tb.v`
- 新增 `scripts/run_xlen64_smoke.bat`
- 实测通过：`PASS: xlen64 smoke test completed at PC=0000000000000010 in 13 cycles`

### 变更 9：打通 Vivado 本地综合链

- `build_vivado_project.bat` 现在会自动临时映射 ASCII 盘符，规避中文路径导致的 Vivado 退出问题
- `build_nexys_a7_100_project.tcl` 增加分步日志，能稳定导出检查点、资源报告和时序报告
- 本地综合会优先挂接 `build/tests/riscv-tests/rv32/simple.hex`，并用 `ROM/RAM = 8KB/8KB` 做资源估算
- 新增 `scripts/clean_vivado_project.bat`，用于清理 `project/` 下的 Vivado 中间产物
- 实测导出：
  - `project/reports/synth_utilization.rpt`
  - `project/reports/synth_timing_summary.rpt`
  - `project/YH_rv_cpu_nexys_a7_100_synth.dcp`

### 变更 10：补入第一版 FPGA 资源与时序结论

- `xc7a100tcsg324-1` 综合结果：
  - `Slice LUTs = 3445`
  - `Slice Registers = 1962`
  - `LUT as Memory = 1024`
  - `BRAM = 0`
  - `DSP = 0`
- 当前 100MHz 约束下 `WNS = -2.405ns`
- 当前模板 `XDC` 仍存在 `no_input_delay(1)` 和 `no_output_delay(4)`，正式板卡到位后要补齐

### 变更 11：新增整体设计总文档

- 新增 `doc/技术文档.md`
- 把 CPU、SoC、验证、FPGA、改动入口和后续维护规则收成一份长期维护的总文档
- 已同步接入 `README.md`、`YH_rv_cpu_handoff.md` 和根 `.codex-handoff.json`
