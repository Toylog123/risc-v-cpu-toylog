`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_ex_stage #(
    parameter integer XLEN = 32
) (
    input  wire [XLEN-1:0] pc,
    input  wire [XLEN-1:0] rs1_value,
    input  wire [XLEN-1:0] rs2_value,
    input  wire [XLEN-1:0] imm,
    input  wire [3:0]      alu_op,
    input  wire            alu_src1_pc,
    input  wire            alu_src2_imm,
    input  wire            branch,
    input  wire [2:0]      branch_funct3,
    input  wire            jump,
    input  wire            jalr,
    input  wire            load,
    input  wire            store,
    input  wire [1:0]      mem_size,
    input  wire            word_op,
    input  wire            is_lui,
    output wire [XLEN-1:0] exec_result,
    output wire [XLEN-1:0] mem_addr,
    output reg  [XLEN-1:0] store_data,
    output reg  [XLEN/8-1:0] store_wstrb,
    output wire            redirect_en,
    output wire [XLEN-1:0] redirect_pc,
    output wire            mem_misaligned
);

localparam integer STRB_W = XLEN / 8;
localparam integer BYTE_OFFSET_W = $clog2(STRB_W);

wire [XLEN-1:0] alu_lhs;
wire [XLEN-1:0] alu_rhs;
wire [XLEN-1:0] alu_result;
wire [XLEN-1:0] rs1_plus_imm;
wire [XLEN-1:0] pc_plus_imm;
wire [XLEN-1:0] jalr_target;
reg  [31:0]     word_result;
wire            alu_eq;
wire            alu_lt;
wire            alu_ltu;
wire            branch_taken;
wire            misaligned_mem;
wire [BYTE_OFFSET_W-1:0] byte_offset;
wire [XLEN-1:0] word_result_sext;

assign alu_lhs = is_lui ? {XLEN{1'b0}} : (alu_src1_pc ? pc : rs1_value);
assign alu_rhs = alu_src2_imm ? imm : rs2_value;
assign rs1_plus_imm = rs1_value + imm;
assign pc_plus_imm = pc + imm;
assign jalr_target = {rs1_plus_imm[XLEN-1:1], 1'b0};
assign byte_offset = mem_addr[BYTE_OFFSET_W-1:0];
assign word_result_sext = {{(XLEN-32){word_result[31]}}, word_result};

YH_rv_cpu_alu #(
    .XLEN(XLEN)
) u_alu (
    .alu_op (alu_op),
    .lhs    (alu_lhs),
    .rhs    (alu_rhs),
    .result (alu_result),
    .eq     (alu_eq),
    .lt     (alu_lt),
    .ltu    (alu_ltu)
);

assign branch_taken =
    branch && (
        ((branch_funct3 == 3'b000) &&  alu_eq)  ||
        ((branch_funct3 == 3'b001) && !alu_eq)  ||
        ((branch_funct3 == 3'b100) &&  alu_lt)  ||
        ((branch_funct3 == 3'b101) && !alu_lt)  ||
        ((branch_funct3 == 3'b110) &&  alu_ltu) ||
        ((branch_funct3 == 3'b111) && !alu_ltu)
    );

assign mem_addr = rs1_plus_imm;
assign exec_result = is_lui ? imm : ((word_op && (XLEN == 64)) ? word_result_sext : alu_result);
assign redirect_en = jump || branch_taken;
assign redirect_pc = jump ? (jalr ? jalr_target : pc_plus_imm) : pc_plus_imm;

assign misaligned_mem =
    (load || store) && (
        ((mem_size == `YH_rv_cpu_MEM_H) && mem_addr[0]) ||
        ((mem_size == `YH_rv_cpu_MEM_W) && (mem_addr[1:0] != 2'b00)) ||
        ((mem_size == `YH_rv_cpu_MEM_D) && (mem_addr[2:0] != 3'b000))
    );

assign mem_misaligned = misaligned_mem;

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

always @* begin
    store_data = {XLEN{1'b0}};
    store_wstrb = {STRB_W{1'b0}};

    case (mem_size)
        `YH_rv_cpu_MEM_B: begin
            store_data = {{(XLEN-8){1'b0}}, rs2_value[7:0]} << {byte_offset, 3'b000};
            store_wstrb = {{(STRB_W-1){1'b0}}, 1'b1} << byte_offset;
        end

        `YH_rv_cpu_MEM_H: begin
            store_data = {{(XLEN-16){1'b0}}, rs2_value[15:0]} << {byte_offset, 3'b000};
            store_wstrb = {{(STRB_W-2){1'b0}}, 2'b11} << byte_offset;
        end

        `YH_rv_cpu_MEM_W: begin
            store_data = {{(XLEN-32){1'b0}}, rs2_value[31:0]} << {byte_offset, 3'b000};
            store_wstrb = {{(STRB_W-4){1'b0}}, 4'hf} << byte_offset;
        end

        default: begin
            store_data = rs2_value;
            store_wstrb = {STRB_W{1'b1}};
        end
    endcase
end

endmodule
