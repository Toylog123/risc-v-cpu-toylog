// ============================================================
// YH_rv_cpu_regfile.v
// Function: RISC-V integer register file
// ============================================================

module YH_rv_cpu_regfile #(
    parameter integer XLEN = 32,
    parameter integer ENABLE_RS3_READ_PORT = 1,
    parameter integer ENABLE_FOLD_READ_PORTS = 1
) (
    input  wire            clk,
    input  wire            rst_n,

    input  wire [4:0]      rs1_addr,
    output wire [XLEN-1:0] rs1_rdata,

    input  wire [4:0]      rs2_addr,
    output wire [XLEN-1:0] rs2_rdata,

    input  wire [4:0]      rs3_addr,
    output wire [XLEN-1:0] rs3_rdata,

    input  wire [4:0]      fold_rs1_addr,
    output wire [XLEN-1:0] fold_rs1_rdata,
    input  wire [4:0]      fold_rs2_addr,
    output wire [XLEN-1:0] fold_rs2_rdata,
    input  wire [4:0]      fold_rs3_addr,
    output wire [XLEN-1:0] fold_rs3_rdata,

    input  wire            rd_wen,
    input  wire [4:0]      rd_addr,
    input  wire [XLEN-1:0] rd_wdata,

    input  wire            rd2_wen,
    input  wire [4:0]      rd2_addr,
    input  wire [XLEN-1:0] rd2_wdata
);

reg [XLEN-1:0] regs [0:31];
integer idx;

assign rs1_rdata =
    (rs1_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == rs1_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == rs1_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[rs1_addr];

assign rs2_rdata =
    (rs2_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == rs2_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == rs2_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[rs2_addr];

assign rs3_rdata =
    (ENABLE_RS3_READ_PORT == 0) ? {XLEN{1'b0}} :
    (rs3_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == rs3_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == rs3_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[rs3_addr];

assign fold_rs1_rdata =
    (ENABLE_FOLD_READ_PORTS == 0) ? {XLEN{1'b0}} :
    (fold_rs1_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == fold_rs1_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == fold_rs1_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[fold_rs1_addr];

assign fold_rs2_rdata =
    (ENABLE_FOLD_READ_PORTS == 0) ? {XLEN{1'b0}} :
    (fold_rs2_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == fold_rs2_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == fold_rs2_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[fold_rs2_addr];

assign fold_rs3_rdata =
    ((ENABLE_FOLD_READ_PORTS == 0) || (ENABLE_RS3_READ_PORT == 0)) ? {XLEN{1'b0}} :
    (fold_rs3_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == fold_rs3_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == fold_rs3_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[fold_rs3_addr];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < 32; idx = idx + 1) begin
            regs[idx] <= {XLEN{1'b0}};
        end
    end else begin
        if (rd_wen && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_wdata;
        end
        if (rd2_wen && (rd2_addr != 5'd0)) begin
            regs[rd2_addr] <= rd2_wdata;
        end
    end
end

endmodule
