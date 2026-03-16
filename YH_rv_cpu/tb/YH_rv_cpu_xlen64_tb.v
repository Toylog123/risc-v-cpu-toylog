`timescale 1ns / 1ps

module YH_rv_cpu_xlen64_tb;

reg         clk;
reg         rst_n;
wire [63:0] imem_addr;
wire [31:0] imem_rdata;
wire [63:0] dmem_addr;
wire [63:0] dmem_rdata;
wire [63:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [63:0] debug_pc;

reg [31:0] imem [0:31];
integer cycle;

assign imem_rdata = imem[imem_addr[31:2]];
assign dmem_rdata = 64'h0000_0000_0000_0000;

YH_rv_cpu #(
    .XLEN(64),
    .RESET_VECTOR(64'h0000_0000_0000_0000)
) dut (
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

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (trap) begin
            $display("Trap asserted unexpectedly at PC=%h", debug_pc);
            $finish(1);
        end

        if (dmem_wstrb != 4'b0000) begin
            $display("Unexpected data write at PC=%h", debug_pc);
            $finish(1);
        end

        if ((cycle > 12) &&
            (dut.u_regfile.regs[1] == 64'hffff_ffff_ffff_ffff) &&
            (dut.u_regfile.regs[3] == 64'h0000_0100_0000_0000) &&
            (dut.u_regfile.regs[4] == 64'h0000_0100_0000_0001) &&
            (debug_pc == 64'h0000_0000_0000_0010)) begin
            $display("PASS: xlen64 smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > 80) begin
            $display("Timeout at PC=%h", debug_pc);
            $finish(1);
        end
    end
end

integer idx;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    // addi x1, x0, -1
    imem[0] = 32'hfff0_0093;
    // addi x2, x0, 1
    imem[1] = 32'h0010_0113;
    // slli x3, x2, 40
    imem[2] = 32'h0281_1193;
    // add x4, x3, x2
    imem[3] = 32'h0021_8233;
    // jal x0, 0
    imem[4] = 32'h0000_006f;

    #20;
    rst_n = 1'b1;
end

endmodule
