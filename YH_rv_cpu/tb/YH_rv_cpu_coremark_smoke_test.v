// YH_rv_cpu_coremark_smoke_test.v - CoreMark smoke test
`timescale 1ns / 1ps

module YH_rv_cpu_coremark_smoke_test;

parameter integer XLEN = 32;
parameter integer MEM_BYTES = 65536;
parameter [31:0] TOHOST_ADDR = 32'h0000_1000;
parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}};

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
integer              cycle;
integer              max_cycles = 15000000;

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

YH_rv_cpu #(.XLEN(XLEN), .RESET_VECTOR(RESET_VECTOR)) dut (
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
            if (dmem_wstrb[i] && (dmem_bus_base32 + i) < MEM_BYTES) begin
                mem[dmem_bus_base32 + i] <= dmem_wdata[i*8 +: 8];
            end
        end

        tohost_value = {
            mem[TOHOST_ADDR + 7], mem[TOHOST_ADDR + 6],
            mem[TOHOST_ADDR + 5], mem[TOHOST_ADDR + 4],
            mem[TOHOST_ADDR + 3], mem[TOHOST_ADDR + 2],
            mem[TOHOST_ADDR + 1], mem[TOHOST_ADDR + 0]
        };

        if (cycle > 0 && cycle % 2000000 == 0)
            $display("CYCLE=%0d PC=%h tohost=%h", cycle, debug_pc, tohost_value);

        if (trap) begin
            $fatal(1, "FAIL: trap at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (tohost_value != 64'd0) begin
            if (tohost_value == 64'd1) begin
                $display("PASS: finished PC=%h cycles=%0d", debug_pc, cycle);
                $finish;
            end else begin
                $fatal(1, "FAIL: tohost=%0d PC=%h", tohost_value, debug_pc);
            end
        end

        if (cycle > max_cycles)
            $fatal(1, "FAIL: timeout PC=%h", debug_pc);
    end
end

initial begin
    clk = 0; rst_n = 0; cycle = 0;
    $readmemh("build/sw/YH_rv_cpu_coremark_rv32_smoke.hex", mem);
    #100; rst_n = 1;
end

endmodule