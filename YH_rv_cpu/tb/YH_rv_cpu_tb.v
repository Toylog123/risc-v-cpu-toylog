`timescale 1ns / 1ps

module YH_rv_cpu_tb;

reg         clk;
reg         rst_n;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
reg [31:0] dmem [0:63];
integer cycle;

assign imem_rdata = imem[imem_addr[31:2]];
assign dmem_rdata = dmem[dmem_addr[31:2]];

YH_rv_cpu dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .trap      (trap),
    .debug_pc  (debug_pc)
);

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

function [31:0] rv32_i;
    input [11:0] imm;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [4:0]  rd;
    input [6:0]  opcode;
    begin
        rv32_i = {imm, rs1, funct3, rd, opcode};
    end
endfunction

function [31:0] rv32_s;
    input [11:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;
    begin
        rv32_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    end
endfunction

function [31:0] rv32_b;
    input [12:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;
    begin
        rv32_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    end
endfunction

task apply_store;
    integer word_index;
    begin
        word_index = dmem_addr[31:2];
        if (dmem_wstrb[0]) dmem[word_index][7:0]   <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) dmem[word_index][15:8]  <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) dmem[word_index][23:16] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) dmem[word_index][31:24] <= dmem_wdata[31:24];
    end
endtask

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        apply_store();
        cycle <= cycle + 1;

        if (cycle > 40) begin
            $display("Timeout at PC=%h", debug_pc);
            $finish;
        end

        if (dut.u_regfile.regs[6] == 32'd42) begin
            if (dut.u_regfile.regs[3] != 32'd15) begin
                $display("Unexpected x3 = %0d", dut.u_regfile.regs[3]);
                $finish;
            end

            if (dmem[0] != 32'd15) begin
                $display("Unexpected data memory word 0 = %0d", dmem[0]);
                $finish;
            end

            if (trap) begin
                $display("Trap asserted unexpectedly");
                $finish;
            end

            $display("PASS: x3=%0d x6=%0d dmem0=%0d", dut.u_regfile.regs[3], dut.u_regfile.regs[6], dmem[0]);
            $finish;
        end
    end
end

integer idx;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
        dmem[idx] = 32'h0000_0000;
    end

    imem[0] = rv32_i(12'd5,  5'd0, 3'b000, 5'd1, 7'b0010011);  // 向 x1 写入立即数 5
    imem[1] = rv32_i(12'd10, 5'd0, 3'b000, 5'd2, 7'b0010011);  // 向 x2 写入立即数 10
    imem[2] = rv32_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011); // x3 = x1 + x2
    imem[3] = rv32_s(12'd0, 5'd3, 5'd0, 3'b010, 7'b0100011);   // 将 x3 写入数据存储器地址 0
    imem[4] = rv32_i(12'd0, 5'd0, 3'b010, 5'd4, 7'b0000011);   // 从数据存储器地址 0 读回到 x4
    imem[5] = rv32_b(13'd8, 5'd4, 5'd3, 3'b000, 7'b1100011);   // 若 x3 等于 x4 则跳过下一条指令
    imem[6] = rv32_i(12'd1, 5'd0, 3'b000, 5'd5, 7'b0010011);   // 若分支失败则向 x5 写入 1
    imem[7] = rv32_i(12'd42, 5'd0, 3'b000, 5'd6, 7'b0010011);  // 向 x6 写入 42 作为最终结果检查
    imem[8] = rv32_i(12'd0, 5'd0, 3'b000, 5'd0, 7'b1100111);   // 通过 jalr 回到地址 0，形成停止点

    #20;
    rst_n = 1'b1;
end

endmodule
