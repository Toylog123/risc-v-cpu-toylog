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
