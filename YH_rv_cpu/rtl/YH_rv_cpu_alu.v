`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_alu #(
    parameter integer XLEN = 32
) (
    input  wire [3:0]      alu_op,
    input  wire [XLEN-1:0] lhs,
    input  wire [XLEN-1:0] rhs,
    output reg  [XLEN-1:0] result,
    output wire            eq,
    output wire            lt,
    output wire            ltu
);

localparam integer SHAMT_W = $clog2(XLEN);

assign eq  = (lhs == rhs);
assign lt  = ($signed(lhs) < $signed(rhs));
assign ltu = (lhs < rhs);

always @* begin
    case (alu_op)
        `YH_rv_cpu_ALU_ADD:  result = lhs + rhs;
        `YH_rv_cpu_ALU_SUB:  result = lhs - rhs;
        `YH_rv_cpu_ALU_SLT:  result = {{(XLEN-1){1'b0}}, lt};
        `YH_rv_cpu_ALU_SLTU: result = {{(XLEN-1){1'b0}}, ltu};
        `YH_rv_cpu_ALU_XOR:  result = lhs ^ rhs;
        `YH_rv_cpu_ALU_OR:   result = lhs | rhs;
        `YH_rv_cpu_ALU_AND:  result = lhs & rhs;
        `YH_rv_cpu_ALU_SLL:  result = lhs << rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SRL:  result = lhs >> rhs[SHAMT_W-1:0];
        `YH_rv_cpu_ALU_SRA:  result = $signed(lhs) >>> rhs[SHAMT_W-1:0];
        default:             result = {XLEN{1'b0}};
    endcase
end

endmodule
