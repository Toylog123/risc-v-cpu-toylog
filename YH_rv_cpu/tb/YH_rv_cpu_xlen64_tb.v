`timescale 1ns / 1ps

module YH_rv_cpu_xlen64_tb;

reg         clk;
reg         rst_n;
wire [63:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [63:0] dmem_addr;
wire [63:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire [63:0] dmem_wdata;
wire [7:0]  dmem_wstrb;
wire        trap;
wire [63:0] debug_pc;

reg [31:0] imem [0:31];
reg [7:0]  dmem [0:63];
integer cycle;
integer idx;

wire [63:0] dmem_rdata_bus;

assign dmem_rdata_bus = {
    dmem[{dmem_addr[31:3], 3'b000} + 32'd7],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd6],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd5],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd4],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd3],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd2],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd1],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd0]
};

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = dmem_rdata_bus;
assign dmem_rvalid = 1'b1;

YH_rv_cpu #(
    .XLEN(64),
    .RESET_VECTOR(64'h0000_0000_0000_0000)
) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
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

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dmem_wstrb[0]) dmem[dmem_addr[31:0] + 32'd0] <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) dmem[dmem_addr[31:0] + 32'd1] <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) dmem[dmem_addr[31:0] + 32'd2] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) dmem[dmem_addr[31:0] + 32'd3] <= dmem_wdata[31:24];
        if (dmem_wstrb[4]) dmem[dmem_addr[31:0] + 32'd4] <= dmem_wdata[39:32];
        if (dmem_wstrb[5]) dmem[dmem_addr[31:0] + 32'd5] <= dmem_wdata[47:40];
        if (dmem_wstrb[6]) dmem[dmem_addr[31:0] + 32'd6] <= dmem_wdata[55:48];
        if (dmem_wstrb[7]) dmem[dmem_addr[31:0] + 32'd7] <= dmem_wdata[63:56];

        if (trap) begin
            $display("Trap asserted unexpectedly at PC=%h", debug_pc);
            $finish(1);
        end

        if ((cycle > 16) &&
            (dut.u_regfile.regs[1] == 64'hffff_ffff_ffff_ffff) &&
            (dut.u_regfile.regs[3] == 64'h0000_0100_0000_0000) &&
            (dut.u_regfile.regs[4] == 64'h0000_0100_0000_0000) &&
            (dut.u_regfile.regs[5] == 64'h0000_0000_0000_0000) &&
            (dut.u_regfile.regs[6] == 64'h0000_0000_0000_0000) &&
            (dut.u_regfile.regs[7] == 64'h0000_0000_0000_0000) &&
            (debug_pc == 64'h0000_0000_0000_0020)) begin
            if ({dmem[7], dmem[6], dmem[5], dmem[4], dmem[3], dmem[2], dmem[1], dmem[0]} != 64'h0000_0100_0000_0000) begin
                $display("Unexpected stored doubleword = %h", {dmem[7], dmem[6], dmem[5], dmem[4], dmem[3], dmem[2], dmem[1], dmem[0]});
                $finish(1);
            end

            $display("PASS: xlen64 smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > 80) begin
            $display("Timeout at PC=%h", debug_pc);
            $finish(1);
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

    for (idx = 0; idx < 64; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    // addi x1, x0, -1
    imem[0] = 32'hfff0_0093;
    // addiw x5, x1, 1
    imem[1] = 32'h0010_829b;
    // addi x2, x0, 1
    imem[2] = 32'h0010_0113;
    // slli x3, x2, 40
    imem[3] = 32'h0281_1193;
    // sd x3, 0(x0)
    imem[4] = 32'h0030_3023;
    // ld x4, 0(x0)
    imem[5] = 32'h0000_3203;
    // lwu x6, 0(x0)
    imem[6] = 32'h0000_6303;
    // addw x7, x1, x2
    imem[7] = 32'h0020_83bb;
    // jal x0, 0
    imem[8] = 32'h0000_006f;

    #20;
    rst_n = 1'b1;
end

endmodule
