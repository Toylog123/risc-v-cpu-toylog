`timescale 1ns / 1ps

module YH_rv_cpu_bitmanip_fast_subset_tb;
reg clk;
reg rst_n;
reg timer_irq;

wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_ready;
wire        dmem_read_req;
wire        dmem_we;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
reg [31:0] cycle;
integer i;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = 32'h0;
assign dmem_rvalid = 1'b1;
assign dmem_ready = 1'b1;

always #5 clk = ~clk;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cycle <= 32'd0;
    end else begin
        cycle <= cycle + 32'd1;
    end
end

YH_rv_cpu #(
    .XLEN(32),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_XTHEAD_EXTENSION(0)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .timer_irq    (timer_irq),
    .imem_req     (imem_req),
    .imem_addr    (imem_addr),
    .imem_rdata   (imem_rdata),
    .imem_rvalid  (imem_rvalid),
    .dmem_addr    (dmem_addr),
    .dmem_rdata   (dmem_rdata),
    .dmem_rvalid  (dmem_rvalid),
    .dmem_ready   (dmem_ready),
    .dmem_read_req(dmem_read_req),
    .dmem_we      (dmem_we),
    .dmem_wdata   (dmem_wdata),
    .dmem_wstrb   (dmem_wstrb),
    .trap         (trap),
    .debug_pc     (debug_pc)
);

task expect_reg;
    input [4:0] reg_index;
    input [31:0] expected;
    input [127:0] label;
    reg [31:0] actual;
    begin
        actual = dut.u_regfile.regs[reg_index];
        if (actual !== expected) begin
            $fatal(1, "FAIL: %0s x%0d=%h expected=%h", label, reg_index, actual, expected);
        end
        $display("[PASS] %0s x%0d=%h", label, reg_index, actual);
    end
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    timer_irq = 1'b0;
    cycle = 32'd0;

    for (i = 0; i < 64; i = i + 1) begin
        imem[i] = 32'h00000013;
    end

    imem[0] = 32'h00300093; // addi   x1,x0,3
    imem[1] = 32'h00500113; // addi   x2,x0,5
    imem[2] = 32'h2020a1b3; // sh1add x3,x1,x2 = 11
    imem[3] = 32'h40117233; // andn   x4,x2,x1 = 4
    imem[4] = 32'h0a20e2b3; // max    x5,x1,x2 = 5
    imem[5] = 32'h00008337; // lui    x6,0x8
    imem[6] = 32'h00130313; // addi   x6,x6,1 => 0x8001
    imem[7] = 32'h48f35393; // bexti  x7,x6,15 => 1
    imem[8] = 32'h00000013; // nop, let bexti reach writeback before trap
    imem[9] = 32'h00000013; // nop
    imem[10] = 32'h0a209433; // clmul  x8,x1,x2, excluded from fast subset
    imem[11] = 32'h0000006f; // loop

    #40;
    rst_n = 1'b1;

    wait (dut.ex_sync_trap_valid || cycle > 100);

    expect_reg(5'd3, 32'd11, "sh1add");
    expect_reg(5'd4, 32'd4,  "andn");
    expect_reg(5'd5, 32'd5,  "max");
    expect_reg(5'd7, 32'd1,  "bexti");

    if (!dut.ex_sync_trap_valid) begin
        $fatal(1, "FAIL: fast bitmanip subset accepted clmul pc=%h instr=%h",
               debug_pc, imem[8]);
    end

    $display("[PASS] fast subset rejects clmul as unsupported");
    $display("PASS: bitmanip fast subset diagnostic completed");
    $finish;
end

always @(posedge clk) begin
    if (rst_n && cycle > 200) begin
        $fatal(1, "FAIL: bitmanip fast subset timeout pc=%h", debug_pc);
    end
end

endmodule
