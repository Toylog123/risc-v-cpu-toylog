`timescale 1ns / 1ps

module YH_rv_cpu_xthead_mac_tb;

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
wire        dmem_we;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
integer cycle;
integer idx;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rvalid = 1'b1;
assign dmem_rdata = 32'h0000_0000;

YH_rv_cpu #(
    .IMEM_SYNC(0),
    .DMEM_SYNC(0),
    .RESET_VECTOR(32'h0000_0000)
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
    .dmem_ready(1'b1),
    .dmem_read_req(dmem_read_req),
    .dmem_we   (dmem_we),
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

function [31:0] th_mac;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [4:0] rd;
    begin
        th_mac = {funct7, rs2, rs1, 3'b001, rd, 7'h0b};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (trap) begin
            $fatal(1, "FAIL: trap asserted pc=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 24) && (dut.u_regfile.regs[31] == 32'd1)) begin
            if (dut.u_regfile.regs[5] != 32'd22) begin
                $fatal(1, "FAIL: th.mula positive accumulator x5=%h", dut.u_regfile.regs[5]);
            end
            if (dut.u_regfile.regs[8] != 32'd90) begin
                $fatal(1, "FAIL: th.mula signed-lowbits accumulator x8=%h", dut.u_regfile.regs[8]);
            end
            if (dut.u_regfile.regs[9] != 32'd5) begin
                $fatal(1, "FAIL: th.mulah signed halfword x9=%h", dut.u_regfile.regs[9]);
            end
            if (dut.u_regfile.regs[12] != 32'hffff_0000) begin
                $fatal(1, "FAIL: th.mulah negative halfword x12=%h", dut.u_regfile.regs[12]);
            end

            $display("PASS: xthead mac diagnostic completed cycles=%0d x5=%h x8=%h x9=%h x12=%h",
                cycle, dut.u_regfile.regs[5], dut.u_regfile.regs[8],
                dut.u_regfile.regs[9], dut.u_regfile.regs[12]);
            $finish;
        end

        if (cycle > 90) begin
            $fatal(1, "FAIL: timeout pc=%h cycle=%0d x5=%h x8=%h x9=%h x12=%h",
                debug_pc, cycle, dut.u_regfile.regs[5], dut.u_regfile.regs[8],
                dut.u_regfile.regs[9], dut.u_regfile.regs[12]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    imem[0]  = rv32_i(12'd3,   5'd0, 3'b000, 5'd1,  7'b0010011); // x1 = 3
    imem[1]  = rv32_i(12'd4,   5'd0, 3'b000, 5'd2,  7'b0010011); // x2 = 4
    imem[2]  = rv32_i(12'd10,  5'd0, 3'b000, 5'd5,  7'b0010011); // x5 = 10
    imem[3]  = th_mac(7'd16, 5'd2, 5'd1, 5'd5);                  // th.mula x5,x1,x2
    imem[4]  = rv32_i(-12'sd2, 5'd0, 3'b000, 5'd6,  7'b0010011); // x6 = -2
    imem[5]  = rv32_i(12'd5,   5'd0, 3'b000, 5'd7,  7'b0010011); // x7 = 5
    imem[6]  = rv32_i(12'd100, 5'd0, 3'b000, 5'd8,  7'b0010011); // x8 = 100
    imem[7]  = th_mac(7'd16, 5'd7, 5'd6, 5'd8);                  // th.mula x8,x6,x7
    imem[8]  = rv32_i(-12'sd1, 5'd0, 3'b000, 5'd10, 7'b0010011); // x10 = -1
    imem[9]  = rv32_i(12'd2,   5'd0, 3'b000, 5'd11, 7'b0010011); // x11 = 2
    imem[10] = rv32_i(12'd7,   5'd0, 3'b000, 5'd9,  7'b0010011); // x9 = 7
    imem[11] = th_mac(7'd20, 5'd11, 5'd10, 5'd9);                // th.mulah x9,x10,x11
    imem[12] = rv32_u(20'd8, 5'd13, 7'b0110111);                 // x13 = 0x8000
    imem[13] = rv32_i(12'd2, 5'd0, 3'b000, 5'd14, 7'b0010011);   // x14 = 2
    imem[14] = th_mac(7'd20, 5'd14, 5'd13, 5'd12);               // th.mulah x12,x13,x14
    imem[15] = rv32_i(12'd1, 5'd0, 3'b000, 5'd31, 7'b0010011);   // done marker

    #20;
    rst_n = 1'b1;
end

endmodule
