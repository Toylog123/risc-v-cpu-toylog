`timescale 1ns / 1ps

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_dcache_word_tb;
reg clk;
reg rst_n;

reg  [31:0] cpu_addr;
reg         cpu_req;
reg         cpu_we;
reg  [31:0] cpu_wdata;
reg  [3:0]  cpu_wstrb;
reg  [1:0]  cpu_size;
reg         cpu_unsigned;
wire [31:0] cpu_rdata;
wire        cpu_rvalid;
wire        cpu_wait;

wire [31:0] mem_addr;
wire        mem_req;
wire        mem_we;
wire [31:0] mem_wdata;
wire [3:0]  mem_wstrb;
reg  [31:0] mem_rdata;
reg         mem_rvalid;
reg         mem_ready;

reg [31:0] memory [0:255];
integer failures;
integer wait_cycles;

YH_rv_cpu_dcache #(
    .XLEN(32),
    .CACHE_SIZE(256),
    .BLOCK_SIZE(4),
    .ASSOC(1),
    .WRITE_POLICY(0)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_addr(cpu_addr),
    .cpu_req(cpu_req),
    .cpu_we(cpu_we),
    .cpu_wdata(cpu_wdata),
    .cpu_wstrb(cpu_wstrb),
    .cpu_size(cpu_size),
    .cpu_unsigned(cpu_unsigned),
    .cpu_rdata(cpu_rdata),
    .cpu_rvalid(cpu_rvalid),
    .cpu_wait(cpu_wait),
    .probe_req(1'b0),
    .probe_addr(32'h0),
    .probe_hit(),
    .mem_addr(mem_addr),
    .mem_req(mem_req),
    .mem_we(mem_we),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata),
    .mem_rvalid(mem_rvalid),
    .mem_ready(mem_ready)
);

always #5 clk = ~clk;

task check;
    input condition;
    input [255:0] message;
    begin
        if (!condition) begin
            $display("FAIL: %0s", message);
            failures = failures + 1;
        end
    end
endtask

task apply_store_word;
    input [31:0] addr;
    input [31:0] data;
    input [3:0]  strb;
    integer b;
    begin
        for (b = 0; b < 4; b = b + 1) begin
            if (strb[b]) begin
                memory[addr[9:2]][b*8 +: 8] <= data[b*8 +: 8];
            end
        end
    end
endtask

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_rvalid <= 1'b0;
        mem_rdata <= 32'h0;
        mem_ready <= 1'b1;
    end else begin
        mem_ready <= 1'b1;
        mem_rvalid <= mem_req && !mem_we;
        mem_rdata <= memory[mem_addr[9:2]];
        if (mem_we) begin
            apply_store_word(mem_addr, mem_wdata, mem_wstrb);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cpu_addr = 32'h0;
    cpu_req = 1'b0;
    cpu_we = 1'b0;
    cpu_wdata = 32'h0;
    cpu_wstrb = 4'h0;
    cpu_size = `YH_rv_cpu_MEM_W;
    cpu_unsigned = 1'b0;
    failures = 0;

    memory[4] = 32'h1122_3344;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    @(negedge clk);
    cpu_addr = 32'h0000_0010;
    cpu_req = 1'b1;
    cpu_we = 1'b0;
    cpu_size = `YH_rv_cpu_MEM_W;
    wait_cycles = 0;
    while (!cpu_rvalid && wait_cycles < 8) begin
        @(posedge clk);
        wait_cycles = wait_cycles + 1;
    end
    check(cpu_rvalid, "read miss should complete");
    check(cpu_rdata == 32'h1122_3344, "read miss data mismatch");
    @(negedge clk);
    cpu_req = 1'b0;

    @(negedge clk);
    cpu_addr = 32'h0000_0010;
    cpu_req = 1'b1;
    cpu_we = 1'b0;
    cpu_size = `YH_rv_cpu_MEM_W;
    #1;
    check(cpu_wait == 1'b0, "cached word read should not wait");
    check(cpu_rvalid == 1'b1, "cached word read should be immediately valid");
    check(cpu_rdata == 32'h1122_3344, "cached word read data mismatch");
    @(negedge clk);
    cpu_req = 1'b0;

    @(negedge clk);
    cpu_addr = 32'h0000_0011;
    cpu_req = 1'b1;
    cpu_we = 1'b0;
    cpu_size = `YH_rv_cpu_MEM_B;
    #1;
    check(cpu_rvalid == 1'b1, "cached byte read should be immediately valid");
    check(cpu_rdata == 32'h0000_0033, "cached byte read data mismatch");
    @(negedge clk);
    cpu_req = 1'b0;

    @(negedge clk);
    cpu_addr = 32'h0000_0011;
    cpu_req = 1'b1;
    cpu_we = 1'b1;
    cpu_wdata = 32'h0000_aa00;
    cpu_wstrb = 4'b0010;
    cpu_size = `YH_rv_cpu_MEM_B;
    #1;
    check(cpu_wait == 1'b0, "store hit should not wait");
    @(posedge clk);
    @(negedge clk);
    cpu_req = 1'b0;
    cpu_we = 1'b0;

    @(negedge clk);
    cpu_addr = 32'h0000_0010;
    cpu_req = 1'b1;
    cpu_we = 1'b0;
    cpu_size = `YH_rv_cpu_MEM_W;
    #1;
    check(cpu_rvalid == 1'b1, "read after store should hit");
    check(cpu_rdata == 32'h1122_aa44, "read after byte store data mismatch");
    check(memory[4] == 32'h1122_aa44, "write-through memory update mismatch");
    @(negedge clk);
    cpu_req = 1'b0;

    @(negedge clk);
    cpu_addr = 32'h0000_0020;
    cpu_req = 1'b1;
    cpu_we = 1'b1;
    cpu_wdata = 32'h5566_7788;
    cpu_wstrb = 4'b1111;
    cpu_size = `YH_rv_cpu_MEM_W;
    #1;
    check(cpu_wait == 1'b0, "store miss should not wait");
    @(posedge clk);
    @(negedge clk);
    cpu_req = 1'b0;
    cpu_we = 1'b0;
    check(memory[8] == 32'h5566_7788, "store miss write-through address mismatch");

    if (failures == 0) begin
        $display("PASS: dcache word-cache behavior");
    end else begin
        $display("FAIL: dcache word-cache behavior failures=%0d", failures);
    end
    $finish;
end

endmodule
