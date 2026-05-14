`timescale 1ns / 1ps

module YH_rv_cpu_id_branch_shift_forward_tb;

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
integer ex_bne_redirects;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = 32'h0000_0000;
assign dmem_rvalid = 1'b1;

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

function [31:0] rv32_b;
    input signed [12:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
        rv32_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
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

        if (dut.ex_redirect_valid && dut.id_ex_branch_r && (dut.id_ex_branch_funct3_r == 3'b001)) begin
            ex_bne_redirects <= ex_bne_redirects + 1;
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 8) &&
            (dut.u_regfile.regs[2] == 32'd2) &&
            (dut.u_regfile.regs[3] == 32'd7) &&
            (dut.u_regfile.regs[6] == 32'd5) &&
            (dut.u_regfile.regs[7] == 32'd11)) begin
            if (ex_bne_redirects != 0) begin
                $fatal(1,
                    "FAIL: ID-forwardable branch was resolved in EX ex_bne_redirects=%0d",
                    ex_bne_redirects);
            end

            $display(
                "PASS: id branch shift/xthead forward diagnostic completed at PC=%h cycles=%0d ex_bne_redirects=%0d",
                debug_pc,
                cycle,
                ex_bne_redirects);
            $finish;
        end

        if (cycle > 80) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d ex_bne_redirects=%0d x2=%h x3=%h x6=%h x7=%h",
                debug_pc,
                cycle,
                ex_bne_redirects,
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[6],
                dut.u_regfile.regs[7]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    ex_bne_redirects = 0;

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    imem[0] = rv32_i(12'sd1, 5'd0, 3'b000, 5'd1, 7'b0010011);  // addi x1, x0, 1
    imem[1] = rv32_i(12'h001, 5'd1, 3'b001, 5'd2, 7'b0010011); // slli x2, x1, 1
    imem[2] = rv32_b(13'sd8, 5'd0, 5'd2, 3'b001, 7'b1100011); // bne x2, x0, +8
    imem[3] = rv32_i(12'sd99, 5'd0, 3'b000, 5'd3, 7'b0010011); // poison
    imem[4] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd3, 7'b0010011);  // target
    imem[5] = rv32_i(12'sd5, 5'd0, 3'b000, 5'd4, 7'b0010011);  // addi x4, x0, 5
    imem[6] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd5, 7'b0010011);  // addi x5, x0, 0
    imem[7] = rv32_r(7'd32, 5'd5, 5'd4, 3'b001, 5'd6, 7'b0001011); // th.mveqz x6, x4, x5
    imem[8] = rv32_b(13'sd8, 5'd0, 5'd6, 3'b001, 7'b1100011); // bne x6, x0, +8
    imem[9] = rv32_i(12'sd99, 5'd0, 3'b000, 5'd7, 7'b0010011); // poison
    imem[10] = rv32_i(12'sd11, 5'd0, 3'b000, 5'd7, 7'b0010011); // target
    imem[11] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);

    #20;
    rst_n = 1'b1;
end

endmodule
