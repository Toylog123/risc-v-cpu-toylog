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
    parameter integer LOAD_USE_FAST_FORWARD = 0, // forward load data from MEM when memory returns within the cycle
    parameter integer DMEM_READ_PREISSUE = 0,
    parameter [31:0] DCACHEABLE_BASE = 32'h0000_4000,
    parameter [31:0] DCACHEABLE_LIMIT = 32'h0001_4000,
    parameter integer DCACHE_EN = 0,         // 数据缓存使能: 0=禁用, 1=启用
    parameter integer ICACHE_EN = 0,         // 指令缓存使能: 0=禁用, 1=启用
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 1, // XThead 条件移动写回门控使能
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1, // ID 早分支允许使用 EX 本周期结果
    parameter integer ENABLE_REDIRECT_TARGET_CACHE = 1,
    parameter integer ENABLE_ID_BRANCH_FOLD = 0,
    parameter integer ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD = 0,
    parameter integer ENABLE_ID_ALU_PAIR_FOLD = 0,
    parameter integer ENABLE_ID_ALU_DEP_FOLD = 0,
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP = 1,
    parameter integer ENABLE_FETCH_REDIRECT_REUSE = 0,
    parameter integer REDIRECT_CACHE_ENTRIES = 1024,
    parameter integer REDIRECT_CACHE_XOR_INDEX = 0,
    parameter integer ENABLE_DYNAMIC_BRANCH_PREDICT = 0,
    parameter integer BRANCH_BHT_ENTRIES = 64,
    parameter integer BRANCH_STATIC_PREDICT_MODE = 0,
    parameter integer BRANCH_BHT_STRONG_ONLY = 0,
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
    input  wire [XLEN-1:0] dmem_pair_rdata,
    input  wire            dmem_rvalid,      // 加载有效
    input  wire            dmem_ready,       // 写完成/内存就绪
    output wire            dmem_read_req,     // 读请求
    output wire            dmem_pair_read_req,
    output wire            dmem_we,          // 写使能
    output wire [XLEN-1:0] dmem_wdata,      // 写数据
    output wire [XLEN/8-1:0] dmem_wstrb,   // 写字节使能
    output wire [XLEN-1:0] dmem_pair_wdata,
    output wire [XLEN/8-1:0] dmem_pair_wstrb,

    // ------------------------------------------------------------
    // 调试和状态信号
    // ------------------------------------------------------------
    output wire            trap,             // trap 标志
    output wire [XLEN-1:0] debug_pc         // 调试 PC 值
);

localparam integer SHAMT_W = $clog2(XLEN);
localparam integer REDIRECT_CACHE_INDEX_BITS = $clog2(REDIRECT_CACHE_ENTRIES);
localparam integer REDIRECT_CACHE_INDEX_MSB = REDIRECT_CACHE_INDEX_BITS + 1;
localparam integer BRANCH_BHT_INDEX_BITS = $clog2(BRANCH_BHT_ENTRIES);

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
reg            fetch_epoch_r;
reg            fetch_req_epoch_r;
reg            fetch_req_epoch_d1_r;
reg [1:0]      fetch_drop_count_r;     // 取指丢弃计数 (用于流水线冲刷)
reg            fetch_buf0_valid_r;      // 取指缓冲区 0 有效
reg [XLEN-1:0] fetch_buf0_pc_r;       // 取指缓冲区 0 PC
reg [31:0]     fetch_buf0_instruction_r; // 取指缓冲区 0 指令
reg            fetch_buf1_valid_r;      // 取指缓冲区 1 有效
reg [XLEN-1:0] fetch_buf1_pc_r;       // 取指缓冲区 1 PC
reg [31:0]     fetch_buf1_instruction_r; // 取指缓冲区 1 指令
reg            redirect_cache_valid_r [0:REDIRECT_CACHE_ENTRIES-1];
(* ram_style = "distributed" *)
reg [XLEN-1:0] redirect_cache_pc_r [0:REDIRECT_CACHE_ENTRIES-1];
(* ram_style = "distributed" *)
reg [31:0]     redirect_cache_instruction_r [0:REDIRECT_CACHE_ENTRIES-1];
integer        redirect_cache_reset_idx;
reg            branch_bht_valid_r [0:BRANCH_BHT_ENTRIES-1];
reg [XLEN-1:0] branch_bht_pc_r [0:BRANCH_BHT_ENTRIES-1];
reg [1:0]      branch_bht_counter_r [0:BRANCH_BHT_ENTRIES-1];
integer        branch_bht_reset_idx;
reg            id_branch_predict_pending_r;
reg [XLEN-1:0] id_branch_predict_pending_branch_pc_r;
reg [XLEN-1:0] id_branch_predict_pending_pc_r;

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
reg [4:0]      id_ex_rs3_addr_r;                  // optional rd-as-source 地址
reg [4:0]      id_ex_rd_addr_r;                   // rd 地址
reg            id_ex_rs1_en_r;                      // rs1 读使能
reg            id_ex_rs2_en_r;                      // rs2 读使能
reg            id_ex_rs3_en_r;                      // optional rd-as-source 读使能
reg            id_ex_rd_en_r;                       // rd 写使能
reg            id_ex_illegal_r;                     // 非法指令
reg [XLEN-1:0] id_ex_rs1_value_r;                  // rs1 值
reg [XLEN-1:0] id_ex_rs2_value_r;                  // rs2 值
reg [XLEN-1:0] id_ex_rs3_value_r;                  // optional rd-as-source 值
reg [XLEN-1:0] id_ex_imm_r;                       // 立即数
(* max_fanout = 16 *) reg [5:0]      id_ex_alu_op_r;   // ALU 操作码
reg            id_ex_alu_src1_pc_r;                  // ALU 源 1 选择
reg            id_ex_alu_src2_imm_r;                 // ALU 源 2 选择
reg            id_ex_branch_r;                       // 分支标志
reg [2:0]      id_ex_branch_funct3_r;               // 分支条件
reg            id_ex_branch_predict_taken_r;
reg [XLEN-1:0] id_ex_branch_predict_pc_r;
reg            id_ex_jump_r;                         // 跳转标志
reg            id_ex_jalr_r;                        // JALR 标志
reg            id_ex_load_r;                         // 加载标志
reg            id_ex_store_r;                        // 存储标志
reg [1:0]      id_ex_wb_sel_r;                     // 写回选择
reg [1:0]      id_ex_mem_size_r;                   // 内存访问宽度
reg            id_ex_mem_unsigned_r;                 // 无符号加载
reg            id_ex_mem_indexed_r;                  // XThead indexed 访存
reg [1:0]      id_ex_mem_index_shift_r;              // XThead indexed scale
reg            id_ex_mem_pair_r;
reg            id_ex_mem_base_update_r;              // XThead auto-inc/dec base update
reg            id_ex_mem_base_update_before_r;
reg            id_ex_store_data_from_rd_r;           // XThead store 数据来自 rd 字段
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
reg            ex_mem_mem_pair_r;
reg [XLEN-1:0] ex_mem_pair_store_data_r;
reg [XLEN/8-1:0] ex_mem_pair_store_wstrb_r;
reg            ex_mem_base_update_en_r;
reg [4:0]      ex_mem_base_update_addr_r;
reg [XLEN-1:0] ex_mem_base_update_value_r;
reg            ex_mem_load_preissued_r;

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
reg            mem_wb_base_update_en_r;
reg [4:0]      mem_wb_base_update_addr_r;
reg [XLEN-1:0] mem_wb_base_update_value_r;

    // ================================================================
    // 组合逻辑信号定义
    // ================================================================

wire [XLEN-1:0] if_pc_next;                    // 下一 PC

    // 译码阶段输出信号
wire [XLEN-1:0] id_pc4;
wire [4:0]      id_rs1_addr;
wire [4:0]      id_rs2_addr;
wire [4:0]      id_rs3_addr;
wire [4:0]      id_rd_addr;
wire            id_rs1_en;
wire            id_rs2_en;
wire            id_rs3_en;
wire            id_rd_en;
wire            id_illegal;
wire [XLEN-1:0] id_imm;
wire [5:0]      id_alu_op;
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
wire            id_mem_indexed;
wire [1:0]      id_mem_index_shift;
wire            id_mem_pair;
wire            id_mem_base_update;
wire            id_mem_base_update_before;
wire            id_store_data_from_rd;
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
wire            id_branch_decode_candidate;
wire            id_branch_decode_eq_class;
wire            id_branch_decode_cmp_class;
wire            id_branch_decode_idex_forward_cheap;
wire            id_branch_decode_idex_value_available;
wire            id_branch_decode_exmem_value_available;
wire            id_branch_decode_rs1_idex_match;
wire            id_branch_decode_rs2_idex_match;
wire            id_branch_decode_rs1_exmem_match;
wire            id_branch_decode_rs2_exmem_match;
wire            id_branch_decode_rs1_pending;
wire            id_branch_decode_rs2_pending;
wire            id_branch_decode_operands_ready;
wire [XLEN-1:0] id_branch_decode_idex_alu_lhs;
wire [XLEN-1:0] id_branch_decode_idex_alu_rhs;
wire [XLEN-1:0] id_branch_decode_idex_forward_data;
reg  [XLEN-1:0] id_branch_decode_idex_cheap_result;
wire [XLEN-1:0] id_branch_decode_rs1_value;
wire [XLEN-1:0] id_branch_decode_rs2_value;
wire [XLEN-1:0] id_branch_decode_cmp_rs1_value;
wire [XLEN-1:0] id_branch_decode_cmp_rs2_value;
wire            id_branch_decode_eq;
wire            id_branch_decode_lt;
wire            id_branch_decode_ltu;
wire            id_branch_decode_taken;
wire            id_branch_decode_redirect_valid;
wire [XLEN-1:0] id_branch_decode_redirect_pc;
wire            id_jal_x0_decode_redirect_valid;
wire            id_jalr_decode_redirect_valid;
wire [XLEN-1:0] id_jalr_decode_target_sum;
wire [XLEN-1:0] id_jalr_decode_redirect_pc;
wire            id_decode_redirect_valid;
wire [XLEN-1:0] id_decode_redirect_pc;
wire            id_branch_predict_redirect_valid;
wire [XLEN-1:0] id_branch_predict_redirect_pc;
wire [BRANCH_BHT_INDEX_BITS-1:0] id_branch_bht_lookup_index;
wire            id_branch_bht_hit;
wire            id_branch_dynamic_predict_taken;
wire            id_branch_static_predict_taken;
wire            id_branch_predict_request_valid;
wire            id_branch_predict_pending_hit;
wire            id_branch_predict_pending_latch_valid;
wire            id_branch_predict_pending_clear_valid;
wire            id_branch_fold_candidate;
wire            id_branch_fold_valid;
wire            id_branch_not_taken_fold_candidate;
wire            id_branch_not_taken_fold_valid;
wire            id_branch_not_taken_fold_recent_operand_match;
wire [XLEN-1:0] id_branch_not_taken_fold_pc;
wire [31:0]     id_branch_not_taken_fold_instruction;
wire [XLEN-1:0] id_branch_not_taken_next_pc;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] not_taken_next_cache_lookup_index_direct;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] not_taken_next_cache_lookup_index_xor;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] not_taken_next_cache_lookup_index;
wire            not_taken_next_cache_hit;
wire            not_taken_next_cache_match;
wire            not_taken_next_cache_deliver;
wire [31:0]     not_taken_next_cache_instruction;
wire [6:0]      not_taken_next_opcode;
wire [4:0]      not_taken_next_rs1_addr;
wire [4:0]      not_taken_next_rs2_addr;
wire            not_taken_next_rs1_en;
wire            not_taken_next_rs2_en;
wire            not_taken_next_uses_fold_load_rd;
wire [XLEN-1:0] fold_decode_pc;
wire [31:0]     fold_decode_instruction;
wire            id_branch_any_fold_valid;
wire            id_any_fold_valid;
wire            id_early_alu_pair_candidate;
wire            id_early_alu_pair_valid;
wire            id_early_alu_pair_fetch_deliver;
wire            id_early_alu_pair_cache_deliver;
wire [31:0]     id_early_alu_pair_instruction;
wire            id_alu_dep_fold_candidate;
wire            id_alu_dep_fold_valid;
wire            id_alu_dep_fold_fetch_deliver;
wire            id_alu_dep_fold_cache_deliver;
wire            id_alu_dep_uses_rs1;
wire            id_alu_dep_uses_rs2;
wire            id_alu_dep_uses_rs3;
wire            id_early_alu_current_simple;
wire            id_early_alu_current_ready;
wire            id_early_alu_current_rs1_pending;
wire            id_early_alu_current_rs2_pending;
wire            id_early_alu_current_self_dep;
wire            id_early_alu_current_waw_pending;
wire            id_early_alu_fold_simple;
wire            id_early_alu_fold_simple_op;
wire            id_early_alu_fold_dep;
wire [XLEN-1:0] id_early_alu_lhs;
wire [XLEN-1:0] id_early_alu_rhs;
reg  [XLEN-1:0] id_early_alu_result;
wire            fold_issue_rs1_en;
wire            fold_issue_rs2_en;
wire            fold_issue_rs3_en;
wire [XLEN-1:0] fold_issue_rs1_value;
wire [XLEN-1:0] fold_issue_rs2_value;
wire [XLEN-1:0] fold_issue_rs3_value;
wire            branch_bht_ex_update_valid;
wire            branch_bht_id_update_valid;
wire            branch_bht_update_valid;
wire [BRANCH_BHT_INDEX_BITS-1:0] branch_bht_update_index;
wire [XLEN-1:0] branch_bht_update_pc;
wire            branch_bht_update_taken;
wire            id_jal_predict_redirect_valid;
wire [XLEN-1:0] id_jal_predict_redirect_pc;
wire [XLEN-1:0] id_predict_redirect_pc;

    // 寄存器堆信号
wire [XLEN-1:0] rs1_rdata;
wire [XLEN-1:0] rs2_rdata;
wire [XLEN-1:0] rs3_rdata;
wire [XLEN-1:0] fold_rs1_rdata;
wire [XLEN-1:0] fold_rs2_rdata;
wire [XLEN-1:0] fold_rs3_rdata;

