`timescale 1ns / 1ps
// ============================================================
// YH_rv_cpu_wb_stage.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 写回阶段 (Write-Back Stage)
// Description: 选择最终写回寄存器的数据
//   三种数据来源:
//     1. ALU 执行结果 (运算指令)
//     2. 内存加载数据 (load 指令)
//     3. PC+4 (JAL/JALR 保存返回地址)
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_wb_stage #(
    parameter integer XLEN = 32  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
) (
    // ------------------------------------------------------------
    // 输入信号 (来自 MEM/WB 流水线寄存器)
    // ------------------------------------------------------------
    input  wire [1:0]      wb_sel,          // 写回数据选择
                                           // 00: ALU 结果
                                           // 01: 内存加载数据
                                           // 10: PC+4
    input  wire [XLEN-1:0] exec_result,     // ALU 执行结果
    input  wire [XLEN-1:0] load_data,       // 内存加载数据
    input  wire [XLEN-1:0] pc4,            // PC + 4 (返回地址)

    // ------------------------------------------------------------
    // 输出信号 (到寄存器堆)
    // ------------------------------------------------------------
    output wire [XLEN-1:0] wb_data         // 写回数据
);

    // ------------------------------------------------------------
    // 写回数据选择
    // 根据 wb_sel 选择正确的数据来源
    // wb_sel 定义在 YH_rv_cpu_defs.vh:
    //   YH_rv_cpu_WB_ALU  = 2'b00  (运算结果)
    //   YH_rv_cpu_WB_MEM  = 2'b01  (内存加载)
    //   YH_rv_cpu_WB_PC4   = 2'b10  (PC+4, JAL/JALR)
    // ------------------------------------------------------------
assign wb_data =
    (wb_sel == `YH_rv_cpu_WB_MEM) ? load_data :    // 内存加载数据
    (wb_sel == `YH_rv_cpu_WB_PC4) ? pc4 :          // PC+4 (返回地址)
    exec_result;                                     // ALU 结果 (默认)

endmodule
