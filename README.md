# 集创赛工作区

## Git 跟踪范围

这个仓库现在只跟踪当前比赛真正需要协作的内容：

- `toylog_cpu/`：正式比赛工程
- `04-工具链/`：工具链说明与安装清单
- `01-项目管理/`：赛题要求、项目规划、过程管理、资料索引
- 根目录 `README.md`
- 根目录 `.gitignore`

## 本地保留但不上传

这些目录继续留在本地工作区，但不再纳入 Git 仓库：

- `02-官方与规范/`
- `03-参考实现/`
- `05-验证测试/`

## 当前约定

- 正式工程只有 `toylog_cpu`
- 每次对 `toylog_cpu` 有实际修改，都同步更新：
  - `toylog_cpu/doc/toylog_cpu_handoff.md`
  - `toylog_cpu/doc/toylog_cpu_change_log.md`
  - `toylog_cpu/doc/toylog_cpu_todo.md`
- 每次对项目安排、分工、交接、任务状态有实际修改，都同步更新：
  - `01-项目管理/03-过程管理/工作记录.md`
  - `01-项目管理/03-过程管理/工作交接.md`
  - `01-项目管理/03-过程管理/任务清单.md`
- 默认同步优先使用 `toylog_cpu/scripts/stage_default_sync.bat`

## 当前仓库结构

```text
集创赛/
├── README.md
├── .gitignore
├── 01-项目管理/
│   ├── 01-赛题要求/
│   ├── 02-项目规划/
│   ├── 03-过程管理/
│   └── 04-资料索引/
├── 04-工具链/
└── toylog_cpu/
```
