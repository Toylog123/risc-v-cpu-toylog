// ============================================================
// YH_rv_cpu_defs.vh
// Author: Toylog
// Version: v1.1
// Function: RISC-V RV32I/RV64I 指令编码和控制信号定义文件
// Description: 本文件定义了 CPU 核心使用的所有常量定义，包括：
//   - 指令操作码 (Opcode): 7位，用于指令译码
//   - ALU 操作码: 4位，控制算术逻辑单元执行的操作
//   - 写回来源控制: 2位，选择写回寄存器的数据来源
//   - 内存访存宽度: 2位，指定加载/存储操作的数据宽度
//   - CSR 操作类型: 2位，定义 CSR 寄存器的读写模式
//   - CSR 寄存器选择: 3位，编码访问哪个 CSR 寄存器
//   - CSR 寄存器地址: 12位，RISC-V 标准规定的 CSR 地址
//   - Trap 中断类型编码: 用于 mcause 寄存器的值
// ============================================================

`ifndef YH_rv_cpu_DEFS_VH
`define YH_rv_cpu_DEFS_VH

// ------------------------------------------------------------
// RISC-V 指令操作码定义 (7位 opcode)
// 用于指令译码阶段识别指令类型
// 每个 opcode 对应一类 RISC-V 指令
// ------------------------------------------------------------
// 加载指令 (Load): lb, lh, lw, lbu, lhu - 从内存读取数据
`define YH_rv_cpu_OPCODE_LOAD    7'b0000011
// 存储指令 (Store): sb, sh, sw - 向内存写入数据
`define YH_rv_cpu_OPCODE_STORE   7'b0100011
// 分支指令 (Branch): beq, bne, blt, bge, bltu, bgeu - 条件跳转
`define YH_rv_cpu_OPCODE_BRANCH  7'b1100011
// 跳转寄存器 (Jump and Link Register): jalr - 跳转到寄存器指定地址
`define YH_rv_cpu_OPCODE_JALR    7'b1100111
// 跳转立即数 (Jump and Link): jal - 跳转到立即数指定地址
`define YH_rv_cpu_OPCODE_JAL     7'b1101111
// 立即数运算 (OP-IMM): addi, slti, xori, ori, andi, slli, srli, srai
`define YH_rv_cpu_OPCODE_OP_IMM  7'b0010011
// 寄存器运算 (OP): add, sub, slt, sltu, xor, or, and, sll, srl, sra
`define YH_rv_cpu_OPCODE_OP      7'b0110011
`define YH_rv_cpu_OPCODE_CUSTOM_0 7'b0001011
// 32位立即数运算 (OP-IMM-32): addiw, slliw, srliw, sraiw - RV64 专用
`define YH_rv_cpu_OPCODE_OP_IMM_32 7'b0011011
// 32位寄存器运算 (OP-32): addw, subw, sllw, srlw, sraw - RV64 专用
`define YH_rv_cpu_OPCODE_OP_32   7'b0111011
// PC相对地址加 (Add Upper Immediate to PC): auipc - 构建 PC 相对地址
`define YH_rv_cpu_OPCODE_AUIPC   7'b0010111
// 高位立即数加载 (Load Upper Immediate): lui - 加载立即数到高位
`define YH_rv_cpu_OPCODE_LUI     7'b0110111
// 系统指令 (System): csrrw, csrrs, csrrc, ecall, ebreak, mret, wfi
`define YH_rv_cpu_OPCODE_MISC_MEM 7'b0001111
`define YH_rv_cpu_OPCODE_SYSTEM  7'b1110011

