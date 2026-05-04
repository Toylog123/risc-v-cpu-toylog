# CICC1003618+初赛+源代码

本目录用于后续打包生成初赛“技术数据（代码类）”提交文件，保留与复现直接相关的最小工程集合，不包含项目管理文档和重复材料。

## 目录说明

- `rtl/`：CPU、SoC、存储与缓存等 RTL 设计代码
- `tb/`：功能回归、性能测试、定向诊断 TestBench
- `sw/`：RISC-V 测试程序、CoreMark/Dhrystone 适配、示例应用与链接脚本
- `fpga/`：PYNQ-Z2 适配工程、约束文件、Vivado TCL 脚本与顶层封装
- `scripts/`：构建、仿真、性能测试、Vivado 构建与结果整理脚本
- `运行环境说明.md`：软硬件环境与基本复现入口

## 建议打包方式

提交前可直接将本目录整体压缩为一个 ZIP 文件，并按大赛命名规则命名为 `CICC1003618+初赛+源代码.zip`。

## 复现入口

1. 功能回归与定向测试：`scripts/` 下各类 `run_*.bat`
2. CoreMark：`scripts/run_coremark_score.bat`
3. Dhrystone：`scripts/run_dhrystone_score.bat`
4. PYNQ-Z2 工程生成与实现：`scripts/build_pynq_z2_project.bat`

当前冻结提交口径为 `RV32I + Zmmul + Zba/Zbb/Zbs`，对应 `4.137461 CoreMark/MHz`、`2.908287 DMIPS/MHz`、`4934 LUT`、PYNQ-Z2 `PROGRAM_OK`。Zbc、XThead、IDBR 相关代码和测试可作为参数化探索路径参考，但不作为本次冻结 bitstream 的正式能力宣称。源码注释率按提交统计口径约为 `30.27%`，补注释后已从本目录直接运行 `scripts\run_zmmul_test.bat` 并通过。

本目录仅保留提交所需代码与脚本。性能日志、材料文稿和阶段性管理文件统一放在提交材料的其他目录中维护。
