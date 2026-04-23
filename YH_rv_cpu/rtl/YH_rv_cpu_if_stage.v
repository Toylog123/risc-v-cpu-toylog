`timescale 1ns / 1ps
// ============================================================
// YH_rv_cpu_if_stage.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 取指阶段 (Instruction Fetch Stage)
// Description: 负责从指令存储器获取指令，并计算下一 PC 地址
//   支持 PC 重定向 (分支跳转、JALR、异常处理)
//   输出指令地址给 imem，生成 PC+4 用于顺序执行
// ============================================================

module YH_rv_cpu_if_stage #(
    parameter integer XLEN = 32,  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
    parameter C_EXT = 0           // C扩展 (压缩指令) 支持: 0=禁用, 1=启用 (预留)
) (
    // ------------------------------------------------------------
    // PC 控制信号
    // ------------------------------------------------------------
    input  wire [XLEN-1:0] pc_current,        // 当前 PC 值 (来自流水线寄存器)
    input  wire            redirect_en,       // PC 重定向使能 (分支跳转/异常)
    input  wire [XLEN-1:0] redirect_pc,       // 重定向目标地址

    // ------------------------------------------------------------
    // 内存访问接口
    // ------------------------------------------------------------
    input  wire [15:0]     instr_raw,         // 原始指令数据 (用于C扩展判断)
    output wire [XLEN-1:0] imem_addr,        // 指令存储器地址
    output wire [XLEN-1:0] pc_next,          // 下一 PC 值
    output wire [XLEN-1:0] pc_plus_4,        // PC + 4 (顺序执行下一地址)
    output wire [XLEN-1:0] pc_plus_2,        // PC + 2 (压缩指令下一地址, C扩展预留)
    output wire            instr_is_compressed  // 指令是否为压缩格式 (C扩展预留)
);

    // ------------------------------------------------------------
    // PC 步进常量
    // RISC-V 指令长度为 32 位 (4 字节)，所以 PC 每次增加 4
    // 压缩指令长度为 16 位 (2 字节)，PC 增加 2
    // ------------------------------------------------------------
localparam [XLEN-1:0] PC_STEP = {{(XLEN-3){1'b0}}, 3'd4};
localparam [XLEN-1:0] PC_STEP_COMP = {{(XLEN-3){1'b0}}, 3'd2};  // 压缩指令步进

// ------------------------------------------------------------
// C扩展预留: 压缩指令判断
// 压缩指令低两位为 00, 01, 10 (不是 11)
// ------------------------------------------------------------
generate
    if (C_EXT == 1) begin : gen_compressed_check
        // 指令低两位不为 11 则为压缩指令
        assign instr_is_compressed = instr_raw[1:0] != 2'b11;
        assign pc_plus_2 = pc_current + PC_STEP_COMP;
    end else begin : gen_no_compressed
        // C扩展禁用时，始终为非压缩指令
        assign instr_is_compressed = 1'b0;
        assign pc_plus_2 = pc_current + PC_STEP_COMP;  // 预留计算
    end
endgenerate

    // ------------------------------------------------------------
    // 指令存储器地址 = 当前 PC
    // ------------------------------------------------------------
assign imem_addr = pc_current;

    // ------------------------------------------------------------
    // PC + 4 计算
    // 用于 JAL 指令保存返回地址
    // ------------------------------------------------------------
assign pc_plus_4 = pc_current + PC_STEP;

    // ------------------------------------------------------------
    // 下一 PC 选择
    // redirect_en=1: 跳转到目标地址 (分支/jalr/异常)
    // redirect_en=0: 顺序执行
    //   - C扩展启用时，根据指令长度选择 PC+4 或 PC+2
    //   - C扩展禁用时，始终 PC+4
    // ------------------------------------------------------------
generate
    if (C_EXT == 1) begin : gen_c_ext_pc_next
        assign pc_next = redirect_en ? redirect_pc :
                         (instr_is_compressed ? pc_plus_2 : pc_plus_4);
    end else begin : gen_no_c_ext_pc_next
        assign pc_next = redirect_en ? redirect_pc : pc_plus_4;
    end
endgenerate

endmodule
