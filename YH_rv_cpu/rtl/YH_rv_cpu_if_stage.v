module YH_rv_cpu_if_stage #(
    parameter integer XLEN = 32
) (
    input  wire [XLEN-1:0] pc_current,
    input  wire            redirect_en,
    input  wire [XLEN-1:0] redirect_pc,
    output wire [XLEN-1:0] imem_addr,
    output wire [XLEN-1:0] pc_next,
    output wire [XLEN-1:0] pc_plus_4
);

localparam [XLEN-1:0] PC_STEP = {{(XLEN-3){1'b0}}, 3'd4};

assign imem_addr = pc_current;
assign pc_plus_4 = pc_current + PC_STEP;
assign pc_next = redirect_en ? redirect_pc : pc_plus_4;

endmodule
