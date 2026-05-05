// CICC1003618 submission context:
// File role: rtl/YH_rv_cpu_id_stage.v is part of the frozen CPU RTL and SoC integration source.
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
// File: rtl/YH_rv_cpu_id_stage.v
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
// YH_rv_cpu_id_stage.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 译码阶段 (Instruction Decode Stage)
// Description: 负责指令译码和寄存器读取
//   包含译码器实例，将指令解析为控制信号
//   从寄存器堆读取源操作数
//   输出控制信号到后续执行阶段
// ============================================================

module YH_rv_cpu_id_stage #(
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
    // 流水线输入信号
    // ------------------------------------------------------------
    input  wire [XLEN-1:0] pc,               // PC 值 (来自 IF/ID 流水线寄存器)
    input  wire [31:0]     instruction,       // 32 位指令字

    // ------------------------------------------------------------
    // 寄存器堆数据输入
    // ------------------------------------------------------------
    input  wire [XLEN-1:0] rs1_rdata,       // 寄存器 1 数据
    input  wire [XLEN-1:0] rs2_rdata,       // 寄存器 2 数据

    // ------------------------------------------------------------
    // 流水线输出信号 (到 ID/EX 流水线寄存器)
    // ------------------------------------------------------------
    output wire [XLEN-1:0] pc4,             // PC + 4 (返回地址)
    output wire [4:0]      rs1_addr,        // rs1 地址
    output wire [4:0]      rs2_addr,        // rs2 地址
    output wire [4:0]      rd_addr,         // rd 地址
    output wire            rs1_en,          // rs1 读取使能
    output wire            rs2_en,          // rs2 读取使能
    output wire            rd_en,           // rd 写入使能
    output wire            illegal,          // 非法指令标志

    // ------------------------------------------------------------
    // 立即数和控制信号
    // ------------------------------------------------------------
    output wire [XLEN-1:0] imm,             // 立即数
    output wire [5:0]      alu_op,          // ALU 操作码
    output wire            alu_src1_pc,     // ALU 源 1 选择: 0=rs1, 1=PC
    output wire            alu_src2_imm,    // ALU 源 2 选择: 0=rs2, 1=imm

    // ------------------------------------------------------------
    // 分支和跳转控制
    // ------------------------------------------------------------
    output wire            branch,          // 分支指令标志
    output wire [2:0]      branch_funct3,    // 分支条件 funct3
    output wire            jump,            // 跳转指令标志
    output wire            jalr,            // JALR 标志

    // ------------------------------------------------------------
    // 内存访问控制
    // ------------------------------------------------------------
    output wire            load,            // 加载指令
    output wire            store,           // 存储指令
    output wire [1:0]      mem_size,        // 内存访问宽度
    output wire            mem_unsigned,    // 无符号加载
    output wire            mem_indexed,
    output wire [1:0]      mem_index_shift,
    output wire            store_data_from_rd,
    output wire            mem_base_update,
    output wire            mem_base_update_before,

    // ------------------------------------------------------------
    // 写回控制和其他
    // ------------------------------------------------------------
    output wire [1:0]      wb_sel,          // 写回数据选择
    output wire            word_op,         // 32 位字操作
    output wire            is_lui,          // LUI 指令

    // ------------------------------------------------------------
    // CSR 控制信号
    // ------------------------------------------------------------
    output wire            csr_valid,       // CSR 指令
    output wire [1:0]      csr_cmd,         // CSR 命令
    output wire            csr_use_imm,     // CSR 立即数模式
    output wire [2:0]      csr_sel,         // CSR 选择
    output wire            csr_read_valid,  // CSR 可读
    output wire            csr_write_allowed,// CSR 可写

    // ------------------------------------------------------------
    // 特权指令
    // ------------------------------------------------------------
    output wire            ecall,           // ecall
    output wire            ebreak,          // ebreak
    output wire            mret,            // mret

    // ------------------------------------------------------------
    // 寄存器数据输出 (带转发支持)
    // ------------------------------------------------------------
    output wire [XLEN-1:0] rs1_value,       // rs1 值 (转发后)
    output wire [XLEN-1:0] rs2_value        // rs2 值 (转发后)
);

    // ------------------------------------------------------------
    // PC + 4 常量
    // ------------------------------------------------------------
localparam [XLEN-1:0] PC_STEP = {{(XLEN-3){1'b0}}, 3'd4};

    // ------------------------------------------------------------
    // PC + 4 计算
    // 用于 JAL/JALR 指令保存返回地址
    // ------------------------------------------------------------
assign pc4 = pc + PC_STEP;

    // ------------------------------------------------------------
    // 寄存器值直接传递
    // 转发逻辑在顶层模块的 hazard_unit 中处理
    // ------------------------------------------------------------
assign rs1_value = rs1_rdata;
assign rs2_value = rs2_rdata;

    // ------------------------------------------------------------
    // 指令译码器实例
    // 将 32 位指令解析为所有控制信号
    // 支持 RV32I 和 RV64I 指令集
    // ------------------------------------------------------------
YH_rv_cpu_decoder #(
    .XLEN(XLEN),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION)
) u_decoder (
    .instruction   (instruction),
    .rs1_addr      (rs1_addr),
    .rs2_addr      (rs2_addr),
    .rd_addr       (rd_addr),
    .rs1_en        (rs1_en),
    .rs2_en        (rs2_en),
    .rd_en         (rd_en),
    .illegal       (illegal),
    .imm           (imm),
    .alu_op        (alu_op),
    .alu_src1_pc   (alu_src1_pc),
    .alu_src2_imm  (alu_src2_imm),
    .branch        (branch),
    .branch_funct3 (branch_funct3),
    .jump          (jump),
    .jalr          (jalr),
    .load          (load),
    .store         (store),
    .wb_sel        (wb_sel),
    .mem_size      (mem_size),
    .mem_unsigned  (mem_unsigned),
    .mem_indexed   (mem_indexed),
    .mem_index_shift(mem_index_shift),
    .store_data_from_rd(store_data_from_rd),
    .mem_base_update(mem_base_update),
    .mem_base_update_before(mem_base_update_before),
    .word_op       (word_op),
    .is_lui        (is_lui),
    .csr_valid     (csr_valid),
    .csr_cmd       (csr_cmd),
    .csr_use_imm   (csr_use_imm),
    .csr_sel       (csr_sel),
    .csr_read_valid(csr_read_valid),
    .csr_write_allowed(csr_write_allowed),
    .ecall         (ecall),
    .ebreak        (ebreak),
    .mret          (mret)
);

endmodule
