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
    parameter integer XLEN = 32  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
) (
    // 控制信号输入
    input  wire [3:0]      alu_op,    // ALU 操作码，定义在 YH_rv_cpu_defs.vh
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
        // 默认: 零
        // 当 alu_op 无效时返回 0
        default:             result = {XLEN{1'b0}};
    endcase
end

endmodule