// ------------------------------------------------------------
// ALU 操作码定义 (4位)
// 控制算术逻辑单元执行的具体运算类型
// ------------------------------------------------------------
`define YH_rv_cpu_ALU_ADD   4'd0  // 加法: result = lhs + rhs (add, addi)
`define YH_rv_cpu_ALU_SUB   4'd1  // 减法: result = lhs - rhs (sub)
`define YH_rv_cpu_ALU_SLT   4'd2  // 有符号小于: result = (lhs < rhs) ? 1 : 0 (slt, slti)
`define YH_rv_cpu_ALU_SLTU  4'd3  // 无符号小于: result = (lhs < rhs) ? 1 : 0 (sltu, sltiu)
`define YH_rv_cpu_ALU_XOR   4'd4  // 异或: result = lhs ^ rhs (xor, xori)
`define YH_rv_cpu_ALU_OR    4'd5   // 或: result = lhs | rhs (or, ori)
`define YH_rv_cpu_ALU_AND   4'd6   // 与: result = lhs & rhs (and, andi)
`define YH_rv_cpu_ALU_SLL   4'd7   // 逻辑左移: result = lhs << rhs[4:0] (sll, slli)
`define YH_rv_cpu_ALU_SRL   4'd8   // 逻辑右移: result = lhs >> rhs[4:0] (srl, srli)
`define YH_rv_cpu_ALU_SRA   4'd9   // 算术右移: result = lhs >>> rhs[4:0], 保留符号位 (sra, srai)

// M扩展指令 (RV32M)
`define YH_rv_cpu_ALU_MUL   5'd10  // 有符号乘法: result = lhs * rhs (mul)
`define YH_rv_cpu_ALU_MULH  5'd11  // 有符号乘法高位: result = ($signed(lhs) * $signed(rhs))[63:32] (mulh)
`define YH_rv_cpu_ALU_MULHSU 5'd12 // 混合乘法高位: result = ($signed(lhs) * rhs)[63:32] (mulhsu)
`define YH_rv_cpu_ALU_MULHU  5'd13 // 无符号乘法高位: result = (lhs * rhs)[63:32] (mulhu)
`define YH_rv_cpu_ALU_DIV   5'd14  // 有符号除法: result = lhs / rhs (div)
`define YH_rv_cpu_ALU_DIVU  5'd15  // 无符号除法: result = lhs / rhs (divu)
`define YH_rv_cpu_ALU_REM   5'd16  // 有符号取模: result = lhs % rhs (rem)
`define YH_rv_cpu_ALU_REMU  5'd17  // 无符号取模: result = lhs % rhs (remu)

// Zba/Zbb/Zbs subset emitted by the CoreMark toolchain experiments.
`define YH_rv_cpu_ALU_SH1ADD 5'd18
`define YH_rv_cpu_ALU_SH2ADD 5'd19
`define YH_rv_cpu_ALU_SH3ADD 5'd20
`define YH_rv_cpu_ALU_ANDN   5'd21
`define YH_rv_cpu_ALU_MAX    5'd22
`define YH_rv_cpu_ALU_SEXT_H 5'd23
`define YH_rv_cpu_ALU_ZEXT_H 5'd24
`define YH_rv_cpu_ALU_BEXT   5'd25
`define YH_rv_cpu_ALU_CZERO_EQZ 5'd26
`define YH_rv_cpu_ALU_CZERO_NEZ 5'd27
`define YH_rv_cpu_ALU_CLMUL     5'd28
`define YH_rv_cpu_ALU_CLMULH    5'd29
`define YH_rv_cpu_ALU_PACK      5'd30
`define YH_rv_cpu_ALU_EXT_RANGE  5'd31
`define YH_rv_cpu_ALU_TH_ADDSL1  6'd32
`define YH_rv_cpu_ALU_TH_ADDSL2  6'd33
`define YH_rv_cpu_ALU_TH_ADDSL3  6'd34
`define YH_rv_cpu_ALU_TH_MVEQZ   6'd35
`define YH_rv_cpu_ALU_TH_MVNEZ   6'd36

// ------------------------------------------------------------
// 写回来源控制 (2位)
// 选择写回寄存器的数据来源
// ------------------------------------------------------------
`define YH_rv_cpu_WB_ALU    2'd0  // 从 ALU 结果写回 (大多数指令)
`define YH_rv_cpu_WB_MEM    2'd1  // 从内存加载数据写回 (load 指令)
`define YH_rv_cpu_WB_PC4    2'd2  // 从 PC+4 写回 (jal, jalr 指令)

// ------------------------------------------------------------
// 内存访存宽度 (2位)
// 指定加载/存储操作的数据宽度
// ------------------------------------------------------------
`define YH_rv_cpu_MEM_B     2'd0  // 字节 (8-bit): lb, lbu, sb
`define YH_rv_cpu_MEM_H     2'd1  // 半字 (16-bit): lh, lhu, sh
`define YH_rv_cpu_MEM_W     2'd2  // 字 (32-bit): lw, sw
`define YH_rv_cpu_MEM_D     2'd3  // 双字 (64-bit): ld, sd (RV64 专用)

