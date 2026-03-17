`timescale 1ns / 1ps

module YH_rv_cpu_riscv_tests_tb #(
    parameter integer XLEN = 32,
    parameter integer MEM_BYTES = 65536,
    parameter [31:0] TOHOST_ADDR = 32'h0000_1000,
    parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}}
) ();

localparam integer STRB_W = XLEN / 8;
localparam integer BUS_ALIGN_LSB = (XLEN == 64) ? 3 : 2;

reg                  clk;
reg                  rst_n;
wire [XLEN-1:0]      imem_addr;
wire [31:0]          imem_rdata;
wire                 imem_rvalid;
wire [XLEN-1:0]      dmem_addr;
wire [XLEN-1:0]      dmem_rdata;
wire [XLEN-1:0]      dmem_wdata;
wire [STRB_W-1:0]    dmem_wstrb;
wire                 trap;
wire [XLEN-1:0]      debug_pc;

reg [7:0]            mem [0:MEM_BYTES-1];
reg [8*260-1:0]      program_hex;
reg [63:0]           tohost_value;
integer              cycle;
integer              idx;
integer              byte_idx;
integer              max_cycles;
integer              debug_cycles;

wire [31:0] imem_addr32;
wire [31:0] dmem_addr32;
wire [31:0] dmem_bus_base32;

assign imem_addr32 = imem_addr[31:0];
assign dmem_addr32 = dmem_addr[31:0];
assign dmem_bus_base32 = {dmem_addr32[31:BUS_ALIGN_LSB], {BUS_ALIGN_LSB{1'b0}}};

generate
    if (XLEN == 64) begin : g_rdata64
        assign dmem_rdata = {
            mem[dmem_bus_base32 + 32'd7],
            mem[dmem_bus_base32 + 32'd6],
            mem[dmem_bus_base32 + 32'd5],
            mem[dmem_bus_base32 + 32'd4],
            mem[dmem_bus_base32 + 32'd3],
            mem[dmem_bus_base32 + 32'd2],
            mem[dmem_bus_base32 + 32'd1],
            mem[dmem_bus_base32 + 32'd0]
        };
    end else begin : g_rdata32
        assign dmem_rdata = {
            mem[dmem_bus_base32 + 32'd3],
            mem[dmem_bus_base32 + 32'd2],
            mem[dmem_bus_base32 + 32'd1],
            mem[dmem_bus_base32 + 32'd0]
        };
    end
endgenerate

assign imem_rdata = {
    mem[imem_addr32 + 32'd3],
    mem[imem_addr32 + 32'd2],
    mem[imem_addr32 + 32'd1],
    mem[imem_addr32 + 32'd0]
};
assign imem_rvalid = 1'b1;

YH_rv_cpu #(
    .XLEN(XLEN),
    .RESET_VECTOR(RESET_VECTOR)
) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .trap      (trap),
    .debug_pc  (debug_pc)
);

always #5 clk = ~clk;

task update_tohost;
    begin
        tohost_value = {
            mem[TOHOST_ADDR + 32'd7],
            mem[TOHOST_ADDR + 32'd6],
            mem[TOHOST_ADDR + 32'd5],
            mem[TOHOST_ADDR + 32'd4],
            mem[TOHOST_ADDR + 32'd3],
            mem[TOHOST_ADDR + 32'd2],
            mem[TOHOST_ADDR + 32'd1],
            mem[TOHOST_ADDR + 32'd0]
        };
    end
endtask

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        for (byte_idx = 0; byte_idx < STRB_W; byte_idx = byte_idx + 1) begin
            if (dmem_wstrb[byte_idx] && ((dmem_bus_base32 + byte_idx) < MEM_BYTES)) begin
                mem[dmem_bus_base32 + byte_idx] <= dmem_wdata[byte_idx * 8 +: 8];
            end
        end

        update_tohost();

        if ((debug_cycles > 0) && (cycle < debug_cycles)) begin
            $display(
                "TRACE cycle=%0d pc=%h inst=%h tohost=%h daddr=%h dwdata=%h wstrb=%h x28=%h x5=%h x6=%h x7=%h",
                cycle,
                debug_pc,
                imem_rdata,
                tohost_value,
                dmem_addr,
                dmem_wdata,
                dmem_wstrb,
                dut.u_regfile.regs[28],
                dut.u_regfile.regs[5],
                dut.u_regfile.regs[6],
                dut.u_regfile.regs[7]
            );
        end

        if (dmem_wstrb != {STRB_W{1'b0}}) begin
            $display(
                "STORE cycle=%0d pc=%h daddr=%h dwdata=%h wstrb=%h tohost_before=%h",
                cycle,
                debug_pc,
                dmem_addr,
                dmem_wdata,
                dmem_wstrb,
                tohost_value
            );
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h", debug_pc);
        end

        if (tohost_value != 64'd0) begin
            if (tohost_value == 64'd1) begin
                $display("PASS: riscv-tests finished at PC=%h in %0d cycles with tohost=%0d", debug_pc, cycle, tohost_value);
                $finish;
            end else begin
                $fatal(1, "FAIL: riscv-tests reported failure at PC=%h in %0d cycles with tohost=%0d", debug_pc, cycle, tohost_value);
            end
        end

        if (cycle > max_cycles) begin
            $fatal(1, "FAIL: riscv-tests timeout at PC=%h after %0d cycles", debug_pc, cycle);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    max_cycles = 20000;
    debug_cycles = 0;
    program_hex = "build/tests/riscv-tests/current.hex";

    if (!$value$plusargs("hex=%s", program_hex)) begin
        program_hex = "build/tests/riscv-tests/current.hex";
    end

    if (!$value$plusargs("max_cycles=%d", max_cycles)) begin
        max_cycles = 20000;
    end

    if (!$value$plusargs("debug_cycles=%d", debug_cycles)) begin
        debug_cycles = 0;
    end

    for (idx = 0; idx < MEM_BYTES; idx = idx + 1) begin
        mem[idx] = 8'h00;
    end

    $readmemh(program_hex, mem);
    update_tohost();

    #20;
    rst_n = 1'b1;
end

endmodule
