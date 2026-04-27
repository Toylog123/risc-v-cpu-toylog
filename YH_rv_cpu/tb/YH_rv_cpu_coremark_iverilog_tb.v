// YH_rv_cpu_coremark_iverilog_tb.v - CoreMark test for iverilog
`timescale 1ns / 1ps

module YH_rv_cpu_coremark_iverilog_tb;

parameter integer XLEN = 32;
parameter integer MEM_BYTES = 65536;
parameter [31:0] TOHOST_ADDR = 32'h00001000;
parameter [31:0] YH_DONE_ADDR = 32'h10000004;

localparam STRB_W = XLEN / 8;
localparam BUS_ALIGN_LSB = 2;

reg                  clk;
reg                  rst_n;
wire                 imem_req;
wire [XLEN-1:0]      imem_addr;
wire [31:0]          imem_rdata;
wire                 imem_rvalid;
wire [XLEN-1:0]      dmem_addr;
wire [XLEN-1:0]      dmem_rdata;
wire                 dmem_rvalid;
wire                 dmem_read_req;
wire [XLEN-1:0]      dmem_wdata;
wire [STRB_W-1:0]    dmem_wstrb;
wire                 trap;
wire [XLEN-1:0]      debug_pc;

reg [7:0]            mem [0:MEM_BYTES-1];
reg [63:0]           tohost_value;
reg                  yh_done;
integer              cycle;
integer              max_cycles;

wire [31:0] imem_addr32;
wire [31:0] dmem_addr32;
wire [31:0] dmem_bus_base32;

assign imem_addr32 = imem_addr[31:0];
assign dmem_addr32 = dmem_addr[31:0];
assign dmem_bus_base32 = {dmem_addr32[31:BUS_ALIGN_LSB], {BUS_ALIGN_LSB{1'b0}}};

assign dmem_rdata = {
    mem[dmem_bus_base32 + 32'd3],
    mem[dmem_bus_base32 + 32'd2],
    mem[dmem_bus_base32 + 32'd1],
    mem[dmem_bus_base32 + 32'd0]
};
assign imem_rdata = {
    mem[imem_addr32 + 32'd3],
    mem[imem_addr32 + 32'd2],
    mem[imem_addr32 + 32'd1],
    mem[imem_addr32 + 32'd0]
};
assign imem_rvalid = 1'b1;
assign dmem_rvalid = 1'b1;

YH_rv_cpu #(.XLEN(XLEN)) dut (
    .clk(clk), .rst_n(rst_n), .timer_irq(1'b0),
    .imem_req(imem_req), .imem_addr(imem_addr), .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid), .dmem_addr(dmem_addr), .dmem_rdata(dmem_rdata),
    .dmem_rvalid(dmem_rvalid), .dmem_read_req(dmem_read_req),
    .dmem_wdata(dmem_wdata), .dmem_wstrb(dmem_wstrb),
    .trap(trap), .debug_pc(debug_pc)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        for (integer i = 0; i < STRB_W; i = i + 1) begin
            if (dmem_wstrb[i]) begin
                if (dmem_addr32 + i == YH_DONE_ADDR && dmem_wdata[i*8 +: 8] == 8'd1) begin
                    yh_done <= 1'b1;
                    $display("YH_DONE written at cycle=%0d PC=%h", cycle, debug_pc);
                end
                if ((dmem_bus_base32 + i) < MEM_BYTES) begin
                    mem[dmem_bus_base32 + i] <= dmem_wdata[i*8 +: 8];
                end
            end
        end

        tohost_value = {
            mem[TOHOST_ADDR + 7], mem[TOHOST_ADDR + 6],
            mem[TOHOST_ADDR + 5], mem[TOHOST_ADDR + 4],
            mem[TOHOST_ADDR + 3], mem[TOHOST_ADDR + 2],
            mem[TOHOST_ADDR + 1], mem[TOHOST_ADDR + 0]
        };

        if (cycle > 0 && cycle % 500000 == 0)
            $display("CYCLE=%0d PC=%h tohost=%h yh_done=%b", cycle, debug_pc, tohost_value, yh_done);

        if (trap) begin
            $fatal(1, "FAIL: trap at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (yh_done || tohost_value == 64'd1) begin
            $display("PASS: coremark finished PC=%h cycles=%0d", debug_pc, cycle);
            $finish;
        end

        if (cycle > max_cycles) begin
            $fatal(1, "FAIL: timeout at PC=%h cycle=%0d tohost=%h yh_done=%b", debug_pc, cycle, tohost_value, yh_done);
        end
    end
end

initial begin
    clk = 0; rst_n = 0; cycle = 0; yh_done = 0;

    if (!$value$plusargs("max_cycles=%d", max_cycles)) begin
        max_cycles = 15000000;
    end

    $readmemh("build/sw/YH_rv_cpu_coremark_rv32.hex", mem);
    $display("Loaded hex, starting CoreMark...");
    #50; rst_n = 1;
end

endmodule