// ------------------------------------------------------------
// CSR 操作类型 (2位)
// 定义 CSR 寄存器的读写模式
// ------------------------------------------------------------
`define YH_rv_cpu_CSR_RW    2'd0  // 读写: csrrw - 先写后读，返回旧值
`define YH_rv_cpu_CSR_RS    2'd1  // 读置位: csrrs - 读并置位某些位
`define YH_rv_cpu_CSR_RC    2'd2  // 读清除: csrrc - 读并清除某些位

// ------------------------------------------------------------
// CSR 寄存器选择信号 (3位)
// 编码访问哪个 CSR 寄存器
// ------------------------------------------------------------
`define YH_rv_cpu_CSR_SEL_NONE      3'd0  // 不访问 CSR
`define YH_rv_cpu_CSR_SEL_MSTATUS   3'd1  // mstatus: 机器状态寄存器
`define YH_rv_cpu_CSR_SEL_MIE       3'd2  // mie: 机器中断使能寄存器
`define YH_rv_cpu_CSR_SEL_MTVEC     3'd3  // mtvec: 机器中断向量基地址
`define YH_rv_cpu_CSR_SEL_MSCRATCH  3'd4  // mscratch: 机器临时寄存器
`define YH_rv_cpu_CSR_SEL_MEPC      3'd5  // mepc: 机器异常程序计数器
`define YH_rv_cpu_CSR_SEL_MCAUSE    3'd6  // mcause: 机器异常原因寄存器
`define YH_rv_cpu_CSR_SEL_MIP       3'd7  // mip: 机器中断待处理寄存器

// ------------------------------------------------------------
// CSR 寄存器地址定义 (12位)
// RISC-V 标准规定的 CSR 地址
// 详见 RISC-V Specification Volume II
// ------------------------------------------------------------
`define YH_rv_cpu_CSR_MSTATUS   12'h300  // mstatus: 机器状态寄存器
`define YH_rv_cpu_CSR_MIE       12'h304  // mie: 机器中断使能寄存器
`define YH_rv_cpu_CSR_MTVEC     12'h305  // mtvec: 机器中断向量基地址
`define YH_rv_cpu_CSR_MSCRATCH  12'h340  // mscratch: 机器临时寄存器
`define YH_rv_cpu_CSR_MEPC      12'h341  // mepc: 机器异常程序计数器
`define YH_rv_cpu_CSR_MCAUSE    12'h342  // mcause: 机器异常原因寄存器
`define YH_rv_cpu_CSR_MIP       12'h344  // mip: 机器中断待处理寄存器

// ------------------------------------------------------------
// CSR 关键位定义
// 用于设置和检查中断相关的控制位
// ------------------------------------------------------------
`define YH_rv_cpu_MSTATUS_MIE   32'h0000_0008  // MIE: 机器模式中断使能位
`define YH_rv_cpu_MSTATUS_MPIE  32'h0000_0080  // MPIE: 机器模式先前中断使能位
`define YH_rv_cpu_MIE_MTIE      32'h0000_0080  // MTIE: 机器定时器中断使能位
`define YH_rv_cpu_MIP_MTIP      32'h0000_0080  // MTIP: 机器定时器中断待处理位

// ------------------------------------------------------------
// Trap 中断类型编码
// 用于 mcause 寄存器的值
// 高位为1表示中断，为0表示异常
// ------------------------------------------------------------
`define YH_rv_cpu_TRAP_ILLEGAL_INSN      32'd2  // 非法指令异常
`define YH_rv_cpu_TRAP_BREAKPOINT        32'd3  // 断点异常 (ebreak 指令)
`define YH_rv_cpu_TRAP_LOAD_MISALIGNED   32'd4  // 加载地址对齐异常
`define YH_rv_cpu_TRAP_STORE_MISALIGNED  32'd6  // 存储地址对齐异常
`define YH_rv_cpu_TRAP_ECALL_MMODE       32'd11 // 机器模式 ecall 异常
`define YH_rv_cpu_TRAP_MTIME_INTERRUPT   32'h8000_0007 // 机器定时器中断 (高位=1 表示中断)

`endif
