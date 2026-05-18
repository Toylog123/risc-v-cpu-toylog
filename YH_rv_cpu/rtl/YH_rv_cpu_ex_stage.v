// ============================================================
// YH_rv_cpu_ex_stage.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 执行阶段 (Execute Stage)
// Description: 执行算术逻辑运算、分支判断、地址计算
//   包含 ALU 实例，执行所有 ALU 操作
//   计算内存访问地址和分支跳转目标
//   处理存储指令的写数据格式化
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_ex_stage #(
    parameter integer XLEN = 32,  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1
) (
    // ------------------------------------------------------------
    // 输入信号 (来自 ID/EX 流水线寄存器)
    // ------------------------------------------------------------
    input  wire [XLEN-1:0] pc,               // PC 值
    input  wire [XLEN-1:0] rs1_value,       // 源寄存器 1 值 (已转发)
    input  wire [XLEN-1:0] rs2_value,       // 源寄存器 2 值 (已转发)
    input  wire [XLEN-1:0] imm,             // 立即数
    input  wire [5:0]      alu_op,          // ALU 操作码
    input  wire            alu_src1_pc,     // ALU 源 1 选择: 0=rs1, 1=PC
    input  wire            alu_src2_imm,    // ALU 源 2 选择: 0=rs2, 1=imm
    input  wire            branch,          // 分支指令标志
    input  wire [2:0]      branch_funct3,    // 分支条件 funct3
    input  wire            jump,            // 跳转指令标志
    input  wire            jalr,           // JALR 标志 (寄存器间接)
    input  wire            load,            // 加载指令
    input  wire            store,           // 存储指令
    input  wire [1:0]      mem_size,        // 内存访问宽度
    input  wire            mem_indexed,     // XThead indexed load/store address mode
    input  wire [1:0]      mem_index_shift, // XThead index scale shift
    input  wire            store_data_from_rd, // XThead store uses rd as data source
    input  wire [XLEN-1:0] store_data_value, // optional rd-as-source store data
    input  wire            mem_base_update, // XThead auto-inc/dec base update mode
    input  wire            mem_base_update_before,
    input  wire            word_op,         // 32 位字操作 (RV64)
    input  wire            is_lui,          // LUI 指令

    // ------------------------------------------------------------
    // 输出信号 (到 EX/MEM 流水线寄存器)
    // ------------------------------------------------------------
    output wire [XLEN-1:0] exec_result,     // 执行结果 (ALU/PC+imm/LUI)
    output wire [XLEN-1:0] mem_addr,        // 内存访问地址
    output wire [XLEN-1:0] mem_base_update_value,
    output reg  [XLEN-1:0] store_data,      // 存储数据 (格式化后)
    output reg  [XLEN/8-1:0] store_wstrb,  // 存储字节使能
    output wire [XLEN-1:0] pair_store_data,
    output wire [XLEN/8-1:0] pair_store_wstrb,
    output wire            redirect_en,     // PC 重定向使能
    output wire [XLEN-1:0] redirect_pc,    // PC 重定向目标
    output wire            mem_misaligned   // 内存地址对齐错误
);

    // ------------------------------------------------------------
    // 参数计算
    // STRB_W: 字节使能信号宽度 (XLEN/8)
    // BYTE_OFFSET_W: 字节偏移宽度 (用于地址对齐)
    // ------------------------------------------------------------
localparam integer STRB_W = XLEN / 8;
localparam integer BYTE_OFFSET_W = $clog2(STRB_W);

    // ------------------------------------------------------------
    // 内部信号定义
    // ------------------------------------------------------------
