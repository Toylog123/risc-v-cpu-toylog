# toylog_cpu 修改记录

## 记录规则

- 每次有实际修改就追加，不覆盖旧记录。
- 每条记录至少包含：日期、范围、目的、结果、验证。
- 如果还有没验证的部分，要明确写出来。

## 2026-03-16

### 变更 1：建立 `toylog_cpu` 正式工程

- 范围：
  - 建立 `toylog_cpu` 目录
  - 补齐基础 RTL、脚本、软件侧骨架和设计文档
- 目的：
  - 把正式参赛工程从参考实现中独立出来
- 结果：
  - 形成自写 `RV32I` 工程基线
- 验证：
  - `scripts/check_syntax.bat` 通过

### 变更 2：推进到五级流水第一版

- 范围：
  - `rtl/toylog_cpu.v`
  - `rtl/toylog_cpu_if_stage.v`
  - `rtl/toylog_cpu_id_stage.v`
  - `rtl/toylog_cpu_ex_stage.v`
  - `rtl/toylog_cpu_mem_stage.v`
  - `rtl/toylog_cpu_wb_stage.v`
  - `rtl/toylog_cpu_hazard_unit.v`
- 目的：
  - 形成符合赛题方向的五级流水骨架
- 结果：
  - 完成基础暂停、前递和跳转冲刷
- 验证：
  - `scripts/check_syntax.bat` 通过

### 变更 3：建立交接、记录和任务清单机制

- 范围：
  - `doc/toylog_cpu_handoff.md`
  - `doc/toylog_cpu_change_log.md`
  - `doc/toylog_cpu_todo.md`
  - 相关同步脚本
- 目的：
  - 保证换设备、换人、换智能体时能快速恢复上下文
- 结果：
  - 形成固定交接入口
- 验证：
  - 交接文件已经纳入默认同步范围

### 变更 4：补齐最小 SoC 与烟测链路

- 范围：
  - `rtl/toylog_cpu_soc.v`
  - `tb/toylog_cpu_soc_tb.v`
  - `scripts/build_firmware.bat`
  - `scripts/run_soc_smoke.bat`
  - `scripts/iverilog_sources.f`
  - `scripts/check_syntax.ps1`
- 目的：
  - 把 CPU 骨架推进到能跑最小程序的系统级闭环
- 结果：
  - 新增 `ROM / RAM / UART / DONE / timer`
  - 固件现在会额外生成 `.hex`
  - 建立基于 `xsim` 的 SoC 烟测流程
- 验证：
  - `scripts/build_firmware.bat` 通过
  - `scripts/run_soc_smoke.bat` 通过

### 变更 5：修复跳转重定向与首次字符串读取错误

- 范围：
  - `rtl/toylog_cpu.v`
  - `rtl/toylog_cpu_regfile.v`
  - `rtl/toylog_cpu_soc.v`
- 目的：
  - 修复 SoC 烟测中卡在 `JAL` 后和首字节 UART 异常的问题
- 结果：
  - `redirect` 和 `exception` 改为只在 `id_ex_valid` 有效时生效
  - 寄存器堆增加写回旁路
  - `timer_ctrl` 写入逻辑改写，去掉 `xsim` 的语法警告
- 验证：
  - `xsim` 输出 `toylog_cpu boot`
  - `PASS: SoC smoke test completed at PC=00000038 in 108 cycles`

### 变更 6：补齐最小机器态 CSR 与同步 trap

- 范围：
  - `rtl/toylog_cpu_defs.vh`
  - `rtl/toylog_cpu_decoder.v`
  - `rtl/toylog_cpu_id_stage.v`
  - `rtl/toylog_cpu.v`
  - `scripts/build_firmware.bat`
  - `scripts/run_trap_smoke.bat`
  - `sw/src/trap_entry.S`
  - `sw/src/trap_smoke.c`
  - `tb/toylog_cpu_trap_tb.v`
- 目的：
  - 让 CPU 具备最小可用的 CSR 访问和同步 trap 返回能力
- 结果：
  - 支持 `mstatus / mtvec / mscratch / mepc / mcause`
  - 支持 `csrrw/csrrs/csrrc` 及其立即数形式
  - 支持 `ecall / ebreak / mret`
  - 新增 trap 烟测固件和 `xsim` 仿真脚本
- 验证：
  - `scripts/run_trap_smoke.bat` 通过
  - `PASS: trap smoke test completed at PC=000000ac in 79 cycles`

### 变更 7：接入 machine timer interrupt 并补齐中断烟测

- 范围：
  - `rtl/toylog_cpu.v`
  - `rtl/toylog_cpu_soc.v`
  - `rtl/toylog_cpu_defs.vh`
  - `tb/toylog_cpu_timer_irq_tb.v`
  - `tb/toylog_cpu_tb.v`
  - `scripts/build_firmware.bat`
  - `scripts/run_timer_irq_smoke.bat`
  - `sw/src/timer_irq_entry.S`
  - `sw/src/timer_irq_smoke.c`
- 目的：
  - 让 CPU 具备最小可用的 machine timer interrupt 路径
- 结果：
  - 增加 `mie / mip / MTIE / MTIP`
  - CPU 接入 `timer_irq` 输入
  - 新增 timer interrupt 固件、handler、testbench 和 `xsim` 烟测
- 验证：
  - `scripts/run_timer_irq_smoke.bat` 通过
  - `PASS: timer irq smoke test completed at PC=000000e4 in 125 cycles`
