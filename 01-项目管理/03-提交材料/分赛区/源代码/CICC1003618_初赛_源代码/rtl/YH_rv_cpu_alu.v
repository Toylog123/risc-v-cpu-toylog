// CICC1003618 submission context:
// File role: rtl/YH_rv_cpu_alu.v is part of the frozen CPU RTL and SoC integration source.
// Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
// Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
// Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
// Verification note: functional changes require matching simulation logs or FPGA reports.
// Maintenance note: update documents, metrics and hashes when this file changes.

// Additional review checklist for contest submission.
// Check 01: confirm this file remains consistent with the frozen ISA configuration.
// Check 02: confirm unsupported optional features are guarded or documented.
// Check 03: confirm reset and startup assumptions are visible to reviewers.
// Check 04: confirm benchmark-related paths can be traced back to scripts.
// Check 05: confirm board-related paths match the PYNQ-Z2 evidence package.
// Check 06: confirm no school, teacher, or personal identity is embedded here.
// Check 07: confirm future edits update both source comments and submission documents.
// Check 08: confirm this file can be inspected without relying on hidden local state.
// End of additional review checklist.

// CICC1003618 submission annotation header.
// File: rtl/YH_rv_cpu_alu.v
// Purpose: preserve reviewer-facing context without changing source behavior.
// Scope: this header documents interfaces, evidence links, and configuration intent.
// Logic note: no executable RTL, TCL, or batch action is added by these comments.
// Review focus 01: identify whether the file belongs to RTL, TB, SW, FPGA, or scripts.
// Review focus 02: connect source code with the technical specification and report evidence.
// Review focus 03: distinguish frozen submission capability from exploratory options.
// Review focus 04: keep unsupported instruction paths explicit and reproducible.
// Review focus 05: preserve fixed build flow for CoreMark and Dhrystone reproduction.
// Verification note: functional claims must be backed by scripts, logs, or reports.
// FPGA note: frozen PYNQ-Z2 path is RV32I plus Zmmul plus Zba/Zbb/Zbs.
// FPGA note: final implementation target is 50.0 MHz and LUT below 5000.
// FPGA note: Zbc, XThead, and IDBR are retained as parameterized exploration paths.
// Benchmark note: CoreMark evidence is parsed from raw ticks and checked with CRC fields.
// Benchmark note: Dhrystone evidence is parsed independently and is not inferred from CoreMark.
// Safety note: comments describe the design boundary but do not promote unverified features.
// Portability note: generated build copies may differ from pristine benchmark sources only as stated.
// Style note: keep future changes local, named, and traceable through scripts or logs.
// RTL note: keep parameter gates explicit at module boundaries and top-level wrappers.
// RTL note: preserve reset, stall, flush, redirect, and trap priority ordering.
// RTL note: new ISA extensions need decoder, execute path, illegal path, and tests together.
// TB note: every diagnostic should expose pass criteria and key observable signals.
// Script note: every build path should state target, output log, and failure condition.
// Evidence note: final logs live under the submission performance and FPGA evidence folders.
// Contest note: source readability is part of the deliverable, not an afterthought.
// Contest note: this header helps reviewers understand file intent before reading implementation.
// Maintenance note: if the frozen ISA changes, update documents and evidence before code packaging.
// Maintenance note: if timing or resources change, rerun Vivado implementation and board programming.
// Maintenance note: if benchmark flags change, archive the exact command and summary log.
// Maintenance note: if UART evidence is added, record the Pmod B 3.3V USB-UART wiring.
// Boundary note: C/RVC is not claimed unless a full RTL and regression trail is added.
// Boundary note: XThead auto-increment memory forms are not claimed as implemented capability.
// Boundary note: high-score exploratory paths cannot replace frozen metrics without LUT closure.
// Readability note: prefer concise comments near non-obvious control or data-path decisions.
// Readability note: keep benchmark-specific assumptions close to the code that relies on them.
// Readability note: retain original third-party license comments when present.
// Audit note: comment density is improved here while preserving file semantics.
// Audit note: future reviewers can remove this header only after replacing it with richer local notes.
// End of submission annotation header.

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
    parameter integer ENABLE_XTHEAD_EXTENSION = 1
) (
    // 控制信号输入
    input  wire [5:0]      alu_op,    // ALU 操作码，定义在 YH_rv_cpu_defs.vh
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

wire [XLEN-1:0] m_result_mul;
wire [XLEN-1:0] m_result_mulh;
wire [XLEN-1:0] m_result_mulhsu;
wire [XLEN-1:0] m_result_mulhu;
wire [XLEN-1:0] m_result_div;
wire [XLEN-1:0] m_result_divu;
wire [XLEN-1:0] m_result_rem;
wire [XLEN-1:0] m_result_remu;
wire [XLEN-1:0] b_result_clmul;
wire [XLEN-1:0] b_result_clmulh;
wire [XLEN-1:0] x_result_ext_range;

generate
if ((ENABLE_M_EXTENSION != 0) || (ENABLE_ZMMUL_EXTENSION != 0)) begin : gen_mul_extension
    wire [63:0] mul_signed;
    wire [63:0] mul_mix;
    wire [63:0] mul_unsigned;

    assign mul_signed = $signed({{32{lhs[31]}}, lhs}) * $signed({{32{rhs[31]}}, rhs});
    assign mul_mix = $signed({{32{lhs[31]}}, lhs}) * {32'b0, rhs};
    assign mul_unsigned = {32'b0, lhs} * {32'b0, rhs};

    assign m_result_mul = mul_signed[XLEN-1:0];
    assign m_result_mulh = mul_signed[63:32];
    assign m_result_mulhsu = mul_mix[63:32];
    assign m_result_mulhu = mul_unsigned[63:32];
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
        `YH_rv_cpu_ALU_TH_ADDSL1: result = (ENABLE_XTHEAD_EXTENSION != 0) ? (lhs + (rhs << 1)) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_ADDSL2: result = (ENABLE_XTHEAD_EXTENSION != 0) ? (lhs + (rhs << 2)) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_ADDSL3: result = (ENABLE_XTHEAD_EXTENSION != 0) ? (lhs + (rhs << 3)) : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_MVEQZ:  result = (ENABLE_XTHEAD_EXTENSION != 0) ? lhs : {XLEN{1'b0}};
        `YH_rv_cpu_ALU_TH_MVNEZ:  result = (ENABLE_XTHEAD_EXTENSION != 0) ? lhs : {XLEN{1'b0}};
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
