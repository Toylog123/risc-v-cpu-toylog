# _tmp 目录说明

本目录专门存放 `icdc_workspace` 本地运行时临时文件，不放正式源码、文档和长期保留的构建产物。

当前约定如下：

- `tool_logs/`
  - `vivado/`
    - `vivado.log`、`vivado.jou`、GUI 打开工程时的日志，以及对应批处理运行日志。
    - `clock_debug/`
      - `clockInfo.txt` 这类 Vivado 时钟调试文件。
  - `xsim/`
    - `xelab.log`、`xvlog.log`、`xsim.log`、`xsim.jou`、`*.pb`、`dfx_runtime.txt` 及备份日志。
- `sim_runtime/`
  - `xsim.dir` 这类体积较大的运行目录和快照目录。
- `vivado_user/`
  - Vivado 本地用户态目录、缓存目录和 `Temp`。
- `legacy/`
  - 旧工作区整体迁移快照，以及历史遗留临时文件。

整理规则：

- `YH_rv_cpu/`、`01-项目管理/`、`04-工具链/` 等正式目录只放正式工程内容。
- `project/` 只保留本地 Vivado 工程、报告、检查点等需要复查的结果。
- 新产生的运行时垃圾不要再回到仓库根目录，统一收纳到本目录。
