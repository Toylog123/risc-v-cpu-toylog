module YH_rv_cpu_if_stage (
    input  wire [31:0] pc_current,
    input  wire        redirect_en,
    input  wire [31:0] redirect_pc,
    output wire [31:0] imem_addr,
    output wire [31:0] pc_next,
    output wire [31:0] pc_plus_4
);

assign imem_addr = pc_current;
assign pc_plus_4 = pc_current + 32'd4;
assign pc_next = redirect_en ? redirect_pc : pc_plus_4;

endmodule
