`timescale 1ns / 1ps
// ============================================================
// YH_rv_cpu_alu.v
// Author: Toylog
// Version: v1.2
// Function: RISC-V 算术逻辑单元 (Arithmetic Logic Unit)
// Description: ALU 是 CPU 的核心执行单元，负责执行所有的算术、逻辑和移位运算
//   支持的操作包括：加法、减法、比较、逻辑运算、移位运算
//   支持RISC-V M扩展：乘法、除法、取余指令
//   参数化设计支持 XLEN=32 (RV32) 或 XLEN=64 (RV64)
// ============================================================

`include "YH_rv_cpu_defs.vh"

// ------------------------------------------------------------
// ALU 模块声明
// 参数化设计允许在实例化时指定数据通路宽度
// ------------------------------------------------------------
module YH_rv_cpu_alu #(
    parameter integer XLEN = 32  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
) (
    // 控制信号输入
    input  wire [4:0]       alu_op,    // ALU 操作码，定义在 YH_rv_cpu_defs.vh
    // 数据输入
    input  wire [XLEN-1:0] lhs,      // 左手操作数 (left-hand side)
    input  wire [XLEN-1:0] rhs,       // 右手操作数 (right-hand side)
    // 结果输出
    output reg  [XLEN-1:0] result,    // 运算结果
    // 比较结果输出 (组合逻辑，不经过寄存器)
    output wire            eq,         // 相等比较结果: lhs == rhs
    output wire            lt,         // 有符号小于比较: lhs < rhs (signed)
    output wire            ltu         // 无符号小于比较: lhs < rhs (unsigned)
);

// ------------------------------------------------------------
// 局部参数定义
// SHAMT_W: 移位量宽度，由数据宽度决定
// 例如: XLEN=32 时，移位量为 5 位 (0-31)
//       XLEN=64 时，移位量为 6 位 (0-63)
// ------------------------------------------------------------
localparam integer SHAMT_W = $clog2(XLEN);

// ------------------------------------------------------------
// 比较运算单元 (组合逻辑)
// 这些比较结果被 SLT/SLTU 指令使用
// 单独实现比较逻辑可以提高速度
// ------------------------------------------------------------
// 相等比较: 用于 beq, bne 指令
assign eq  = (lhs == rhs);
// 有符号小于比较: 用于 slt, slti 指令
// $signed() 将操作数视为有符号数进行比较
assign lt  = ($signed(lhs) < $signed(rhs));
// 无符号小于比较: 用于 sltu, sltiu 指令
// 不转换符号，直接按位比较
assign ltu = (lhs < rhs);

// ------------------------------------------------------------
// M扩展运算变量声明
// 用于乘法和除法运算的临时结果
// ------------------------------------------------------------
// 乘法运算需要2*XLEN位的结果
wire [2*XLEN-1:0] mul_result;       // 完整乘法结果
wire [2*XLEN-1:0] mul_signed;      // 有符号乘法扩展
wire [2*XLEN-1:0] mul_unsigned;     // 无符号乘法扩展
wire [2*XLEN-1:0] mul_mix;         // 混合符号乘法扩展

