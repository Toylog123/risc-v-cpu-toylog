# YH_rv_cpu 交接说明

## 交接规则

- 只要修改了 `YH_rv_cpu` 的 RTL、脚本、验证或文档，就同步更新本文件、`YH_rv_cpu_change_log.md` 和 `YH_rv_cpu_todo.md`。
- 结论以当前仓库文件和脚本实测结果为准，不靠口头状态。
- 默认同步范围是 `YH_rv_cpu`、`04-工具链`、`01-项目管理`。

## 当前状态

- 日期：`2026-03-16`
- 正式工程名：`YH_rv_cpu`
- 当前验证基线：自写 `RV32I + Zicsr` 五级流水
- 当前目标架构：向 `RV32 / RV64` 共线推进
- 当前 SoC 状态：最小 SoC 已打通，可通过 UART 输出 `YH_rv_cpu boot`
- 当前 Vivado 状态：本地综合链已打通，资源/时序报告可导出到根目录 `project/reports/`
- 当前整体设计总入口：`doc/技术文档.md`

## 已完成能力

- 五级流水结构：`IF / ID / EX / MEM / WB`
- 关键数据通路 `XLEN` 参数化骨架
- 基础前递：`EX/MEM`、`MEM/WB`
- 基础 `load-use` 暂停
- 分支和跳转重定向
- 最小机器态 `CSR / trap`
  - `mstatus`
  - `mie`
  - `mip`
  - `mtvec`
  - `mscratch`
  - `mepc`
  - `mcause`
  - `csrrw/csrrs/csrrc`
  - `ecall / ebreak / mret`
- machine timer interrupt 最小闭环
- `XLEN=64` 基础烟测
- 最小 SoC
  - `ROM`
  - `RAM`
  - `UART`
  - `DONE`
  - `timer`

## 当前验证结果

- `scripts/check_syntax.bat`：通过
- `scripts/build_firmware.bat`：通过
- `scripts/run_soc_smoke.bat`：通过
- `scripts/run_trap_smoke.bat`：通过
- `scripts/run_timer_irq_smoke.bat`：通过
- `scripts/run_xlen64_smoke.bat`：通过
- `scripts/run_riscv_tests_subset.bat rv32 add`：通过
- `scripts/build_vivado_project.bat synth`：通过

关键结果：

- `PASS: SoC smoke test completed at PC=00000038 in 102 cycles`
- `PASS: trap smoke test completed at PC=000000ac in 79 cycles`
- `PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`
- `PASS: xlen64 smoke test completed at PC=0000000000000020 in 17 cycles`
- `PASS: riscv-tests finished at PC=0000059c in 495 cycles with tohost=1`
- Vivado 综合结果：`Slice LUTs = 3445`，`Slice Registers = 1962`，`LUT as Memory = 1024`
- Vivado 时序结果：`sys_clk = 100MHz` 时 `WNS = -2.405ns`

## 当前缺口

- `RV64` 指令级扩展和专门验证还没落地
- `riscv-tests` 还没扩大到更高覆盖率
- `CoreMark` 还没接稳
- 正式板卡约束还没建
- FPGA 上板记录还没有形成
- 100MHz 时序还没收敛，当前需要继续做时序优化

## 现在最值得继续做的事

1. 在 `XLEN` 骨架和 `xlen64` 烟测基础上继续补 `RV64` 译码、访存和相关语义。
2. 接 `riscv-tests`，形成第一版回归。
3. 接 `CoreMark`，形成可复现跑分链路。
4. 继续做时序收敛，并准备正式板卡 `XDC`。

## 关键文件

- CPU 顶层：`rtl/YH_rv_cpu.v`
- SoC 顶层：`rtl/YH_rv_cpu_soc.v`
- 总技术文档：`doc/技术文档.md`
- 初步设计：`doc/YH_rv_cpu_preliminary_design.md`
- 修改记录：`doc/YH_rv_cpu_change_log.md`
- 任务清单：`doc/YH_rv_cpu_todo.md`
- FPGA 说明：`fpga/vivado/README.md`

## 接手顺序

1. `../../01-项目管理/03-过程管理/工作交接.md`
2. `../../01-项目管理/03-过程管理/任务清单.md`
3. `../../README.md`
4. `README.md`
5. `doc/技术文档.md`
6. `doc/YH_rv_cpu_preliminary_design.md`
7. `doc/YH_rv_cpu_change_log.md`
8. `doc/YH_rv_cpu_todo.md`

## 2026-03-17 最新补充

- Vivado 综合现在按双档口径输出：
  - `100MHz`：`project/reports/clk_10p000ns`
  - `50MHz`：`project/reports/clk_20p000ns`
- 最新结果覆盖此前那版单一 100MHz 结论：
  - `100MHz`：`3450 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = -2.487ns`
  - `50MHz`：`3424 LUT / 1962 FF / 1024 LUTRAM / 0 BRAM / 0 DSP`，`WNS = 7.525ns`
- 当前最重要的判断：
  - 比赛要求的 `50MHz` 已经有综合余量
  - 后续 FPGA 主任务变成“继续收敛 100MHz + 推进 BRAM 化 + 等板卡到位后冻结正式 XDC”
- 这一天额外试过一轮“拆流水寄存器使能链”的 RTL 方向，但 100MHz 最差结果一度变到 `-3.139ns`，说明这条小修方向收益不够，已经回退，不在主线上保留
- 当前对 BRAM 的真实结论是：
  - 现在的 `ROM/RAM` 之所以还是 LUT / distributed RAM，不是单纯属性没写对
  - 根因是当前 SoC 还采用零等待、组合读出的存储接口
  - 后续要上 BRAM，先改 `imem/dmem` 的同步返回语义，再改底层存储实现
