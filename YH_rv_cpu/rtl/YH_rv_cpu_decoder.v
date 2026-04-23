`timescale 1ns / 1ps
// ============================================================
// YH_rv_cpu_decoder.v
// Author: Toylog
// Version: v1.2
// Function: RISC-V 指令译码器 (Instruction Decoder)
// Description: 译码阶段的核心模块，负责将 32 位指令字解析为控制信号
//   支持 RV32I 和 RV64I 指令集
//   支持RISC-V M扩展：乘法、除法、取余指令
//   输出包括：寄存器地址、操作数选择、ALU 控制、内存访问控制、分支跳转控制
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_decoder #(
    parameter integer XLEN = 32  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
) (
    // ------------------------------------------------------------
    // 指令输入
    // ------------------------------------------------------------
    input  wire [31:0]     instruction,     // 32 位指令字

    // ------------------------------------------------------------
    // 寄存器地址输出 (源/目标寄存器)
    // ------------------------------------------------------------
    output wire [4:0]      rs1_addr,        // 源寄存器 1 地址
    output wire [4:0]      rs2_addr,        // 源寄存器 2 地址
    output wire [4:0]      rd_addr,         // 目标寄存器地址

    // ------------------------------------------------------------
    // 寄存器访问使能信号
    // ------------------------------------------------------------
    output reg             rs1_en,          // rs1 读取使能
    output reg             rs2_en,          // rs2 读取使能
    output reg             rd_en,           // rd 写入使能

    // ------------------------------------------------------------
    // 指令合法性标志
    // ------------------------------------------------------------
    output reg             illegal,         // 非法指令标志

    // ------------------------------------------------------------
    // 立即数输出 (符号扩展到 XLEN 位)
    // ------------------------------------------------------------
    output reg  [XLEN-1:0] imm,             // 立即数 (I/S/B/U/J 型)

    // ------------------------------------------------------------
    // ALU 控制信号
    // ------------------------------------------------------------
    output reg  [4:0]      alu_op,          // ALU 操作码
    output reg             alu_src1_pc,     // ALU 源操作数 1 选择: 0=rs1, 1=PC
    output reg             alu_src2_imm,     // ALU 源操作数 2 选择: 0=rs2, 1=imm

    // ------------------------------------------------------------
    // 分支控制信号
    // ------------------------------------------------------------
    output reg             branch,          // 分支指令标志
    output reg  [2:0]      branch_funct3,    // 分支条件 funct3

    // ------------------------------------------------------------
    // 跳转控制信号
    // ------------------------------------------------------------
    output reg             jump,            // 跳转指令标志 (JAL/JALR)
    output reg             jalr,            // JALR 标志 (寄存器间接跳转)

    // ------------------------------------------------------------
    // 内存访问控制信号
    // ------------------------------------------------------------
    output reg             load,            // 加载指令标志
    output reg             store,           // 存储指令标志
    output reg  [1:0]      mem_size,         // 内存访问宽度: B/H/W/D
    output reg             mem_unsigned,     // 加载无符号扩展标志

    // ------------------------------------------------------------
    // Word 操作标志 (RV64 32 位字操作)
    // ------------------------------------------------------------
    output reg             word_op,         // 32 位字操作标志

    // ------------------------------------------------------------
    // LUI/AUIPC 标志
    // ------------------------------------------------------------
    output reg             is_lui,          // LUI 指令标志

    // ------------------------------------------------------------
    // 写回控制信号
    // ------------------------------------------------------------
    output reg  [1:0]      wb_sel,          // 写回数据选择

    // ------------------------------------------------------------
    // CSR 控制信号 (控制状态寄存器)
    // ------------------------------------------------------------
    output reg             csr_valid,        // CSR 指令标志
    output reg  [1:0]      csr_cmd,          // CSR 命令: RW/RS/RC
    output reg             csr_use_imm,      // CSR 立即数模式
    output reg  [2:0]      csr_sel,          // CSR 寄存器选择
    output reg             csr_read_valid,   // CSR 可读标志
    output reg             csr_write_allowed,// CSR 可写标志

    // ------------------------------------------------------------
    // 特权指令标志
    // ------------------------------------------------------------
    output reg             ecall,            // ecall 环境调用
    output reg             ebreak,           // ebreak 断点
    output reg             mret             // mret 从机器模式返回
);

    // ------------------------------------------------------------
    // 指令字段提取
    // opcode: 指令操作码 (bit[6:0])
    // funct3: 功能码 (bit[14:12])
    // funct7: 功能码 (bit[31:25], 用于区分同类指令的不同变体)
    // ------------------------------------------------------------
wire [6:0] opcode = instruction[6:0];
wire [2:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

    // ------------------------------------------------------------
    // 立即数生成 (符号扩展到 XLEN 位)
    //
    // I 型: 加载、立即数运算 (bit[31:20])
    // S 型: 存储 (bit[31:25] + bit[11:7])
    // B 型: 分支 (bit[31] + bit[7] + bit[30:25] + bit[11:8] + 0)
    // U 型: LUI/AUIPC (bit[31:12] + 12'b0)
    // J 型: JAL (bit[31] + bit[19:12] + bit[20] + bit[30:21] + 0)
    // ------------------------------------------------------------
wire [XLEN-1:0] imm_i = {{(XLEN-12){instruction[31]}}, instruction[31:20]};
wire [XLEN-1:0] imm_s = {{(XLEN-12){instruction[31]}}, instruction[31:25], instruction[11:7]};
wire [XLEN-1:0] imm_b = {{(XLEN-13){instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
wire [XLEN-1:0] imm_u = {{(XLEN-32){instruction[31]}}, instruction[31:12], 12'b0};
wire [XLEN-1:0] imm_j = {{(XLEN-21){instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    // ------------------------------------------------------------
    // 寄存器地址分配
    // ------------------------------------------------------------
assign rd_addr  = instruction[11:7];   // rd: bit[11:7]
assign rs1_addr = instruction[19:15];  // rs1: bit[19:15]
assign rs2_addr = instruction[24:20];  // rs2: bit[24:20]

    // ------------------------------------------------------------
    // 主译码进程
    // 根据 opcode 分支到对应的指令类型处理
    // ------------------------------------------------------------
always @* begin
    // 默认值初始化 (所有信号设为安全状态)
    rs1_en        = 1'b0;
    rs2_en        = 1'b0;
    rd_en         = 1'b0;
    illegal       = 1'b0;
    imm           = {XLEN{1'b0}};
    alu_op        = `YH_rv_cpu_ALU_ADD;  // 默认加法
    alu_src1_pc   = 1'b0;
    alu_src2_imm  = 1'b0;
    branch        = 1'b0;
    branch_funct3 = 3'b000;
    jump          = 1'b0;
    jalr          = 1'b0;
    load          = 1'b0;
    store         = 1'b0;
    wb_sel        = `YH_rv_cpu_WB_ALU;   // 默认写回 ALU 结果
    mem_size      = `YH_rv_cpu_MEM_W;    // 默认 32 位访问
    mem_unsigned  = 1'b0;
    word_op       = 1'b0;
    is_lui        = 1'b0;
    csr_valid     = 1'b0;
    csr_cmd       = `YH_rv_cpu_CSR_RW;
    csr_use_imm   = 1'b0;
    csr_sel       = `YH_rv_cpu_CSR_SEL_NONE;
    csr_read_valid = 1'b0;
    csr_write_allowed = 1'b0;
    ecall         = 1'b0;
    ebreak        = 1'b0;
    mret          = 1'b0;

    case (opcode)
        // ============================================================
        // LUI (Load Upper Immediate): 将立即数加载到 rd 高位
        // 格式: rd = imm_u << 12
        // ============================================================
        `YH_rv_cpu_OPCODE_LUI: begin
            rd_en  = 1'b1;
            is_lui = 1'b1;
            imm    = imm_u;
        end

        // ============================================================
        // AUIPC (Add Upper Immediate to PC): PC + 立即数高 20 位
        // 格式: rd = pc + (imm_u << 12)
        // ============================================================
        `YH_rv_cpu_OPCODE_AUIPC: begin
            rd_en        = 1'b1;
            imm          = imm_u;
            alu_src1_pc  = 1'b1;         // ALU 源操作数 1 = PC
            alu_src2_imm = 1'b1;         // ALU 源操作数 2 = imm
        end

        // ============================================================
        // JAL (Jump and Link): 相对跳转并保存返回地址
        // 格式: rd = pc + 4; pc = pc + imm_j
        // ============================================================
        `YH_rv_cpu_OPCODE_JAL: begin
            rd_en  = 1'b1;
            jump   = 1'b1;
            wb_sel = `YH_rv_cpu_WB_PC4;  // 写回 PC+4 (返回地址)
            imm    = imm_j;
        end

        // ============================================================
        // JALR (Jump and Link Register): 寄存器间接跳转
        // 格式: rd = pc + 4; pc = (rs1 + imm_i) & ~1
        // ============================================================
        `YH_rv_cpu_OPCODE_JALR: begin
            rd_en        = 1'b1;
            rs1_en       = 1'b1;
            jump         = 1'b1;
            jalr         = 1'b1;          // 标志为寄存器间接跳转
            wb_sel       = `YH_rv_cpu_WB_PC4;
            alu_src2_imm = 1'b1;
            imm          = imm_i;
            // JALR 必须 funct3=0，否则非法
            if (funct3 != 3'b000) begin
                illegal = 1'b1;
            end
        end

        // ============================================================
        // BRANCH: 条件分支指令
        // 支持: beq, bne, blt, bge, bltu, bgeu
        // ============================================================
        `YH_rv_cpu_OPCODE_BRANCH: begin
            rs1_en        = 1'b1;
            rs2_en        = 1'b1;
            branch        = 1'b1;
            branch_funct3 = funct3;
            imm           = imm_b;
            // blt/bltU/bge/bgeU (funct3=010/011) 在 RV32I 中保留
            if ((funct3 == 3'b010) || (funct3 == 3'b011)) begin
                illegal = 1'b1;
            end
        end

        // ============================================================
        // LOAD: 从内存加载数据到寄存器
        // 支持: lb, lh, lw, lbu, lhu (RV32)
        //       lb, lh, lw, ld, lbu, lhu, lwu (RV64)
        // ============================================================
        `YH_rv_cpu_OPCODE_LOAD: begin
            rd_en        = 1'b1;
            rs1_en       = 1'b1;
            load         = 1'b1;
            alu_src2_imm = 1'b1;          // 内存地址 = rs1 + imm
            wb_sel       = `YH_rv_cpu_WB_MEM; // 写回内存加载数据
            imm          = imm_i;

            case (funct3)
                3'b000: begin            // lb
                    mem_size     = `YH_rv_cpu_MEM_B;
                    mem_unsigned = 1'b0;
                end
                3'b001: begin            // lh
                    mem_size     = `YH_rv_cpu_MEM_H;
                    mem_unsigned = 1'b0;
                end
                3'b010: begin            // lw
                    mem_size     = `YH_rv_cpu_MEM_W;
                    mem_unsigned = 1'b0;
                end
                3'b011: begin            // ld (RV64 only)
                    if (XLEN == 64) begin
                        mem_size     = `YH_rv_cpu_MEM_D;
                        mem_unsigned = 1'b0;
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b100: begin            // lbu
                    mem_size     = `YH_rv_cpu_MEM_B;
                    mem_unsigned = 1'b1; // 无符号扩展
                end
                3'b101: begin            // lhu
                    mem_size     = `YH_rv_cpu_MEM_H;
                    mem_unsigned = 1'b1;
                end
                3'b110: begin            // lwu (RV64 only)
                    if (XLEN == 64) begin
                        mem_size     = `YH_rv_cpu_MEM_W;
                        mem_unsigned = 1'b1;
                    end else begin
                        illegal = 1'b1;
                    end
                end
                default: illegal = 1'b1;
            endcase
        end

        // ============================================================
        // STORE: 将寄存器数据存储到内存
        // 支持: sb, sh, sw (RV32), sb, sh, sw, sd (RV64)
        // ============================================================
        `YH_rv_cpu_OPCODE_STORE: begin
            rs1_en       = 1'b1;
            rs2_en       = 1'b1;
            store        = 1'b1;
            alu_src2_imm = 1'b1;
            imm          = imm_s;

            case (funct3)
                3'b000: mem_size = `YH_rv_cpu_MEM_B; // sb
                3'b001: mem_size = `YH_rv_cpu_MEM_H; // sh
                3'b010: mem_size = `YH_rv_cpu_MEM_W; // sw
                3'b011: begin                           // sd (RV64 only)
                    if (XLEN == 64) begin
                        mem_size = `YH_rv_cpu_MEM_D;
                    end else begin
                        illegal = 1'b1;
                    end
                end
                default: illegal = 1'b1;
            endcase
        end

        // ============================================================
        // OP-IMM: 立即数运算指令
        // 支持: addi, slti, sltiu, xori, ori, andi, slli, srli, srai
        // ============================================================
        `YH_rv_cpu_OPCODE_OP_IMM: begin
            rd_en        = 1'b1;
            rs1_en       = 1'b1;
            alu_src2_imm = 1'b1;          // 第二个 ALU 操作数为立即数
            imm          = imm_i;

            case (funct3)
                3'b000: alu_op = `YH_rv_cpu_ALU_ADD;    // addi
                3'b010: alu_op = `YH_rv_cpu_ALU_SLT;   // slti
                3'b011: alu_op = `YH_rv_cpu_ALU_SLTU;  // sltiu
                3'b100: alu_op = `YH_rv_cpu_ALU_XOR;   // xori
                3'b110: alu_op = `YH_rv_cpu_ALU_OR;    // ori
                3'b111: alu_op = `YH_rv_cpu_ALU_AND;   // andi
                3'b001: begin                           // slli
                    alu_op = `YH_rv_cpu_ALU_SLL;
                    // 移位量检查: RV64 使用 6 位移位量，RV32 使用 5 位
                    if (XLEN == 64) begin
                        if (instruction[31:26] != 6'b000000) begin
                            illegal = 1'b1;
                        end
                    end else if (funct7 != 7'b0000000) begin
                        illegal = 1'b1;
                    end
                end
                3'b101: begin                           // srli/srai
                    if (XLEN == 64) begin
                        if (instruction[31:26] == 6'b000000) begin
                            alu_op = `YH_rv_cpu_ALU_SRL; // srli
                        end else if (instruction[31:26] == 6'b010000) begin
                            alu_op = `YH_rv_cpu_ALU_SRA; // srai
                        end else begin
                            illegal = 1'b1;
                        end
                    end else begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SRL;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = `YH_rv_cpu_ALU_SRA;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                end
                default: illegal = 1'b1;
            endcase
        end

        // ============================================================
        // OP: 寄存器运算指令
        // 支持: add, sub, sll, slt, sltu, xor, srl, sra, or, and
        // M扩展: mul, mulh, mulhu, mulhsu, div, divu, rem, remu
        // ============================================================
        `YH_rv_cpu_OPCODE_OP: begin
            rd_en  = 1'b1;
            rs1_en = 1'b1;
            rs2_en = 1'b1;

            case (funct3)
                3'b000: begin                           // add/sub 或 MUL
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_ADD;    // add
                    end else if (funct7 == 7'b0100000) begin
                        alu_op = `YH_rv_cpu_ALU_SUB;    // sub
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_MUL;    // mul (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b001: begin                           // sll 或 MULH
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_SLL;   // sll
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_MULH;   // mulh (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b010: begin                           // slt 或 MULHSU (修正)
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_SLT;   // slt
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_MULHSU; // mulhsu (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b011: begin                           // sltu 或 MULHU (修正)
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_SLTU;  // sltu
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_MULHU; // mulhu (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b100: begin                           // xor 或 DIV
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_XOR;   // xor
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_DIV;   // div (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b101: begin                           // srl/sra 或 DIVU
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_SRL;   // srl
                    end else if (funct7 == 7'b0100000) begin
                        alu_op = `YH_rv_cpu_ALU_SRA;   // sra
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_DIVU;  // divu (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b110: begin                           // or 或 REM
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_OR;    // or
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_REM;   // rem (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                3'b111: begin                           // and 或 REMU
                    if (funct7 == 7'b0000000) begin
                        alu_op = `YH_rv_cpu_ALU_AND;   // and
                    end else if (funct7 == 7'b0000001) begin
                        alu_op = `YH_rv_cpu_ALU_REMU;  // remu (M扩展)
                    end else begin
                        illegal = 1'b1;
                    end
                end
                default: illegal = 1'b1;
            endcase
        end

        // ============================================================
        // OP-IMM-32: RV64 32 位立即数运算
        // 支持: addiw, slliw, srliw, sraiw
        // ============================================================
        `YH_rv_cpu_OPCODE_OP_IMM_32: begin
            if (XLEN != 64) begin
                // 这些指令只在 RV64 中有效
                illegal = 1'b1;
            end else begin
                rd_en        = 1'b1;
                rs1_en       = 1'b1;
                alu_src2_imm = 1'b1;
                imm          = imm_i;
                word_op      = 1'b1;          // 标志 32 位字操作

                case (funct3)
                    3'b000: alu_op = `YH_rv_cpu_ALU_ADD; // addiw
                    3'b001: begin                        // slliw
                        alu_op = `YH_rv_cpu_ALU_SLL;
                        if (funct7 != 7'b0000000) begin
                            illegal = 1'b1;
                        end
                    end
                    3'b101: begin                        // srliw/sraiw
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SRL;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = `YH_rv_cpu_ALU_SRA;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    default: illegal = 1'b1;
                endcase
            end
        end

        // ============================================================
        // OP-32: RV64 32 位寄存器运算
        // 支持: addw, subw, sllw, srlw, sraw
        // ============================================================
        `YH_rv_cpu_OPCODE_OP_32: begin
            if (XLEN != 64) begin
                illegal = 1'b1;
            end else begin
                rd_en   = 1'b1;
                rs1_en  = 1'b1;
                rs2_en  = 1'b1;
                word_op = 1'b1;

                case (funct3)
                    3'b000: begin                        // addw/subw
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_ADD;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = `YH_rv_cpu_ALU_SUB;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b001: begin                        // sllw
                        alu_op = `YH_rv_cpu_ALU_SLL;
                        if (funct7 != 7'b0000000) begin
                            illegal = 1'b1;
                        end
                    end
                    3'b101: begin                        // srlw/sraw
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SRL;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = `YH_rv_cpu_ALU_SRA;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    default: illegal = 1'b1;
                endcase
            end
        end

        // ============================================================
        // SYSTEM: 特权指令和 CSR 访问
        // 支持: ecall, ebreak, mret, csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
        // ============================================================
        `YH_rv_cpu_OPCODE_MISC_MEM: begin
            if ((funct3 != 3'b000) && (funct3 != 3'b001)) begin
                illegal = 1'b1;
            end
        end

        `YH_rv_cpu_OPCODE_SYSTEM: begin
            if (funct3 == 3'b000) begin
                // 环境调用/断点/返回指令 (无 CSR 操作数)
                case (instruction[31:20])
                    12'h000: ecall = 1'b1;   // ecall
                    12'h001: ebreak = 1'b1;  // ebreak
                    12'h302: mret = 1'b1;   // mret (从机器模式返回)
                    default: illegal = 1'b1;
                endcase

                // 这些指令不能有源/目标寄存器操作数
                if ((rs1_addr != 5'd0) || (rd_addr != 5'd0)) begin
                    illegal = 1'b1;
                end
            end else begin
                // CSR 访问指令
                csr_valid = 1'b1;
                rd_en = 1'b1;

                // CSR 寄存器选择
                case (instruction[31:20])
                    `YH_rv_cpu_CSR_MSTATUS: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_MSTATUS;
                        csr_read_valid = 1'b1;
                        csr_write_allowed = 1'b1;
                    end
                    `YH_rv_cpu_CSR_MIE: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_MIE;
                        csr_read_valid = 1'b1;
                        csr_write_allowed = 1'b1;
                    end
                    `YH_rv_cpu_CSR_MTVEC: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_MTVEC;
                        csr_read_valid = 1'b1;
                        csr_write_allowed = 1'b1;
                    end
                    `YH_rv_cpu_CSR_MSCRATCH: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_MSCRATCH;
                        csr_read_valid = 1'b1;
                        csr_write_allowed = 1'b1;
                    end
                    `YH_rv_cpu_CSR_MEPC: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_MEPC;
                        csr_read_valid = 1'b1;
                        csr_write_allowed = 1'b1;
                    end
                    `YH_rv_cpu_CSR_MCAUSE: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_MCAUSE;
                        csr_read_valid = 1'b1;
                        csr_write_allowed = 1'b1;
                    end
                    `YH_rv_cpu_CSR_MIP: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_MIP;
                        csr_read_valid = 1'b1;
                        csr_write_allowed = 1'b0;  // MIP 是只读的
                    end
                    default: begin
                        csr_sel = `YH_rv_cpu_CSR_SEL_NONE;
                        csr_read_valid = 1'b0;
                        csr_write_allowed = 1'b0;
                    end
                endcase

                // CSR 命令 (根据 funct3 编码)
                case (funct3)
                    3'b001: begin                       // csrrw: 写 (读后写)
                        rs1_en = 1'b1;
                        csr_cmd = `YH_rv_cpu_CSR_RW;
                    end
                    3'b010: begin                       // csrrs: 置位
                        rs1_en = 1'b1;
                        csr_cmd = `YH_rv_cpu_CSR_RS;
                    end
                    3'b011: begin                       // csrrc: 清除
                        rs1_en = 1'b1;
                        csr_cmd = `YH_rv_cpu_CSR_RC;
                    end
                    3'b101: begin                       // csrrwi: 立即数写
                        csr_cmd = `YH_rv_cpu_CSR_RW;
                        csr_use_imm = 1'b1;
                    end
                    3'b110: begin                       // csrrsi: 立即数置位
                        csr_cmd = `YH_rv_cpu_CSR_RS;
                        csr_use_imm = 1'b1;
                    end
                    3'b111: begin                       // csrrci: 立即数清除
                        csr_cmd = `YH_rv_cpu_CSR_RC;
                        csr_use_imm = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end
        end

        // ============================================================
        // 未知/非法操作码
        // ============================================================
        default: begin
            illegal = 1'b1;
        end
    endcase
end

endmodule
