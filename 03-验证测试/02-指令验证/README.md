# 02-指令验证

本子目录用于整理指令功能验证相关资料与说明。

当前主线指令验证仍以 `YH_rv_cpu/scripts/`、`YH_rv_cpu/tb/` 和 `YH_rv_cpu/build/tests/` 下的真实流程与结果为准；如需在工作区维护 `riscv-tests/` 本地参考副本，应单独分类管理，不默认混入本次提交。

## 当前关注项

- `rv32 baseline`
- `rv64 baseline`
- `rv32 full-ui`
- `rv64 full-ui`
- misaligned trap 软件补偿相关验证口径

## 入口建议

- 回归记录：`YH_rv_cpu/doc/regression_test_log.md`
- 当前交接：`YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- 工程脚本入口：`YH_rv_cpu/scripts/`
