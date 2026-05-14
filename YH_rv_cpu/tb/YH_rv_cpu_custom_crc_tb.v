`timescale 1ns / 1ps

module YH_rv_cpu_custom_crc_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:31];
integer cycle;
integer idx;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = 32'h0000_0000;
assign dmem_rvalid = 1'b1;

YH_rv_cpu #(
    .IMEM_SYNC(0),
    .DMEM_SYNC(0),
    .RESET_VECTOR(32'h0000_0000),
    .ENABLE_XTHEAD_EXTENSION(1)
) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
    .imem_req  (imem_req),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_read_req(dmem_read_req),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .trap      (trap),
    .debug_pc  (debug_pc)
);

function [31:0] rv32_i;
    input signed [11:0] imm;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_i = {imm[11:0], rs1, funct3, rd, opcode};
    end
endfunction

function [31:0] rv32_u;
    input [19:0] imm20;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_u = {imm20, rd, opcode};
    end
endfunction

function [31:0] rv32_r;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_r = {funct7, rs2, rs1, funct3, rd, opcode};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 8) &&
            (dut.u_regfile.regs[1] == 32'h1234_5678) &&
            (dut.u_regfile.regs[3] == 32'h0000_3ea2) &&
            (dut.u_regfile.regs[4] == 32'h0000_7d6e)) begin
            $display(
                "PASS: custom crc diagnostic completed at PC=%h cycles=%0d crc16=%h crc32=%h",
                debug_pc,
                cycle,
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[4]);
            $finish;
        end

        if (cycle > 80) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d x1=%h x3=%h x4=%h",
                debug_pc,
                cycle,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[4]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    imem[0] = rv32_u(20'h12345, 5'd1, 7'b0110111);                  // lui x1, 0x12345
    imem[1] = rv32_i(12'h678, 5'd1, 3'b000, 5'd1, 7'b0010011);       // addi x1, x1, 0x678
    imem[2] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd2, 7'b0010011);        // addi x2, x0, 0
    imem[3] = rv32_r(7'd40, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0001011);   // xcrc16 x3, x1, x2
    imem[4] = rv32_r(7'd41, 5'd2, 5'd1, 3'b000, 5'd4, 7'b0001011);   // xcrc32 x4, x1, x2
    imem[5] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);

    #20;
    rst_n = 1'b1;
end

endmodule