wire [XLEN-1:0] fold_id_pc4;
wire [4:0]      fold_id_rs1_addr;
wire [4:0]      fold_id_rs2_addr;
wire [4:0]      fold_id_rs3_addr;
wire [4:0]      fold_id_rd_addr;
wire            fold_id_rs1_en;
wire            fold_id_rs2_en;
wire            fold_id_rs3_en;
wire            fold_id_rd_en;
wire            fold_id_illegal;
wire [XLEN-1:0] fold_id_imm;
wire [5:0]      fold_id_alu_op;
wire            fold_id_alu_src1_pc;
wire            fold_id_alu_src2_imm;
wire            fold_id_branch;
wire [2:0]      fold_id_branch_funct3;
wire            fold_id_jump;
wire            fold_id_jalr;
wire            fold_id_load;
wire            fold_id_store;
wire [1:0]      fold_id_wb_sel;
wire [1:0]      fold_id_mem_size;
wire            fold_id_mem_unsigned;
wire            fold_id_mem_indexed;
wire [1:0]      fold_id_mem_index_shift;
wire            fold_id_mem_pair;
wire            fold_id_mem_base_update;
wire            fold_id_mem_base_update_before;
wire            fold_id_store_data_from_rd;
wire            fold_id_word_op;
wire            fold_id_is_lui;
wire            fold_id_csr_valid;
wire [1:0]      fold_id_csr_cmd;
wire            fold_id_csr_use_imm;
wire [2:0]      fold_id_csr_sel;
wire            fold_id_csr_read_valid;
wire            fold_id_csr_write_allowed;
wire            fold_id_ecall;
wire            fold_id_ebreak;
wire            fold_id_mret;
wire [XLEN-1:0] fold_id_rs1_value;
wire [XLEN-1:0] fold_id_rs2_value;
wire            fold_id_hazard;
wire            fold_id_control_or_trap;
wire            rf_rd2_wen;
wire [4:0]      rf_rd2_addr;
wire [XLEN-1:0] rf_rd2_wdata;

assign id_rs3_addr = id_rd_addr;
assign id_rs3_en = id_store_data_from_rd ||
    (id_alu_op == `YH_rv_cpu_ALU_TH_MULA) ||
    (id_alu_op == `YH_rv_cpu_ALU_TH_MULAH);
assign fold_id_rs3_addr = fold_id_rd_addr;
assign fold_id_rs3_en = fold_id_store_data_from_rd ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_TH_MULA) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_TH_MULAH);
assign rf_rd2_wen =
    (mem_wb_valid_r && mem_wb_base_update_en_r && !trap_r) ||
    (id_early_alu_pair_valid && !trap_r);
assign rf_rd2_addr =
    id_early_alu_pair_valid ? id_rd_addr : mem_wb_base_update_addr_r;
assign rf_rd2_wdata =
    id_early_alu_pair_valid ? id_early_alu_result : mem_wb_base_update_value_r;

    // 冒险检测信号
wire            hazard_stall_decode;
wire            store_data_load_use_hazard;
wire            stall_decode;
wire [1:0]      forward_a_sel;
wire [1:0]      forward_b_sel;

    // 执行阶段转发后的操作数
reg [XLEN-1:0] ex_rs1_forwarded;
reg [XLEN-1:0] ex_rs2_forwarded;
reg [XLEN-1:0] ex_store_src_forwarded;

    // 执行阶段输出
wire [XLEN-1:0] ex_exec_result;
wire [XLEN-1:0] ex_mem_addr;
wire [XLEN-1:0] ex_mem_base_update_value;
wire [XLEN-1:0] ex_store_data;
wire [XLEN/8-1:0] ex_store_wstrb;
wire [XLEN-1:0] ex_pair_store_data;
wire [XLEN/8-1:0] ex_pair_store_wstrb;
wire            ex_redirect_en;
wire            ex_redirect_valid_raw;
wire            ex_redirect_valid;
wire            ex_branch_predict_hit_valid;
wire            ex_branch_predict_recover_valid;
wire [XLEN-1:0] ex_redirect_pc;
wire            ex_mem_misaligned;
wire [XLEN-1:0] ex_exec_result_final;
wire            ex_rd_en_effective;

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
wire            async_redirect_refill_valid;
wire [XLEN-1:0] async_redirect_refill_next_pc;
wire            decode_flush_valid;
wire            if_id_duplicate_fetch;

    // 访存阶段输出
wire [XLEN-1:0] mem_load_data;
wire            mem_wait;

    // Dcache中间信号 (当DCACHE_EN=1时，mem_stage连接到此，dcache再连接到dmem)
wire [XLEN-1:0] mem_stage_dmem_addr;
wire            mem_stage_dmem_read_req;
wire            mem_stage_dmem_pair_read_req;
wire [XLEN-1:0] mem_stage_dmem_wdata;
wire [XLEN/8-1:0] mem_stage_dmem_wstrb;
wire [XLEN-1:0] mem_stage_dmem_pair_wdata;
wire [XLEN/8-1:0] mem_stage_dmem_pair_wstrb;
wire [XLEN-1:0] mem_stage_dmem_rdata;
wire [XLEN-1:0] mem_pair_load_data;
wire [XLEN-1:0] ex_mem_base_update_forward_data;
wire [XLEN-1:0] mem_stage_load_data;
wire            ex_dmem_preissue_valid;
wire            mem_stage_dmem_port_busy;
wire            ex_mem_dcacheable;
wire            dcache_direct_access;
wire            dcache_direct_load;

    // DCache CPU接口信号 (当DCACHE_EN=1时使用)
wire            dcache_cpu_req;
wire            dcache_cpu_we;
wire [XLEN-1:0] dcache_cpu_addr;
wire [XLEN-1:0] dcache_cpu_wdata;
wire [XLEN/8-1:0] dcache_cpu_wstrb;
wire [1:0]      dcache_cpu_size;
wire [XLEN-1:0] dcache_cpu_rdata;
wire            dcache_cpu_rvalid;
wire            dcache_cpu_wait;

    // DCache Mem接口信号
wire [XLEN-1:0] dcache_mem_addr;
wire            dcache_mem_req;
wire            dcache_mem_we;
wire [XLEN-1:0] dcache_mem_wdata;
wire [XLEN/8-1:0] dcache_mem_wstrb;
wire [XLEN-1:0] dcache_mem_rdata;
wire            dcache_mem_rvalid;
wire            dcache_mem_ready;

    // Icache中间信号 (当ICACHE_EN=1时，if_stage连接到此，icache再连接到imem)
wire            icache_cpu_req;
wire [XLEN-1:0] icache_cpu_addr;
wire [31:0]     icache_cpu_rdata;
wire            icache_cpu_rvalid;
wire            icache_cpu_wait;

    // Icache Mem接口信号
wire [XLEN-1:0] icache_mem_addr;
wire            icache_mem_req;
wire            icache_mem_we;
wire [31:0]     icache_mem_wdata;
wire [3:0]      icache_mem_wstrb;
wire [31:0]     icache_mem_rdata;
wire            icache_mem_rvalid;

    // 写回阶段输出
wire [XLEN-1:0] wb_data;

    // 前递数据
wire [XLEN-1:0] ex_mem_forward_data;
wire            ex_mem_load_data_ready;
wire            id_ex_load_forward_ready;
wire            ex_mem_load_forward_ready;

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
wire [REDIRECT_CACHE_INDEX_BITS-1:0] redirect_cache_lookup_index_direct;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] redirect_cache_lookup_index_xor;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] redirect_cache_lookup_index;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] redirect_cache_update_index_direct;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] redirect_cache_update_index_xor;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] redirect_cache_update_index;
wire            redirect_cache_lookup_valid;
wire            redirect_cache_hit;
wire            redirect_cache_deliver;
wire            redirect_cache_update_valid;
wire [31:0]     redirect_cache_instruction;
wire [XLEN-1:0] fold_next_cache_pc;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] fold_next_cache_lookup_index_direct;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] fold_next_cache_lookup_index_xor;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] fold_next_cache_lookup_index;
wire            fold_next_cache_hit;
wire            fold_next_cache_deliver;
wire [31:0]     fold_next_cache_instruction;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] regular_cache_lookup_index_direct;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] regular_cache_lookup_index_xor;
wire [REDIRECT_CACHE_INDEX_BITS-1:0] regular_cache_lookup_index;
wire            regular_cache_lookup_valid;
wire            regular_cache_hit;
wire            regular_cache_deliver;
wire [31:0]     regular_cache_instruction;
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
localparam [1:0] IMEM_DROP_COUNT = 2'd0;

    // ================================================================
    // 输出信号分配
    // ================================================================
assign trap = trap_r;
assign debug_pc = pc_r;

    // ICache中间信号
wire [XLEN-1:0] ifetch_addr;          // 取指地址中间信号
wire [31:0]     instr_data_from_mem;  // 来自内存/缓存的指令数据
wire            fetch_request_ok;
wire            fetch_request_epoch;
wire            fetch_rsp_epoch;
wire            fetch_rsp_epoch_match;
wire            fetch_redirect_target_request;
wire            fetch_regular_request;
wire            fetch_imem_req;

assign instr_data_from_mem = (ICACHE_EN != 0) ? icache_cpu_rdata : imem_rdata;
assign fetch_request_epoch = fetch_control_redirect_valid ? !fetch_epoch_r : fetch_epoch_r;

    // ================================================================
    // 取指请求逻辑
    // ICACHE_EN=0: 直接驱动imem_req
    // ICACHE_EN=1: imem_req由gen_icache块中的icache_mem_req驱动(见line ~1062)
    // ================================================================
assign fetch_request_ok = (IMEM_SYNC != 0) && !trap_r && !mem_wait && !stall_decode;
assign fetch_redirect_target_request =
    fetch_request_ok &&
    (IMEM_OUTPUT_REG == 0) &&
    (ICACHE_EN == 0) &&
    fetch_control_redirect_valid &&
    !fetch_redirect_reuse_valid &&
    !redirect_cache_deliver;
assign fetch_regular_request = fetch_request_ok && !fetch_control_redirect_valid && !regular_cache_deliver;
assign fetch_imem_req = fetch_regular_request || fetch_redirect_target_request;

    // ================================================================
    // 执行阶段前递数据选择
    // ================================================================
