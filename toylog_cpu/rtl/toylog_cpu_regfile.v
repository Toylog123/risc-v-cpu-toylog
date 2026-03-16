module toylog_cpu_regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_rdata,
    output wire [31:0] rs2_rdata,
    input  wire        rd_wen,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_wdata
);

reg [31:0] regs [0:31];
integer idx;

assign rs1_rdata = (rs1_addr == 5'd0) ? 32'h0000_0000 : regs[rs1_addr];
assign rs2_rdata = (rs2_addr == 5'd0) ? 32'h0000_0000 : regs[rs2_addr];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < 32; idx = idx + 1) begin
            regs[idx] <= 32'h0000_0000;
        end
    end else if (rd_wen && (rd_addr != 5'd0)) begin
        regs[rd_addr] <= rd_wdata;
    end
end

endmodule
