`timescale 1ns / 1ps
// ============================================================
// YH_rv_cpu.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V RV32I/RV64I 处理器核顶层模块
// Description: 五级流水线 RISC-V CPU 内核，负责：
//   - 五级流水线组织 (IF/ID/EX/MEM/WB)
//   - 流水线寄存器管理与控制
//   - CSR 寄存器控制 (mstatus/mie/mtvec/mepc/mcause/mscratch/mip)
//   - 异常/中断处理
//   - 加载使用冒险检测与数据转发
//   - 指令/数据存储器接口管理
// 支持参数化配置：
//   - XLEN: 32 (RV32) 或 64 (RV64)
//   - IMEM_SYNC/DMEM_SYNC: 同步/异步内存访问模式
//   - IMEM_OUTPUT_REG: 指令存储器输出寄存器配置
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu #(
    parameter integer XLEN = 32,           // 数据通路宽度: 32 (RV32) 或 64 (RV64)
    parameter integer IMEM_SYNC = 0,        // 指令存储器同步模式
    parameter integer IMEM_OUTPUT_REG = 0,  // 指令存储器输出寄存器
    parameter integer DMEM_SYNC = 0,        // 数据存储器同步模式
    parameter integer DCACHE_EN = 0,        // 数据缓存使能: 0=禁用, 1=启用
    parameter integer C_EXT = 0,            // C扩展 (压缩指令) 支持: 0=禁用, 1=启用 (预留)
    parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}}  // 复位向量地址
) (
    // ------------------------------------------------------------
    // 时钟和复位
    // ------------------------------------------------------------
    input  wire            clk,              // 时钟信号
    input  wire            rst_n,            // 异步低有效复位

    // ------------------------------------------------------------
    // 中断信号
    // ------------------------------------------------------------
    input  wire            timer_irq,        // 定时器中断请求

    // ------------------------------------------------------------
    // 指令存储器接口
    // ------------------------------------------------------------
    output wire            imem_req,         // 取指请求
    output wire [XLEN-1:0] imem_addr,       // 取指地址
    input  wire [31:0]     imem_rdata,      // 指令数据
    input  wire            imem_rvalid,      // 取指有效

    // ------------------------------------------------------------
    // 数据存储器接口
    // ------------------------------------------------------------
    output wire [XLEN-1:0] dmem_addr,       // 访存地址
    input  wire [XLEN-1:0] dmem_rdata,      // 加载数据
    input  wire            dmem_rvalid,      // 加载有效
    output wire            dmem_read_req,     // 读请求
    output wire [XLEN-1:0] dmem_wdata,      // 写数据
    output wire [XLEN/8-1:0] dmem_wstrb,   // 写字节使能

    // ------------------------------------------------------------
    // 调试和状态信号
    // ------------------------------------------------------------
    output wire            trap,             // trap 标志
    output wire [XLEN-1:0] debug_pc         // 调试 PC 值
);

    // ================================================================
    // 流水线寄存器定义
    // ================================================================

    // ------------------------------------------------------------
    // PC 和取指阶段相关寄存器
    // ------------------------------------------------------------
reg [XLEN-1:0] pc_r;                    // PC 寄存器
reg            trap_r;                  // trap 状态标志
reg [XLEN-1:0] fetch_pc_r;             // 取指 PC (用于同步内存)
reg [XLEN-1:0] fetch_pc_d1_r;          // 取指 PC 延迟 1 拍
reg            fetch_valid_r;           // 取指有效标志
reg            fetch_valid_d1_r;       // 取指有效延迟 1 拍
reg [1:0]      fetch_drop_count_r;     // 取指丢弃计数 (用于流水线冲刷)
reg            fetch_buf0_valid_r;      // 取指缓冲区 0 有效
reg [XLEN-1:0] fetch_buf0_pc_r;       // 取指缓冲区 0 PC
reg [31:0]     fetch_buf0_instruction_r; // 取指缓冲区 0 指令
reg            fetch_buf1_valid_r;      // 取指缓冲区 1 有效
reg [XLEN-1:0] fetch_buf1_pc_r;       // 取指缓冲区 1 PC
reg [31:0]     fetch_buf1_instruction_r; // 取指缓冲区 1 指令

    // ------------------------------------------------------------
    // IF/ID 流水线寄存器
    // 传递取指阶段的指令到译码阶段
    // ------------------------------------------------------------
(* max_fanout = 16 *) reg            if_id_valid_r;       // IF/ID 有效
reg [XLEN-1:0] if_id_pc_r;                          // IF/ID PC
reg [31:0]     if_id_instruction_r;                  // IF/ID 指令

    // ------------------------------------------------------------
    // ID/EX 流水线寄存器
    // 传递译码阶段的控制信号到执行阶段
    // ------------------------------------------------------------
reg            id_ex_valid_r;                        // ID/EX 有效
reg [XLEN-1:0] id_ex_pc_r;                         // ID/EX PC
reg [XLEN-1:0] id_ex_pc4_r;                        // ID/EX PC+4
reg [4:0]      id_ex_rs1_addr_r;                  // rs1 地址
reg [4:0]      id_ex_rs2_addr_r;                  // rs2 地址
reg [4:0]      id_ex_rd_addr_r;                   // rd 地址
reg            id_ex_rs1_en_r;                      // rs1 读使能
reg            id_ex_rs2_en_r;                      // rs2 读使能
reg            id_ex_rd_en_r;                       // rd 写使能
reg            id_ex_illegal_r;                     // 非法指令
reg [XLEN-1:0] id_ex_rs1_value_r;                  // rs1 值
reg [XLEN-1:0] id_ex_rs2_value_r;                  // rs2 值
reg [XLEN-1:0] id_ex_imm_r;                       // 立即数
(* max_fanout = 16 *) reg [4:0]      id_ex_alu_op_r;   // ALU 操作码
reg            id_ex_alu_src1_pc_r;                  // ALU 源 1 选择
reg            id_ex_alu_src2_imm_r;                 // ALU 源 2 选择
reg            id_ex_branch_r;                       // 分支标志
reg [2:0]      id_ex_branch_funct3_r;               // 分支条件
reg            id_ex_jump_r;                         // 跳转标志
reg            id_ex_jalr_r;                        // JALR 标志
reg            id_ex_load_r;                         // 加载标志
reg            id_ex_store_r;                        // 存储标志
reg [1:0]      id_ex_wb_sel_r;                     // 写回选择
reg [1:0]      id_ex_mem_size_r;                   // 内存访问宽度
reg            id_ex_mem_unsigned_r;                 // 无符号加载
reg            id_ex_word_op_r;                     // 32 位字操作
(* max_fanout = 8 *) reg            id_ex_is_lui_r;   // LUI 标志
reg            id_ex_csr_valid_r;                   // CSR 指令
reg [1:0]      id_ex_csr_cmd_r;                    // CSR 命令
reg            id_ex_csr_use_imm_r;                 // CSR 立即数模式
reg [2:0]      id_ex_csr_sel_r;                    // CSR 选择
reg            id_ex_csr_read_valid_r;               // CSR 可读
reg            id_ex_csr_write_allowed_r;            // CSR 可写
reg            id_ex_ecall_r;                       // ecall
reg            id_ex_ebreak_r;                      // ebreak
reg            id_ex_mret_r;                        // mret

    // ------------------------------------------------------------
    // EX/MEM 流水线寄存器
    // 传递执行阶段的结果到访存阶段
    // ------------------------------------------------------------
reg            ex_mem_valid_r;                      // EX/MEM 有效
reg [XLEN-1:0] ex_mem_pc4_r;                      // EX/MEM PC+4
reg [4:0]      ex_mem_rd_addr_r;                   // rd 地址
(* max_fanout = 8 *) reg            ex_mem_rd_en_r; // rd 写使能
reg [1:0]      ex_mem_wb_sel_r;                   // 写回选择
reg            ex_mem_load_r;                       // 加载
reg            ex_mem_store_r;                      // 存储
reg [1:0]      ex_mem_mem_size_r;                 // 内存访问宽度
reg            ex_mem_mem_unsigned_r;               // 无符号加载
reg [XLEN-1:0] ex_mem_exec_result_r;              // 执行结果
reg [XLEN-1:0] ex_mem_mem_addr_r;                // 内存地址
reg [XLEN-1:0] ex_mem_store_data_r;              // 存储数据
reg [XLEN/8-1:0] ex_mem_store_wstrb_r;           // 写字节使能

    // ------------------------------------------------------------
    // MEM/WB 流水线寄存器
    // 传递访存阶段的结果到写回阶段
    // ------------------------------------------------------------
reg            mem_wb_valid_r;                      // MEM/WB 有效
reg [XLEN-1:0] mem_wb_pc4_r;                     // MEM/WB PC+4
(* max_fanout = 8 *) reg [4:0]      mem_wb_rd_addr_r; // rd 地址
(* max_fanout = 8 *) reg            mem_wb_rd_en_r;  // rd 写使能
reg [1:0]      mem_wb_wb_sel_r;                  // 写回选择
reg [XLEN-1:0] mem_wb_exec_result_r;            // 执行结果
reg [XLEN-1:0] mem_wb_load_data_r;              // 加载数据

    // ================================================================
    // 组合逻辑信号定义
    // ================================================================

wire [XLEN-1:0] if_pc_next;                    // 下一 PC

    // 译码阶段输出信号
wire [XLEN-1:0] id_pc4;
wire [4:0]      id_rs1_addr;
wire [4:0]      id_rs2_addr;
wire [4:0]      id_rd_addr;
wire            id_rs1_en;
wire            id_rs2_en;
wire            id_rd_en;
wire            id_illegal;
wire [XLEN-1:0] id_imm;
wire [4:0]      id_alu_op;
wire            id_alu_src1_pc;
wire            id_alu_src2_imm;
wire            id_branch;
wire [2:0]      id_branch_funct3;
wire            id_jump;
wire            id_jalr;
wire            id_load;
wire            id_store;
wire [1:0]      id_wb_sel;
wire [1:0]      id_mem_size;
wire            id_mem_unsigned;
wire            id_word_op;
wire            id_is_lui;
wire            id_csr_valid;
wire [1:0]      id_csr_cmd;
wire            id_csr_use_imm;
wire [2:0]      id_csr_sel;
wire            id_csr_read_valid;
wire            id_csr_write_allowed;
wire            id_ecall;
wire            id_ebreak;
wire            id_mret;
wire [XLEN-1:0] id_rs1_value;
wire [XLEN-1:0] id_rs2_value;
wire            id_branch_beq_bne;
wire            id_branch_decode_rs1_pending;
wire            id_branch_decode_rs2_pending;
wire            id_branch_decode_operands_ready;
wire            id_branch_decode_taken;
wire            id_branch_decode_redirect_valid;
wire [XLEN-1:0] id_branch_decode_redirect_pc;

    // 寄存器堆信号
wire [XLEN-1:0] rs1_rdata;
wire [XLEN-1:0] rs2_rdata;

    // 冒险检测信号
wire            stall_decode;
wire [1:0]      forward_a_sel;
wire [1:0]      forward_b_sel;

    // 执行阶段转发后的操作数
reg [XLEN-1:0] ex_rs1_forwarded;
reg [XLEN-1:0] ex_rs2_forwarded;

    // 执行阶段输出
wire [XLEN-1:0] ex_exec_result;
wire [XLEN-1:0] ex_mem_addr;
wire [XLEN-1:0] ex_store_data;
wire [XLEN/8-1:0] ex_store_wstrb;
wire            ex_redirect_en;
wire            ex_redirect_valid;
wire [XLEN-1:0] ex_redirect_pc;
wire            ex_mem_misaligned;
wire [XLEN-1:0] ex_exec_result_final;

    // CSR 相关信号
wire [XLEN-1:0] csr_rdata_ex;
wire [XLEN-1:0] csr_write_operand_ex;
wire [XLEN-1:0] csr_write_data_ex;
wire            csr_write_request_ex;
wire            csr_write_en_ex;
wire            csr_read_valid_ex;
wire            csr_write_allowed_ex;
wire            csr_access_illegal_ex;
wire            ex_sync_trap_valid;
wire            ex_trap_valid;
wire [XLEN-1:0] ex_trap_cause;
wire            ex_mret_valid;
wire            ex_interrupt_valid;
wire            ex_control_redirect_valid;
(* max_fanout = 16 *) wire ex_fetch_redirect_valid;
(* max_fanout = 8 *) wire ex_decode_flush_valid;
wire [XLEN-1:0] ex_control_redirect_pc;
wire [XLEN-1:0] csr_mip_value;
wire            fetch_control_redirect_valid;
wire [XLEN-1:0] fetch_control_redirect_pc;
wire            decode_flush_valid;

    // 访存阶段输出
wire [XLEN-1:0] mem_load_data;
wire            mem_wait;

    // 写回阶段输出
wire [XLEN-1:0] wb_data;

    // 前递数据
wire [XLEN-1:0] ex_mem_forward_data;

    // CSR 寄存器
reg  [XLEN-1:0] csr_mstatus_r;
reg  [XLEN-1:0] csr_mie_r;
reg  [XLEN-1:0] csr_mtvec_r;
reg  [XLEN-1:0] csr_mscratch_r;
reg  [XLEN-1:0] csr_mepc_r;
reg  [XLEN-1:0] csr_mcause_r;

    //流水线控制信号
wire            pipeline_run;
wire            csr_write_fire;
wire            csr_mstatus_trap_write;
wire            csr_mstatus_mret_write;
wire            csr_mstatus_csr_write;
wire            csr_mie_csr_write;
wire            csr_mtvec_csr_write;
wire            csr_mscratch_csr_write;
wire            csr_mepc_trap_write;
wire            csr_mepc_csr_write;
wire            csr_mcause_trap_write;
wire            csr_mcause_csr_write;

    // 取指缓冲和控制信号
wire [XLEN-1:0] fetch_rsp_pc;
wire            fetch_rsp_valid;
wire            fetch_drop_response;
wire            fetch_pipe_valid;
wire [XLEN-1:0] fetch_queue_pc;
wire [31:0]     fetch_queue_instruction;
wire            fetch_queue_valid;
wire            fetch_buffer_valid;
wire            fetch_live_to_ifid;
wire            fetch_queue_consume;
wire            fetch_queue_enqueue;
wire            fetch_data_issue;
wire            fetch_live_to_ifid_data;
wire            fetch_queue_enqueue_data;
wire            fetch_buf0_shift_data;
wire            fetch_buf0_valid_after_shift;
wire            fetch_buf1_valid_after_shift;
wire            fetch_buf0_load_rsp_data;
wire            fetch_buf1_load_rsp_data;
wire            fetch_buf0_load_data;
wire            fetch_buf1_load_data;
wire            fetch_reuse_redirect_valid;
wire [XLEN-1:0] fetch_reuse_redirect_pc;
wire            fetch_redirect_buf0_hit;
wire            fetch_redirect_buf1_hit;
wire            fetch_redirect_pipe_hit;
wire            fetch_redirect_reuse_valid;
wire            if_id_fetch_valid;
(* max_fanout = 8 *) wire if_id_write_en;
wire            if_id_load_bubble;
wire            if_id_next_valid;
wire            if_id_data_write_en;
(* keep = "true", max_fanout = 4 *) wire id_ex_flush_valid_local;
(* keep = "true", max_fanout = 4 *) wire id_ex_stall_bubble_local;
wire [XLEN-1:0] if_id_next_pc;
wire [31:0]     if_id_next_instruction;
reg  [XLEN-1:0] fetch_buf0_pc_next_data;
reg  [31:0]     fetch_buf0_instruction_next_data;
reg  [XLEN-1:0] fetch_buf1_pc_next_data;
reg  [31:0]     fetch_buf1_instruction_next_data;
reg  [1:0]      fetch_drop_count_next_state;
reg             fetch_buf0_valid_next_state;
reg             fetch_buf1_valid_next_state;
reg  [XLEN-1:0] if_id_pc_next_data;
reg  [31:0]     if_id_instruction_next_data;
wire            fetch_buf0_valid_next;
wire            fetch_buf1_valid_next;

    // ================================================================
    // 常量定义
    // ================================================================
localparam [XLEN-1:0] ZERO_XLEN = {XLEN{1'b0}};
localparam [1:0] IMEM_DROP_COUNT = (IMEM_OUTPUT_REG != 0) ? 2'd1 : 2'd0;

    // ================================================================
    // 输出信号分配
    // ================================================================
assign trap = trap_r;
assign debug_pc = pc_r;

    // ================================================================
    // 取指请求逻辑
    // ================================================================
assign imem_req = (IMEM_SYNC != 0) && !trap_r && !mem_wait && !stall_decode && !fetch_control_redirect_valid;

    // ================================================================
    // 执行阶段前递数据选择
    // ================================================================
assign ex_mem_forward_data =
    (ex_mem_wb_sel_r == `YH_rv_cpu_WB_PC4) ? ex_mem_pc4_r : ex_mem_exec_result_r;

    // ================================================================
    // 重定向有效性
    // ================================================================
