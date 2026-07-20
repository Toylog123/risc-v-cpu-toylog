`timescale 1ns / 1ps

module YH_rv_cpu_xthead_memidx_tb;

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
integer write_seen;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rvalid = 1'b1;
assign dmem_rdata = 32'h1234_5678;

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

function [31:0] th_memidx;
    input [4:0] funct5;
    input [1:0] imm2;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
        th_memidx = {funct5, imm2, rs2, rs1, funct3, rd, 7'h0b};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (trap) begin
            $fatal(1, "FAIL: trap asserted pc=%h cycle=%0d", debug_pc, cycle);
        end

        if (dmem_read_req && (dmem_addr != 32'd24) &&
            (dmem_addr != 32'd41) && (dmem_addr != 32'd64) &&
            (dmem_addr != 32'd68) && (dmem_addr != 32'd96) &&
            (dmem_addr != 32'd104)) begin
            $fatal(1, "FAIL: th indexed load used wrong address %h", dmem_addr);
        end

        if (|dmem_wstrb) begin
            write_seen <= write_seen + 1;
            if (dmem_addr == 32'd24) begin
                if (dmem_wdata != 32'h1234_5678) begin
                    $fatal(1, "FAIL: th.srw wrote wrong data %h", dmem_wdata);
                end
                if (dmem_wstrb != 4'b1111) begin
                    $fatal(1, "FAIL: th.srw wrote wrong strobe %b", dmem_wstrb);
                end
            end else if (dmem_addr == 32'd48) begin
                if (dmem_wdata != 32'h0000_0056) begin
                    $fatal(1, "FAIL: th.sbia wrote wrong data %h", dmem_wdata);
                end
                if (dmem_wstrb != 4'b0001) begin
                    $fatal(1, "FAIL: th.sbia wrote wrong strobe %b", dmem_wstrb);
                end
            end else if (dmem_addr == 32'd80) begin
                if (dmem_wdata != 32'h1234_5678) begin
                    $fatal(1, "FAIL: th.swia wrote wrong data %h", dmem_wdata);
                end
                if (dmem_wstrb != 4'b1111) begin
                    $fatal(1, "FAIL: th.swia wrote wrong strobe %b", dmem_wstrb);
                end
            end else if (dmem_addr == 32'd112) begin
                if (dmem_wdata != 32'h0000_5678) begin
                    $fatal(1, "FAIL: th.shia wrote wrong data %h", dmem_wdata);
                end
                if (dmem_wstrb != 4'b0011) begin
                    $fatal(1, "FAIL: th.shia wrote wrong strobe %b", dmem_wstrb);
                end
            end else begin
                $fatal(1, "FAIL: unexpected th store address %h", dmem_addr);
            end
        end

        if ((cycle > 24) && (dut.u_regfile.regs[9] == 32'd9)) begin
            if (dut.u_regfile.regs[3] != 32'h1234_5678) begin
                $fatal(1, "FAIL: th.lrw loaded x3=%h", dut.u_regfile.regs[3]);
            end
            if (dut.u_regfile.regs[4] != 32'h0000_5678) begin
                $fatal(1, "FAIL: th.lrhu loaded x4=%h", dut.u_regfile.regs[4]);
            end
            if (dut.u_regfile.regs[6] != 32'h0000_0078) begin
                $fatal(1, "FAIL: th.lrbu loaded x6=%h", dut.u_regfile.regs[6]);
            end
            if (dut.u_regfile.regs[7] != 32'h0000_0056) begin
                $fatal(1, "FAIL: th.lbuib loaded x7=%h", dut.u_regfile.regs[7]);
            end
            if (dut.u_regfile.regs[8] != 32'h1234_5678) begin
                $fatal(1, "FAIL: th.lwia loaded x8=%h", dut.u_regfile.regs[8]);
            end
            if (dut.u_regfile.regs[15] != 32'h1234_5678) begin
                $fatal(1, "FAIL: th.lwib loaded x15=%h", dut.u_regfile.regs[15]);
            end
            if (dut.u_regfile.regs[16] != 32'h0000_5678) begin
                $fatal(1, "FAIL: th.lhia loaded x16=%h", dut.u_regfile.regs[16]);
            end
            if (dut.u_regfile.regs[17] != 32'h0000_0078) begin
                $fatal(1, "FAIL: th.lbuia loaded x17=%h", dut.u_regfile.regs[17]);
            end
            if (dut.u_regfile.regs[10] != 32'd41) begin
                $fatal(1, "FAIL: th.lbuib base update x10=%h", dut.u_regfile.regs[10]);
            end
            if (dut.u_regfile.regs[11] != 32'd49) begin
                $fatal(1, "FAIL: th.sbia base update x11=%h", dut.u_regfile.regs[11]);
            end
            if (dut.u_regfile.regs[12] != 32'd68) begin
                $fatal(1, "FAIL: th.lwia base update x12=%h", dut.u_regfile.regs[12]);
            end
            if (dut.u_regfile.regs[14] != 32'd68) begin
                $fatal(1, "FAIL: th.lwib base update x14=%h", dut.u_regfile.regs[14]);
            end
            if (dut.u_regfile.regs[13] != 32'd84) begin
                $fatal(1, "FAIL: th.swia base update x13=%h", dut.u_regfile.regs[13]);
            end
            if (dut.u_regfile.regs[18] != 32'd103) begin
                $fatal(1, "FAIL: th.lbuia base update x18=%h", dut.u_regfile.regs[18]);
            end
            if (dut.u_regfile.regs[19] != 32'd114) begin
                $fatal(1, "FAIL: th.shia base update x19=%h", dut.u_regfile.regs[19]);
            end
            if (write_seen != 4) begin
                $fatal(1, "FAIL: expected four th stores, saw %0d", write_seen);
            end
            $display("PASS: xthead memidx diagnostic completed cycles=%0d", cycle);
            $finish;
        end

        if (cycle > 80) begin
            $fatal(1, "FAIL: timeout pc=%h cycle=%0d x3=%h x5=%h writes=%0d",
                debug_pc, cycle, dut.u_regfile.regs[3], dut.u_regfile.regs[5], write_seen);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    write_seen = 0;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    imem[0] = rv32_i(12'd16, 5'd0, 3'b000, 5'd1, 7'b0010011); // addi x1,x0,16
    imem[1] = rv32_i(12'd2,  5'd0, 3'b000, 5'd2, 7'b0010011); // addi x2,x0,2
    imem[2] = th_memidx(5'h08, 2'd2, 5'd2, 5'd1, 3'b100, 5'd3); // th.lrw x3,x1,x2,2
    imem[3] = th_memidx(5'h08, 2'd2, 5'd2, 5'd1, 3'b101, 5'd3); // th.srw x3,x1,x2,2
    imem[4] = th_memidx(5'h14, 2'd2, 5'd2, 5'd1, 3'b100, 5'd4); // th.lrhu x4,x1,x2,2
    imem[5] = th_memidx(5'h10, 2'd2, 5'd2, 5'd1, 3'b100, 5'd6); // th.lrbu x6,x1,x2,2
    imem[6] = rv32_i(12'd40, 5'd0, 3'b000, 5'd10, 7'b0010011); // x10 = 40
    imem[7] = th_memidx(5'h11, 2'd0, 5'd1, 5'd10, 3'b100, 5'd7); // th.lbuib x7,(x10),1,0
    imem[8] = rv32_i(12'd48, 5'd0, 3'b000, 5'd11, 7'b0010011); // x11 = 48
    imem[9] = th_memidx(5'h03, 2'd0, 5'd1, 5'd11, 3'b101, 5'd7); // th.sbia x7,(x11),1,0
    imem[10] = rv32_i(12'd64, 5'd0, 3'b000, 5'd12, 7'b0010011); // x12 = 64
    imem[11] = th_memidx(5'h0b, 2'd0, 5'd4, 5'd12, 3'b100, 5'd8); // th.lwia x8,(x12),4,0
    imem[12] = rv32_i(12'd64, 5'd0, 3'b000, 5'd14, 7'b0010011); // x14 = 64
    imem[13] = th_memidx(5'h09, 2'd0, 5'd4, 5'd14, 3'b100, 5'd15); // th.lwib x15,(x14),4,0
    imem[14] = rv32_i(12'd80, 5'd0, 3'b000, 5'd13, 7'b0010011); // x13 = 80
    imem[15] = th_memidx(5'h0b, 2'd0, 5'd4, 5'd13, 3'b101, 5'd8); // th.swia x8,(x13),4,0
    imem[16] = rv32_i(12'd96, 5'd0, 3'b000, 5'd18, 7'b0010011); // x18 = 96
    imem[17] = th_memidx(5'h07, 2'd0, 5'd2, 5'd18, 3'b100, 5'd16); // th.lhia x16,(x18),2,0
    imem[18] = rv32_i(12'd104, 5'd0, 3'b000, 5'd18, 7'b0010011); // x18 = 104
    imem[19] = th_memidx(5'h13, 2'd0, 5'b1_1111, 5'd18, 3'b100, 5'd17); // th.lbuia x17,(x18),-1,0
    imem[20] = rv32_i(12'd112, 5'd0, 3'b000, 5'd19, 7'b0010011); // x19 = 112
    imem[21] = th_memidx(5'h07, 2'd0, 5'd2, 5'd19, 3'b101, 5'd4); // th.shia x4,(x19),2,0
    imem[22] = rv32_i(12'd9,  5'd0, 3'b000, 5'd9, 7'b0010011); // done marker

    #20;
    rst_n = 1'b1;
end

endmodule
