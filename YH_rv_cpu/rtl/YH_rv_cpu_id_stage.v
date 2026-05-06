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