wire [XLEN-1:0] alu_lhs;           // ALU 左操作数
wire [XLEN-1:0] alu_rhs;           // ALU 右操作数
wire [XLEN-1:0] alu_result;        // ALU 结果
wire [XLEN-1:0] rs1_plus_imm;     // rs1 + imm (内存地址计算)
wire [XLEN-1:0] mem_index_offset; // XThead indexed address offset
wire [XLEN-1:0] mem_update_offset;
wire [XLEN-1:0] store_data_raw;   // selected store source before size formatting
wire [XLEN-1:0] pc_plus_imm;      // pc + imm (分支目标)
wire [XLEN-1:0] jalr_target;      // JALR 目标地址
reg  [31:0]     word_result;       // 32 位字结果 (RV64)
wire            alu_eq;            // ALU 相等标志
wire            alu_lt;            // ALU 小于标志 (有符号)
wire            alu_ltu;           // ALU 小于标志 (无符号)
wire            branch_taken;      // 分支实际跳转标志
wire            misaligned_mem;    // 内存地址未对齐
wire [BYTE_OFFSET_W-1:0] byte_offset; // 字节偏移
wire [XLEN-1:0] word_result_sext; // 符号扩展的 32 位结果

    // ------------------------------------------------------------
    // ALU 操作数选择
    // alu_src1_pc: LUI 为 0，AUIPC 为 PC，其他为 rs1
    // alu_src2_imm: 立即数指令为 imm，其他为 rs2
    // ------------------------------------------------------------
