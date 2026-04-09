# 图片目录说明

本目录用于存放初赛设计说明书中准备插入的图片。

## 建议文件名

- `overall_architecture.pdf`：总体架构框图
- `pipeline_datapath.pdf`：五级流水数据通路图
- `soc_memory_map.pdf`：SoC 存储与 MMIO 结构图
- `verification_flow.pdf`：验证流程图
- `fpga_preboard_flow.pdf`：FPGA pre-board 流程图

## 使用方式

正文里已经预留了插图占位块。后续替换时，可将占位块替换为类似下面的语句：

```tex
\begin{figure}[H]
  \centering
  \includegraphics[width=0.88\textwidth]{overall_architecture.pdf}
  \caption{系统总体架构图}
\end{figure}
```
