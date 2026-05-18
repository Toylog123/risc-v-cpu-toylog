`timescale 1ns / 1ps

module YH_rv_cpu_xthead_mempair_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire [31:0] dmem_pair_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire        dmem_pair_read_req;
wire        dmem_we;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire [31:0] dmem_pair_wdata;
wire [3:0]  dmem_pair_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
reg [31:0] dmem [0:63];
integer cycle;
integer idx;
integer pair_read_seen;
integer pair_write_seen;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rvalid = 1'b1;
assign dmem_rdata = dmem[dmem_addr[31:2]];
assign dmem_pair_rdata = dmem[(dmem_addr + 32'd4) >> 2];

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
    .dmem_pair_rdata(dmem_pair_rdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_ready(1'b1),
    .dmem_read_req(dmem_read_req),
    .dmem_pair_read_req(dmem_pair_read_req),
    .dmem_we   (dmem_we),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .dmem_pair_wdata(dmem_pair_wdata),
    .dmem_pair_wstrb(dmem_pair_wstrb),
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

function [31:0] th_mempair;
    input [1:0] imm2;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
        th_mempair = {5'h1c, imm2, rs2, rs1, funct3, rd, 7'h0b};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (trap) begin
            $fatal(1, "FAIL: trap asserted pc=%h cycle=%0d", debug_pc, cycle);
        end

        if (dmem_pair_read_req) begin
            pair_read_seen <= pair_read_seen + 1;
            if ((dmem_addr != 32'd72) && (dmem_addr != 32'd80)) begin
                $fatal(1, "FAIL: unexpected pair read base address %h", dmem_addr);
            end
        end

        if (|dmem_wstrb) begin
            dmem[dmem_addr[31:2]] <= dmem_wdata;
        end
        if (|dmem_pair_wstrb) begin
            pair_write_seen <= pair_write_seen + 1;
            dmem[(dmem_addr + 32'd4) >> 2] <= dmem_pair_wdata;
            if (dmem_addr != 32'd80) begin
                $fatal(1, "FAIL: unexpected pair write base address %h", dmem_addr);
            end
        end

        if (dut.u_regfile.regs[31] == 32'd1) begin
            if (dut.u_regfile.regs[5] != 32'h1111_2222) begin
                $fatal(1, "FAIL: th.lwd first destination x5=%h", dut.u_regfile.regs[5]);
            end
            if (dut.u_regfile.regs[6] != 32'h3333_4444) begin
                $fatal(1, "FAIL: th.lwd second destination x6=%h", dut.u_regfile.regs[6]);
            end
            if (dut.u_regfile.regs[7] != 32'h3333_4445) begin
                $fatal(1, "FAIL: pair-load forwarding into x7=%h", dut.u_regfile.regs[7]);
            end
            if (dmem[20] != 32'd10 || dmem[21] != 32'd20) begin
                $fatal(1, "FAIL: th.swd memory values dmem20=%h dmem21=%h", dmem[20], dmem[21]);
            end
            if (dut.u_regfile.regs[10] != 32'd10 || dut.u_regfile.regs[11] != 32'd20) begin
                $fatal(1, "FAIL: th.lwd reload values x10=%h x11=%h", dut.u_regfile.regs[10], dut.u_regfile.regs[11]);
            end
            if (dut.u_regfile.regs[12] != 32'd21) begin
                $fatal(1, "FAIL: reload second-destination forwarding x12=%h", dut.u_regfile.regs[12]);
            end
            if (pair_read_seen != 2 || pair_write_seen != 1) begin
                $fatal(1, "FAIL: expected 2 pair reads and 1 pair write, saw reads=%0d writes=%0d",
                    pair_read_seen, pair_write_seen);
            end
            $display("PASS: xthead mempair diagnostic completed cycles=%0d", cycle);
            $finish;
        end

        if (cycle > 80) begin
            $fatal(1, "FAIL: timeout pc=%h cycle=%0d x5=%h x6=%h x31=%h",
                debug_pc, cycle, dut.u_regfile.regs[5], dut.u_regfile.regs[6], dut.u_regfile.regs[31]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    pair_read_seen = 0;
    pair_write_seen = 0;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
        dmem[idx] = 32'h0000_0000;
    end

    dmem[18] = 32'h1111_2222; // address 72
    dmem[19] = 32'h3333_4444; // address 76

    imem[0] = rv32_i(12'd64, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = 64
    imem[1] = th_mempair(2'd1, 5'd6, 5'd1, 3'b100, 5'd5);     // th.lwd x5,x6,(x1),1,3
    imem[2] = rv32_i(12'd1, 5'd6, 3'b000, 5'd7, 7'b0010011);  // x7 = x6 + 1
    imem[3] = rv32_i(12'd10, 5'd0, 3'b000, 5'd8, 7'b0010011); // x8 = 10
    imem[4] = rv32_i(12'd20, 5'd0, 3'b000, 5'd9, 7'b0010011); // x9 = 20
    imem[5] = th_mempair(2'd2, 5'd9, 5'd1, 3'b101, 5'd8);     // th.swd x8,x9,(x1),2,3
    imem[6] = th_mempair(2'd2, 5'd11, 5'd1, 3'b100, 5'd10);   // th.lwd x10,x11,(x1),2,3
    imem[7] = rv32_i(12'd1, 5'd11, 3'b000, 5'd12, 7'b0010011); // x12 = x11 + 1
    imem[8] = rv32_i(12'd1, 5'd0, 3'b000, 5'd31, 7'b0010011); // done marker

    #20;
    rst_n = 1'b1;
end

endmodule
