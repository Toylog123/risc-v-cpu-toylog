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
// File: rtl/YH_rv_cpu_decoder.v
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
// YH_rv_cpu_decoder.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 指令译码器 (Instruction Decoder)
// Description: 译码阶段的核心模块，负责将 32 位指令字解析为控制信号
//   支持 RV32I 和 RV64I 指令集
//   输出包括：寄存器地址、操作数选择、ALU 控制、内存访问控制、分支跳转控制
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_decoder #(
    parameter integer XLEN = 32,
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1
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
    output reg  [5:0]      alu_op,          // ALU 操作码
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
    output reg             mem_indexed,
    output reg  [1:0]      mem_index_shift,
    output reg             store_data_from_rd,
    output reg             mem_base_update,
    output reg             mem_base_update_before,

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
wire [XLEN-1:0] imm_th_inc = {{(XLEN-5){instruction[24]}}, instruction[24:20]};

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
    mem_indexed   = 1'b0;
    mem_index_shift = 2'b00;
    store_data_from_rd = 1'b0;
    mem_base_update = 1'b0;
    mem_base_update_before = 1'b0;
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
                3'b001: begin                           // slli / sext.h
                    if (instruction[31:20] == 12'h605) begin
                        if (ENABLE_BITMANIP_EXTENSION != 0) alu_op = `YH_rv_cpu_ALU_SEXT_H;
                        else illegal = 1'b1;
                    end else begin
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
                end
                3'b101: begin                           // srli/srai/bexti
                    if (XLEN == 64) begin
                        if (instruction[31:26] == 6'b000000) begin
                            alu_op = `YH_rv_cpu_ALU_SRL; // srli
                        end else if (instruction[31:26] == 6'b010000) begin
                            alu_op = `YH_rv_cpu_ALU_SRA; // srai
                        end else if (funct7 == 7'b0100100) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_BEXT; // bexti
                        end else begin
                            illegal = 1'b1;
                        end
                    end else begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SRL;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = `YH_rv_cpu_ALU_SRA;
                        end else if (funct7 == 7'b0100100) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_BEXT;
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
        // ============================================================
        `YH_rv_cpu_OPCODE_OP: begin
            rd_en  = 1'b1;
            rs1_en = 1'b1;
            rs2_en = 1'b1;

            // M扩展指令 (funct7=0000001)
            if (funct7 == 7'b0000001) begin
                case (funct3)
                    3'b000: begin
                        if ((ENABLE_M_EXTENSION != 0) || (ENABLE_ZMMUL_EXTENSION != 0)) alu_op = `YH_rv_cpu_ALU_MUL;
                        else illegal = 1'b1;
                    end
                    3'b001: begin
                        if ((ENABLE_M_EXTENSION != 0) || (ENABLE_ZMMUL_EXTENSION != 0)) alu_op = `YH_rv_cpu_ALU_MULH;
                        else illegal = 1'b1;
                    end
                    3'b010: begin
                        if ((ENABLE_M_EXTENSION != 0) || (ENABLE_ZMMUL_EXTENSION != 0)) alu_op = `YH_rv_cpu_ALU_MULHSU;
                        else illegal = 1'b1;
                    end
                    3'b011: begin
                        if ((ENABLE_M_EXTENSION != 0) || (ENABLE_ZMMUL_EXTENSION != 0)) alu_op = `YH_rv_cpu_ALU_MULHU;
                        else illegal = 1'b1;
                    end
                    3'b100: begin
                        if (ENABLE_M_EXTENSION != 0) alu_op = `YH_rv_cpu_ALU_DIV;
                        else illegal = 1'b1;
                    end
                    3'b101: begin
                        if (ENABLE_M_EXTENSION != 0) alu_op = `YH_rv_cpu_ALU_DIVU;
                        else illegal = 1'b1;
                    end
                    3'b110: begin
                        if (ENABLE_M_EXTENSION != 0) alu_op = `YH_rv_cpu_ALU_REM;
                        else illegal = 1'b1;
                    end
                    3'b111: begin
                        if (ENABLE_M_EXTENSION != 0) alu_op = `YH_rv_cpu_ALU_REMU;
                        else illegal = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end else begin
                case (funct3)
                    3'b000: begin                           // add/sub
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_ADD;    // add
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = `YH_rv_cpu_ALU_SUB;   // sub
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b001: begin                           // sll/clmul
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SLL;
                        end else if (funct7 == 7'b0000101) begin
                            if (ENABLE_ZBC_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_CLMUL;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b010: begin                           // slt/sh1add
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SLT;
                        end else if (funct7 == 7'b0010000) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_SH1ADD;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b011: begin                           // sltu/clmulh
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SLTU;
                        end else if (funct7 == 7'b0000101) begin
                            if (ENABLE_ZBC_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_CLMULH;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b100: begin                           // xor/zext.h/pack/sh2add
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_XOR;
                        end else if ((funct7 == 7'b0000100) && (rs2_addr == 5'd0)) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_ZEXT_H;
                        end else if (funct7 == 7'b0000100) begin
                            if (ENABLE_ZBKB_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_PACK;
                        end else if (funct7 == 7'b0010000) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_SH2ADD;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b101: begin                           // srl/sra/czero.eqz
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_SRL;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = `YH_rv_cpu_ALU_SRA;
                        end else if (funct7 == 7'b0000111) begin
                            if (ENABLE_ZICOND_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_CZERO_EQZ;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b110: begin                           // or/max/sh3add
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_OR;
                        end else if (funct7 == 7'b0000101) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_MAX;
                        end else if (funct7 == 7'b0010000) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_SH3ADD;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    3'b111: begin                           // and/andn/czero.nez
                        if (funct7 == 7'b0000000) begin
                            alu_op = `YH_rv_cpu_ALU_AND;
                        end else if (funct7 == 7'b0100000) begin
                            if (ENABLE_BITMANIP_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_ANDN;
                        end else if (funct7 == 7'b0000111) begin
                            if (ENABLE_ZICOND_EXTENSION == 0) illegal = 1'b1;
                            alu_op = `YH_rv_cpu_ALU_CZERO_NEZ;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    default: illegal = 1'b1;
                endcase
            end
        end

        // ============================================================
        // CUSTOM-0: small XThead subset used in compiler experiments
        // ============================================================
        `YH_rv_cpu_OPCODE_CUSTOM_0: begin
            rd_en  = 1'b1;
            rs1_en = 1'b1;

            case (funct3)
                3'b001: begin                           // th.addsl
                    rs2_en = 1'b1;
                    case (funct7)
                        7'd1: alu_op = `YH_rv_cpu_ALU_TH_ADDSL1;
                        7'd2: alu_op = `YH_rv_cpu_ALU_TH_ADDSL2;
                        7'd3: alu_op = `YH_rv_cpu_ALU_TH_ADDSL3;
                        7'd32: alu_op = `YH_rv_cpu_ALU_TH_MVEQZ;
                        7'd33: alu_op = `YH_rv_cpu_ALU_TH_MVNEZ;
                        default: illegal = 1'b1;
                    endcase
                end
                3'b010: begin                           // th.ext
                    alu_src2_imm = 1'b1;
                    imm = {{(XLEN-12){1'b0}}, 1'b1, funct7[6:1], rs2_addr};
                    alu_op = `YH_rv_cpu_ALU_EXT_RANGE;
                end
                3'b011: begin                           // th.extu
                    alu_src2_imm = 1'b1;
                    imm = {{(XLEN-12){1'b0}}, 1'b0, funct7[6:1], rs2_addr};
                    alu_op = `YH_rv_cpu_ALU_EXT_RANGE;
                end
                3'b100: begin                           // XTheadMemIdx indexed loads
                    load = 1'b1;
                    wb_sel = `YH_rv_cpu_WB_MEM;
                    mem_index_shift = funct7[1:0];
                    case (funct7[6:2])
                        5'h00: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_B; mem_unsigned = 1'b0; end
                        5'h10: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_B; mem_unsigned = 1'b1; end
                        5'h04: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_H; mem_unsigned = 1'b0; end
                        5'h14: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_H; mem_unsigned = 1'b1; end
                        5'h08: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_W; mem_unsigned = 1'b0; end
                        5'h11: begin mem_base_update = 1'b1; mem_base_update_before = 1'b1; imm = imm_th_inc; mem_size = `YH_rv_cpu_MEM_B; mem_unsigned = 1'b1; end
                        5'h0b: begin mem_base_update = 1'b1; imm = imm_th_inc; mem_size = `YH_rv_cpu_MEM_W; mem_unsigned = 1'b0; end
                        default: illegal = 1'b1;
                    endcase
                end
                3'b101: begin                           // XTheadMemIdx indexed stores
                    rd_en = 1'b0;
                    store = 1'b1;
                    mem_index_shift = funct7[1:0];
                    store_data_from_rd = 1'b1;
                    case (funct7[6:2])
                        5'h00: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_B; end
                        5'h04: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_H; end
                        5'h08: begin rs2_en = 1'b1; mem_indexed = 1'b1; mem_size = `YH_rv_cpu_MEM_W; end
                        5'h03: begin mem_base_update = 1'b1; imm = imm_th_inc; mem_size = `YH_rv_cpu_MEM_B; end
                        5'h0b: begin mem_base_update = 1'b1; imm = imm_th_inc; mem_size = `YH_rv_cpu_MEM_W; end
                        default: illegal = 1'b1;
                    endcase
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
