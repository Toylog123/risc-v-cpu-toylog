`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_alu (
    input  wire [3:0]  alu_op,
    input  wire [31:0] lhs,
    input  wire [31:0] rhs,
    output reg  [31:0] result,
    output wire        eq,
    output wire        lt,
    output wire        ltu
);

assign eq  = (lhs == rhs);
assign lt  = ($signed(lhs) < $signed(rhs));
assign ltu = (lhs < rhs);

always @* begin
    case (alu_op)
        `YH_rv_cpu_ALU_ADD:  result = lhs + rhs;
        `YH_rv_cpu_ALU_SUB:  result = lhs - rhs;
        `YH_rv_cpu_ALU_SLT:  result = {31'b0, lt};
        `YH_rv_cpu_ALU_SLTU: result = {31'b0, ltu};
        `YH_rv_cpu_ALU_XOR:  result = lhs ^ rhs;
        `YH_rv_cpu_ALU_OR:   result = lhs | rhs;
        `YH_rv_cpu_ALU_AND:  result = lhs & rhs;
        `YH_rv_cpu_ALU_SLL:  result = lhs << rhs[4:0];
        `YH_rv_cpu_ALU_SRL:  result = lhs >> rhs[4:0];
        `YH_rv_cpu_ALU_SRA:  result = $signed(lhs) >>> rhs[4:0];
        default:          result = 32'h0000_0000;
    endcase
end

endmodule