assign ex_mem_forward_data =
    ((ex_mem_wb_sel_r == `YH_rv_cpu_WB_MEM) && ex_mem_load_forward_ready) ? mem_load_data :
    (ex_mem_wb_sel_r == `YH_rv_cpu_WB_PC4) ? ex_mem_pc4_r : ex_mem_exec_result_r;
assign ex_mem_base_update_forward_data =
    (ex_mem_mem_pair_r && ex_mem_load_r && ex_mem_load_forward_ready) ?
        mem_pair_load_data : ex_mem_base_update_value_r;
assign ex_mem_dcacheable =
    (ex_mem_mem_addr_r[31:0] >= DCACHEABLE_BASE) &&
    (ex_mem_mem_addr_r[31:0] < DCACHEABLE_LIMIT);
assign dcache_direct_access =
    (DCACHE_EN != 0) &&
    ex_mem_valid_r &&
    (ex_mem_load_r || ex_mem_store_r) &&
    (ex_mem_mem_pair_r || !ex_mem_dcacheable);
assign dcache_direct_load = dcache_direct_access && ex_mem_load_r;
assign ex_mem_load_data_ready =
    (DCACHE_EN != 0) ? (dcache_direct_load ? dmem_rvalid : dcache_cpu_rvalid) :
    (DMEM_SYNC == 0) ? 1'b1 :
    dmem_rvalid;
assign id_ex_load_forward_ready = (LOAD_USE_FAST_FORWARD != 0) || ex_dmem_preissue_valid;
assign ex_mem_load_forward_ready = (LOAD_USE_FAST_FORWARD != 0) || ex_mem_load_data_ready;

assign store_data_load_use_hazard =
    if_id_valid_r &&
    id_rs3_en &&
    (
        (id_ex_valid_r && id_ex_load_r && !id_ex_load_forward_ready && id_ex_rd_en_r &&
         (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == id_rs3_addr)) ||
        (ex_mem_valid_r && ex_mem_load_r && !ex_mem_load_forward_ready && ex_mem_rd_en_r &&
         (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_rs3_addr))
    );

assign stall_decode = hazard_stall_decode || store_data_load_use_hazard;

// ================================================================
// 重定向有效性
// ================================================================
assign ex_redirect_valid_raw = id_ex_valid_r && ex_redirect_en;
assign ex_branch_predict_hit_valid =
    id_ex_branch_predict_taken_r &&
    ex_redirect_valid_raw &&
    (ex_redirect_pc == id_ex_branch_predict_pc_r);
assign ex_branch_predict_recover_valid =
    id_ex_valid_r &&
    id_ex_branch_predict_taken_r &&
    id_ex_branch_r &&
    !ex_redirect_en;
assign ex_redirect_valid = ex_redirect_valid_raw && !ex_branch_predict_hit_valid;

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

generate
if (ENABLE_XTHEAD_COND_MOVE != 0) begin : gen_xthead_cond_move_wen
    assign ex_rd_en_effective =
        id_ex_rd_en_r &&
        !(((id_ex_alu_op_r == `YH_rv_cpu_ALU_TH_MVEQZ) && (ex_rs2_forwarded != ZERO_XLEN)) ||
          ((id_ex_alu_op_r == `YH_rv_cpu_ALU_TH_MVNEZ) && (ex_rs2_forwarded == ZERO_XLEN)));
end else begin : gen_no_xthead_cond_move_wen
    assign ex_rd_en_effective = id_ex_rd_en_r;
end
endgenerate

    // ================================================================
    // Trap 有效性 (中断 + 同步异常)
    // ================================================================
assign ex_trap_valid = ex_interrupt_valid || ex_sync_trap_valid;

    // ================================================================
    // 控制流重定向有效性
    // 包括 trap、mret、跳转/分支
    // ================================================================
assign ex_control_redirect_valid =
    ex_trap_valid ||
    ex_mret_valid ||
    ex_redirect_valid ||
    ex_branch_predict_recover_valid;
assign ex_fetch_redirect_valid = ex_control_redirect_valid;
assign ex_decode_flush_valid = ex_control_redirect_valid;

    // ================================================================
    // ID 阶段早分支重定向
    // 覆盖 operand-ready 的 taken conditional branch；ID/EX 前递只接低成本 ALU 结果
    // ================================================================
assign id_branch_decode_candidate =
    if_id_valid_r &&
    id_branch;
assign id_branch_decode_eq_class = (id_branch_funct3[2:1] == 2'b00);
assign id_branch_decode_cmp_class = id_branch_funct3[2];
assign id_branch_decode_idex_forward_cheap =
    !id_ex_is_lui_r &&
    (id_ex_wb_sel_r == `YH_rv_cpu_WB_ALU) &&
    (
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_ADD) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SUB) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SLT) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SLTU) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_XOR) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_OR)  ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_AND) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SLL) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SRL) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SRA) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SH1ADD) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SH2ADD) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SH3ADD) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_TH_ADDSL1) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_TH_ADDSL2) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_TH_ADDSL3) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_TH_MVEQZ) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_TH_MVNEZ) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_CZERO_EQZ) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_CZERO_NEZ) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_ANDN) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_SEXT_H) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_ZEXT_H) ||
        (id_ex_alu_op_r == `YH_rv_cpu_ALU_BEXT)
    );
assign id_branch_decode_idex_value_available =
    (ENABLE_ID_BRANCH_EX_FORWARD != 0) &&
    (id_branch_decode_eq_class || id_branch_decode_cmp_class) &&
    id_branch_decode_idex_forward_cheap &&
    !id_ex_load_r &&
    !id_ex_csr_valid_r;
assign id_branch_decode_exmem_value_available =
    !ex_mem_load_r || ex_mem_load_forward_ready;
assign id_branch_decode_rs1_idex_match =
    id_rs1_en &&
    id_ex_valid_r &&
    ex_rd_en_effective &&
    (id_ex_rd_addr_r != 5'd0) &&
    (id_ex_rd_addr_r == id_rs1_addr);
assign id_branch_decode_rs2_idex_match =
    id_rs2_en &&
    id_ex_valid_r &&
    ex_rd_en_effective &&
    (id_ex_rd_addr_r != 5'd0) &&
    (id_ex_rd_addr_r == id_rs2_addr);
assign id_branch_decode_rs1_exmem_match =
    id_rs1_en &&
    ex_mem_valid_r &&
    ex_mem_rd_en_r &&
    (ex_mem_rd_addr_r != 5'd0) &&
    (ex_mem_rd_addr_r == id_rs1_addr);
assign id_branch_decode_rs2_exmem_match =
    id_rs2_en &&
    ex_mem_valid_r &&
    ex_mem_rd_en_r &&
    (ex_mem_rd_addr_r != 5'd0) &&
    (ex_mem_rd_addr_r == id_rs2_addr);
assign id_branch_decode_rs1_pending =
    id_branch_decode_rs1_idex_match ? !id_branch_decode_idex_value_available :
    (id_branch_decode_rs1_exmem_match && !id_branch_decode_exmem_value_available);
assign id_branch_decode_rs2_pending =
    id_branch_decode_rs2_idex_match ? !id_branch_decode_idex_value_available :
    (id_branch_decode_rs2_exmem_match && !id_branch_decode_exmem_value_available);
assign id_branch_decode_operands_ready =
    !id_branch_decode_rs1_pending &&
    !id_branch_decode_rs2_pending;
assign id_branch_decode_idex_alu_lhs = id_ex_alu_src1_pc_r ? id_ex_pc_r : ex_rs1_forwarded;
assign id_branch_decode_idex_alu_rhs = id_ex_alu_src2_imm_r ? id_ex_imm_r : ex_rs2_forwarded;
always @* begin
    case (id_ex_alu_op_r)
        `YH_rv_cpu_ALU_SUB: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs - id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_SLT: id_branch_decode_idex_cheap_result = {{(XLEN-1){1'b0}}, ($signed(id_branch_decode_idex_alu_lhs) < $signed(id_branch_decode_idex_alu_rhs))};
        `YH_rv_cpu_ALU_SLTU: id_branch_decode_idex_cheap_result = {{(XLEN-1){1'b0}}, (id_branch_decode_idex_alu_lhs < id_branch_decode_idex_alu_rhs)};
        `YH_rv_cpu_ALU_XOR: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs ^ id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_OR:  id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs | id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_AND: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs & id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_SLL: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs << id_branch_decode_idex_alu_rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SRL: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs >> id_branch_decode_idex_alu_rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SRA: id_branch_decode_idex_cheap_result = $signed(id_branch_decode_idex_alu_lhs) >>> id_branch_decode_idex_alu_rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SH1ADD: id_branch_decode_idex_cheap_result = (id_branch_decode_idex_alu_lhs << 1) + id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_SH2ADD: id_branch_decode_idex_cheap_result = (id_branch_decode_idex_alu_lhs << 2) + id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_SH3ADD: id_branch_decode_idex_cheap_result = (id_branch_decode_idex_alu_lhs << 3) + id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_TH_ADDSL1: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs + (id_branch_decode_idex_alu_rhs << 1);
        `YH_rv_cpu_ALU_TH_ADDSL2: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs + (id_branch_decode_idex_alu_rhs << 2);
        `YH_rv_cpu_ALU_TH_ADDSL3: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs + (id_branch_decode_idex_alu_rhs << 3);
        `YH_rv_cpu_ALU_TH_MVEQZ:  id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs;
        `YH_rv_cpu_ALU_TH_MVNEZ:  id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs;
        `YH_rv_cpu_ALU_CZERO_EQZ: id_branch_decode_idex_cheap_result = (id_branch_decode_idex_alu_rhs == ZERO_XLEN) ? ZERO_XLEN : id_branch_decode_idex_alu_lhs;
        `YH_rv_cpu_ALU_CZERO_NEZ: id_branch_decode_idex_cheap_result = (id_branch_decode_idex_alu_rhs != ZERO_XLEN) ? ZERO_XLEN : id_branch_decode_idex_alu_lhs;
        `YH_rv_cpu_ALU_ANDN: id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs & ~id_branch_decode_idex_alu_rhs;
        `YH_rv_cpu_ALU_SEXT_H: id_branch_decode_idex_cheap_result = {{(XLEN-16){id_branch_decode_idex_alu_lhs[15]}}, id_branch_decode_idex_alu_lhs[15:0]};
        `YH_rv_cpu_ALU_ZEXT_H: id_branch_decode_idex_cheap_result = {{(XLEN-16){1'b0}}, id_branch_decode_idex_alu_lhs[15:0]};
        `YH_rv_cpu_ALU_BEXT: id_branch_decode_idex_cheap_result = {{(XLEN-1){1'b0}}, id_branch_decode_idex_alu_lhs[id_branch_decode_idex_alu_rhs[SHAMT_W-1:0]]};
        default:           id_branch_decode_idex_cheap_result = id_branch_decode_idex_alu_lhs + id_branch_decode_idex_alu_rhs;
    endcase
end
assign id_branch_decode_idex_forward_data = id_branch_decode_idex_cheap_result;
assign id_branch_decode_rs1_value =
    (id_branch_decode_rs1_idex_match && id_branch_decode_idex_value_available) ?
        id_branch_decode_idex_forward_data :
    (id_branch_decode_rs1_exmem_match && id_branch_decode_exmem_value_available) ?
        ex_mem_forward_data :
    id_rs1_value;
assign id_branch_decode_rs2_value =
    (id_branch_decode_rs2_idex_match && id_branch_decode_idex_value_available) ?
        id_branch_decode_idex_forward_data :
    (id_branch_decode_rs2_exmem_match && id_branch_decode_exmem_value_available) ?
        ex_mem_forward_data :
    id_rs2_value;
assign id_branch_decode_cmp_rs1_value =
    (id_branch_decode_rs1_idex_match && id_branch_decode_idex_value_available) ?
        id_branch_decode_idex_forward_data :
    (id_branch_decode_rs1_exmem_match && id_branch_decode_exmem_value_available) ?
        ex_mem_forward_data :
    id_rs1_value;
assign id_branch_decode_cmp_rs2_value =
    (id_branch_decode_rs2_idex_match && id_branch_decode_idex_value_available) ?
        id_branch_decode_idex_forward_data :
    (id_branch_decode_rs2_exmem_match && id_branch_decode_exmem_value_available) ?
        ex_mem_forward_data :
    id_rs2_value;
assign id_branch_decode_eq = (id_branch_decode_rs1_value == id_branch_decode_rs2_value);
assign id_branch_decode_lt = ($signed(id_branch_decode_cmp_rs1_value) < $signed(id_branch_decode_cmp_rs2_value));
assign id_branch_decode_ltu = (id_branch_decode_cmp_rs1_value < id_branch_decode_cmp_rs2_value);
assign id_branch_decode_taken =
    id_branch_decode_candidate &&
    id_branch_decode_operands_ready &&
    (
        ((id_branch_funct3 == 3'b000) &&  id_branch_decode_eq)  ||
        ((id_branch_funct3 == 3'b001) && !id_branch_decode_eq)  ||
        ((id_branch_funct3 == 3'b100) &&  id_branch_decode_lt)  ||
        ((id_branch_funct3 == 3'b101) && !id_branch_decode_lt)  ||
        ((id_branch_funct3 == 3'b110) &&  id_branch_decode_ltu) ||
        ((id_branch_funct3 == 3'b111) && !id_branch_decode_ltu)
    );
assign id_branch_decode_redirect_valid =
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    id_branch_decode_taken;
assign id_branch_decode_redirect_pc = if_id_pc_r + id_imm;
assign id_jal_x0_decode_redirect_valid =
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    if_id_valid_r &&
    id_jump &&
    !id_jalr &&
    (id_rd_addr == 5'd0);
assign id_jalr_decode_target_sum = id_branch_decode_rs1_value + id_imm;
assign id_jalr_decode_redirect_pc = {id_jalr_decode_target_sum[XLEN-1:1], 1'b0};
assign id_jalr_decode_redirect_valid =
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    if_id_valid_r &&
    id_jump &&
    id_jalr &&
    !id_branch_decode_rs1_pending;
assign id_decode_redirect_valid =
    id_branch_decode_redirect_valid ||
    id_jal_x0_decode_redirect_valid ||
    id_jalr_decode_redirect_valid;
assign id_decode_redirect_pc =
    id_jal_x0_decode_redirect_valid ? (if_id_pc_r + id_imm) :
    id_jalr_decode_redirect_valid ? id_jalr_decode_redirect_pc :
    id_branch_decode_redirect_pc;
assign id_branch_bht_lookup_index = if_id_pc_r[BRANCH_BHT_INDEX_BITS+1:2];
assign id_branch_bht_hit =
    (ENABLE_DYNAMIC_BRANCH_PREDICT != 0) &&
    branch_bht_valid_r[id_branch_bht_lookup_index] &&
    (branch_bht_pc_r[id_branch_bht_lookup_index] == if_id_pc_r);
assign id_branch_dynamic_predict_taken =
    id_branch_bht_hit &&
    ((BRANCH_BHT_STRONG_ONLY != 0) ?
        (branch_bht_counter_r[id_branch_bht_lookup_index] == 2'b11) :
        branch_bht_counter_r[id_branch_bht_lookup_index][1]);
assign id_branch_static_predict_taken =
    (BRANCH_STATIC_PREDICT_MODE >= 2) ? 1'b1 :
    (BRANCH_STATIC_PREDICT_MODE == 1) ?
        (id_imm[XLEN-1] || (id_branch_funct3 == 3'b001) || (id_branch_funct3 == 3'b111)) :
        (id_imm[XLEN-1] || (id_branch_funct3 == 3'b001));
assign id_branch_predict_pending_hit =
    id_branch_predict_pending_r &&
    (id_branch_predict_pending_branch_pc_r == if_id_pc_r);
assign id_branch_predict_request_valid =
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    if_id_valid_r &&
    id_branch &&
    !id_illegal &&
    (id_branch_static_predict_taken || id_branch_dynamic_predict_taken) &&
    (!stall_decode || id_branch_dynamic_predict_taken) &&
    !id_branch_decode_operands_ready;
assign id_branch_predict_redirect_valid =
    id_branch_predict_request_valid &&
    !id_branch_predict_pending_hit;
assign id_branch_predict_redirect_pc = if_id_pc_r + id_imm;
assign id_branch_predict_pending_latch_valid =
    id_branch_predict_redirect_valid &&
    stall_decode;
assign id_branch_predict_pending_clear_valid =
    pipeline_run &&
    !stall_decode &&
    if_id_valid_r &&
    id_branch_predict_pending_hit;
assign branch_bht_ex_update_valid =
    (ENABLE_DYNAMIC_BRANCH_PREDICT != 0) &&
    id_ex_valid_r &&
    id_ex_branch_r &&
    !id_ex_illegal_r &&
    !ex_trap_valid;
assign branch_bht_id_update_valid =
    (ENABLE_DYNAMIC_BRANCH_PREDICT != 0) &&
    id_branch_decode_redirect_valid;
assign branch_bht_update_valid = branch_bht_ex_update_valid || branch_bht_id_update_valid;
assign branch_bht_update_pc = branch_bht_ex_update_valid ? id_ex_pc_r : if_id_pc_r;
assign branch_bht_update_taken = branch_bht_ex_update_valid ? ex_redirect_en : 1'b1;
assign branch_bht_update_index = branch_bht_update_pc[BRANCH_BHT_INDEX_BITS+1:2];
assign id_branch_fold_candidate =
    (ENABLE_ID_BRANCH_FOLD != 0) &&
    id_branch_decode_redirect_valid &&
    redirect_cache_deliver;
assign id_branch_not_taken_fold_pc = if_id_pc_r + {{(XLEN-3){1'b0}}, 3'd4};
assign id_branch_not_taken_fold_instruction = regular_cache_instruction;
assign id_branch_not_taken_next_pc = if_id_pc_r + {{(XLEN-4){1'b0}}, 4'd8};
assign id_branch_not_taken_fold_candidate =
    (ENABLE_ID_BRANCH_FOLD != 0) &&
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    if_id_valid_r &&
    id_branch &&
    !id_illegal &&
    id_branch_decode_operands_ready &&
    !id_branch_decode_taken &&
    regular_cache_deliver &&
    (ifetch_addr == id_branch_not_taken_fold_pc);
assign id_branch_not_taken_fold_recent_operand_match =
    id_branch_decode_rs1_idex_match ||
    id_branch_decode_rs2_idex_match ||
    id_branch_decode_rs1_exmem_match ||
    id_branch_decode_rs2_exmem_match;
assign not_taken_next_opcode = not_taken_next_cache_instruction[6:0];
assign not_taken_next_rs1_addr = not_taken_next_cache_instruction[19:15];
assign not_taken_next_rs2_addr = not_taken_next_cache_instruction[24:20];
assign not_taken_next_rs1_en =
    (not_taken_next_opcode == 7'b0110011) ||
    (not_taken_next_opcode == 7'b0010011) ||
    (not_taken_next_opcode == 7'b0000011) ||
    (not_taken_next_opcode == 7'b0100011) ||
    (not_taken_next_opcode == 7'b1100011) ||
    (not_taken_next_opcode == 7'b1100111) ||
    (not_taken_next_opcode == 7'b1110011);
assign not_taken_next_rs2_en =
    (not_taken_next_opcode == 7'b0110011) ||
    (not_taken_next_opcode == 7'b0100011) ||
    (not_taken_next_opcode == 7'b1100011);
assign not_taken_next_uses_fold_load_rd =
    fold_id_rd_en &&
    (fold_id_rd_addr != 5'd0) &&
    not_taken_next_cache_match &&
    (
        (not_taken_next_rs1_en && (not_taken_next_rs1_addr == fold_id_rd_addr)) ||
        (not_taken_next_rs2_en && (not_taken_next_rs2_addr == fold_id_rd_addr))
    );
assign fold_id_control_or_trap =
    fold_id_illegal ||
    fold_id_branch ||
    fold_id_jump ||
    fold_id_csr_valid ||
    fold_id_ecall ||
    fold_id_ebreak ||
    fold_id_mret;
assign fold_id_hazard =
    (fold_id_rs1_en && id_ex_valid_r && id_ex_load_r && id_ex_rd_en_r &&
     (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == fold_id_rs1_addr)) ||
    (fold_id_rs2_en && id_ex_valid_r && id_ex_load_r && id_ex_rd_en_r &&
     (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == fold_id_rs2_addr)) ||
    (fold_id_rs3_en && id_ex_valid_r && id_ex_load_r && id_ex_rd_en_r &&
     (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == fold_id_rs3_addr)) ||
    (fold_id_rs1_en && ex_mem_valid_r && ex_mem_load_r && !ex_mem_load_data_ready && ex_mem_rd_en_r &&
     (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == fold_id_rs1_addr)) ||
    (fold_id_rs2_en && ex_mem_valid_r && ex_mem_load_r && !ex_mem_load_data_ready && ex_mem_rd_en_r &&
     (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == fold_id_rs2_addr)) ||
    (fold_id_rs3_en && ex_mem_valid_r && ex_mem_load_r && !ex_mem_load_data_ready && ex_mem_rd_en_r &&
     (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == fold_id_rs3_addr));
assign id_branch_fold_valid =
    id_branch_fold_candidate &&
    !fold_id_control_or_trap &&
    !fold_id_hazard;
assign id_branch_not_taken_fold_valid =
    id_branch_not_taken_fold_candidate &&
    !fold_id_control_or_trap &&
    (!fold_id_load ||
     ((ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD != 0) &&
      !id_branch_not_taken_fold_recent_operand_match &&
      !not_taken_next_uses_fold_load_rd)) &&
    !fold_id_hazard;
assign id_branch_any_fold_valid =
    id_branch_fold_valid ||
    id_branch_not_taken_fold_valid;
assign id_any_fold_valid =
    id_branch_any_fold_valid ||
    id_early_alu_pair_valid ||
    id_alu_dep_fold_valid;

assign id_early_alu_current_simple =
    ((ENABLE_ID_ALU_PAIR_FOLD != 0) || (ENABLE_ID_ALU_DEP_FOLD != 0)) &&
    if_id_valid_r &&
    !id_illegal &&
    !id_branch &&
    !id_jump &&
    !id_load &&
    !id_store &&
    !id_csr_valid &&
    !id_ecall &&
    !id_ebreak &&
    !id_mret &&
    id_rd_en &&
    (id_rd_addr != 5'd0) &&
    (id_wb_sel == `YH_rv_cpu_WB_ALU) &&
    (
        (id_alu_op == `YH_rv_cpu_ALU_ADD) ||
        (id_alu_op == `YH_rv_cpu_ALU_SUB) ||
        (id_alu_op == `YH_rv_cpu_ALU_SLT) ||
        (id_alu_op == `YH_rv_cpu_ALU_SLTU) ||
        (id_alu_op == `YH_rv_cpu_ALU_XOR) ||
        (id_alu_op == `YH_rv_cpu_ALU_OR)  ||
        (id_alu_op == `YH_rv_cpu_ALU_AND) ||
        (id_alu_op == `YH_rv_cpu_ALU_SLL) ||
        (id_alu_op == `YH_rv_cpu_ALU_SRL) ||
        (id_alu_op == `YH_rv_cpu_ALU_SRA) ||
        (id_alu_op == `YH_rv_cpu_ALU_SH1ADD) ||
        (id_alu_op == `YH_rv_cpu_ALU_SH2ADD) ||
        (id_alu_op == `YH_rv_cpu_ALU_SH3ADD) ||
        (id_alu_op == `YH_rv_cpu_ALU_TH_ADDSL1) ||
        (id_alu_op == `YH_rv_cpu_ALU_TH_ADDSL2) ||
        (id_alu_op == `YH_rv_cpu_ALU_TH_ADDSL3) ||
        (id_alu_op == `YH_rv_cpu_ALU_TH_MVEQZ) ||
        (id_alu_op == `YH_rv_cpu_ALU_TH_MVNEZ) ||
        (id_alu_op == `YH_rv_cpu_ALU_CZERO_EQZ) ||
        (id_alu_op == `YH_rv_cpu_ALU_CZERO_NEZ) ||
        (id_alu_op == `YH_rv_cpu_ALU_ANDN) ||
        (id_alu_op == `YH_rv_cpu_ALU_SEXT_H) ||
        (id_alu_op == `YH_rv_cpu_ALU_ZEXT_H) ||
        (id_alu_op == `YH_rv_cpu_ALU_BEXT)
    );
assign id_early_alu_current_rs1_pending =
    id_rs1_en &&
    (
        (id_ex_valid_r &&
         ((id_ex_rd_en_r && (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == id_rs1_addr)) ||
          ((id_ex_mem_base_update_r || (id_ex_mem_pair_r && id_ex_load_r)) &&
           (id_ex_rs1_addr_r != 5'd0) && (id_ex_rs1_addr_r == id_rs1_addr)))) ||
        (ex_mem_valid_r &&
         ((ex_mem_rd_en_r && (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_rs1_addr)) ||
          (ex_mem_base_update_en_r && (ex_mem_base_update_addr_r != 5'd0) &&
           (ex_mem_base_update_addr_r == id_rs1_addr))))
    );
assign id_early_alu_current_rs2_pending =
    id_rs2_en &&
    (
        (id_ex_valid_r &&
         ((id_ex_rd_en_r && (id_ex_rd_addr_r != 5'd0) && (id_ex_rd_addr_r == id_rs2_addr)) ||
          ((id_ex_mem_base_update_r || (id_ex_mem_pair_r && id_ex_load_r)) &&
           (id_ex_rs1_addr_r != 5'd0) && (id_ex_rs1_addr_r == id_rs2_addr)))) ||
        (ex_mem_valid_r &&
         ((ex_mem_rd_en_r && (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_rs2_addr)) ||
          (ex_mem_base_update_en_r && (ex_mem_base_update_addr_r != 5'd0) &&
           (ex_mem_base_update_addr_r == id_rs2_addr))))
    );
assign id_early_alu_current_self_dep =
    id_rd_en &&
    (id_rd_addr != 5'd0) &&
    (
        (id_rs1_en && (id_rs1_addr == id_rd_addr)) ||
        (id_rs2_en && (id_rs2_addr == id_rd_addr))
    );
assign id_early_alu_current_waw_pending =
    id_rd_en &&
    (id_rd_addr != 5'd0) &&
    (
        (id_ex_valid_r &&
         ((id_ex_rd_en_r && (id_ex_rd_addr_r == id_rd_addr)) ||
          ((id_ex_mem_base_update_r || (id_ex_mem_pair_r && id_ex_load_r)) &&
           (id_ex_rs1_addr_r == id_rd_addr)))) ||
        (ex_mem_valid_r &&
         ((ex_mem_rd_en_r && (ex_mem_rd_addr_r == id_rd_addr)) ||
          (ex_mem_base_update_en_r && (ex_mem_base_update_addr_r == id_rd_addr))))
    );
assign id_early_alu_current_ready =
    id_early_alu_current_simple &&
    !id_early_alu_current_rs1_pending &&
    !id_early_alu_current_rs2_pending &&
    !id_early_alu_current_self_dep &&
    !id_early_alu_current_waw_pending;
assign id_early_alu_fold_simple_op =
    (fold_id_alu_op == `YH_rv_cpu_ALU_ADD) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SUB) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SLT) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SLTU) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_XOR) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_OR)  ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_AND) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SLL) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SRL) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SRA) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SH1ADD) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SH2ADD) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SH3ADD) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_TH_ADDSL1) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_TH_ADDSL2) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_TH_ADDSL3) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_TH_MVEQZ) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_TH_MVNEZ) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_CZERO_EQZ) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_CZERO_NEZ) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_ANDN) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_SEXT_H) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_ZEXT_H) ||
    (fold_id_alu_op == `YH_rv_cpu_ALU_BEXT);
assign id_early_alu_fold_simple =
    !fold_id_illegal &&
    !fold_id_branch &&
    !fold_id_jump &&
    !fold_id_load &&
    !fold_id_store &&
    !fold_id_csr_valid &&
    !fold_id_ecall &&
    !fold_id_ebreak &&
    !fold_id_mret &&
    id_early_alu_fold_simple_op &&
    (fold_id_wb_sel == `YH_rv_cpu_WB_ALU);
assign id_early_alu_fold_dep =
    id_rd_en &&
    (id_rd_addr != 5'd0) &&
    (
        (fold_id_rs1_en && (fold_id_rs1_addr == id_rd_addr)) ||
        (fold_id_rs2_en && (fold_id_rs2_addr == id_rd_addr)) ||
        (fold_id_rs3_en && (fold_id_rs3_addr == id_rd_addr))
    );
assign id_early_alu_pair_fetch_deliver =
    fetch_queue_valid &&
    (fetch_queue_pc == id_branch_not_taken_fold_pc);
assign id_early_alu_pair_cache_deliver =
    regular_cache_deliver &&
    (ifetch_addr == id_branch_not_taken_fold_pc);
assign id_early_alu_pair_instruction =
    id_early_alu_pair_fetch_deliver ? fetch_queue_instruction : regular_cache_instruction;
assign id_early_alu_pair_candidate =
    (ENABLE_ID_ALU_PAIR_FOLD != 0) &&
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    if_id_valid_r &&
    (id_early_alu_pair_fetch_deliver || id_early_alu_pair_cache_deliver);
assign id_early_alu_pair_valid =
    id_early_alu_pair_candidate &&
    id_early_alu_current_ready &&
    id_early_alu_fold_simple &&
    !id_early_alu_fold_dep &&
    !fold_id_hazard &&
    !(mem_wb_valid_r && mem_wb_base_update_en_r);
assign id_alu_dep_fold_fetch_deliver = id_early_alu_pair_fetch_deliver;
assign id_alu_dep_fold_cache_deliver = id_early_alu_pair_cache_deliver;
assign id_alu_dep_uses_rs1 =
    fold_id_rs1_en &&
    (fold_id_rs1_addr == id_rd_addr);
assign id_alu_dep_uses_rs2 =
    fold_id_rs2_en &&
    (fold_id_rs2_addr == id_rd_addr);
assign id_alu_dep_uses_rs3 =
    fold_id_rs3_en &&
    (fold_id_rs3_addr == id_rd_addr);
assign id_alu_dep_fold_candidate =
    (ENABLE_ID_ALU_DEP_FOLD != 0) &&
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    if_id_valid_r &&
    (id_alu_dep_fold_fetch_deliver || id_alu_dep_fold_cache_deliver);
assign id_alu_dep_fold_valid =
    id_alu_dep_fold_candidate &&
    id_early_alu_current_ready &&
    id_early_alu_fold_simple &&
    id_early_alu_fold_dep &&
    fold_id_rd_en &&
    (fold_id_rd_addr == id_rd_addr) &&
    !fold_id_hazard &&
    !id_early_alu_pair_valid;
assign fold_issue_rs1_en =
    fold_id_rs1_en &&
    !(id_alu_dep_fold_valid && id_alu_dep_uses_rs1);
assign fold_issue_rs2_en =
    fold_id_rs2_en &&
    !(id_alu_dep_fold_valid && id_alu_dep_uses_rs2);
assign fold_issue_rs3_en =
    fold_id_rs3_en &&
    !(id_alu_dep_fold_valid && id_alu_dep_uses_rs3);
assign fold_issue_rs1_value =
    (id_alu_dep_fold_valid && id_alu_dep_uses_rs1) ? id_early_alu_result : fold_id_rs1_value;
assign fold_issue_rs2_value =
    (id_alu_dep_fold_valid && id_alu_dep_uses_rs2) ? id_early_alu_result : fold_id_rs2_value;
assign fold_issue_rs3_value =
    (id_alu_dep_fold_valid && id_alu_dep_uses_rs3) ? id_early_alu_result : fold_rs3_rdata;
assign id_early_alu_lhs = id_is_lui ? ZERO_XLEN : (id_alu_src1_pc ? if_id_pc_r : id_rs1_value);
assign id_early_alu_rhs = id_alu_src2_imm ? id_imm : id_rs2_value;
always @* begin
    case (id_alu_op)
        `YH_rv_cpu_ALU_SUB: id_early_alu_result = id_early_alu_lhs - id_early_alu_rhs;
        `YH_rv_cpu_ALU_SLT: id_early_alu_result = {{(XLEN-1){1'b0}}, ($signed(id_early_alu_lhs) < $signed(id_early_alu_rhs))};
        `YH_rv_cpu_ALU_SLTU: id_early_alu_result = {{(XLEN-1){1'b0}}, (id_early_alu_lhs < id_early_alu_rhs)};
        `YH_rv_cpu_ALU_XOR: id_early_alu_result = id_early_alu_lhs ^ id_early_alu_rhs;
        `YH_rv_cpu_ALU_OR:  id_early_alu_result = id_early_alu_lhs | id_early_alu_rhs;
        `YH_rv_cpu_ALU_AND: id_early_alu_result = id_early_alu_lhs & id_early_alu_rhs;
        `YH_rv_cpu_ALU_SLL: id_early_alu_result = id_early_alu_lhs << id_early_alu_rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SRL: id_early_alu_result = id_early_alu_lhs >> id_early_alu_rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SRA: id_early_alu_result = $signed(id_early_alu_lhs) >>> id_early_alu_rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SH1ADD: id_early_alu_result = (id_early_alu_lhs << 1) + id_early_alu_rhs;
        `YH_rv_cpu_ALU_SH2ADD: id_early_alu_result = (id_early_alu_lhs << 2) + id_early_alu_rhs;
        `YH_rv_cpu_ALU_SH3ADD: id_early_alu_result = (id_early_alu_lhs << 3) + id_early_alu_rhs;
        `YH_rv_cpu_ALU_TH_ADDSL1: id_early_alu_result = id_early_alu_lhs + (id_early_alu_rhs << 1);
        `YH_rv_cpu_ALU_TH_ADDSL2: id_early_alu_result = id_early_alu_lhs + (id_early_alu_rhs << 2);
        `YH_rv_cpu_ALU_TH_ADDSL3: id_early_alu_result = id_early_alu_lhs + (id_early_alu_rhs << 3);
        `YH_rv_cpu_ALU_TH_MVEQZ:  id_early_alu_result = id_early_alu_lhs;
        `YH_rv_cpu_ALU_TH_MVNEZ:  id_early_alu_result = id_early_alu_lhs;
        `YH_rv_cpu_ALU_CZERO_EQZ: id_early_alu_result = (id_early_alu_rhs == ZERO_XLEN) ? ZERO_XLEN : id_early_alu_lhs;
        `YH_rv_cpu_ALU_CZERO_NEZ: id_early_alu_result = (id_early_alu_rhs != ZERO_XLEN) ? ZERO_XLEN : id_early_alu_lhs;
        `YH_rv_cpu_ALU_ANDN: id_early_alu_result = id_early_alu_lhs & ~id_early_alu_rhs;
        `YH_rv_cpu_ALU_SEXT_H: id_early_alu_result = {{(XLEN-16){id_early_alu_lhs[15]}}, id_early_alu_lhs[15:0]};
        `YH_rv_cpu_ALU_ZEXT_H: id_early_alu_result = {{(XLEN-16){1'b0}}, id_early_alu_lhs[15:0]};
        `YH_rv_cpu_ALU_BEXT: id_early_alu_result = {{(XLEN-1){1'b0}}, id_early_alu_lhs[id_early_alu_rhs[SHAMT_W-1:0]]};
        default: id_early_alu_result = id_early_alu_lhs + id_early_alu_rhs;
    endcase
end

assign id_jal_predict_redirect_valid =
    pipeline_run &&
    !ex_fetch_redirect_valid &&
    !stall_decode &&
    if_id_valid_r &&
    id_jump &&
    !id_jalr &&
    !id_illegal &&
    (id_rd_addr != 5'd0);
assign id_jal_predict_redirect_pc = if_id_pc_r + id_imm;
assign id_predict_redirect_pc =
    id_jal_predict_redirect_valid ? id_jal_predict_redirect_pc :
    id_branch_predict_redirect_pc;
assign fetch_control_redirect_valid =
    ex_fetch_redirect_valid ||
    id_decode_redirect_valid ||
    id_jal_predict_redirect_valid ||
    id_branch_predict_redirect_valid;
assign fetch_control_redirect_pc =
    ex_fetch_redirect_valid ? ex_control_redirect_pc :
    id_decode_redirect_valid ? id_decode_redirect_pc :
    id_predict_redirect_pc;
assign decode_flush_valid = ex_decode_flush_valid;
assign async_redirect_refill_valid =
    (IMEM_SYNC == 0) &&
    (
        id_decode_redirect_valid ||
        id_jal_predict_redirect_valid ||
        id_branch_predict_redirect_valid ||
        ex_redirect_valid ||
        ex_branch_predict_recover_valid
    );
assign async_redirect_refill_next_pc =
    fetch_control_redirect_pc + {{(XLEN-3){1'b0}}, 3'd4};

    // ================================================================
    // 取指缓冲重用逻辑
    // ================================================================
assign fetch_reuse_redirect_valid = ex_redirect_valid;
assign fetch_reuse_redirect_pc = ex_redirect_pc;

    // ================================================================
    // 内存等待信号 (同步内存访问或DCache)
    // ================================================================
    // 当DCACHE_EN=1时，使用dcache的等待信号
    // 否则使用原始的同步内存等待逻辑
assign mem_wait = DCACHE_EN ?
    (dcache_cpu_wait || ((DMEM_SYNC != 0) && dcache_direct_load && !dmem_rvalid)) :
    ((DMEM_SYNC != 0) && ex_mem_valid_r && ex_mem_load_r && !dmem_rvalid);

    // ================================================================
    // 取指响应 PC 和有效信号
    // ================================================================
assign fetch_rsp_pc = (IMEM_OUTPUT_REG != 0) ? fetch_pc_d1_r : fetch_pc_r;
assign fetch_rsp_valid = (IMEM_OUTPUT_REG != 0) ? fetch_valid_d1_r : fetch_valid_r;
assign fetch_rsp_epoch = (IMEM_OUTPUT_REG != 0) ? fetch_req_epoch_d1_r : fetch_req_epoch_r;
assign fetch_rsp_epoch_match = (fetch_rsp_epoch == fetch_epoch_r) && !fetch_control_redirect_valid;

    // ================================================================
    // 取指丢弃响应
    // ================================================================
assign fetch_drop_response = (fetch_drop_count_r != 2'd0);

    // ================================================================
    // 取指流水线有效性
    // ================================================================
assign fetch_pipe_valid = (IMEM_SYNC != 0) ?
    (fetch_rsp_valid && imem_rvalid && !fetch_drop_response && fetch_rsp_epoch_match) :
    1'b0;

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
    instr_data_from_mem;

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
assign fetch_redirect_pipe_hit =
    (IMEM_SYNC != 0) &&
    fetch_reuse_redirect_valid &&
    !fetch_buffer_valid &&
    fetch_pipe_valid &&
    (fetch_rsp_pc == fetch_reuse_redirect_pc);
assign fetch_redirect_reuse_valid =
    (ENABLE_FETCH_REDIRECT_REUSE != 0) &&
    (fetch_redirect_buf0_hit || fetch_redirect_buf1_hit || fetch_redirect_pipe_hit);

assign redirect_cache_lookup_index_direct =
    fetch_control_redirect_pc[REDIRECT_CACHE_INDEX_MSB:2];
assign redirect_cache_lookup_index_xor =
    fetch_control_redirect_pc[REDIRECT_CACHE_INDEX_MSB:2] ^
    fetch_control_redirect_pc[(2*REDIRECT_CACHE_INDEX_MSB-1):(REDIRECT_CACHE_INDEX_MSB+1)];
assign redirect_cache_lookup_index =
    (REDIRECT_CACHE_XOR_INDEX != 0) ? redirect_cache_lookup_index_xor : redirect_cache_lookup_index_direct;
assign redirect_cache_update_index_direct =
    fetch_queue_pc[REDIRECT_CACHE_INDEX_MSB:2];
assign redirect_cache_update_index_xor =
    fetch_queue_pc[REDIRECT_CACHE_INDEX_MSB:2] ^
    fetch_queue_pc[(2*REDIRECT_CACHE_INDEX_MSB-1):(REDIRECT_CACHE_INDEX_MSB+1)];
assign redirect_cache_update_index =
    (REDIRECT_CACHE_XOR_INDEX != 0) ? redirect_cache_update_index_xor : redirect_cache_update_index_direct;
assign redirect_cache_lookup_valid =
    (IMEM_SYNC != 0) &&
    (ICACHE_EN == 0) &&
    (IMEM_OUTPUT_REG == 0) &&
    (ENABLE_REDIRECT_TARGET_CACHE != 0) &&
    fetch_control_redirect_valid &&
    !ex_trap_valid &&
    !ex_mret_valid;
assign redirect_cache_hit =
    redirect_cache_lookup_valid &&
    redirect_cache_valid_r[redirect_cache_lookup_index] &&
    (redirect_cache_pc_r[redirect_cache_lookup_index] == fetch_control_redirect_pc);
assign redirect_cache_deliver = redirect_cache_hit;
assign redirect_cache_instruction = redirect_cache_instruction_r[redirect_cache_lookup_index];
assign fold_next_cache_pc = fetch_control_redirect_pc + {{(XLEN-3){1'b0}}, 3'd4};
assign fold_next_cache_lookup_index_direct =
    fold_next_cache_pc[REDIRECT_CACHE_INDEX_MSB:2];
assign fold_next_cache_lookup_index_xor =
    fold_next_cache_pc[REDIRECT_CACHE_INDEX_MSB:2] ^
    fold_next_cache_pc[(2*REDIRECT_CACHE_INDEX_MSB-1):(REDIRECT_CACHE_INDEX_MSB+1)];
assign fold_next_cache_lookup_index =
    (REDIRECT_CACHE_XOR_INDEX != 0) ? fold_next_cache_lookup_index_xor : fold_next_cache_lookup_index_direct;
assign fold_next_cache_hit =
    id_branch_fold_valid &&
    redirect_cache_valid_r[fold_next_cache_lookup_index] &&
    (redirect_cache_pc_r[fold_next_cache_lookup_index] == fold_next_cache_pc);
assign fold_next_cache_deliver = fold_next_cache_hit;
assign fold_next_cache_instruction = redirect_cache_instruction_r[fold_next_cache_lookup_index];
assign not_taken_next_cache_lookup_index_direct =
    id_branch_not_taken_next_pc[REDIRECT_CACHE_INDEX_MSB:2];
assign not_taken_next_cache_lookup_index_xor =
    id_branch_not_taken_next_pc[REDIRECT_CACHE_INDEX_MSB:2] ^
    id_branch_not_taken_next_pc[(2*REDIRECT_CACHE_INDEX_MSB-1):(REDIRECT_CACHE_INDEX_MSB+1)];
assign not_taken_next_cache_lookup_index =
    (REDIRECT_CACHE_XOR_INDEX != 0) ? not_taken_next_cache_lookup_index_xor : not_taken_next_cache_lookup_index_direct;
assign not_taken_next_cache_match =
    redirect_cache_valid_r[not_taken_next_cache_lookup_index] &&
    (redirect_cache_pc_r[not_taken_next_cache_lookup_index] == id_branch_not_taken_next_pc);
assign not_taken_next_cache_hit =
    (id_branch_not_taken_fold_valid || id_early_alu_pair_valid || id_alu_dep_fold_valid) &&
    not_taken_next_cache_match;
assign not_taken_next_cache_deliver = not_taken_next_cache_hit;
assign not_taken_next_cache_instruction = redirect_cache_instruction_r[not_taken_next_cache_lookup_index];
assign regular_cache_lookup_index_direct =
    ifetch_addr[REDIRECT_CACHE_INDEX_MSB:2];
assign regular_cache_lookup_index_xor =
    ifetch_addr[REDIRECT_CACHE_INDEX_MSB:2] ^
    ifetch_addr[(2*REDIRECT_CACHE_INDEX_MSB-1):(REDIRECT_CACHE_INDEX_MSB+1)];
assign regular_cache_lookup_index =
    (REDIRECT_CACHE_XOR_INDEX != 0) ? regular_cache_lookup_index_xor : regular_cache_lookup_index_direct;
assign regular_cache_lookup_valid =
    (IMEM_SYNC != 0) &&
    (ICACHE_EN == 0) &&
    (IMEM_OUTPUT_REG == 0) &&
    (ENABLE_REDIRECT_TARGET_CACHE != 0) &&
    (ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP != 0) &&
    fetch_request_ok &&
    !fetch_control_redirect_valid &&
    !fetch_queue_valid;
assign regular_cache_hit =
    regular_cache_lookup_valid &&
    redirect_cache_valid_r[regular_cache_lookup_index] &&
    (redirect_cache_pc_r[regular_cache_lookup_index] == ifetch_addr);
assign regular_cache_deliver = regular_cache_hit;
assign regular_cache_instruction = redirect_cache_instruction_r[regular_cache_lookup_index];

    // ================================================================
    // IF/ID 流水线控制
    // ================================================================
assign if_id_fetch_valid = (IMEM_SYNC != 0) ?
    (fetch_queue_valid || fold_next_cache_deliver || not_taken_next_cache_deliver ||
     (redirect_cache_deliver && !id_branch_fold_valid) || regular_cache_deliver) :
    1'b1;
assign if_id_write_en = pipeline_run && (!stall_decode || decode_flush_valid);
assign if_id_duplicate_fetch =
    (IMEM_SYNC != 0) &&
    if_id_valid_r &&
    if_id_fetch_valid &&
    !stall_decode &&
    !decode_flush_valid &&
    (fetch_queue_pc == if_id_pc_r) &&
    (fetch_queue_instruction == if_id_instruction_r);
assign if_id_load_bubble =
    (id_branch_fold_valid && !fold_next_cache_deliver) ||
    (id_branch_not_taken_fold_valid && !not_taken_next_cache_deliver) ||
    (id_early_alu_pair_valid && !not_taken_next_cache_deliver) ||
    (id_alu_dep_fold_valid && !not_taken_next_cache_deliver) ||
    (decode_flush_valid && !async_redirect_refill_valid && !redirect_cache_deliver) ||
    ((IMEM_SYNC != 0) && fetch_control_redirect_valid && !redirect_cache_deliver) ||
    !if_id_fetch_valid;
assign if_id_next_valid = if_id_load_bubble ? 1'b0 : 1'b1;
assign if_id_data_write_en =
    (IMEM_SYNC != 0) ?
    (pipeline_run && !stall_decode && if_id_fetch_valid) :
    (pipeline_run && !stall_decode);
assign fold_decode_pc =
    (id_branch_not_taken_fold_candidate || id_early_alu_pair_candidate || id_alu_dep_fold_candidate) ? id_branch_not_taken_fold_pc :
    fetch_control_redirect_pc;
assign fold_decode_instruction =
    (id_early_alu_pair_candidate || id_alu_dep_fold_candidate) ? id_early_alu_pair_instruction :
    id_branch_not_taken_fold_candidate ? id_branch_not_taken_fold_instruction :
    redirect_cache_instruction;
assign redirect_cache_update_valid =
    (IMEM_SYNC != 0) &&
    (ICACHE_EN == 0) &&
    (IMEM_OUTPUT_REG == 0) &&
    (ENABLE_REDIRECT_TARGET_CACHE != 0) &&
    if_id_data_write_en &&
    fetch_queue_valid &&
    !redirect_cache_deliver;

assign id_ex_flush_valid_local = decode_flush_valid;
assign id_ex_stall_bubble_local = stall_decode;

    // ================================================================
    // IF/ID 下一拍数据和指令
    // ================================================================
assign if_id_next_pc = if_id_load_bubble ? ZERO_XLEN :
    fold_next_cache_deliver ? fold_next_cache_pc :
    not_taken_next_cache_deliver ? id_branch_not_taken_next_pc :
    redirect_cache_deliver ? fetch_control_redirect_pc :
    regular_cache_deliver ? ifetch_addr :
    ((IMEM_SYNC != 0) ? fetch_queue_pc : ifetch_addr);
assign if_id_next_instruction = if_id_load_bubble ? 32'h0000_0013 :
    fold_next_cache_deliver ? fold_next_cache_instruction :
    not_taken_next_cache_deliver ? not_taken_next_cache_instruction :
    redirect_cache_deliver ? redirect_cache_instruction :
    regular_cache_deliver ? regular_cache_instruction :
    ((IMEM_SYNC != 0) ? fetch_queue_instruction : instr_data_from_mem);

    // ================================================================
    // 控制流重定向 PC 选择
    // trap -> mtvec, mret -> mepc, 跳转 -> 目标地址
    // ================================================================
assign ex_control_redirect_pc =
    ex_trap_valid ? csr_mtvec_r :
    ex_mret_valid ? csr_mepc_r :
    ex_branch_predict_recover_valid ? id_ex_pc4_r :
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
                fetch_buf0_instruction_next_data = instr_data_from_mem;
            end
        end else begin
            if (fetch_buf0_load_data) begin
                if (fetch_buf0_load_rsp_data) begin
                    fetch_buf0_pc_next_data = fetch_rsp_pc;
                    fetch_buf0_instruction_next_data = instr_data_from_mem;
                end else begin
                    fetch_buf0_pc_next_data = fetch_buf1_pc_r;
                    fetch_buf0_instruction_next_data = fetch_buf1_instruction_r;
                end
            end
            if (fetch_buf1_load_data) begin
                fetch_buf1_pc_next_data = fetch_rsp_pc;
                fetch_buf1_instruction_next_data = instr_data_from_mem;
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
        if_id_pc_next_data = if_id_next_pc;
        if_id_instruction_next_data = if_id_next_instruction;
    end
end

    // ================================================================
    // 子模块实例化
    // ================================================================

    // 取指阶段
YH_rv_cpu_if_stage #(
    .XLEN(XLEN)
) u_if_stage (
    .pc_current  (pc_r),
    .redirect_en (fetch_control_redirect_valid),
    .redirect_pc (fetch_control_redirect_pc),
    .imem_addr   (ifetch_addr),
    .pc_next     (if_pc_next),
    .pc_plus_4   ()
);

    // 寄存器堆
YH_rv_cpu_regfile #(
    .XLEN(XLEN)
) u_regfile (
    .clk       (clk),
    .rst_n     (rst_n),
    .rs1_addr  (id_rs1_addr),
    .rs2_addr  (id_rs2_addr),
    .rs3_addr  (id_rs3_addr),
    .rs1_rdata (rs1_rdata),
    .rs2_rdata (rs2_rdata),
    .rs3_rdata (rs3_rdata),
    .fold_rs1_addr  (fold_id_rs1_addr),
    .fold_rs1_rdata (fold_rs1_rdata),
    .fold_rs2_addr  (fold_id_rs2_addr),
    .fold_rs2_rdata (fold_rs2_rdata),
    .fold_rs3_addr  (fold_id_rs3_addr),
    .fold_rs3_rdata (fold_rs3_rdata),
    .rd_wen    (mem_wb_valid_r && mem_wb_rd_en_r && !trap_r),
    .rd_addr   (mem_wb_rd_addr_r),
    .rd_wdata  (wb_data),
    .rd2_wen   (rf_rd2_wen),
    .rd2_addr  (rf_rd2_addr),
    .rd2_wdata (rf_rd2_wdata)
);

    // 译码阶段
YH_rv_cpu_id_stage #(
    .XLEN(XLEN),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION)
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
    .mem_indexed   (id_mem_indexed),
    .mem_index_shift(id_mem_index_shift),
    .mem_pair      (id_mem_pair),
    .mem_base_update(id_mem_base_update),
    .mem_base_update_before(id_mem_base_update_before),
    .store_data_from_rd(id_store_data_from_rd),
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
YH_rv_cpu_id_stage #(
    .XLEN(XLEN),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION)
) u_fold_target_id_stage (
    .pc            (fold_decode_pc),
    .instruction   (fold_decode_instruction),
    .rs1_rdata     (fold_rs1_rdata),
    .rs2_rdata     (fold_rs2_rdata),
    .pc4           (fold_id_pc4),
    .rs1_addr      (fold_id_rs1_addr),
    .rs2_addr      (fold_id_rs2_addr),
    .rd_addr       (fold_id_rd_addr),
    .rs1_en        (fold_id_rs1_en),
    .rs2_en        (fold_id_rs2_en),
    .rd_en         (fold_id_rd_en),
    .illegal       (fold_id_illegal),
    .imm           (fold_id_imm),
    .alu_op        (fold_id_alu_op),
    .alu_src1_pc   (fold_id_alu_src1_pc),
    .alu_src2_imm  (fold_id_alu_src2_imm),
    .branch        (fold_id_branch),
    .branch_funct3 (fold_id_branch_funct3),
    .jump          (fold_id_jump),
    .jalr          (fold_id_jalr),
    .load          (fold_id_load),
    .store         (fold_id_store),
    .wb_sel        (fold_id_wb_sel),
    .mem_size      (fold_id_mem_size),
    .mem_unsigned  (fold_id_mem_unsigned),
    .mem_indexed   (fold_id_mem_indexed),
    .mem_index_shift(fold_id_mem_index_shift),
    .mem_pair      (fold_id_mem_pair),
    .mem_base_update(fold_id_mem_base_update),
    .mem_base_update_before(fold_id_mem_base_update_before),
    .store_data_from_rd(fold_id_store_data_from_rd),
    .word_op       (fold_id_word_op),
    .is_lui        (fold_id_is_lui),
    .csr_valid     (fold_id_csr_valid),
    .csr_cmd       (fold_id_csr_cmd),
    .csr_use_imm   (fold_id_csr_use_imm),
    .csr_sel       (fold_id_csr_sel),
    .csr_read_valid(fold_id_csr_read_valid),
    .csr_write_allowed(fold_id_csr_write_allowed),
    .ecall         (fold_id_ecall),
    .ebreak        (fold_id_ebreak),
    .mret          (fold_id_mret),
    .rs1_value     (fold_id_rs1_value),
    .rs2_value     (fold_id_rs2_value)
);

YH_rv_cpu_hazard_unit #(
    .LOAD_USE_FAST_FORWARD(LOAD_USE_FAST_FORWARD)
) u_hazard_unit (
    .if_id_rs1_en   (if_id_valid_r && id_rs1_en),
    .if_id_rs2_en   (if_id_valid_r && id_rs2_en),
    .if_id_rs1_addr (id_rs1_addr),
    .if_id_rs2_addr (id_rs2_addr),
    .id_ex_valid    (id_ex_valid_r),
    .id_ex_load     (id_ex_load_r),
    .id_ex_load_ready(id_ex_load_forward_ready),
    .id_ex_rd_en    (id_ex_rd_en_r),
    .id_ex_rd_addr  (id_ex_rd_addr_r),
    .id_ex_rs1_en   (id_ex_rs1_en_r),
    .id_ex_rs2_en   (id_ex_rs2_en_r),
    .id_ex_rs1_addr (id_ex_rs1_addr_r),
    .id_ex_rs2_addr (id_ex_rs2_addr_r),
    .ex_mem_valid   (ex_mem_valid_r),
    .ex_mem_load    (ex_mem_load_r),
    .ex_mem_load_ready(ex_mem_load_data_ready),
    .ex_mem_rd_en   (ex_mem_rd_en_r),
    .ex_mem_rd_addr (ex_mem_rd_addr_r),
    .mem_wb_valid   (mem_wb_valid_r),
    .mem_wb_load    (mem_wb_wb_sel_r == `YH_rv_cpu_WB_MEM),
    .mem_wb_rd_en   (mem_wb_rd_en_r),
    .mem_wb_rd_addr (mem_wb_rd_addr_r),
    .stall_decode   (hazard_stall_decode),
    .forward_a_sel  (forward_a_sel),
    .forward_b_sel  (forward_b_sel),
    .dcache_wait    (DCACHE_EN ? dcache_cpu_wait : 1'b0),
    .icache_wait    (ICACHE_EN ? icache_cpu_wait : 1'b0)
);

    // ================================================================
    // 数据转发选择
    // ================================================================
always @* begin
    ex_rs1_forwarded = id_ex_rs1_value_r;
    ex_rs2_forwarded = id_ex_rs2_value_r;
    ex_store_src_forwarded = id_ex_rs3_value_r;

    if (id_ex_rs1_en_r && ex_mem_valid_r && ex_mem_rd_en_r &&
        (!ex_mem_load_r || ex_mem_load_forward_ready) &&
        (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_ex_rs1_addr_r)) begin
        ex_rs1_forwarded = ex_mem_forward_data;
    end else if (id_ex_rs1_en_r && ex_mem_valid_r && ex_mem_base_update_en_r &&
                 (ex_mem_base_update_addr_r != 5'd0) && (ex_mem_base_update_addr_r == id_ex_rs1_addr_r)) begin
        ex_rs1_forwarded = ex_mem_base_update_forward_data;
    end else if (id_ex_rs1_en_r && mem_wb_valid_r && mem_wb_rd_en_r &&
                 (mem_wb_rd_addr_r != 5'd0) && (mem_wb_rd_addr_r == id_ex_rs1_addr_r)) begin
        ex_rs1_forwarded = wb_data;
    end else if (id_ex_rs1_en_r && mem_wb_valid_r && mem_wb_base_update_en_r &&
                 (mem_wb_base_update_addr_r != 5'd0) && (mem_wb_base_update_addr_r == id_ex_rs1_addr_r)) begin
        ex_rs1_forwarded = mem_wb_base_update_value_r;
    end

    if (id_ex_rs2_en_r && ex_mem_valid_r && ex_mem_rd_en_r &&
        (!ex_mem_load_r || ex_mem_load_forward_ready) &&
        (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_ex_rs2_addr_r)) begin
        ex_rs2_forwarded = ex_mem_forward_data;
    end else if (id_ex_rs2_en_r && ex_mem_valid_r && ex_mem_base_update_en_r &&
                 (ex_mem_base_update_addr_r != 5'd0) && (ex_mem_base_update_addr_r == id_ex_rs2_addr_r)) begin
        ex_rs2_forwarded = ex_mem_base_update_forward_data;
    end else if (id_ex_rs2_en_r && mem_wb_valid_r && mem_wb_rd_en_r &&
                 (mem_wb_rd_addr_r != 5'd0) && (mem_wb_rd_addr_r == id_ex_rs2_addr_r)) begin
        ex_rs2_forwarded = wb_data;
    end else if (id_ex_rs2_en_r && mem_wb_valid_r && mem_wb_base_update_en_r &&
                 (mem_wb_base_update_addr_r != 5'd0) && (mem_wb_base_update_addr_r == id_ex_rs2_addr_r)) begin
        ex_rs2_forwarded = mem_wb_base_update_value_r;
    end

    if (id_ex_rs3_en_r && ex_mem_valid_r && ex_mem_rd_en_r &&
        (!ex_mem_load_r || ex_mem_load_forward_ready) &&
        (ex_mem_rd_addr_r != 5'd0) && (ex_mem_rd_addr_r == id_ex_rs3_addr_r)) begin
        ex_store_src_forwarded = ex_mem_forward_data;
    end else if (id_ex_rs3_en_r && ex_mem_valid_r && ex_mem_base_update_en_r &&
                 (ex_mem_base_update_addr_r != 5'd0) && (ex_mem_base_update_addr_r == id_ex_rs3_addr_r)) begin
        ex_store_src_forwarded = ex_mem_base_update_forward_data;
    end else if (id_ex_rs3_en_r && mem_wb_valid_r && mem_wb_rd_en_r &&
                 (mem_wb_rd_addr_r != 5'd0) && (mem_wb_rd_addr_r == id_ex_rs3_addr_r)) begin
        ex_store_src_forwarded = wb_data;
    end else if (id_ex_rs3_en_r && mem_wb_valid_r && mem_wb_base_update_en_r &&
                 (mem_wb_base_update_addr_r != 5'd0) && (mem_wb_base_update_addr_r == id_ex_rs3_addr_r)) begin
        ex_store_src_forwarded = mem_wb_base_update_value_r;
    end
end

    // 执行阶段
YH_rv_cpu_ex_stage #(
    .XLEN(XLEN),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION)
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
    .mem_indexed   (id_ex_mem_indexed_r),
    .mem_index_shift(id_ex_mem_index_shift_r),
    .store_data_from_rd(id_ex_store_data_from_rd_r),
    .store_data_value(ex_store_src_forwarded),
    .mem_base_update(id_ex_mem_base_update_r),
    .mem_base_update_before(id_ex_mem_base_update_before_r),
    .word_op       (id_ex_word_op_r),
    .is_lui        (id_ex_is_lui_r),
    .exec_result   (ex_exec_result),
    .mem_addr      (ex_mem_addr),
    .mem_base_update_value(ex_mem_base_update_value),
    .store_data    (ex_store_data),
    .store_wstrb   (ex_store_wstrb),
    .pair_store_data(ex_pair_store_data),
    .pair_store_wstrb(ex_pair_store_wstrb),
    .redirect_en   (ex_redirect_en),
    .redirect_pc   (ex_redirect_pc),
    .mem_misaligned(ex_mem_misaligned)
);

assign ex_dmem_preissue_valid =
    (DMEM_READ_PREISSUE != 0) &&
    (DCACHE_EN == 0) &&
    (DMEM_SYNC != 0) &&
    id_ex_valid_r &&
    id_ex_load_r &&
    !id_ex_mem_pair_r &&
    (id_ex_mem_size_r == `YH_rv_cpu_MEM_W) &&
    (ex_mem_addr[1:0] == 2'b00) &&
    !mem_stage_dmem_port_busy &&
    !ex_trap_valid &&
    !mem_wait;
assign mem_stage_dmem_port_busy =
    ex_mem_valid_r &&
    (
        ex_mem_store_r ||
        ex_mem_mem_pair_r ||
        (ex_mem_load_r && !ex_mem_load_preissued_r)
    );

    // ================================================================
    // 访存阶段 - 带DCache支持
    // ================================================================
    generate
        if (DCACHE_EN == 0) begin : gen_dcache_bypass
            // DCACHE_EN=0: 直接连接mem_stage到dmem，无缓存
            YH_rv_cpu_mem_stage #(
                .XLEN(XLEN)
            ) u_mem_stage (
                .valid         (ex_mem_valid_r),
                .load          (ex_mem_load_r),
                .store         (ex_mem_store_r),
                .mem_pair      (ex_mem_mem_pair_r),
                .mem_addr      (ex_mem_mem_addr_r),
                .store_data_in (ex_mem_store_data_r),
                .store_wstrb_in(ex_mem_store_wstrb_r),
                .pair_store_data_in(ex_mem_pair_store_data_r),
                .pair_store_wstrb_in(ex_mem_pair_store_wstrb_r),
                .mem_size      (ex_mem_mem_size_r),
                .mem_unsigned  (ex_mem_mem_unsigned_r),
                .dmem_rdata    (dmem_rdata),
                .dmem_pair_rdata(dmem_pair_rdata),
                .dmem_addr     (mem_stage_dmem_addr),
                .dmem_read_req (mem_stage_dmem_read_req),
                .dmem_pair_read_req(mem_stage_dmem_pair_read_req),
                .dmem_wdata    (mem_stage_dmem_wdata),
                .dmem_wstrb    (mem_stage_dmem_wstrb),
                .dmem_pair_wdata(mem_stage_dmem_pair_wdata),
                .dmem_pair_wstrb(mem_stage_dmem_pair_wstrb),
                .load_data     (mem_load_data),
                .pair_load_data(mem_pair_load_data)
            );
            assign dmem_addr = ex_dmem_preissue_valid ? ex_mem_addr : mem_stage_dmem_addr;
            assign dmem_read_req = ex_dmem_preissue_valid ||
                (mem_stage_dmem_read_req && !ex_mem_load_preissued_r);
            assign dmem_pair_read_req = mem_stage_dmem_pair_read_req && !ex_mem_load_preissued_r;
            assign dmem_wdata = mem_stage_dmem_wdata;
            assign dmem_wstrb = mem_stage_dmem_wstrb;
            assign dmem_pair_wdata = mem_stage_dmem_pair_wdata;
            assign dmem_pair_wstrb = mem_stage_dmem_pair_wstrb;
        end else begin : gen_dcache
            YH_rv_cpu_mem_stage #(
                .XLEN(XLEN)
            ) u_mem_stage_pair_bypass (
                .valid         (ex_mem_valid_r),
                .load          (ex_mem_load_r),
                .store         (ex_mem_store_r),
                .mem_pair      (ex_mem_mem_pair_r),
                .mem_addr      (ex_mem_mem_addr_r),
                .store_data_in (ex_mem_store_data_r),
                .store_wstrb_in(ex_mem_store_wstrb_r),
                .pair_store_data_in(ex_mem_pair_store_data_r),
                .pair_store_wstrb_in(ex_mem_pair_store_wstrb_r),
                .mem_size      (ex_mem_mem_size_r),
                .mem_unsigned  (ex_mem_mem_unsigned_r),
                .dmem_rdata    (dmem_rdata),
                .dmem_pair_rdata(dmem_pair_rdata),
                .dmem_addr     (mem_stage_dmem_addr),
                .dmem_read_req (mem_stage_dmem_read_req),
                .dmem_pair_read_req(mem_stage_dmem_pair_read_req),
                .dmem_wdata    (mem_stage_dmem_wdata),
                .dmem_wstrb    (mem_stage_dmem_wstrb),
                .dmem_pair_wdata(mem_stage_dmem_pair_wdata),
                .dmem_pair_wstrb(mem_stage_dmem_pair_wstrb),
                .load_data     (mem_stage_load_data),
                .pair_load_data(mem_pair_load_data)
            );
            // DCACHE_EN=1: 通过dcache连接
            // mem_stage连接到dcache CPU接口，dcache再连接到实际dmem

            // mem_stage信号连接到dcache CPU接口
            assign dcache_cpu_addr  = ex_mem_mem_addr_r;
            assign dcache_cpu_req   = ex_mem_valid_r && !ex_mem_mem_pair_r && ex_mem_dcacheable && (ex_mem_load_r || ex_mem_store_r);
            assign dcache_cpu_we    = ex_mem_valid_r && !ex_mem_mem_pair_r && ex_mem_dcacheable && ex_mem_store_r;
            assign dcache_cpu_wdata = ex_mem_store_data_r;
            assign dcache_cpu_wstrb = ex_mem_store_wstrb_r;
            assign dcache_cpu_size  = ex_mem_mem_size_r;

            // dcache输出load_data到流水线
            assign mem_load_data = dcache_direct_access ? mem_stage_load_data : dcache_cpu_rdata;

            // dcache实例
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
                .cpu_unsigned   (ex_mem_mem_unsigned_r),
                .cpu_rdata      (dcache_cpu_rdata),
                .cpu_rvalid     (dcache_cpu_rvalid),
                .cpu_wait       (dcache_cpu_wait),
                .mem_addr       (dcache_mem_addr),
                .mem_req        (dcache_mem_req),
                .mem_we         (dcache_mem_we),
                .mem_wdata      (dcache_mem_wdata),
                .mem_wstrb      (dcache_mem_wstrb),
                .mem_rdata      (dmem_rdata),
                .mem_rvalid     (dmem_rvalid),
                .mem_ready      (dmem_ready)
            );
            assign dmem_addr = dcache_direct_access ? mem_stage_dmem_addr : dcache_mem_addr;
            assign dmem_read_req = dcache_direct_access ? mem_stage_dmem_read_req : dcache_mem_req;
            assign dmem_pair_read_req = dcache_direct_access ? mem_stage_dmem_pair_read_req : 1'b0;
            assign dmem_we = dcache_direct_access ? (|mem_stage_dmem_wstrb) : dcache_mem_we;
            assign dmem_wdata = dcache_direct_access ? mem_stage_dmem_wdata : dcache_mem_wdata;
            assign dmem_wstrb = dcache_direct_access ? mem_stage_dmem_wstrb : dcache_mem_wstrb;
            assign dmem_pair_wdata = dcache_direct_access ? mem_stage_dmem_pair_wdata : {XLEN{1'b0}};
            assign dmem_pair_wstrb = dcache_direct_access ? mem_stage_dmem_pair_wstrb : {XLEN/8{1'b0}};
        end
    endgenerate

    // ================================================================
    // 取指阶段 - 带ICache支持
    // ================================================================
    generate
        if (ICACHE_EN == 0) begin : gen_icache_bypass
            // ICACHE_EN=0: 直接连接ifetch_addr到imem_addr
            assign imem_addr = ifetch_addr;
            assign imem_req = fetch_imem_req;
        end else begin : gen_icache
            // ICACHE_EN=1: 通过icache连接
            // ifetch_addr连接到icache CPU接口，icache再连接到实际imem

            // ifetch信号连接到icache CPU接口
            assign icache_cpu_addr = ifetch_addr;
            assign icache_cpu_req = fetch_imem_req;

            // icache输出到外部内存接口
            assign imem_addr = icache_mem_addr;
            assign imem_req = icache_mem_req;

            // icache实例
            YH_rv_cpu_icache #(
                .XLEN(XLEN),
                .CACHE_SIZE(4096),
                .BLOCK_SIZE(32),
                .ASSOC(1)
            ) u_icache (
                .clk        (clk),
                .rst_n      (rst_n),
                .cpu_addr   (icache_cpu_addr),
                .cpu_req    (icache_cpu_req),
                .cpu_rdata  (icache_cpu_rdata),
                .cpu_rvalid (icache_cpu_rvalid),
                .cpu_wait   (icache_cpu_wait),
                .mem_addr   (icache_mem_addr),
                .mem_req    (icache_mem_req),
                .mem_we     (icache_mem_we),
                .mem_wdata  (icache_mem_wdata),
                .mem_wstrb  (icache_mem_wstrb),
                .mem_rdata  (imem_rdata),
                .mem_rvalid (imem_rvalid)
            );
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
        fetch_epoch_r <= 1'b0;
        fetch_req_epoch_r <= 1'b0;
        fetch_req_epoch_d1_r <= 1'b0;

        id_ex_valid_r <= 1'b0;
        id_ex_pc_r <= ZERO_XLEN;
        id_ex_pc4_r <= ZERO_XLEN;
        id_ex_rs1_addr_r <= 5'd0;
        id_ex_rs2_addr_r <= 5'd0;
        id_ex_rs3_addr_r <= 5'd0;
        id_ex_rd_addr_r <= 5'd0;
        id_ex_rs1_en_r <= 1'b0;
        id_ex_rs2_en_r <= 1'b0;
        id_ex_rs3_en_r <= 1'b0;
        id_ex_rd_en_r <= 1'b0;
        id_ex_illegal_r <= 1'b0;
        id_ex_rs1_value_r <= ZERO_XLEN;
        id_ex_rs2_value_r <= ZERO_XLEN;
        id_ex_rs3_value_r <= ZERO_XLEN;
        id_ex_imm_r <= ZERO_XLEN;
        id_ex_alu_op_r <= `YH_rv_cpu_ALU_ADD;
        id_ex_alu_src1_pc_r <= 1'b0;
        id_ex_alu_src2_imm_r <= 1'b0;
        id_ex_branch_r <= 1'b0;
        id_ex_branch_funct3_r <= 3'b000;
        id_ex_branch_predict_taken_r <= 1'b0;
        id_ex_branch_predict_pc_r <= ZERO_XLEN;
        id_ex_jump_r <= 1'b0;
        id_ex_jalr_r <= 1'b0;
        id_ex_load_r <= 1'b0;
        id_ex_store_r <= 1'b0;
        id_ex_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        id_ex_mem_size_r <= `YH_rv_cpu_MEM_W;
        id_ex_mem_unsigned_r <= 1'b0;
        id_ex_mem_indexed_r <= 1'b0;
        id_ex_mem_index_shift_r <= 2'b00;
        id_ex_mem_pair_r <= 1'b0;
        id_ex_mem_base_update_r <= 1'b0;
        id_ex_mem_base_update_before_r <= 1'b0;
        id_ex_store_data_from_rd_r <= 1'b0;
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
        ex_mem_load_preissued_r <= 1'b0;
        ex_mem_store_r <= 1'b0;
        ex_mem_mem_size_r <= `YH_rv_cpu_MEM_W;
        ex_mem_mem_unsigned_r <= 1'b0;
        ex_mem_exec_result_r <= ZERO_XLEN;
        ex_mem_mem_addr_r <= ZERO_XLEN;
        ex_mem_store_data_r <= ZERO_XLEN;
        ex_mem_store_wstrb_r <= {(XLEN/8){1'b0}};
        ex_mem_mem_pair_r <= 1'b0;
        ex_mem_pair_store_data_r <= ZERO_XLEN;
        ex_mem_pair_store_wstrb_r <= {(XLEN/8){1'b0}};
        ex_mem_base_update_en_r <= 1'b0;
        ex_mem_base_update_addr_r <= 5'd0;
        ex_mem_base_update_value_r <= ZERO_XLEN;

        mem_wb_valid_r <= 1'b0;
        mem_wb_pc4_r <= ZERO_XLEN;
        mem_wb_rd_addr_r <= 5'd0;
        mem_wb_rd_en_r <= 1'b0;
        mem_wb_wb_sel_r <= `YH_rv_cpu_WB_ALU;
        mem_wb_exec_result_r <= ZERO_XLEN;
        mem_wb_load_data_r <= ZERO_XLEN;
        mem_wb_base_update_en_r <= 1'b0;
        mem_wb_base_update_addr_r <= 5'd0;
        mem_wb_base_update_value_r <= ZERO_XLEN;
    end else if (!trap_r) begin
        if (IMEM_SYNC != 0) begin
            fetch_pc_d1_r <= fetch_pc_r;
            fetch_valid_d1_r <= fetch_valid_r;
            fetch_req_epoch_d1_r <= fetch_req_epoch_r;
            fetch_pc_r <= imem_req ? ifetch_addr : ZERO_XLEN;
            if (imem_req) begin
                fetch_req_epoch_r <= fetch_request_epoch;
            end
            if (fetch_control_redirect_valid) begin
                fetch_epoch_r <= !fetch_epoch_r;
            end
            // For ICACHE_EN=1: set fetch_valid_r when cache miss (icache_cpu_wait=1), clear when data arrives (icache_cpu_rvalid=1)
            fetch_valid_r <= ((ICACHE_EN != 0) && icache_cpu_wait && !icache_cpu_rvalid) ||
                 ((ICACHE_EN == 0) && imem_req);
        end else begin
            fetch_pc_r <= ZERO_XLEN;
            fetch_pc_d1_r <= ZERO_XLEN;
            fetch_valid_r <= 1'b0;
            fetch_valid_d1_r <= 1'b0;
            fetch_epoch_r <= 1'b0;
            fetch_req_epoch_r <= 1'b0;
            fetch_req_epoch_d1_r <= 1'b0;
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
            mem_wb_base_update_en_r <= ex_mem_base_update_en_r;
            mem_wb_base_update_addr_r <= ex_mem_base_update_addr_r;
            mem_wb_base_update_value_r <= (ex_mem_mem_pair_r && ex_mem_load_r) ? mem_pair_load_data : ex_mem_base_update_value_r;

            if (ex_trap_valid) begin
                pc_r <= ex_control_redirect_pc;
                id_ex_valid_r <= 1'b0;
                id_ex_pc_r <= ZERO_XLEN;
                id_ex_pc4_r <= ZERO_XLEN;
                id_ex_rs1_addr_r <= 5'd0;
                id_ex_rs2_addr_r <= 5'd0;
                id_ex_rs3_addr_r <= 5'd0;
                id_ex_rd_addr_r <= 5'd0;
                id_ex_rs1_en_r <= 1'b0;
                id_ex_rs2_en_r <= 1'b0;
                id_ex_rs3_en_r <= 1'b0;
                id_ex_rd_en_r <= 1'b0;
                id_ex_illegal_r <= id_ex_illegal_r;
                id_ex_rs1_value_r <= ZERO_XLEN;
                id_ex_rs2_value_r <= ZERO_XLEN;
                id_ex_rs3_value_r <= ZERO_XLEN;
                id_ex_imm_r <= id_ex_imm_r;
                id_ex_alu_op_r <= id_ex_alu_op_r;
                id_ex_alu_src1_pc_r <= id_ex_alu_src1_pc_r;
                id_ex_alu_src2_imm_r <= id_ex_alu_src2_imm_r;
                id_ex_branch_r <= id_ex_branch_r;
                id_ex_branch_funct3_r <= id_ex_branch_funct3_r;
                id_ex_branch_predict_taken_r <= 1'b0;
                id_ex_branch_predict_pc_r <= ZERO_XLEN;
                id_ex_jump_r <= id_ex_jump_r;
                id_ex_jalr_r <= id_ex_jalr_r;
                id_ex_load_r <= id_ex_load_r;
                id_ex_store_r <= id_ex_store_r;
                id_ex_wb_sel_r <= id_ex_wb_sel_r;
                id_ex_mem_size_r <= id_ex_mem_size_r;
                id_ex_mem_unsigned_r <= id_ex_mem_unsigned_r;
                id_ex_mem_indexed_r <= id_ex_mem_indexed_r;
                id_ex_mem_index_shift_r <= id_ex_mem_index_shift_r;
                id_ex_mem_pair_r <= id_ex_mem_pair_r;
                id_ex_mem_base_update_r <= id_ex_mem_base_update_r;
                id_ex_mem_base_update_before_r <= id_ex_mem_base_update_before_r;
                id_ex_store_data_from_rd_r <= id_ex_store_data_from_rd_r;
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
                    pc_r <=
                        (id_branch_not_taken_fold_valid || id_early_alu_pair_valid || id_alu_dep_fold_valid) ?
                            (id_branch_not_taken_fold_pc +
                             (not_taken_next_cache_deliver ? {{(XLEN-4){1'b0}}, 4'd8} :
                              {{(XLEN-3){1'b0}}, 3'd4})) :
                        ((IMEM_SYNC != 0) && (fetch_redirect_target_request || redirect_cache_deliver)) ?
                            (fetch_control_redirect_pc +
                             (fold_next_cache_deliver ? {{(XLEN-4){1'b0}}, 4'd8} :
                              {{(XLEN-3){1'b0}}, 3'd4})) :
                        async_redirect_refill_valid ? async_redirect_refill_next_pc :
                        if_pc_next;
                end

                ex_mem_valid_r <= id_ex_valid_r;
                ex_mem_pc4_r <= id_ex_pc4_r;
                ex_mem_rd_addr_r <= id_ex_rd_addr_r;
                ex_mem_rd_en_r <= ex_rd_en_effective;
                ex_mem_wb_sel_r <= id_ex_wb_sel_r;
                ex_mem_load_r <= id_ex_load_r;
                ex_mem_load_preissued_r <= ex_dmem_preissue_valid;
                ex_mem_store_r <= id_ex_store_r;
                ex_mem_mem_size_r <= id_ex_mem_size_r;
                ex_mem_mem_unsigned_r <= id_ex_mem_unsigned_r;
                ex_mem_exec_result_r <= ex_exec_result_final;
                ex_mem_mem_addr_r <= ex_mem_addr;
                ex_mem_store_data_r <= ex_store_data;
                ex_mem_store_wstrb_r <= ex_store_wstrb;
                ex_mem_mem_pair_r <= id_ex_mem_pair_r;
                ex_mem_pair_store_data_r <= ex_pair_store_data;
                ex_mem_pair_store_wstrb_r <= ex_pair_store_wstrb;
                ex_mem_base_update_en_r <= id_ex_valid_r && (id_ex_mem_base_update_r || (id_ex_mem_pair_r && id_ex_load_r));
                ex_mem_base_update_addr_r <= (id_ex_mem_pair_r && id_ex_load_r) ? id_ex_rs2_addr_r : id_ex_rs1_addr_r;
                ex_mem_base_update_value_r <= ex_mem_base_update_value;

                if (id_ex_flush_valid_local) begin
                    id_ex_valid_r <= 1'b0;
                    id_ex_pc_r <= ZERO_XLEN;
                    id_ex_pc4_r <= ZERO_XLEN;
                    id_ex_rs1_addr_r <= 5'd0;
                    id_ex_rs2_addr_r <= 5'd0;
                    id_ex_rs3_addr_r <= 5'd0;
                    id_ex_rd_addr_r <= 5'd0;
                    id_ex_rs1_en_r <= 1'b0;
                    id_ex_rs2_en_r <= 1'b0;
                    id_ex_rs3_en_r <= 1'b0;
                    id_ex_rd_en_r <= 1'b0;
                    id_ex_illegal_r <= id_ex_illegal_r;
                    id_ex_rs1_value_r <= ZERO_XLEN;
                    id_ex_rs2_value_r <= ZERO_XLEN;
                    id_ex_rs3_value_r <= ZERO_XLEN;
                    id_ex_imm_r <= id_ex_imm_r;
                    id_ex_alu_op_r <= id_ex_alu_op_r;
                    id_ex_alu_src1_pc_r <= id_ex_alu_src1_pc_r;
                    id_ex_alu_src2_imm_r <= id_ex_alu_src2_imm_r;
                    id_ex_branch_r <= id_ex_branch_r;
                    id_ex_branch_funct3_r <= id_ex_branch_funct3_r;
                    id_ex_branch_predict_taken_r <= 1'b0;
                    id_ex_branch_predict_pc_r <= ZERO_XLEN;
                    id_ex_jump_r <= id_ex_jump_r;
                    id_ex_jalr_r <= id_ex_jalr_r;
                    id_ex_load_r <= id_ex_load_r;
                    id_ex_store_r <= id_ex_store_r;
                    id_ex_wb_sel_r <= id_ex_wb_sel_r;
                    id_ex_mem_size_r <= id_ex_mem_size_r;
                    id_ex_mem_unsigned_r <= id_ex_mem_unsigned_r;
                    id_ex_mem_indexed_r <= id_ex_mem_indexed_r;
                    id_ex_mem_index_shift_r <= id_ex_mem_index_shift_r;
                    id_ex_mem_pair_r <= id_ex_mem_pair_r;
                    id_ex_mem_base_update_r <= id_ex_mem_base_update_r;
                    id_ex_mem_base_update_before_r <= id_ex_mem_base_update_before_r;
                    id_ex_store_data_from_rd_r <= id_ex_store_data_from_rd_r;
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
                    id_ex_rs3_addr_r <= 5'd0;
                    id_ex_rd_addr_r <= 5'd0;
                    id_ex_rs1_en_r <= 1'b0;
                    id_ex_rs2_en_r <= 1'b0;
                    id_ex_rs3_en_r <= 1'b0;
                    id_ex_rd_en_r <= 1'b0;
                    id_ex_illegal_r <= id_ex_illegal_r;
                    id_ex_rs1_value_r <= ZERO_XLEN;
                    id_ex_rs2_value_r <= ZERO_XLEN;
                    id_ex_rs3_value_r <= ZERO_XLEN;
                    id_ex_imm_r <= id_ex_imm_r;
                    id_ex_alu_op_r <= id_ex_alu_op_r;
                    id_ex_alu_src1_pc_r <= id_ex_alu_src1_pc_r;
                    id_ex_alu_src2_imm_r <= id_ex_alu_src2_imm_r;
                    id_ex_branch_r <= id_ex_branch_r;
                    id_ex_branch_funct3_r <= id_ex_branch_funct3_r;
                    id_ex_branch_predict_taken_r <= 1'b0;
                    id_ex_branch_predict_pc_r <= ZERO_XLEN;
                    id_ex_jump_r <= id_ex_jump_r;
                    id_ex_jalr_r <= id_ex_jalr_r;
                    id_ex_load_r <= id_ex_load_r;
                    id_ex_store_r <= id_ex_store_r;
                    id_ex_wb_sel_r <= id_ex_wb_sel_r;
                    id_ex_mem_size_r <= id_ex_mem_size_r;
                    id_ex_mem_unsigned_r <= id_ex_mem_unsigned_r;
                    id_ex_mem_indexed_r <= id_ex_mem_indexed_r;
                    id_ex_mem_index_shift_r <= id_ex_mem_index_shift_r;
                    id_ex_mem_pair_r <= id_ex_mem_pair_r;
                    id_ex_mem_base_update_r <= id_ex_mem_base_update_r;
                    id_ex_mem_base_update_before_r <= id_ex_mem_base_update_before_r;
                    id_ex_store_data_from_rd_r <= id_ex_store_data_from_rd_r;
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
                    if (id_any_fold_valid) begin
                        id_ex_valid_r <= 1'b1;
                        id_ex_pc_r <= fold_decode_pc;
                        id_ex_pc4_r <= fold_id_pc4;
                        id_ex_rs1_addr_r <= fold_id_rs1_addr;
                        id_ex_rs2_addr_r <= fold_id_rs2_addr;
                        id_ex_rs3_addr_r <= fold_id_rs3_addr;
                        id_ex_rd_addr_r <= fold_id_rd_addr;
                        id_ex_rs1_en_r <= fold_issue_rs1_en;
                        id_ex_rs2_en_r <= fold_issue_rs2_en;
                        id_ex_rs3_en_r <= fold_issue_rs3_en;
                        id_ex_rd_en_r <= fold_id_rd_en;
                        id_ex_illegal_r <= fold_id_illegal;
                        id_ex_rs1_value_r <= fold_issue_rs1_value;
                        id_ex_rs2_value_r <= fold_issue_rs2_value;
                        id_ex_rs3_value_r <= fold_issue_rs3_value;
                        id_ex_imm_r <= fold_id_imm;
                        id_ex_alu_op_r <= fold_id_alu_op;
                        id_ex_alu_src1_pc_r <= fold_id_alu_src1_pc;
                        id_ex_alu_src2_imm_r <= fold_id_alu_src2_imm;
                        id_ex_branch_r <= fold_id_branch;
                        id_ex_branch_funct3_r <= fold_id_branch_funct3;
                        id_ex_branch_predict_taken_r <= 1'b0;
                        id_ex_branch_predict_pc_r <= ZERO_XLEN;
                        id_ex_jump_r <= fold_id_jump;
                        id_ex_jalr_r <= fold_id_jalr;
                        id_ex_load_r <= fold_id_load;
                        id_ex_store_r <= fold_id_store;
                        id_ex_wb_sel_r <= fold_id_wb_sel;
                        id_ex_mem_size_r <= fold_id_mem_size;
                        id_ex_mem_unsigned_r <= fold_id_mem_unsigned;
                        id_ex_mem_indexed_r <= fold_id_mem_indexed;
                        id_ex_mem_index_shift_r <= fold_id_mem_index_shift;
                        id_ex_mem_pair_r <= fold_id_mem_pair;
                        id_ex_mem_base_update_r <= fold_id_mem_base_update;
                        id_ex_mem_base_update_before_r <= fold_id_mem_base_update_before;
                        id_ex_store_data_from_rd_r <= fold_id_store_data_from_rd;
                        id_ex_word_op_r <= fold_id_word_op;
                        id_ex_is_lui_r <= fold_id_is_lui;
                        id_ex_csr_valid_r <= fold_id_csr_valid;
                        id_ex_csr_cmd_r <= fold_id_csr_cmd;
                        id_ex_csr_use_imm_r <= fold_id_csr_use_imm;
                        id_ex_csr_sel_r <= fold_id_csr_sel;
                        id_ex_csr_read_valid_r <= fold_id_csr_read_valid;
                        id_ex_csr_write_allowed_r <= fold_id_csr_write_allowed;
                        id_ex_ecall_r <= fold_id_ecall;
                        id_ex_ebreak_r <= fold_id_ebreak;
                        id_ex_mret_r <= fold_id_mret;
                    end else begin
                        id_ex_valid_r <= if_id_valid_r;
                        id_ex_pc_r <= if_id_pc_r;
                        id_ex_pc4_r <= id_pc4;
                        id_ex_rs1_addr_r <= id_rs1_addr;
                        id_ex_rs2_addr_r <= id_rs2_addr;
                        id_ex_rs3_addr_r <= id_rs3_addr;
                        id_ex_rd_addr_r <= id_rd_addr;
                        id_ex_rs1_en_r <= id_rs1_en;
                        id_ex_rs2_en_r <= id_rs2_en;
                        id_ex_rs3_en_r <= id_rs3_en;
                        id_ex_rd_en_r <= id_rd_en;
                        id_ex_illegal_r <= id_illegal;
                        id_ex_rs1_value_r <= id_rs1_value;
                        id_ex_rs2_value_r <= id_rs2_value;
                        id_ex_rs3_value_r <= rs3_rdata;
                        id_ex_imm_r <= id_imm;
                        id_ex_alu_op_r <= id_alu_op;
                        id_ex_alu_src1_pc_r <= id_alu_src1_pc;
                        id_ex_alu_src2_imm_r <= id_alu_src2_imm;
                        id_ex_branch_r <= id_branch;
                        id_ex_branch_funct3_r <= id_branch_funct3;
                        id_ex_branch_predict_taken_r <=
                            id_branch_predict_pending_hit ||
                            id_decode_redirect_valid ||
                            id_branch_predict_redirect_valid ||
                            id_jal_predict_redirect_valid;
                        id_ex_branch_predict_pc_r <=
                            id_branch_predict_pending_hit ? id_branch_predict_pending_pc_r :
                            id_decode_redirect_valid ? id_decode_redirect_pc :
                            id_predict_redirect_pc;
                        id_ex_jump_r <= id_jump;
                        id_ex_jalr_r <= id_jalr;
                        id_ex_load_r <= id_load;
                        id_ex_store_r <= id_store;
                        id_ex_wb_sel_r <= id_wb_sel;
                        id_ex_mem_size_r <= id_mem_size;
                        id_ex_mem_unsigned_r <= id_mem_unsigned;
                        id_ex_mem_indexed_r <= id_mem_indexed;
                        id_ex_mem_index_shift_r <= id_mem_index_shift;
                        id_ex_mem_pair_r <= id_mem_pair;
                        id_ex_mem_base_update_r <= id_mem_base_update;
                        id_ex_mem_base_update_before_r <= id_mem_base_update_before;
                        id_ex_store_data_from_rd_r <= id_store_data_from_rd;
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
// Small direct-mapped redirect target instruction cache.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (redirect_cache_reset_idx = 0; redirect_cache_reset_idx < REDIRECT_CACHE_ENTRIES; redirect_cache_reset_idx = redirect_cache_reset_idx + 1) begin
            redirect_cache_valid_r[redirect_cache_reset_idx] <= 1'b0;
        end
    end else if (!trap_r) begin
        if (redirect_cache_update_valid) begin
            redirect_cache_valid_r[redirect_cache_update_index] <= 1'b1;
        end
    end
end

always @(posedge clk) begin
    if (rst_n && !trap_r && redirect_cache_update_valid) begin
        redirect_cache_pc_r[redirect_cache_update_index] <= fetch_queue_pc;
        redirect_cache_instruction_r[redirect_cache_update_index] <= fetch_queue_instruction;
    end
end

// Small tagged BHT for repeated unresolved branch directions.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (branch_bht_reset_idx = 0; branch_bht_reset_idx < BRANCH_BHT_ENTRIES; branch_bht_reset_idx = branch_bht_reset_idx + 1) begin
            branch_bht_valid_r[branch_bht_reset_idx] <= 1'b0;
        end
    end else if (!trap_r) begin
        if (branch_bht_update_valid) begin
            branch_bht_valid_r[branch_bht_update_index] <= 1'b1;
            branch_bht_pc_r[branch_bht_update_index] <= branch_bht_update_pc;
            if (!branch_bht_valid_r[branch_bht_update_index] ||
                (branch_bht_pc_r[branch_bht_update_index] != branch_bht_update_pc)) begin
                branch_bht_counter_r[branch_bht_update_index] <= branch_bht_update_taken ? 2'b11 : 2'b00;
            end else if (branch_bht_update_taken) begin
                branch_bht_counter_r[branch_bht_update_index] <=
                    (branch_bht_counter_r[branch_bht_update_index] == 2'b11) ?
                    2'b11 : (branch_bht_counter_r[branch_bht_update_index] + 2'b01);
            end else begin
                branch_bht_counter_r[branch_bht_update_index] <=
                    (branch_bht_counter_r[branch_bht_update_index] == 2'b00) ?
                    2'b00 : (branch_bht_counter_r[branch_bht_update_index] - 2'b01);
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        id_branch_predict_pending_r <= 1'b0;
        id_branch_predict_pending_branch_pc_r <= ZERO_XLEN;
        id_branch_predict_pending_pc_r <= ZERO_XLEN;
    end else if (trap_r) begin
        id_branch_predict_pending_r <= 1'b0;
        id_branch_predict_pending_branch_pc_r <= ZERO_XLEN;
        id_branch_predict_pending_pc_r <= ZERO_XLEN;
    end else begin
        if (id_branch_predict_pending_latch_valid) begin
            id_branch_predict_pending_r <= 1'b1;
            id_branch_predict_pending_branch_pc_r <= if_id_pc_r;
            id_branch_predict_pending_pc_r <= id_branch_predict_redirect_pc;
        end else if (id_branch_predict_pending_clear_valid) begin
            id_branch_predict_pending_r <= 1'b0;
            id_branch_predict_pending_branch_pc_r <= ZERO_XLEN;
            id_branch_predict_pending_pc_r <= ZERO_XLEN;
        end
    end
end

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
