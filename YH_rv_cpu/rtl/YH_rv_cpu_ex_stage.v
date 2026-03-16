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
    input  wire            is_lui,
    input  wire            illegal,
    output wire [XLEN-1:0] exec_result,
    output wire [XLEN-1:0] mem_addr,
    output reg  [XLEN-1:0] store_data,
    output reg  [3:0]      store_wstrb,
    output wire            redirect_en,
    output wire [XLEN-1:0] redirect_pc,
    output wire            exception
);

wire [XLEN-1:0] alu_lhs;
wire [XLEN-1:0] alu_rhs;
wire [XLEN-1:0] alu_result;
wire            alu_eq;
wire            alu_lt;
wire            alu_ltu;
wire            branch_taken;
wire            misaligned_mem;

assign alu_lhs = is_lui ? {XLEN{1'b0}} : (alu_src1_pc ? pc : rs1_value);
assign alu_rhs = alu_src2_imm ? imm : rs2_value;

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

assign mem_addr = alu_result;
assign exec_result = is_lui ? imm : alu_result;
assign redirect_en = jump || branch_taken;
assign redirect_pc = jump ? (jalr ? {alu_result[XLEN-1:1], 1'b0} : (pc + imm)) : (pc + imm);

assign misaligned_mem =
    (load || store) && (
        ((mem_size == `YH_rv_cpu_MEM_H) && mem_addr[0]) ||
        ((mem_size == `YH_rv_cpu_MEM_W) && (mem_addr[1:0] != 2'b00))
    );

assign exception = illegal || misaligned_mem;

always @* begin
    store_data = {XLEN{1'b0}};
    store_wstrb = 4'b0000;

    case (mem_size)
        `YH_rv_cpu_MEM_B: begin
            case (mem_addr[1:0])
                2'b00: begin
                    store_data = {{(XLEN-8){1'b0}}, rs2_value[7:0]};
                    store_wstrb = 4'b0001;
                end
                2'b01: begin
                    store_data = {{(XLEN-16){1'b0}}, rs2_value[7:0], 8'b0};
                    store_wstrb = 4'b0010;
                end
                2'b10: begin
                    store_data = {{(XLEN-24){1'b0}}, rs2_value[7:0], 16'b0};
                    store_wstrb = 4'b0100;
                end
                default: begin
                    store_data = {{(XLEN-32){1'b0}}, rs2_value[7:0], 24'b0};
                    store_wstrb = 4'b1000;
                end
            endcase
        end

        `YH_rv_cpu_MEM_H: begin
            if (!mem_addr[1]) begin
                store_data = {{(XLEN-16){1'b0}}, rs2_value[15:0]};
                store_wstrb = 4'b0011;
            end else begin
                store_data = {{(XLEN-32){1'b0}}, rs2_value[15:0], 16'b0};
                store_wstrb = 4'b1100;
            end
        end

        default: begin
            store_data = {{(XLEN-32){1'b0}}, rs2_value[31:0]};
            store_wstrb = 4'b1111;
        end
    endcase
end

endmodule