assign alu_lhs = is_lui ? {XLEN{1'b0}} : (alu_src1_pc ? pc : rs1_value);
assign alu_rhs = alu_src2_imm ? imm : rs2_value;

    // ------------------------------------------------------------
    // 地址计算
    // rs1_plus_imm: 内存访问地址 (load/store)
    // pc_plus_imm: 相对跳转目标 (JAL/分支)
    // jalr_target: JALR 目标 (rs1 + imm) & ~1
    // ------------------------------------------------------------
assign mem_index_offset = rs2_value << mem_index_shift;
assign mem_update_offset = imm << mem_index_shift;
assign rs1_plus_imm = mem_base_update ?
    (mem_base_update_before ? (rs1_value + mem_update_offset) : rs1_value) :
    (mem_indexed ? (rs1_value + mem_index_offset) : (rs1_value + imm));
assign store_data_raw = store_data_from_rd ? store_data_value : rs2_value;
assign pc_plus_imm = pc + imm;
assign jalr_target = {rs1_plus_imm[XLEN-1:1], 1'b0};  // JALR 要求最低位为 0

    // ------------------------------------------------------------
    // 字节偏移计算
    // 用于存储指令的字节使能生成
    // ------------------------------------------------------------
assign byte_offset = mem_addr[BYTE_OFFSET_W-1:0];

    // ------------------------------------------------------------
    // RV64 32 位字操作结果符号扩展
    // ------------------------------------------------------------
assign word_result_sext = {{(XLEN-32){word_result[31]}}, word_result};

    // ------------------------------------------------------------
    // ALU 实例
    // 执行所有算术逻辑运算
    // ------------------------------------------------------------
YH_rv_cpu_alu #(
    .XLEN(XLEN),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION)
) u_alu (
    .alu_op (alu_op),
    .lhs    (alu_lhs),
    .rhs    (alu_rhs),
    .acc    (store_data_value),
    .result (alu_result),
    .eq     (alu_eq),
    .lt     (alu_lt),
    .ltu    (alu_ltu)
);

    // ------------------------------------------------------------
    // 分支条件判断
    // 根据 branch_funct3 判断分支是否成立
    // beq/bne/blt/bltu/bge/bgeu
    // ------------------------------------------------------------
assign branch_taken =
    branch && (
        ((branch_funct3 == 3'b000) &&  alu_eq)  ||  // beq: rs1 == rs2
        ((branch_funct3 == 3'b001) && !alu_eq)  ||  // bne: rs1 != rs2
        ((branch_funct3 == 3'b100) &&  alu_lt)  ||  // blt: rs1 < rs2 (signed)
        ((branch_funct3 == 3'b101) && !alu_lt)  ||  // bge: rs1 >= rs2 (signed)
        ((branch_funct3 == 3'b110) &&  alu_ltu) ||  // bltu: rs1 < rs2 (unsigned)
        ((branch_funct3 == 3'b111) && !alu_ltu)    // bgeu: rs1 >= rs2 (unsigned)
    );

    // ------------------------------------------------------------
    // 执行结果选择
    // LUI: 直接输出立即数
    // RV64 32 位字操作: 符号扩展 32 位结果
    // 其他: ALU 结果
    // ------------------------------------------------------------
assign mem_addr = rs1_plus_imm;  // 内存访问地址始终为 rs1 + imm
assign mem_base_update_value = rs1_value + mem_update_offset;
assign exec_result = is_lui ? imm : ((word_op && (XLEN == 64)) ? word_result_sext : alu_result);
assign pair_store_data = {{(XLEN-32){1'b0}}, rs2_value[31:0]} << {byte_offset, 3'b000};
assign pair_store_wstrb = {{(STRB_W-4){1'b0}}, 4'hf} << byte_offset;

    // ------------------------------------------------------------
    // PC 重定向
    // 跳转指令或分支成立时重定向 PC
    // JALR 需要特殊处理 (jalr_target)
    // ------------------------------------------------------------
assign redirect_en = jump || branch_taken;
assign redirect_pc = jump ? (jalr ? jalr_target : pc_plus_imm) : pc_plus_imm;

    // ------------------------------------------------------------
    // 内存对齐检查
    // 检查访存地址是否满足对齐要求
    // 错误时触发异常
    // ------------------------------------------------------------
assign misaligned_mem =
    (load || store) && (
        ((mem_size == `YH_rv_cpu_MEM_H) && mem_addr[0]) ||           // 半字访问需 2 字节对齐
        ((mem_size == `YH_rv_cpu_MEM_W) && (mem_addr[1:0] != 2'b00)) || // 字访问需 4 字节对齐
        ((mem_size == `YH_rv_cpu_MEM_D) && (mem_addr[2:0] != 3'b000))    // 双字访问需 8 字节对齐
    );

assign mem_misaligned = misaligned_mem;

    // ------------------------------------------------------------
    // 32 位字操作结果计算 (RV64)
    // 只在 RV64 的 32 位字操作指令时使用
    // ------------------------------------------------------------
always @* begin
    case (alu_op)
        `YH_rv_cpu_ALU_ADD: word_result = rs1_value[31:0] + alu_rhs[31:0];
        `YH_rv_cpu_ALU_SUB: word_result = rs1_value[31:0] - alu_rhs[31:0];
        `YH_rv_cpu_ALU_SLL: word_result = rs1_value[31:0] << alu_rhs[4:0];
        `YH_rv_cpu_ALU_SRL: word_result = rs1_value[31:0] >> alu_rhs[4:0];
        `YH_rv_cpu_ALU_SRA: word_result = $signed(rs1_value[31:0]) >>> alu_rhs[4:0];
        default:            word_result = 32'h0000_0000;
    endcase
end

    // ------------------------------------------------------------
    // 存储数据格式化
    // 根据 mem_size 和字节偏移生成正确位置的存储数据
    // 同时生成字节使能信号 (store_wstrb)
    // ------------------------------------------------------------
always @* begin
    store_data = {XLEN{1'b0}};
    store_wstrb = {STRB_W{1'b0}};

    case (mem_size)
        `YH_rv_cpu_MEM_B: begin
            store_data = {{(XLEN-8){1'b0}}, store_data_raw[7:0]} << {byte_offset, 3'b000};
            store_wstrb = {{(STRB_W-1){1'b0}}, 1'b1} << byte_offset;
        end

        `YH_rv_cpu_MEM_H: begin
            store_data = {{(XLEN-16){1'b0}}, store_data_raw[15:0]} << {byte_offset, 3'b000};
            store_wstrb = {{(STRB_W-2){1'b0}}, 2'b11} << byte_offset;
        end

        `YH_rv_cpu_MEM_W: begin
            store_data = {{(XLEN-32){1'b0}}, store_data_raw[31:0]} << {byte_offset, 3'b000};
            store_wstrb = {{(STRB_W-4){1'b0}}, 4'hf} << byte_offset;
        end

        default: begin
            // 双字访问: 不移位，使用全部字节
            store_data = store_data_raw;
            store_wstrb = {STRB_W{1'b1}};
        end
    endcase
end

endmodule