assign ex_redirect_valid = id_ex_valid_r && ex_redirect_en;

    // ================================================================
    // CSR 操作数选择
    // ================================================================
assign csr_write_operand_ex = id_ex_csr_use_imm_r ? {{(XLEN-5){1'b0}}, id_ex_rs1_addr_r} : ex_rs1_forwarded;

    // ================================================================
    // CSR 写请求生成
    // ================================================================
assign csr_write_request_ex =
    id_ex_csr_valid_r &&
    (
        (id_ex_csr_cmd_r == `YH_rv_cpu_CSR_RW) ||
        (csr_write_operand_ex != ZERO_XLEN)
    );
assign csr_write_en_ex = csr_write_request_ex && !csr_access_illegal_ex;

    // ================================================================
    // CSR 写数据生成
    // 根据 CSR 命令 (RW/RS/RC) 计算写数据
    // ================================================================
assign csr_write_data_ex =
    (id_ex_csr_cmd_r == `YH_rv_cpu_CSR_RW) ? csr_write_operand_ex :
    (id_ex_csr_cmd_r == `YH_rv_cpu_CSR_RS) ? (csr_rdata_ex | csr_write_operand_ex) :
    (csr_rdata_ex & ~csr_write_operand_ex);

    // ================================================================
    // MIP 值 (机器中断待处理)
    // ================================================================
assign csr_mip_value = timer_irq ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_MIP_MTIP} : ZERO_XLEN;

    // ================================================================
    // 异常原因编码
    // ================================================================
assign ex_trap_cause =
    ex_interrupt_valid ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_MTIME_INTERRUPT} :
    (id_ex_ecall_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_ECALL_MMODE} :
    (id_ex_ebreak_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_BREAKPOINT} :
    (!csr_read_valid_ex && id_ex_csr_valid_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_ILLEGAL_INSN} :
    (id_ex_illegal_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_ILLEGAL_INSN} :
    (id_ex_load_r) ? {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_LOAD_MISALIGNED} :
    {{(XLEN-32){1'b0}}, `YH_rv_cpu_TRAP_STORE_MISALIGNED};

    // ================================================================
    // MRET 有效性
    // ================================================================
assign ex_mret_valid = id_ex_valid_r && id_ex_mret_r;

    // ================================================================
    // 中断有效性检查
    // 需要 MIE (机器中断使能) 和 MTIE (机器定时器中断使能) 同时置位
    // ================================================================
assign ex_interrupt_valid =
    id_ex_valid_r &&
    !ex_mem_misaligned &&
    !id_ex_ecall_r &&
    !id_ex_ebreak_r &&
    !id_ex_mret_r &&
    !id_ex_illegal_r &&
    !csr_access_illegal_ex &&
    (csr_mstatus_r & `YH_rv_cpu_MSTATUS_MIE) != ZERO_XLEN &&
    (csr_mie_r & `YH_rv_cpu_MIE_MTIE) != ZERO_XLEN &&
    timer_irq;

    // ================================================================
    // 同步异常有效性 (立即处理的异常)
    // ================================================================
assign ex_sync_trap_valid =
    id_ex_valid_r &&
    (ex_mem_misaligned || id_ex_ecall_r || id_ex_ebreak_r || id_ex_illegal_r || csr_access_illegal_ex);

    // ================================================================
    // Trap 有效性 (中断 + 同步异常)
    // ================================================================
assign ex_trap_valid = ex_interrupt_valid || ex_sync_trap_valid;

    // ================================================================
    // 控制流重定向有效性
    // 包括 trap、mret、跳转/分支
    // ================================================================
assign ex_control_redirect_valid = ex_trap_valid || ex_mret_valid || ex_redirect_valid;
assign ex_fetch_redirect_valid = ex_control_redirect_valid;
assign ex_decode_flush_valid = ex_control_redirect_valid;

    // ================================================================
    // ID 阶段早分支重定向
    // 仅覆盖 operand-ready 的 taken BEQ/BNE，其他控制流仍走 EX backstop
    // ================================================================
assign id_branch_beq_bne =
    if_id_valid_r &&
    id_branch &&
    ((id_branch_funct3 == 3'b000) || (id_branch_funct3 == 3'b001));
assign id_branch_decode_rs1_pending =
    id_rs1_en &&
    (
        (id_ex_valid_r && id_ex_rd_en_r && (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == id_rs1_addr)) ||
        (ex_mem_valid_r && ex_mem_rd_en_r && (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_rs1_addr))
    );
assign id_branch_decode_rs2_pending =
    id_rs2_en &&
    (
        (id_ex_valid_r && id_ex_rd_en_r && (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == id_rs2_addr)) ||
        (ex_mem_valid_r && ex_mem_rd_en_r && (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_rs2_addr))
    );
assign id_branch_decode_operands_ready =
    !id_branch_decode_rs1_pending &&
    !id_branch_decode_rs2_pending;
assign id_branch_decode_taken =
    id_branch_beq_bne &&
    id_branch_decode_operands_ready &&
    (
        ((id_branch_funct3 == 3'b000) && (id_rs1_value == id_rs2_value)) ||
        ((id_branch_funct3 == 3'b001) && (id_rs1_value != id_rs2_value))
    );
assign id_branch_decode_redirect_valid =
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    id_branch_decode_taken;
assign id_branch_decode_redirect_pc = if_id_pc_r + id_imm;
assign fetch_control_redirect_valid = ex_fetch_redirect_valid || id_branch_decode_redirect_valid;
assign fetch_control_redirect_pc =
    ex_fetch_redirect_valid ? ex_control_redirect_pc : id_branch_decode_redirect_pc;
assign decode_flush_valid = ex_decode_flush_valid || id_branch_decode_redirect_valid;

    // ================================================================
    // 取指缓冲重用逻辑
    // ================================================================
assign fetch_reuse_redirect_valid = ex_redirect_valid;
assign fetch_reuse_redirect_pc = ex_redirect_pc;

    // ================================================================
    // 访存阶段输出信号 (中间变量，避免多驱动)
    // ================================================================
wire [XLEN-1:0] mem_stage_dmem_addr;
wire            mem_stage_dmem_read_req;
wire [XLEN-1:0] mem_stage_dmem_wdata;
wire [XLEN/8-1:0] mem_stage_dmem_wstrb;
wire [XLEN-1:0] mem_stage_dmem_rdata;
wire [XLEN-1:0] mem_stage_load_data;

// ================================================================
    // 数据缓存接口信号 (DCACHE_EN=1时使用)
    // ================================================================
wire [XLEN-1:0] dcache_cpu_addr;
wire            dcache_cpu_req;
wire            dcache_cpu_we;
wire [XLEN-1:0] dcache_cpu_wdata;
wire [XLEN/8-1:0] dcache_cpu_wstrb;
wire [1:0]      dcache_cpu_size;
wire [XLEN-1:0] dcache_cpu_rdata;
wire            dcache_cpu_rvalid;
wire            dcache_cpu_wait;

wire [XLEN-1:0] dcache_mem_addr;
wire            dcache_mem_req;
wire            dcache_mem_we;
wire [31:0]     dcache_mem_wdata;
wire [3:0]      dcache_mem_wstrb;
wire [31:0]     dcache_mem_rdata;
wire            dcache_mem_rvalid;
wire            dcache_mem_ready;

// ================================================================
    // 数据缓存模块 (可选)
    // ================================================================
generate
    if (DCACHE_EN == 1) begin : gen_dcache
        YH_rv_cpu_dcache #(
            .XLEN(XLEN),
            .CACHE_SIZE(4096),
            .BLOCK_SIZE(32),
            .ASSOC(1),
            .WRITE_POLICY(0)
        ) u_dcache (
            .clk            (clk),
            .rst_n          (rst_n),
            .cpu_addr       (dcache_cpu_addr),
            .cpu_req        (dcache_cpu_req),
            .cpu_we         (dcache_cpu_we),
            .cpu_wdata      (dcache_cpu_wdata),
            .cpu_wstrb      (dcache_cpu_wstrb),
            .cpu_size       (dcache_cpu_size),
            .cpu_rdata      (dcache_cpu_rdata),
            .cpu_rvalid     (dcache_cpu_rvalid),
            .cpu_wait       (dcache_cpu_wait),
            .mem_addr       (dcache_mem_addr),
            .mem_req        (dcache_mem_req),
            .mem_we         (dcache_mem_we),
            .mem_wdata      (dcache_mem_wdata),
            .mem_wstrb      (dcache_mem_wstrb),
            .mem_rdata      (dcache_mem_rdata),
            .mem_rvalid     (dcache_mem_rvalid),
            .mem_ready      (dcache_mem_ready)
        );

        // DCache CPU侧连接 - 来自mem_stage输出
        assign dcache_cpu_addr  = mem_stage_dmem_addr;
        assign dcache_cpu_req   = mem_stage_dmem_read_req;
        assign dcache_cpu_we    = ex_mem_store_r;
        assign dcache_cpu_wdata = mem_stage_dmem_wdata;
        assign dcache_cpu_wstrb = mem_stage_dmem_wstrb;
        assign dcache_cpu_size  = ex_mem_mem_size_r;

        // DCache返回数据给mem_stage
        assign mem_stage_load_data = dcache_cpu_rvalid ? dcache_cpu_rdata : {XLEN{1'b0}};

        // 外部dmem信号由dcache的mem接口驱动
        assign dmem_addr     = dcache_mem_addr[XLEN-1:0];
        assign dmem_read_req = dcache_mem_req;
        assign dmem_we       = dcache_mem_we;
        assign dmem_wdata    = dcache_mem_wdata;
        assign dmem_wstrb    = dcache_mem_wstrb;
        assign dcache_mem_rdata  = dmem_rdata;
        assign dcache_mem_rvalid = dmem_rvalid;
        assign dcache_mem_ready  = 1'b1;

        // mem_wait由dcache_cpu_wait驱动
        wire mem_wait_base;
        assign mem_wait_base = (DMEM_SYNC != 0) && ex_mem_valid_r && ex_mem_load_r && !dmem_rvalid;
        assign mem_wait = mem_wait_base || dcache_cpu_wait;
    end
endgenerate

// ================================================================
    // 取指响应 PC 和有效信号
    // ================================================================
assign fetch_rsp_pc = (IMEM_OUTPUT_REG != 0) ? fetch_pc_d1_r : fetch_pc_r;
assign fetch_rsp_valid = (IMEM_OUTPUT_REG != 0) ? fetch_valid_d1_r : fetch_valid_r;

    // ================================================================
    // 取指丢弃响应
    // ================================================================
assign fetch_drop_response = (fetch_drop_count_r != 2'd0);

    // ================================================================
    // 取指流水线有效性
    // ================================================================
assign fetch_pipe_valid = (IMEM_SYNC != 0) ? (fetch_rsp_valid && imem_rvalid && !fetch_drop_response) : 1'b0;

    // ================================================================
    // 取指缓冲区有效性
    // ================================================================
assign fetch_buffer_valid = fetch_buf0_valid_r || fetch_buf1_valid_r;

    // ================================================================
    // 取指队列有效性
    // ================================================================
assign fetch_queue_valid = fetch_buffer_valid || fetch_pipe_valid;
assign fetch_queue_pc = fetch_buf0_valid_r ?
    fetch_buf0_pc_r :
    fetch_buf1_valid_r ?
    fetch_buf1_pc_r :
    fetch_rsp_pc;
assign fetch_queue_instruction = fetch_buf0_valid_r ?
    fetch_buf0_instruction_r :
    fetch_buf1_valid_r ?
    fetch_buf1_instruction_r :
    imem_rdata;

    // ================================================================
    // 取指队列消费和入队
    // ================================================================
assign fetch_live_to_ifid = (IMEM_SYNC != 0) && if_id_write_en && !fetch_buffer_valid && fetch_pipe_valid;
assign fetch_queue_consume = (IMEM_SYNC != 0) && if_id_write_en && fetch_buffer_valid;
assign fetch_queue_enqueue = (IMEM_SYNC != 0) && fetch_pipe_valid && !fetch_live_to_ifid;
assign fetch_data_issue = (IMEM_SYNC != 0) && pipeline_run && !stall_decode;
assign fetch_live_to_ifid_data = fetch_data_issue && !fetch_buffer_valid && fetch_pipe_valid;
assign fetch_queue_enqueue_data = (IMEM_SYNC != 0) && fetch_pipe_valid && !fetch_live_to_ifid_data;

    // ================================================================
    // 取指缓冲区移位逻辑
    // ================================================================
assign fetch_buf0_shift_data = fetch_buf1_valid_r && (fetch_data_issue || !fetch_buf0_valid_r);
assign fetch_buf0_valid_after_shift = fetch_buf0_shift_data || (fetch_buf0_valid_r && !fetch_data_issue);
assign fetch_buf1_valid_after_shift = fetch_buf1_valid_r && !fetch_buf0_shift_data;
assign fetch_buf0_load_rsp_data = fetch_queue_enqueue_data && !fetch_buf0_valid_after_shift;
assign fetch_buf1_load_rsp_data =
    fetch_queue_enqueue_data && fetch_buf0_valid_after_shift && !fetch_buf1_valid_after_shift;
assign fetch_buf0_valid_next = fetch_buf0_valid_after_shift || fetch_queue_enqueue_data;
assign fetch_buf1_valid_next = fetch_buf1_valid_after_shift || fetch_buf1_load_rsp_data;
assign fetch_buf0_load_data = fetch_buf0_shift_data || fetch_buf0_load_rsp_data;
assign fetch_buf1_load_data = fetch_buf1_load_rsp_data;

    // ================================================================
    // 取指重定向命中检测
    // ================================================================
assign fetch_redirect_buf0_hit =
    (IMEM_SYNC != 0) &&
    fetch_reuse_redirect_valid &&
    fetch_buf0_valid_r &&
    (fetch_buf0_pc_r == fetch_reuse_redirect_pc);
assign fetch_redirect_buf1_hit =
    (IMEM_SYNC != 0) &&
    fetch_reuse_redirect_valid &&
    fetch_buf1_valid_r &&
    (fetch_buf1_pc_r == fetch_reuse_redirect_pc);
assign fetch_redirect_pipe_hit = 1'b0;
assign fetch_redirect_reuse_valid =
    fetch_redirect_buf0_hit ||
    fetch_redirect_buf1_hit ||
    fetch_redirect_pipe_hit;

    // ================================================================
    // IF/ID 流水线控制
    // ================================================================
assign if_id_fetch_valid = (IMEM_SYNC != 0) ? fetch_queue_valid : 1'b1;
assign if_id_write_en = pipeline_run && (!stall_decode || decode_flush_valid);
assign if_id_load_bubble = decode_flush_valid || !if_id_fetch_valid;
assign if_id_next_valid = if_id_load_bubble ? 1'b0 : 1'b1;
assign if_id_data_write_en =
    (IMEM_SYNC != 0) ?
    (pipeline_run && !stall_decode && if_id_fetch_valid) :
    (pipeline_run && !stall_decode);

assign id_ex_flush_valid_local = decode_flush_valid;
assign id_ex_stall_bubble_local = stall_decode;

    // ================================================================
    // IF/ID 下一拍数据和指令
    // ================================================================
assign if_id_next_pc = if_id_load_bubble ? ZERO_XLEN : ((IMEM_SYNC != 0) ? fetch_queue_pc : pc_r);
assign if_id_next_instruction = if_id_load_bubble ? 32'h0000_0013 : ((IMEM_SYNC != 0) ? fetch_queue_instruction : imem_rdata);

    // ================================================================
    // 控制流重定向 PC 选择
    // trap -> mtvec, mret -> mepc, 跳转 -> 目标地址
    // ================================================================
assign ex_control_redirect_pc =
    ex_trap_valid ? csr_mtvec_r :
    ex_mret_valid ? csr_mepc_r :
    ex_redirect_pc;

    // ================================================================
    // 执行结果最终选择 (CSR 优先)
    // ================================================================
assign ex_exec_result_final = id_ex_csr_valid_r ? csr_rdata_ex : ex_exec_result;

    // ================================================================
    // 流水线运行条件
    // ================================================================
assign pipeline_run = !trap_r && !mem_wait;

    // ================================================================
    // CSR 写操作触发
    // ================================================================
assign csr_write_fire =
    pipeline_run &&
    !ex_trap_valid &&
    id_ex_valid_r &&
    id_ex_csr_valid_r &&
    csr_write_en_ex;

    // ================================================================
    // CSR 寄存器写条件
    // ================================================================
assign csr_mstatus_trap_write = pipeline_run && ex_trap_valid;
assign csr_mstatus_mret_write = pipeline_run && !ex_trap_valid && ex_mret_valid;
assign csr_read_valid_ex = id_ex_csr_read_valid_r;
assign csr_write_allowed_ex = id_ex_csr_write_allowed_r;
assign csr_mstatus_csr_write = csr_write_fire && (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MSTATUS);
assign csr_mie_csr_write = csr_write_fire && (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MIE);
assign csr_mtvec_csr_write = csr_write_fire && (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MTVEC);
assign csr_mscratch_csr_write = csr_write_fire && (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MSCRATCH);
assign csr_mepc_trap_write = pipeline_run && ex_trap_valid;
assign csr_mepc_csr_write = csr_write_fire && (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MEPC);
assign csr_mcause_trap_write = pipeline_run && ex_trap_valid;
assign csr_mcause_csr_write = csr_write_fire && (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MCAUSE);

    // ================================================================
    // CSR 读数据选择
    // ================================================================
assign csr_rdata_ex =
    (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MSTATUS)  ? csr_mstatus_r :
    (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MIE)      ? csr_mie_r :
    (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MTVEC)    ? csr_mtvec_r :
    (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MSCRATCH) ? csr_mscratch_r :
    (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MEPC)     ? csr_mepc_r :
    (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MCAUSE)   ? csr_mcause_r :
    (id_ex_csr_sel_r == `YH_rv_cpu_CSR_SEL_MIP)      ? csr_mip_value :
    ZERO_XLEN;

    // ================================================================
    // CSR 非法访问检测
    // ================================================================
assign csr_access_illegal_ex =
    id_ex_csr_valid_r &&
    (
        !csr_read_valid_ex ||
        (csr_write_request_ex && !csr_write_allowed_ex)
    );

    // ================================================================
    // 取指缓冲下一状态计算 (组合逻辑)
    // ================================================================
always @* begin
    fetch_drop_count_next_state = fetch_drop_count_r;
    fetch_buf0_valid_next_state = fetch_buf0_valid_r;
    fetch_buf1_valid_next_state = fetch_buf1_valid_r;

    if (IMEM_SYNC != 0) begin
        if (fetch_control_redirect_valid) begin
            if (fetch_redirect_reuse_valid) begin
                fetch_drop_count_next_state = 2'd0;
                if (fetch_redirect_buf1_hit) begin
                    fetch_buf0_valid_next_state = 1'b0;
                    fetch_buf1_valid_next_state = 1'b1;
                end else if (fetch_redirect_pipe_hit) begin
                    fetch_buf0_valid_next_state = 1'b1;
                    fetch_buf1_valid_next_state = 1'b0;
                end
            end else begin
                fetch_drop_count_next_state = IMEM_DROP_COUNT;
                fetch_buf0_valid_next_state = 1'b0;
                fetch_buf1_valid_next_state = 1'b0;
            end
        end else begin
            fetch_buf0_valid_next_state = fetch_buf0_valid_next;
            fetch_buf1_valid_next_state = fetch_buf1_valid_next;
            if (imem_rvalid && (fetch_drop_count_r != 2'd0)) begin
                fetch_drop_count_next_state = fetch_drop_count_r - 2'd1;
            end
        end

        if (!mem_wait) begin
            if (ex_trap_valid || id_ex_flush_valid_local) begin
                fetch_drop_count_next_state = IMEM_DROP_COUNT;
                fetch_buf0_valid_next_state = 1'b0;
                fetch_buf1_valid_next_state = 1'b0;
            end
        end
    end else begin
        fetch_drop_count_next_state = 2'd0;
        fetch_buf0_valid_next_state = 1'b0;
        fetch_buf1_valid_next_state = 1'b0;
    end
end

    // ================================================================
    // 取指缓冲区数据下一状态
    // ================================================================
always @* begin
    fetch_buf0_pc_next_data = fetch_buf0_pc_r;
    fetch_buf0_instruction_next_data = fetch_buf0_instruction_r;
    fetch_buf1_pc_next_data = fetch_buf1_pc_r;
    fetch_buf1_instruction_next_data = fetch_buf1_instruction_r;

    if (IMEM_SYNC != 0) begin
        if (fetch_control_redirect_valid) begin
            if (fetch_redirect_pipe_hit) begin
                fetch_buf0_pc_next_data = fetch_rsp_pc;
                fetch_buf0_instruction_next_data = imem_rdata;
            end
        end else begin
            if (fetch_buf0_load_data) begin
                if (fetch_buf0_load_rsp_data) begin
                    fetch_buf0_pc_next_data = fetch_rsp_pc;
                    fetch_buf0_instruction_next_data = imem_rdata;
                end else begin
                    fetch_buf0_pc_next_data = fetch_buf1_pc_r;
                    fetch_buf0_instruction_next_data = fetch_buf1_instruction_r;
                end
            end
            if (fetch_buf1_load_data) begin
                fetch_buf1_pc_next_data = fetch_rsp_pc;
                fetch_buf1_instruction_next_data = imem_rdata;
            end
        end
    end
end

    // ================================================================
    // IF/ID 流水线寄存器下一状态
    // ================================================================
always @* begin
    if_id_pc_next_data = if_id_pc_r;
    if_id_instruction_next_data = if_id_instruction_r;

    // Flush only clears IF/ID valid. The payload can stay unchanged because
    // hazard and ID/EX consume it only when if_id_valid_r is asserted.
    if (if_id_data_write_en) begin
        if_id_pc_next_data = (IMEM_SYNC != 0) ? fetch_queue_pc : pc_r;
        if_id_instruction_next_data = (IMEM_SYNC != 0) ? fetch_queue_instruction : imem_rdata;
    end
end

    // ================================================================
    // 子模块实例化
    // ================================================================

    // 取指阶段
YH_rv_cpu_if_stage #(
    .XLEN(XLEN),
    .C_EXT(C_EXT)
) u_if_stage (
    .pc_current  (pc_r),
    .redirect_en (fetch_control_redirect_valid),
    .redirect_pc (fetch_control_redirect_pc),
    .instr_raw   (imem_rdata[15:0]),       // C扩展预留: 用于判断压缩指令
    .imem_addr   (imem_addr),
    .pc_next     (if_pc_next),
    .pc_plus_4   (),
    .pc_plus_2   (),                       // C扩展预留
    .instr_is_compressed ()               // C扩展预留
);

    // 寄存器堆
YH_rv_cpu_regfile #(
    .XLEN(XLEN)
) u_regfile (
    .clk       (clk),
    .rst_n     (rst_n),
    .rs1_addr  (id_rs1_addr),
    .rs2_addr  (id_rs2_addr),
    .rs1_rdata (rs1_rdata),
    .rs2_rdata (rs2_rdata),
    .rd_wen    (mem_wb_valid_r && mem_wb_rd_en_r && !trap_r),
    .rd_addr   (mem_wb_rd_addr_r),
    .rd_wdata  (wb_data)
);

    // 译码阶段
YH_rv_cpu_id_stage #(
    .XLEN(XLEN)
) u_id_stage (
    .pc            (if_id_pc_r),
    .instruction   (if_id_instruction_r),
    .rs1_rdata     (rs1_rdata),
    .rs2_rdata     (rs2_rdata),
    .pc4           (id_pc4),
    .rs1_addr      (id_rs1_addr),
    .rs2_addr      (id_rs2_addr),
    .rd_addr       (id_rd_addr),
    .rs1_en        (id_rs1_en),
    .rs2_en        (id_rs2_en),
    .rd_en         (id_rd_en),
    .illegal       (id_illegal),
    .imm           (id_imm),
    .alu_op        (id_alu_op),
    .alu_src1_pc   (id_alu_src1_pc),
    .alu_src2_imm  (id_alu_src2_imm),
    .branch        (id_branch),
    .branch_funct3 (id_branch_funct3),
    .jump          (id_jump),
    .jalr          (id_jalr),
    .load          (id_load),
    .store         (id_store),
    .wb_sel        (id_wb_sel),
    .mem_size      (id_mem_size),
    .mem_unsigned  (id_mem_unsigned),
    .word_op       (id_word_op),
    .is_lui        (id_is_lui),
    .csr_valid     (id_csr_valid),
    .csr_cmd       (id_csr_cmd),
    .csr_use_imm   (id_csr_use_imm),
    .csr_sel       (id_csr_sel),
    .csr_read_valid(id_csr_read_valid),
    .csr_write_allowed(id_csr_write_allowed),
    .ecall         (id_ecall),
    .ebreak        (id_ebreak),
    .mret          (id_mret),
    .rs1_value     (id_rs1_value),
    .rs2_value     (id_rs2_value)
);

    // 冒险检测单元
YH_rv_cpu_hazard_unit u_hazard_unit (
    .if_id_rs1_en   (if_id_valid_r && id_rs1_en),
    .if_id_rs2_en   (if_id_valid_r && id_rs2_en),
    .if_id_rs1_addr (id_rs1_addr),
    .if_id_rs2_addr (id_rs2_addr),
    .id_ex_valid    (id_ex_valid_r),
    .id_ex_load     (id_ex_load_r),
    .id_ex_rd_en    (id_ex_rd_en_r),
    .id_ex_rd_addr  (id_ex_rd_addr_r),
    .id_ex_rs1_en   (id_ex_rs1_en_r),
    .id_ex_rs2_en   (id_ex_rs2_en_r),
    .id_ex_rs1_addr (id_ex_rs1_addr_r),
    .id_ex_rs2_addr (id_ex_rs2_addr_r),
    .ex_mem_valid   (ex_mem_valid_r),
    .ex_mem_load    (ex_mem_load_r),
    .ex_mem_rd_en   (ex_mem_rd_en_r),
    .ex_mem_rd_addr (ex_mem_rd_addr_r),
    .mem_wb_valid   (mem_wb_valid_r),
    .mem_wb_rd_en   (mem_wb_rd_en_r),
    .mem_wb_rd_addr (mem_wb_rd_addr_r),
    .stall_decode   (stall_decode),
    .forward_a_sel  (forward_a_sel),
    .forward_b_sel  (forward_b_sel)
);

    // ================================================================
    // 数据转发选择
    // ================================================================
always @* begin
    ex_rs1_forwarded = id_ex_rs1_value_r;
    ex_rs2_forwarded = id_ex_rs2_value_r;

    case (forward_a_sel)
        2'b01: ex_rs1_forwarded = ex_mem_forward_data;
        2'b10: ex_rs1_forwarded = wb_data;
        default: ex_rs1_forwarded = id_ex_rs1_value_r;
    endcase

    case (forward_b_sel)
        2'b01: ex_rs2_forwarded = ex_mem_forward_data;
        2'b10: ex_rs2_forwarded = wb_data;
        default: ex_rs2_forwarded = id_ex_rs2_value_r;
    endcase
end

    // 执行阶段
YH_rv_cpu_ex_stage #(
    .XLEN(XLEN)
) u_ex_stage (
    .pc            (id_ex_pc_r),
    .rs1_value     (ex_rs1_forwarded),
    .rs2_value     (ex_rs2_forwarded),
    .imm           (id_ex_imm_r),
    .alu_op        (id_ex_alu_op_r),
    .alu_src1_pc   (id_ex_alu_src1_pc_r),
    .alu_src2_imm  (id_ex_alu_src2_imm_r),
    .branch        (id_ex_branch_r),
    .branch_funct3 (id_ex_branch_funct3_r),
    .jump          (id_ex_jump_r),
    .jalr          (id_ex_jalr_r),
    .load          (id_ex_load_r),
    .store         (id_ex_store_r),
    .mem_size      (id_ex_mem_size_r),
    .word_op       (id_ex_word_op_r),
    .is_lui        (id_ex_is_lui_r),
    .exec_result   (ex_exec_result),
    .mem_addr      (ex_mem_addr),
    .store_data    (ex_store_data),
    .store_wstrb   (ex_store_wstrb),
    .redirect_en   (ex_redirect_en),
    .redirect_pc   (ex_redirect_pc),
    .mem_misaligned(ex_mem_misaligned)
);

    // 访存阶段
YH_rv_cpu_mem_stage #(
    .XLEN(XLEN)
) u_mem_stage (
    .valid         (ex_mem_valid_r),
    .load          (ex_mem_load_r),
    .store         (ex_mem_store_r),
    .mem_addr      (ex_mem_mem_addr_r),
    .store_data_in (ex_mem_store_data_r),
    .store_wstrb_in(ex_mem_store_wstrb_r),
    .mem_size      (ex_mem_mem_size_r),
    .mem_unsigned  (ex_mem_mem_unsigned_r),
    .dmem_rdata    (mem_stage_dmem_rdata),
    .dmem_addr     (mem_stage_dmem_addr),
    .dmem_read_req (mem_stage_dmem_read_req),
    .dmem_wdata    (mem_stage_dmem_wdata),
    .dmem_wstrb    (mem_stage_dmem_wstrb),
    .load_data     (mem_stage_load_data)
);

    // ================================================================
    // 当DCACHE禁用时，直接连接mem_stage到外部dmem
    // ================================================================
generate
    if (DCACHE_EN == 0) begin : gen_no_dcache
        assign dmem_addr     = mem_stage_dmem_addr;
        assign dmem_read_req = mem_stage_dmem_read_req;
        assign dmem_wdata    = mem_stage_dmem_wdata;
        assign dmem_wstrb    = mem_stage_dmem_wstrb;
        assign mem_stage_dmem_rdata = dmem_rdata;
        assign mem_stage_load_data  = dmem_rvalid ? dmem_rdata : {XLEN{1'b0}};
        assign mem_wait = (DMEM_SYNC != 0) && ex_mem_valid_r && ex_mem_load_r && !dmem_rvalid;
    end
endgenerate

    // 写回阶段
YH_rv_cpu_wb_stage #(
    .XLEN(XLEN)
) u_wb_stage (
    .wb_sel      (mem_wb_wb_sel_r),
    .exec_result (mem_wb_exec_result_r),
    .load_data   (mem_wb_load_data_r),
    .pc4         (mem_wb_pc4_r),
    .wb_data     (wb_data)
);

    // ================================================================
    // 主流水线寄存器更新
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_r <= RESET_VECTOR;
        trap_r <= 1'b0;
        fetch_pc_r <= ZERO_XLEN;
        fetch_pc_d1_r <= ZERO_XLEN;
        fetch_valid_r <= 1'b0;
        fetch_valid_d1_r <= 1'b0;

        id_ex_valid_r <= 1'b0;
        id_ex_pc_r <= ZERO_XLEN;
        id_ex_pc4_r <= ZERO_XLEN;
        id_ex_rs1_addr_r <= 5'd0;
        id_ex_rs2_addr_r <= 5'd0;
        id_ex_rd_addr_r <= 5'd0;
        id_ex_rs1_en_r <= 1'b0;
        id_ex_rs2_en_r <= 1'b0;
        id_ex_rd_en_r <= 1'b0;
        id_ex_illegal_r <= 1'b0;
        id_ex_rs1_value_r <= ZERO_XLEN;
        id_ex_rs2_value_r <= ZERO_XLEN;
        id_ex_imm_r <= ZERO_XLEN;
        id_ex_alu_op_r <= `YH_rv_cpu_ALU_ADD;
        id_ex_alu_src1_pc_r <= 1'b0;
        id_ex_alu_src2_imm_r <= 1'b0;
        id_ex_branch_r <= 1'b0;
        id_ex_branch_funct3_r <= 3'b000;
        id_ex_jump_r <= 1'b0;
        id_ex_jalr_r <= 1'b0;
        id_ex_load_r <= 1'b0;
        id_ex_store_r <= 1'b0;
        id_ex_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        id_ex_mem_size_r <= `YH_rv_cpu_MEM_W;
        id_ex_mem_unsigned_r <= 1'b0;
        id_ex_word_op_r <= 1'b0;
        id_ex_is_lui_r <= 1'b0;
        id_ex_csr_valid_r <= 1'b0;
        id_ex_csr_cmd_r <= `YH_rv_cpu_CSR_RW;
        id_ex_csr_use_imm_r <= 1'b0;
        id_ex_csr_sel_r <= `YH_rv_cpu_CSR_SEL_NONE;
        id_ex_csr_read_valid_r <= 1'b0;
        id_ex_csr_write_allowed_r <= 1'b0;
        id_ex_ecall_r <= 1'b0;
        id_ex_ebreak_r <= 1'b0;
        id_ex_mret_r <= 1'b0;

        ex_mem_valid_r <= 1'b0;
        ex_mem_pc4_r <= ZERO_XLEN;
        ex_mem_rd_addr_r <= 5'd0;
        ex_mem_rd_en_r <= 1'b0;
        ex_mem_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        ex_mem_load_r <= 1'b0;
        ex_mem_store_r <= 1'b0;
        ex_mem_mem_size_r <= `YH_rv_cpu_MEM_W;
        ex_mem_mem_unsigned_r <= 1'b0;
        ex_mem_exec_result_r <= ZERO_XLEN;
        ex_mem_mem_addr_r <= ZERO_XLEN;
        ex_mem_store_data_r <= ZERO_XLEN;
        ex_mem_store_wstrb_r <= {(XLEN/8){1'b0}};

        mem_wb_valid_r <= 1'b0;
        mem_wb_pc4_r <= ZERO_XLEN;
        mem_wb_rd_addr_r <= 5'd0;
        mem_wb_rd_en_r <= 1'b0;
        mem_wb_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        mem_wb_exec_result_r <= ZERO_XLEN;
        mem_wb_load_data_r <= ZERO_XLEN;
    end else if (!trap_r) begin
        if (IMEM_SYNC != 0) begin
            fetch_pc_d1_r <= fetch_pc_r;
            fetch_valid_d1_r <= fetch_valid_r;
            fetch_pc_r <= imem_req ? pc_r : ZERO_XLEN;
            fetch_valid_r <= imem_req;
        end else begin
            fetch_pc_r <= ZERO_XLEN;
            fetch_pc_d1_r <= ZERO_XLEN;
            fetch_valid_r <= 1'b0;
            fetch_valid_d1_r <= 1'b0;
        end

        if (mem_wait) begin
            // Hold WB steady while a synchronous load waits for data so a
            // stalled EX instruction can still forward the last committed value.
        end else begin
            mem_wb_valid_r <= ex_mem_valid_r;
            mem_wb_pc4_r <= ex_mem_pc4_r;
            mem_wb_rd_addr_r <= ex_mem_rd_addr_r;
            mem_wb_rd_en_r <= ex_mem_rd_en_r;
            mem_wb_wb_sel_r <= ex_mem_wb_sel_r;
            mem_wb_exec_result_r <= ex_mem_exec_result_r;
            mem_wb_load_data_r <= mem_load_data;

            if (ex_trap_valid) begin
                pc_r <= ex_control_redirect_pc;
                id_ex_valid_r <= 1'b0;
                id_ex_pc_r <= ZERO_XLEN;
                id_ex_pc4_r <= ZERO_XLEN;
                id_ex_rs1_addr_r <= 5'd0;
                id_ex_rs2_addr_r <= 5'd0;
                id_ex_rd_addr_r <= 5'd0;
                id_ex_rs1_en_r <= 1'b0;
                id_ex_rs2_en_r <= 1'b0;
                id_ex_rd_en_r <= 1'b0;
                id_ex_illegal_r <= id_ex_illegal_r;
                id_ex_rs1_value_r <= ZERO_XLEN;
                id_ex_rs2_value_r <= ZERO_XLEN;
                id_ex_imm_r <= id_ex_imm_r;
                id_ex_alu_op_r <= id_ex_alu_op_r;
                id_ex_alu_src1_pc_r <= id_ex_alu_src1_pc_r;
                id_ex_alu_src2_imm_r <= id_ex_alu_src2_imm_r;
                id_ex_branch_r <= id_ex_branch_r;
                id_ex_branch_funct3_r <= id_ex_branch_funct3_r;
                id_ex_jump_r <= id_ex_jump_r;
                id_ex_jalr_r <= id_ex_jalr_r;
                id_ex_load_r <= id_ex_load_r;
                id_ex_store_r <= id_ex_store_r;
                id_ex_wb_sel_r <= id_ex_wb_sel_r;
                id_ex_mem_size_r <= id_ex_mem_size_r;
                id_ex_mem_unsigned_r <= id_ex_mem_unsigned_r;
                id_ex_word_op_r <= id_ex_word_op_r;
                id_ex_is_lui_r <= id_ex_is_lui_r;
                id_ex_csr_valid_r <= id_ex_csr_valid_r;
                id_ex_csr_cmd_r <= id_ex_csr_cmd_r;
                id_ex_csr_use_imm_r <= id_ex_csr_use_imm_r;
                id_ex_csr_sel_r <= id_ex_csr_sel_r;
                id_ex_csr_read_valid_r <= id_ex_csr_read_valid_r;
                id_ex_csr_write_allowed_r <= id_ex_csr_write_allowed_r;
                id_ex_ecall_r <= id_ex_ecall_r;
                id_ex_ebreak_r <= id_ex_ebreak_r;
                id_ex_mret_r <= id_ex_mret_r;
            end else begin
                if (fetch_control_redirect_valid || !stall_decode) begin
                    pc_r <= if_pc_next;
                end

                ex_mem_valid_r <= id_ex_valid_r;
                ex_mem_pc4_r <= id_ex_pc4_r;
                ex_mem_rd_addr_r <= id_ex_rd_addr_r;
                ex_mem_rd_en_r <= id_ex_rd_en_r;
                ex_mem_wb_sel_r <= id_ex_wb_sel_r;
                ex_mem_load_r <= id_ex_load_r;
                ex_mem_store_r <= id_ex_store_r;
                ex_mem_mem_size_r <= id_ex_mem_size_r;
                ex_mem_mem_unsigned_r <= id_ex_mem_unsigned_r;
                ex_mem_exec_result_r <= ex_exec_result_final;
                ex_mem_mem_addr_r <= ex_mem_addr;
                ex_mem_store_data_r <= ex_store_data;
                ex_mem_store_wstrb_r <= ex_store_wstrb;

                if (id_ex_flush_valid_local) begin
                    id_ex_valid_r <= 1'b0;
                    id_ex_pc_r <= ZERO_XLEN;
                    id_ex_pc4_r <= ZERO_XLEN;
                    id_ex_rs1_addr_r <= 5'd0;
                    id_ex_rs2_addr_r <= 5'd0;
                    id_ex_rd_addr_r <= 5'd0;
                    id_ex_rs1_en_r <= 1'b0;
                    id_ex_rs2_en_r <= 1'b0;
                    id_ex_rd_en_r <= 1'b0;
                    id_ex_illegal_r <= id_ex_illegal_r;
                    id_ex_rs1_value_r <= ZERO_XLEN;
                    id_ex_rs2_value_r <= ZERO_XLEN;
                    id_ex_imm_r <= id_ex_imm_r;
                    id_ex_alu_op_r <= id_ex_alu_op_r;
                    id_ex_alu_src1_pc_r <= id_ex_alu_src1_pc_r;
                    id_ex_alu_src2_imm_r <= id_ex_alu_src2_imm_r;
                    id_ex_branch_r <= id_ex_branch_r;
                    id_ex_branch_funct3_r <= id_ex_branch_funct3_r;
                    id_ex_jump_r <= id_ex_jump_r;
                    id_ex_jalr_r <= id_ex_jalr_r;
                    id_ex_load_r <= id_ex_load_r;
                    id_ex_store_r <= id_ex_store_r;
                    id_ex_wb_sel_r <= id_ex_wb_sel_r;
                    id_ex_mem_size_r <= id_ex_mem_size_r;
                    id_ex_mem_unsigned_r <= id_ex_mem_unsigned_r;
                    id_ex_word_op_r <= id_ex_word_op_r;
                    id_ex_is_lui_r <= id_ex_is_lui_r;
                    id_ex_csr_valid_r <= id_ex_csr_valid_r;
                    id_ex_csr_cmd_r <= id_ex_csr_cmd_r;
                    id_ex_csr_use_imm_r <= id_ex_csr_use_imm_r;
                    id_ex_csr_sel_r <= id_ex_csr_sel_r;
                    id_ex_csr_read_valid_r <= id_ex_csr_read_valid_r;
                    id_ex_csr_write_allowed_r <= id_ex_csr_write_allowed_r;
                    id_ex_ecall_r <= id_ex_ecall_r;
                    id_ex_ebreak_r <= id_ex_ebreak_r;
                    id_ex_mret_r <= id_ex_mret_r;
                end else if (id_ex_stall_bubble_local) begin
                    id_ex_valid_r <= 1'b0;
                    id_ex_pc_r <= ZERO_XLEN;
                    id_ex_pc4_r <= ZERO_XLEN;
                    id_ex_rs1_addr_r <= 5'd0;
                    id_ex_rs2_addr_r <= 5'd0;
                    id_ex_rd_addr_r <= 5'd0;
                    id_ex_rs1_en_r <= 1'b0;
                    id_ex_rs2_en_r <= 1'b0;
                    id_ex_rd_en_r <= 1'b0;
                    id_ex_illegal_r <= id_ex_illegal_r;
                    id_ex_rs1_value_r <= ZERO_XLEN;
                    id_ex_rs2_value_r <= ZERO_XLEN;
                    id_ex_imm_r <= id_ex_imm_r;
                    id_ex_alu_op_r <= id_ex_alu_op_r;
                    id_ex_alu_src1_pc_r <= id_ex_alu_src1_pc_r;
                    id_ex_alu_src2_imm_r <= id_ex_alu_src2_imm_r;
                    id_ex_branch_r <= id_ex_branch_r;
                    id_ex_branch_funct3_r <= id_ex_branch_funct3_r;
                    id_ex_jump_r <= id_ex_jump_r;
                    id_ex_jalr_r <= id_ex_jalr_r;
                    id_ex_load_r <= id_ex_load_r;
                    id_ex_store_r <= id_ex_store_r;
                    id_ex_wb_sel_r <= id_ex_wb_sel_r;
                    id_ex_mem_size_r <= id_ex_mem_size_r;
                    id_ex_mem_unsigned_r <= id_ex_mem_unsigned_r;
                    id_ex_word_op_r <= id_ex_word_op_r;
                    id_ex_is_lui_r <= id_ex_is_lui_r;
                    id_ex_csr_valid_r <= id_ex_csr_valid_r;
                    id_ex_csr_cmd_r <= id_ex_csr_cmd_r;
                    id_ex_csr_use_imm_r <= id_ex_csr_use_imm_r;
                    id_ex_csr_sel_r <= id_ex_csr_sel_r;
                    id_ex_csr_read_valid_r <= id_ex_csr_read_valid_r;
                    id_ex_csr_write_allowed_r <= id_ex_csr_write_allowed_r;
                    id_ex_ecall_r <= id_ex_ecall_r;
                    id_ex_ebreak_r <= id_ex_ebreak_r;
                    id_ex_mret_r <= id_ex_mret_r;
                end else begin
                    id_ex_valid_r <= if_id_valid_r;
                    id_ex_pc_r <= if_id_pc_r;
                    id_ex_pc4_r <= id_pc4;
                    id_ex_rs1_addr_r <= id_rs1_addr;
                    id_ex_rs2_addr_r <= id_rs2_addr;
                    id_ex_rd_addr_r <= id_rd_addr;
                    id_ex_rs1_en_r <= id_rs1_en;
                    id_ex_rs2_en_r <= id_rs2_en;
                    id_ex_rd_en_r <= id_rd_en;
                    id_ex_illegal_r <= id_illegal;
                    id_ex_rs1_value_r <= id_rs1_value;
                    id_ex_rs2_value_r <= id_rs2_value;
                    id_ex_imm_r <= id_imm;
                    id_ex_alu_op_r <= id_alu_op;
                    id_ex_alu_src1_pc_r <= id_alu_src1_pc;
                    id_ex_alu_src2_imm_r <= id_alu_src2_imm;
                    id_ex_branch_r <= id_branch;
                    id_ex_branch_funct3_r <= id_branch_funct3;
                    id_ex_jump_r <= id_jump;
                    id_ex_jalr_r <= id_jalr;
                    id_ex_load_r <= id_load;
                    id_ex_store_r <= id_store;
                    id_ex_wb_sel_r <= id_wb_sel;
                    id_ex_mem_size_r <= id_mem_size;
                    id_ex_mem_unsigned_r <= id_mem_unsigned;
                    id_ex_word_op_r <= id_word_op;
                    id_ex_is_lui_r <= id_is_lui;
                    id_ex_csr_valid_r <= id_csr_valid;
                    id_ex_csr_cmd_r <= id_csr_cmd;
                    id_ex_csr_use_imm_r <= id_csr_use_imm;
                    id_ex_csr_sel_r <= id_csr_sel;
                    id_ex_csr_read_valid_r <= id_csr_read_valid;
                    id_ex_csr_write_allowed_r <= id_csr_write_allowed;
                    id_ex_ecall_r <= id_ecall;
                    id_ex_ebreak_r <= id_ebreak;
                    id_ex_mret_r <= id_mret;
                end
            end
        end
    end
end

    // ================================================================
    // 取指缓冲和丢弃计数器更新
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fetch_drop_count_r <= 2'd0;
        fetch_buf0_valid_r <= 1'b0;
        fetch_buf1_valid_r <= 1'b0;
    end else if (!trap_r) begin
        fetch_drop_count_r <= fetch_drop_count_next_state;
        fetch_buf0_valid_r <= fetch_buf0_valid_next_state;
        fetch_buf1_valid_r <= fetch_buf1_valid_next_state;
    end
end

    // ================================================================
    // IF/ID 有效位更新
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        if_id_valid_r <= 1'b0;
    end else if (if_id_write_en) begin
        if_id_valid_r <= if_id_next_valid;
    end
end

    // ================================================================
    // 取指缓冲区数据更新
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fetch_buf0_pc_r <= ZERO_XLEN;
        fetch_buf0_instruction_r <= 32'h0000_0000;
        fetch_buf1_pc_r <= ZERO_XLEN;
        fetch_buf1_instruction_r <= 32'h0000_0000;
    end else if (!trap_r) begin
        if (IMEM_SYNC != 0) begin
            fetch_buf0_pc_r <= fetch_buf0_pc_next_data;
            fetch_buf0_instruction_r <= fetch_buf0_instruction_next_data;
            fetch_buf1_pc_r <= fetch_buf1_pc_next_data;
            fetch_buf1_instruction_r <= fetch_buf1_instruction_next_data;
        end else begin
            fetch_buf0_pc_r <= ZERO_XLEN;
            fetch_buf0_instruction_r <= 32'h0000_0000;
            fetch_buf1_pc_r <= ZERO_XLEN;
            fetch_buf1_instruction_r <= 32'h0000_0000;
        end
    end
end

    // ================================================================
    // IF/ID PC 和指令更新
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        if_id_pc_r <= ZERO_XLEN;
        if_id_instruction_r <= 32'h0000_0013;
    end else if (!trap_r) begin
        if_id_pc_r <= if_id_pc_next_data;
        if_id_instruction_r <= if_id_instruction_next_data;
    end
end

    // ================================================================
    // CSR 寄存器更新
    // ================================================================

    // mstatus: 机器状态寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        csr_mstatus_r <= ZERO_XLEN;
    end else if (csr_mstatus_trap_write) begin
        csr_mstatus_r <=
            (csr_mstatus_r & ~(`YH_rv_cpu_MSTATUS_MIE | `YH_rv_cpu_MSTATUS_MPIE)) |
            ((csr_mstatus_r & `YH_rv_cpu_MSTATUS_MIE) << 4);
    end else if (csr_mstatus_mret_write) begin
        csr_mstatus_r <=
            (csr_mstatus_r & ~(`YH_rv_cpu_MSTATUS_MIE | `YH_rv_cpu_MSTATUS_MPIE)) |
            ((csr_mstatus_r & `YH_rv_cpu_MSTATUS_MPIE) >> 4) |
            `YH_rv_cpu_MSTATUS_MPIE;
    end else if (csr_mstatus_csr_write) begin
        csr_mstatus_r <= csr_write_data_ex &
            (`YH_rv_cpu_MSTATUS_MIE | `YH_rv_cpu_MSTATUS_MPIE);
    end
end

    // mie: 机器中断使能寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        csr_mie_r <= ZERO_XLEN;
    end else if (csr_mie_csr_write) begin
        csr_mie_r <= csr_write_data_ex & `YH_rv_cpu_MIE_MTIE;
    end
end

    // mtvec: 机器陷阱向量寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        csr_mtvec_r <= RESET_VECTOR;
    end else if (csr_mtvec_csr_write) begin
        csr_mtvec_r <= {csr_write_data_ex[XLEN-1:2], 2'b00};
    end
end

    // mscratch: 机器 Scratch 寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        csr_mscratch_r <= ZERO_XLEN;
    end else if (csr_mscratch_csr_write) begin
        csr_mscratch_r <= csr_write_data_ex;
    end
end

    // mepc: 机器异常程序计数器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        csr_mepc_r <= ZERO_XLEN;
    end else if (csr_mepc_trap_write) begin
        csr_mepc_r <= id_ex_pc_r;
    end else if (csr_mepc_csr_write) begin
        csr_mepc_r <= {csr_write_data_ex[XLEN-1:2], 2'b00};
    end
end

    // mcause: 机器异常原因寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        csr_mcause_r <= ZERO_XLEN;
    end else if (csr_mcause_trap_write) begin
        csr_mcause_r <= ex_trap_cause;
    end else if (csr_mcause_csr_write) begin
        csr_mcause_r <= csr_write_data_ex;
    end
end

endmodule
