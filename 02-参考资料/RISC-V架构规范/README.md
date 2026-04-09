# RISC-V 架构规范

本目录用于整理本项目参考的 RISC-V 架构规范资料。

## 当前内容

- `riscv-isa-manual/`
  RISC-V 官方 ISA 手册的本地参考副本，用于查阅指令语义、CSR 定义、特权架构和扩展规范。

## 使用说明

1. 这类资料主要用于本地查阅和设计对照，不直接替代工程内技术文档。
2. 大体量官方参考仓库是否纳入版本控制，应单独评估并形成独立提交，不建议和主线文档改动混提。
3. 当需要核对 ISA 口径时，优先对照：
   - `modules/unpriv/pages/rv32.adoc`
   - `modules/unpriv/pages/rv64.adoc`
   - `modules/unpriv/pages/zicsr.adoc`
   - `modules/unpriv/pages/zifencei.adoc`
   - `modules/priv/pages/machine.adoc`
   - `modules/priv/pages/priv-csrs.adoc`

## 与项目的关系

当前 `YH_rv_cpu` 的主线冻结基线聚焦于 RV32/RV64 基本整数路径、CSR、异常与 CoreMark 相关验证。后续若继续扩展指令支持或重新审视 trap / fence 语义，可从本目录回查规范原文。
