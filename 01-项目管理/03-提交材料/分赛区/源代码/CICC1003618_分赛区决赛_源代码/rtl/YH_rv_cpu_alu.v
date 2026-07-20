// ============================================================
// YH_rv_cpu_alu.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 算术逻辑单元 (Arithmetic Logic Unit)
// Description: ALU 是 CPU 的核心执行单元，负责执行所有的算术、逻辑和移位运算
//   支持的操作包括：加法、减法、比较、逻辑运算、移位运算
//   参数化设计支持 XLEN=32 (RV32) 或 XLEN=64 (RV64)
// ============================================================

`include "YH_rv_cpu_defs.vh"

// ------------------------------------------------------------
// ALU 模块声明
// 参数化设计允许在实例化时指定数据通路宽度
// ------------------------------------------------------------
module YH_rv_cpu_alu #(
    parameter integer XLEN = 32,  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_CRC_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_MUL_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 1,
    parameter integer ENABLE_XTHEAD_EXT_FULL_RANGE = 0,
    parameter integer ENABLE_XTHEAD_ADDSL_EXTENSION = 0
) (
    // 控制信号输入
    input  wire [5:0]      alu_op,    // ALU 操作码，定义在 YH_rv_cpu_defs.vh
    // 数据输入
    input  wire [XLEN-1:0] lhs,      // 左手操作数 (left-hand side)
    input  wire [XLEN-1:0] rhs,       // 右手操作数 (right-hand side)
    input  wire [XLEN-1:0] acc,       // rd-as-source accumulator for custom MAC ops
    input  wire [XLEN-1:0] mul_lhs,   // timing-isolated MUL/MAC left operand
    input  wire [XLEN-1:0] mul_rhs,   // timing-isolated MUL/MAC right operand
    input  wire [XLEN-1:0] mul_acc,   // timing-isolated MUL/MAC accumulator
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

wire [XLEN-1:0] m_result_mul;
wire [XLEN-1:0] m_result_mulh;
wire [XLEN-1:0] m_result_mulhsu;
wire [XLEN-1:0] m_result_mulhu;
wire [XLEN-1:0] m_result_div;
wire [XLEN-1:0] m_result_divu;
wire [XLEN-1:0] m_result_rem;
wire [XLEN-1:0] m_result_remu;
wire [XLEN-1:0] x_result_th_mula;
wire [XLEN-1:0] x_result_th_mulah;
wire [XLEN-1:0] b_result_clmul;
wire [XLEN-1:0] b_result_clmulh;
wire [XLEN-1:0] x_result_ext_range;
wire [XLEN-1:0] x_result_crc16;
wire [XLEN-1:0] x_result_crc32;
wire            m_mul_op_active;
wire            x_th_mula_op_active;
wire            x_th_mulah_op_active;
wire            x_th_mul_op_active;
wire [XLEN-1:0] m_mul_lhs;
wire [XLEN-1:0] m_mul_rhs;
wire [XLEN-1:0] x_th_mul_lhs;
wire [XLEN-1:0] x_th_mul_rhs;
wire [XLEN-1:0] x_th_mul_acc;

assign m_mul_op_active =
    (alu_op == `YH_rv_cpu_ALU_MUL) ||
    (alu_op == `YH_rv_cpu_ALU_MULH) ||
    (alu_op == `YH_rv_cpu_ALU_MULHSU) ||
    (alu_op == `YH_rv_cpu_ALU_MULHU);
assign x_th_mula_op_active = (alu_op == `YH_rv_cpu_ALU_TH_MULA);
assign x_th_mulah_op_active = (alu_op == `YH_rv_cpu_ALU_TH_MULAH);
assign x_th_mul_op_active = x_th_mula_op_active || x_th_mulah_op_active;
assign m_mul_lhs = m_mul_op_active ? mul_lhs : {XLEN{1'b0}};
assign m_mul_rhs = m_mul_op_active ? mul_rhs : {XLEN{1'b0}};
assign x_th_mul_lhs = x_th_mul_op_active ? mul_lhs : {XLEN{1'b0}};
assign x_th_mul_rhs = x_th_mul_op_active ? mul_rhs : {XLEN{1'b0}};
assign x_th_mul_acc = x_th_mul_op_active ? mul_acc : {XLEN{1'b0}};

function [XLEN-1:0] yh_xthead_ext_hot_range;
    input [XLEN-1:0] value;
    input [11:0]     ctrl;
    begin
        case (ctrl)
            {1'b0, 6'd15, 5'd0}:  yh_xthead_ext_hot_range = {{(XLEN-16){1'b0}}, value[15:0]};
            {1'b1, 6'd15, 5'd0}:  yh_xthead_ext_hot_range = {{(XLEN-16){value[15]}}, value[15:0]};
            {1'b0, 6'd15, 5'd8}:  yh_xthead_ext_hot_range = {{(XLEN-8){1'b0}}, value[15:8]};
            {1'b1, 6'd15, 5'd8}:  yh_xthead_ext_hot_range = {{(XLEN-8){value[15]}}, value[15:8]};
            {1'b0, 6'd11, 5'd5}:  yh_xthead_ext_hot_range = {{(XLEN-7){1'b0}}, value[11:5]};
            {1'b1, 6'd11, 5'd5}:  yh_xthead_ext_hot_range = {{(XLEN-7){value[11]}}, value[11:5]};
            {1'b0, 6'd5,  5'd2}:  yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[5:2]};
            {1'b1, 6'd5,  5'd2}:  yh_xthead_ext_hot_range = {{(XLEN-4){value[5]}}, value[5:2]};
            {1'b0, 6'd6,  5'd3}:  yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[6:3]};
            {1'b1, 6'd6,  5'd3}:  yh_xthead_ext_hot_range = {{(XLEN-4){value[6]}}, value[6:3]};
            {1'b0, 6'd7,  5'd4}:  yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[7:4]};
            {1'b1, 6'd7,  5'd4}:  yh_xthead_ext_hot_range = {{(XLEN-4){value[7]}}, value[7:4]};
            {1'b0, 6'd11, 5'd8}:  yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[11:8]};
            {1'b1, 6'd11, 5'd8}:  yh_xthead_ext_hot_range = {{(XLEN-4){value[11]}}, value[11:8]};
            {1'b0, 6'd15, 5'd12}: yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[15:12]};
            {1'b1, 6'd15, 5'd12}: yh_xthead_ext_hot_range = {{(XLEN-4){value[15]}}, value[15:12]};
            {1'b0, 6'd4,  5'd3}:  yh_xthead_ext_hot_range = {{(XLEN-2){1'b0}}, value[4:3]};
            {1'b1, 6'd4,  5'd3}:  yh_xthead_ext_hot_range = {{(XLEN-2){value[4]}}, value[4:3]};
            {1'b0, 6'd19, 5'd16}: yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[19:16]};
            {1'b1, 6'd19, 5'd16}: yh_xthead_ext_hot_range = {{(XLEN-4){value[19]}}, value[19:16]};
            {1'b0, 6'd23, 5'd20}: yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[23:20]};
            {1'b1, 6'd23, 5'd20}: yh_xthead_ext_hot_range = {{(XLEN-4){value[23]}}, value[23:20]};
            {1'b0, 6'd27, 5'd24}: yh_xthead_ext_hot_range = {{(XLEN-4){1'b0}}, value[27:24]};
            {1'b1, 6'd27, 5'd24}: yh_xthead_ext_hot_range = {{(XLEN-4){value[27]}}, value[27:24]};
            default:              yh_xthead_ext_hot_range = {XLEN{1'b0}};
        endcase
    end
endfunction

function [15:0] yh_crc8_next;
    input [7:0]  data_in;
    input [15:0] crc_in;
    reg   [7:0]  data;
    reg   [15:0] crc;
    reg          x16;
    integer      crc_i;
    begin
        data = data_in;
        crc  = crc_in;
        for (crc_i = 0; crc_i < 8; crc_i = crc_i + 1) begin
            x16  = data[0] ^ crc[0];
            data = {1'b0, data[7:1]};
            if (x16) begin
                crc = ((crc ^ 16'h4002) >> 1) | 16'h8000;
            end else begin
                crc = crc >> 1;
            end
        end
        yh_crc8_next = crc;
    end
endfunction

function [15:0] yh_crc16_next;
    input [15:0] value_in;
    input [15:0] crc_in;
    reg   [15:0] crc_lo;
    begin
        crc_lo        = yh_crc8_next(value_in[7:0], crc_in);
        yh_crc16_next = yh_crc8_next(value_in[15:8], crc_lo);
end
endfunction

function [15:0] yh_crc32_next;
    input [31:0] value_in;
    input [15:0] crc_in;
    reg   [15:0] crc_b0;
    reg   [15:0] crc_b1;
    reg   [15:0] crc_b2;
    begin
        crc_b0        = yh_crc8_next(value_in[7:0], crc_in);
        crc_b1        = yh_crc8_next(value_in[15:8], crc_b0);
        crc_b2        = yh_crc8_next(value_in[23:16], crc_b1);
        yh_crc32_next = yh_crc8_next(value_in[31:24], crc_b2);
end
endfunction

generate
if (ENABLE_XTHEAD_CRC_EXTENSION != 0) begin : gen_xthead_crc_extension
    assign x_result_crc16 = {{(XLEN-16){1'b0}}, yh_crc16_next(lhs[15:0], rhs[15:0])};
    assign x_result_crc32 = {{(XLEN-16){1'b0}}, yh_crc32_next(lhs[31:0], rhs[15:0])};
end else begin : gen_no_xthead_crc_extension
    assign x_result_crc16 = {XLEN{1'b0}};
    assign x_result_crc32 = {XLEN{1'b0}};
end
endgenerate

generate
if ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_MUL_EXTENSION != 0)) begin : gen_xthead_mul_extension
    assign x_result_th_mula = x_th_mula_op_active ? (x_th_mul_acc + (x_th_mul_lhs * x_th_mul_rhs)) : {XLEN{1'b0}};

    if (XLEN == 32) begin : gen_th_mulah_rv32
        wire signed [31:0] th_mulah_lhs16;
        wire signed [31:0] th_mulah_rhs16;
        wire signed [31:0] th_mulah_acc32;
        wire signed [31:0] th_mulah_sum32;

        assign th_mulah_lhs16 = {{16{x_th_mul_lhs[15]}}, x_th_mul_lhs[15:0]};
        assign th_mulah_rhs16 = {{16{x_th_mul_rhs[15]}}, x_th_mul_rhs[15:0]};
        assign th_mulah_acc32 = x_th_mul_acc[31:0];
        assign th_mulah_sum32 = th_mulah_acc32 + (th_mulah_lhs16 * th_mulah_rhs16);
        assign x_result_th_mulah = x_th_mulah_op_active ? th_mulah_sum32 : {XLEN{1'b0}};
    end else begin : gen_th_mulah_rv64
        wire signed [31:0] th_mulah_lhs16;
        wire signed [31:0] th_mulah_rhs16;
        wire signed [31:0] th_mulah_acc32;
        wire signed [31:0] th_mulah_sum32;

        assign th_mulah_lhs16 = {{16{x_th_mul_lhs[15]}}, x_th_mul_lhs[15:0]};
        assign th_mulah_rhs16 = {{16{x_th_mul_rhs[15]}}, x_th_mul_rhs[15:0]};
        assign th_mulah_acc32 = x_th_mul_acc[31:0];
        assign th_mulah_sum32 = th_mulah_acc32 + (th_mulah_lhs16 * th_mulah_rhs16);
        assign x_result_th_mulah = x_th_mulah_op_active ? {{(XLEN-32){th_mulah_sum32[31]}}, th_mulah_sum32} : {XLEN{1'b0}};
    end
end else begin : gen_no_xthead_mul_extension
    assign x_result_th_mula = {XLEN{1'b0}};
    assign x_result_th_mulah = {XLEN{1'b0}};
end
endgenerate

generate
if ((ENABLE_M_EXTENSION != 0) || (ENABLE_ZMMUL_EXTENSION != 0)) begin : gen_mul_extension
    wire        mul_lhs_signed;
    wire        mul_rhs_signed;
    wire [32:0] mul_lhs_ext;
    wire [32:0] mul_rhs_ext;
    wire signed [65:0] mul_product;

    // Share one 33x33 multiplier across MUL/MULH/MULHSU/MULHU.
    assign mul_lhs_signed = (alu_op == `YH_rv_cpu_ALU_MULH) || (alu_op == `YH_rv_cpu_ALU_MULHSU);
    assign mul_rhs_signed = (alu_op == `YH_rv_cpu_ALU_MULH);
    assign mul_lhs_ext = {mul_lhs_signed & m_mul_lhs[31], m_mul_lhs[31:0]};
    assign mul_rhs_ext = {mul_rhs_signed & m_mul_rhs[31], m_mul_rhs[31:0]};
    assign mul_product = $signed(mul_lhs_ext) * $signed(mul_rhs_ext);

    assign m_result_mul = mul_product[XLEN-1:0];
    assign m_result_mulh = mul_product[63:32];
    assign m_result_mulhsu = mul_product[63:32];
    assign m_result_mulhu = mul_product[63:32];