// MULHSU用中间变量：lhs符号扩展到2*XLEN位，rhs零扩展到2*XLEN位
wire signed [2*XLEN-1:0] mul_lhs_sext = {{XLEN{lhs[XLEN-1]}}, lhs};
wire signed [2*XLEN-1:0] mul_rhs_zext = {{XLEN{1'b0}}, rhs};

// 有符号除法特殊处理
// RISC-V规定除零结果为全1，溢出结果为最小负数
wire div_by_zero;                   // 除零标志
wire div_overflow;                  // 除法溢出标志 (仅当 lhs=-2^(XLEN-1), rhs=-1 时)

// 有符号操作数扩展 (用于乘法高位)
wire signed [XLEN-1:0] lhs_signed = lhs;
wire signed [XLEN-1:0] rhs_signed = rhs;

// ------------------------------------------------------------
// M扩展运算单元 (组合逻辑)
// 实现RISC-V M扩展的乘法和除法指令
// ------------------------------------------------------------

// 乘法运算
// MUL: lhs * rhs，取结果的低XLEN位
assign mul_result = lhs * rhs;

// 有符号乘法高位 (MULH)
// lhs和rhs都作为有符号数相乘，结果取高XLEN位
assign mul_signed = $signed({{XLEN{1'b0}}, lhs_signed}) * $signed({{XLEN{1'b0}}, rhs_signed});

// 无符号乘法高位 (MULHU)
// lhs和rhs都作为无符号数相乘，结果取高XLEN位
assign mul_unsigned = lhs * rhs;

// MULHSU: lhs signed * rhs unsigned, result high bits
assign mul_mix = mul_lhs_sext * mul_rhs_zext;

// 除零检测
assign div_by_zero = (rhs == {XLEN{1'b0}});

// 除法溢出检测: lhs = -2^(XLEN-1), rhs = -1
// 例如: XLEN=32 时，lhs = 0x80000000, rhs = 0xFFFFFFFF
// 结果应该保持为 -2^(XLEN-1) (即溢出时商等于被除数)
assign div_overflow = (lhs[XLEN-1:XLEN-1] == 1'b1) && 
                      (rhs == {1'b1, {(XLEN-1){1'b0}}}) &&
                      (|rhs == 1'b0);  // 检查rhs是否为-1

// ------------------------------------------------------------
// 主运算单元 (组合逻辑)
// 根据 alu_op 选择执行不同的运算
// case 语句综合为并行选择器
// ------------------------------------------------------------
always @* begin
    case (alu_op)
        // 加法运算: add, addi
        // result = lhs + rhs
        `YH_rv_cpu_ALU_ADD:  result = lhs + rhs;
        // 减法运算: sub
        // result = lhs - rhs
        `YH_rv_cpu_ALU_SUB:  result = lhs - rhs;
        // 有符号小于: slt, slti
        // 将比较结果 (1 位) 扩展为 XLEN 位
        // lt 为 1 时 result = 1，否则 result = 0
        `YH_rv_cpu_ALU_SLT:  result = {{(XLEN-1){1'b0}}, lt};
        // 无符号小于: sltu, sltiu
        // 同样将比较结果扩展为 XLEN 位
        `YH_rv_cpu_ALU_SLTU: result = {{(XLEN-1){1'b0}}, ltu};
        // 异或运算: xor, xori
        // 按位异或
        `YH_rv_cpu_ALU_XOR:  result = lhs ^ rhs;
        // 或运算: or, ori
        // 按位或
        `YH_rv_cpu_ALU_OR:   result = lhs | rhs;
        // 与运算: and, andi
        // 按位与
        `YH_rv_cpu_ALU_AND:  result = lhs & rhs;
        // 逻辑左移: sll, slli
        // lhs 左移 rhs[4:0] (RV32) 或 rhs[5:0] (RV64) 位
        // 低位补 0
        `YH_rv_cpu_ALU_SLL:  result = lhs << rhs[SHAMT_W-1:0];
        // 逻辑右移: srl, srli
        // lhs 右移 rhs[4:0] (RV32) 或 rhs[5:0] (RV64) 位
        // 高位补 0
        `YH_rv_cpu_ALU_SRL:  result = lhs >> rhs[SHAMT_W-1:0];
        // 算术右移: sra, srai
        // lhs 右移 rhs[4:0] (RV32) 或 rhs[5:0] (RV64) 位
        // 高位补符号位，保留负数符号
        `YH_rv_cpu_ALU_SRA:  result = $signed(lhs) >>> rhs[SHAMT_W-1:0];
        
        // ============================================================
        // M扩展: 乘法指令
        // ============================================================
        // MUL: 乘法指令，取结果的低XLEN位
        // result = lhs * rhs
        `YH_rv_cpu_ALU_MUL:   result = mul_result[XLEN-1:0];
        
        // MULH: 有符号乘法高位
        // lhs和rhs都作为有符号数，结果取高XLEN位
        `YH_rv_cpu_ALU_MULH:  result = mul_signed[2*XLEN-1:XLEN];
        
        // MULHU: 无符号乘法高位
        // lhs和rhs都作为无符号数，结果取高XLEN位
        `YH_rv_cpu_ALU_MULHU: result = mul_unsigned[2*XLEN-1:XLEN];
        
        // MULHSU: 混合符号乘法高位
        // lhs作为有符号数，rhs作为无符号数，结果取高XLEN位
        `YH_rv_cpu_ALU_MULHSU: result = mul_mix[2*XLEN-1:XLEN];
        
        // ============================================================
        // M扩展: 除法指令
        // ============================================================
        // DIV: 有符号除法
        // 除零结果为-1，溢出结果为最小负数
        `YH_rv_cpu_ALU_DIV: begin
            if (div_by_zero) begin
                result = {XLEN{1'b1}};  // 除零返回全1
            end else if (div_overflow) begin
                result = {1'b1, {(XLEN-1){1'b0}}};  // 溢出保持最小负数
            end else begin
                result = lhs_signed / rhs_signed;
            end
        end
        
        // DIVU: 无符号除法
        // 除零结果为全1
        `YH_rv_cpu_ALU_DIVU: begin
            if (div_by_zero) begin
                result = {XLEN{1'b1}};
            end else begin
                result = lhs / rhs;
            end
        end
        
        // REM: 有符号取余
        // 除零结果为被除数lhs
        `YH_rv_cpu_ALU_REM: begin
            if (div_by_zero) begin
                result = lhs;  // 除零时返回被除数
            end else if (div_overflow) begin
                result = {XLEN{1'b0}};  // 溢出时余数为0
            end else begin
                result = lhs_signed % rhs_signed;
            end
        end
        
        // REMU: 无符号取余
        // 除零结果为被除数lhs
        `YH_rv_cpu_ALU_REMU: begin
            if (div_by_zero) begin
                result = lhs;
            end else begin
                result = lhs % rhs;
            end
        end
        
        // 默认: 零
        // 当 alu_op 无效时返回 0
        default:             result = {XLEN{1'b0}};
    endcase
end

endmodule
