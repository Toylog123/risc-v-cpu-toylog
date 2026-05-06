`timescale 1ns / 1ps

module YH_rv_cpu_zmmul_tb;
reg clk;
reg rst_n;
reg timer_irq;

wire imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire dmem_rvalid;
wire dmem_ready;
wire dmem_read_req;
wire dmem_we;
wire [31:0] dmem_wdata;
wire [3:0] dmem_wstrb;
wire trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
reg [31:0] cycle;

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
    .ENABLE_ZMMUL_EXTENSION(1)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .timer_irq(timer_irq),
    .imem_req(imem_req),
    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid),
    .dmem_addr(dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_ready(dmem_ready),
    .dmem_read_req(dmem_read_req),
    .dmem_we(dmem_we),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .trap(trap),
    .debug_pc(debug_pc)
);

task clear_imem;
    integer i;
    begin
        for (i = 0; i < 64; i = i + 1) begin
            imem[i] = 32'h00000013;
        end
    end
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    timer_irq = 1'b0;
    clear_imem();

    imem[0] = 32'h00700093; // addi x1, x0, 7
    imem[1] = 32'h00600113; // addi x2, x0, 6
    imem[2] = 32'h022081b3; // mul  x3, x1, x2
    imem[3] = 32'h00000013; // nop
    imem[4] = 32'h00000013; // nop
    imem[5] = 32'h0220d233; // divu x4, x1, x2
    imem[6] = 32'h0000006f; // jal  x0, 0

    #40;
    rst_n = 1'b1;
    wait (dut.ex_sync_trap_valid || cycle > 100);
    if (dut.u_regfile.regs[3] !== 32'd42) begin
        $fatal(1, "FAIL: zmmul mul result=%h expected=0000002a", dut.u_regfile.regs[3]);
    end
    $display("[PASS] zmmul mul result=%h", dut.u_regfile.regs[3]);
    if (!dut.ex_sync_trap_valid) begin
        $fatal(1, "FAIL: zmmul divu did not raise sync trap pc=%h id_illegal=%b idex_illegal=%b instr=%h",
               debug_pc, dut.u_id_stage.u_decoder.illegal, dut.id_ex_illegal_r, imem[debug_pc[31:2]]);
    end
    $display("[PASS] zmmul divu raised sync trap as unsupported");
    $display("PASS: zmmul diagnostic completed");
    $finish;
end

always @(posedge clk) begin
    if (rst_n && cycle > 200) begin
        $fatal(1, "FAIL: zmmul timeout pc=%h", debug_pc);
    end
end

endmodule