end else begin : gen_no_mul_extension
    assign m_result_mul = {XLEN{1'b0}};
    assign m_result_mulh = {XLEN{1'b0}};
    assign m_result_mulhsu = {XLEN{1'b0}};
    assign m_result_mulhu = {XLEN{1'b0}};
end
endgenerate

generate
if (ENABLE_M_EXTENSION != 0) begin : gen_div_extension
    wire [XLEN-1:0] xlen_one;
    wire lhs_neg;
    wire rhs_neg;
    wire div_neg;
    wire div_overflow;
    wire [XLEN-1:0] lhs_abs;
    wire [XLEN-1:0] rhs_abs;
    wire [XLEN-1:0] rhs_abs_safe;
    wire [XLEN-1:0] div_abs;
    wire [XLEN-1:0] rem_abs;
    wire [XLEN-1:0] div_signed_result;
    wire [XLEN-1:0] rem_signed_result;

    assign xlen_one = {{(XLEN-1){1'b0}}, 1'b1};
    assign lhs_neg = lhs[XLEN-1];
    assign rhs_neg = rhs[XLEN-1];
    assign div_neg = lhs_neg ^ rhs_neg;
    assign div_overflow = (lhs == {1'b1, {(XLEN-1){1'b0}}}) && (rhs == {XLEN{1'b1}});
    assign lhs_abs = lhs_neg ? (~lhs + xlen_one) : lhs;
    assign rhs_abs = rhs_neg ? (~rhs + xlen_one) : rhs;
    assign rhs_abs_safe = (rhs == {XLEN{1'b0}}) ? xlen_one : rhs_abs;
    assign div_abs = lhs_abs / rhs_abs_safe;
    assign rem_abs = lhs_abs % rhs_abs_safe;
    assign div_signed_result = div_neg ? (~div_abs + xlen_one) : div_abs;
    assign rem_signed_result = lhs_neg ? (~rem_abs + xlen_one) : rem_abs;

    assign m_result_div = (rhs == 0) ? {XLEN{1'b1}} : (div_overflow ? lhs : div_signed_result);
    assign m_result_divu = (rhs == 0) ? {XLEN{1'b1}} : lhs / rhs;
    assign m_result_rem = (rhs == 0) ? lhs : (div_overflow ? {XLEN{1'b0}} : rem_signed_result);
    assign m_result_remu = (rhs == 0) ? lhs : lhs % rhs;
end else begin : gen_no_div_extension
    assign m_result_div = {XLEN{1'b0}};
    assign m_result_divu = {XLEN{1'b0}};
    assign m_result_rem = {XLEN{1'b0}};
    assign m_result_remu = {XLEN{1'b0}};
end
endgenerate

generate
if (ENABLE_ZBC_EXTENSION != 0) begin : gen_zbc_extension
    reg  [(2*XLEN)-1:0] clmul_product;
    integer clmul_i;

    always @* begin
        clmul_product = {(2*XLEN){1'b0}};
        for (clmul_i = 0; clmul_i < XLEN; clmul_i = clmul_i + 1) begin
            if (rhs[clmul_i]) begin
                clmul_product = clmul_product ^ (({{XLEN{1'b0}}, lhs}) << clmul_i);
            end
        end
    end

    assign b_result_clmul = clmul_product[XLEN-1:0];
    assign b_result_clmulh = clmul_product[(2*XLEN)-1:XLEN];
end else begin : gen_no_zbc_extension
    assign b_result_clmul = {XLEN{1'b0}};
    assign b_result_clmulh = {XLEN{1'b0}};
end
endgenerate

generate
if (ENABLE_XTHEAD_EXTENSION != 0) begin : gen_xthead_extension
    if (ENABLE_XTHEAD_EXT_FULL_RANGE != 0) begin : gen_xthead_ext_full_range
        reg [XLEN-1:0] ext_range_result;
        integer ext_i;

        always @* begin
            ext_range_result = {XLEN{1'b0}};
            if (rhs[10:5] >= rhs[4:0]) begin
                for (ext_i = 0; ext_i < XLEN; ext_i = ext_i + 1) begin
                    if (ext_i <= (rhs[10:5] - rhs[4:0])) begin
                        ext_range_result[ext_i] = lhs[rhs[4:0] + ext_i[4:0]];
                    end else if (rhs[11]) begin
                        ext_range_result[ext_i] = lhs[rhs[10:5]];
                    end
                end
            end
        end

        assign x_result_ext_range = ext_range_result;
    end else begin : gen_xthead_ext_hot_range
        assign x_result_ext_range = yh_xthead_ext_hot_range(lhs, rhs[11:0]);
    end
end else begin : gen_no_xthead_extension
    assign x_result_ext_range = {XLEN{1'b0}};
end
endgenerate

// ------------------------------------------------------------
// 主运算单元 (组合逻辑)
// 根据 alu_op 选择执行不同的运算
// case 语句综合为并行选择器
// ------------------------------------------------------------
always @* begin
    case (alu_op)
        // 加法运算: add, addi
        `YH_rv_cpu_ALU_ADD:  result = lhs + rhs;
        // 减法运算: sub
        `YH_rv_cpu_ALU_SUB:  result = lhs - rhs;
        // 有符号小于: slt, slti
        `YH_rv_cpu_ALU_SLT:  result = {{(XLEN-1){1'b0}}, lt};
        // 无符号小于: sltu, sltiu
        `YH_rv_cpu_ALU_SLTU: result = {{(XLEN-1){1'b0}}, ltu};
        // 异或运算: xor, xori
        `YH_rv_cpu_ALU_XOR:  result = lhs ^ rhs;
        // 或运算: or, ori
        `YH_rv_cpu_ALU_OR:   result = lhs | rhs;
        // 与运算: and, andi
        `YH_rv_cpu_ALU_AND:  result = lhs & rhs;
        // 逻辑左移: sll, slli
        `YH_rv_cpu_ALU_SLL:  result = lhs << rhs[SHAMT_W-1:0];
        // 逻辑右移: srl, srli
        `YH_rv_cpu_ALU_SRL:  result = lhs >> rhs[SHAMT_W-1:0];
        // 算术右移: sra, srai
        `YH_rv_cpu_ALU_SRA:  result = $signed(lhs) >>> rhs[SHAMT_W-1:0];
        // MUL: 有符号乘法 (32x32=64, 取低32位)
        `YH_rv_cpu_ALU_MUL:  result = m_result_mul;
        // MULH: 有符号乘法高位
        `YH_rv_cpu_ALU_MULH: result = m_result_mulh;
        // MULHSU: 混合乘法高位 (lhs有符号, rhs无符号)
        `YH_rv_cpu_ALU_MULHSU: result = m_result_mulhsu;
        // MULHU: 无符号乘法高位
        `YH_rv_cpu_ALU_MULHU: result = m_result_mulhu;
        // DIV: 有符号除法
        `YH_rv_cpu_ALU_DIV:  result = m_result_div;
        // DIVU: 无符号除法
        `YH_rv_cpu_ALU_DIVU: result = m_result_divu;
        // REM: 有符号取模
        `YH_rv_cpu_ALU_REM:  result = m_result_rem;
        // REMU: 无符号取模
        `YH_rv_cpu_ALU_REMU: result = m_result_remu;
        `YH_rv_cpu_ALU_SH1ADD: result = (ENABLE_BITMANIP_EXTENSION != 0) ? ((lhs << 1) + rhs) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_SH2ADD: result = (ENABLE_BITMANIP_EXTENSION != 0) ? ((lhs << 2) + rhs) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_SH3ADD: result = (ENABLE_BITMANIP_EXTENSION != 0) ? ((lhs << 3) + rhs) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_ADDSL1: result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_ADDSL_EXTENSION != 0)) ? (lhs + (rhs << 1)) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_ADDSL2: result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_ADDSL_EXTENSION != 0)) ? (lhs + (rhs << 2)) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_ADDSL3: result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_ADDSL_EXTENSION != 0)) ? (lhs + (rhs << 3)) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_MVEQZ:  result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_COND_MOVE != 0)) ? lhs : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_MVNEZ:  result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_COND_MOVE != 0)) ? lhs : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_XCRC16:    result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_CRC_EXTENSION != 0)) ? x_result_crc16 : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_XCRC32:    result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_CRC_EXTENSION != 0)) ? x_result_crc32 : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_MULA:   result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_MUL_EXTENSION != 0)) ? x_result_th_mula : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_MULAH:  result = ((ENABLE_XTHEAD_EXTENSION != 0) && (ENABLE_XTHEAD_MUL_EXTENSION != 0)) ? x_result_th_mulah : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_ANDN:   result = (ENABLE_BITMANIP_EXTENSION != 0) ? (lhs & ~rhs) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_MAX:    result = (ENABLE_BITMANIP_EXTENSION != 0) ? (($signed(lhs) > $signed(rhs)) ? lhs : rhs) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_SEXT_H: result = (ENABLE_BITMANIP_EXTENSION != 0) ? {{(XLEN-16){lhs[15]}}, lhs[15:0]} : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_ZEXT_H: result = (ENABLE_BITMANIP_EXTENSION != 0) ? {{(XLEN-16){1'b0}}, lhs[15:0]} : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_BEXT:   result = (ENABLE_BITMANIP_EXTENSION != 0) ? {{(XLEN-1){1'b0}}, lhs[rhs[SHAMT_W-1:0]]} : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_CZERO_EQZ: result = (ENABLE_ZICOND_EXTENSION != 0) ? ((rhs == {XLEN{1'b0}}) ? {XLEN{1'b0}} : lhs) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_CZERO_NEZ: result = (ENABLE_ZICOND_EXTENSION != 0) ? ((rhs != {XLEN{1'b0}}) ? {XLEN{1'b0}} : lhs) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_CLMUL:     result = b_result_clmul;
        `YH_rv_cpu_ALU_CLMULH:    result = b_result_clmulh;
        `YH_rv_cpu_ALU_PACK:      result = (ENABLE_ZBKB_EXTENSION != 0) ? {rhs[15:0], lhs[15:0]} : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_EXT_RANGE: result = x_result_ext_range;
        // 默认: 零
        default:             result = {XLEN{1'b0}};
    endcase
end

endmodule
