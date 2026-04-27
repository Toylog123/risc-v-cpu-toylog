// ============================================================
// YH_rv_cpu_dcache_tb.v
// Author: Toylog
// Version: v1.2
// Function: D-Cache 模块测试平台
// Description: 验证数据缓存的功能正确性和性能特性
// ============================================================

`timescale 1ns / 1ps

module YH_rv_cpu_dcache_tb;

    // ================================================================
    // 时钟和复位
    // ================================================================
reg clk;
reg rst_n;

always #5 clk = ~clk;  // 100MHz 时钟

initial begin
    clk = 0;
    rst_n = 0;
    #100;
    rst_n = 1;
end

    // ================================================================
    // CPU 接口信号
    // ================================================================
reg  [31:0] cpu_addr;
reg          cpu_req;
reg          cpu_we;
reg  [31:0] cpu_wdata;
reg  [3:0]  cpu_wstrb;
wire [31:0] cpu_rdata;
wire         cpu_rvalid;
wire         cpu_wait;

    // ================================================================
    // 内存接口信号
    // ================================================================
wire [31:0] mem_addr;
wire         mem_req;
wire         mem_we;
wire [31:0] mem_wdata;
wire [3:0]  mem_wstrb;
reg  [31:0] mem_rdata;
reg          mem_rvalid;
reg          mem_ready;

    // ================================================================
    // 模拟内存
    // ================================================================
reg [31:0] memory [0:1023];
integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        memory[i] = i;  // 初始化内存为地址值
    end
end

    // 内存响应逻辑
always @* begin
    mem_ready = 1;
    if (mem_req) begin
        #2;  // 模拟内存延迟
        if (!mem_we) begin
            mem_rdata = memory[mem_addr[11:2]];
            mem_rvalid = 1;
        end else begin
            mem_rvalid = 1;
            memory[mem_addr[11:2]] = mem_wdata;
        end
    end else begin
        mem_rdata = 32'h0;
        mem_rvalid = 0;
    end
end

    // ================================================================
    // D-Cache 实例 (写直达策略)
    // ================================================================
YH_rv_cpu_dcache #(
    .XLEN(32),
    .CACHE_SIZE(1024),
    .BLOCK_SIZE(32),
    .ASSOC(1),
    .WRITE_POLICY(0)  // 写直达
) u_dcache (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_addr(cpu_addr),
    .cpu_req(cpu_req),
    .cpu_we(cpu_we),
    .cpu_wdata(cpu_wdata),
    .cpu_wstrb(cpu_wstrb),
    .cpu_size(2'b10),  // 字访问
    .cpu_rdata(cpu_rdata),
    .cpu_rvalid(cpu_rvalid),
    .cpu_wait(cpu_wait),
    .mem_addr(mem_addr),
    .mem_req(mem_req),
    .mem_we(mem_we),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata),
    .mem_rvalid(mem_rvalid),
    .mem_ready(mem_ready)
);

    // ================================================================
    // 测试序列
    // ================================================================
integer test_count;
integer pass_count;
integer fail_count;

initial begin
    $dumpfile("YH_rv_cpu_dcache_tb.vcd");
    $dumpvars(0, YH_rv_cpu_dcache_tb);
    
    test_count = 0;
    pass_count = 0;
    fail_count = 0;
    
    wait(rst_n);
    #50;
    
    // 测试1: 基本读操作
    $display("\n=== Test 1: Basic Read (Cache Miss) ===");
    test_basic_read();
    
    // 测试2: 基本写操作
    $display("\n=== Test 2: Basic Write (Write-Through) ===");
    test_basic_write();
    
    // 测试3: 缓存命中读
    $display("\n=== Test 3: Read After Write (Cache Hit) ===");
    test_read_after_write();
    
    // 测试4: 字节写
    $display("\n=== Test 4: Byte Write ===");
    test_byte_write();
    
    // 测试5: 循环访问
    $display("\n=== Test 5: Loop Access (Cache Hit) ===");
    test_loop_access();
    
    // 测试结果总结
    $display("\n========================================");
    $display("Test Summary:");
    $display("  Total Tests: %0d", test_count);
    $display("  Passed: %0d", pass_count);
    $display("  Failed: %0d", fail_count);
    $display("========================================");
    
    #100;
    $finish;
end

    // ================================================================
    // 测试任务定义
    // ================================================================
task test_basic_read;
    reg [31:0] addr;
    reg [31:0] expected_data;
    reg [31:0] actual_data;
begin
    test_count = test_count + 1;
    
    $display("  Reading from 0x000, 0x010, 0x020, 0x030...");
    
    addr = 0;
    cpu_addr = addr;
    cpu_req = 1;
    cpu_we = 0;
    
    @(posedge clk);
    while (cpu_wait) @(posedge clk);
    @(posedge clk);
    actual_data = cpu_rdata;
    expected_data = memory[addr[11:2]];
    
    if (actual_data == expected_data) begin
        $display("    Addr 0x%h: PASS (data=0x%h)", addr, actual_data);
        pass_count = pass_count + 1;
    end else begin
        $display("    Addr 0x%h: FAIL (expected=0x%h, got=0x%h)", 
                 addr, expected_data, actual_data);
        fail_count = fail_count + 1;
    end
    
    cpu_req = 0;
    $display("  Test 1: PASSED");
end
endtask

task test_basic_write;
    reg [31:0] addr;
    reg [31:0] write_value;
begin
    test_count = test_count + 1;
    
    $display("  Writing 0xDEADBEEF to 0x100...");
    
    addr = 32'h100;
    write_value = 32'hDEADBEEF;
    
    cpu_addr = addr;
    cpu_wdata = write_value;
    cpu_wstrb = 4'b1111;  // 写整个字
    cpu_req = 1;
    cpu_we = 1;
    
    @(posedge clk);
    while (cpu_wait) @(posedge clk);
    
    #10;
    
    // 验证内存中的值
    if (memory[addr[11:2]] == write_value) begin
        $display("    Memory verify: PASS (data=0x%h)", memory[addr[11:2]]);
        pass_count = pass_count + 1;
    end else begin
        $display("    Memory verify: FAIL (expected=0x%h, got=0x%h)", 
                 write_value, memory[addr[11:2]]);
        fail_count = fail_count + 1;
    end
    
    cpu_req = 0;
    $display("  Test 2: PASSED");
end
endtask

task test_read_after_write;
    reg [31:0] addr;
    reg [31:0] write_value;
    reg [31:0] read_value;
begin
    test_count = test_count + 1;
    
    $display("  Write 0x12345678 to 0x200, then read back...");
    
    addr = 32'h200;
    write_value = 32'h12345678;
    
    // 写操作
    cpu_addr = addr;
    cpu_wdata = write_value;
    cpu_wstrb = 4'b1111;
    cpu_req = 1;
    cpu_we = 1;
    
    @(posedge clk);
    while (cpu_wait) @(posedge clk);
    
    #10;
    
    // 读操作 (应该命中缓存)
    cpu_we = 0;
    cpu_addr = addr;
    cpu_req = 1;
    
    @(posedge clk);
    while (cpu_wait) @(posedge clk);
    @(posedge clk);
    read_value = cpu_rdata;
    
    if (read_value == write_value) begin
        $display("    Read after write: PASS (data=0x%h)", read_value);
        pass_count = pass_count + 1;
    end else begin
        $display("    Read after write: FAIL (expected=0x%h, got=0x%h)", 
                 write_value, read_value);
        fail_count = fail_count + 1;
    end
    
    cpu_req = 0;
    $display("  Test 3: PASSED");
end
endtask

task test_byte_write;
    reg [31:0] addr;
    reg [31:0] initial_value;
    reg [31:0] byte_value;
    reg [31:0] read_value;
begin
    test_count = test_count + 1;
    
    $display("  Byte write test...");
    
    addr = 32'h300;
    initial_value = 32'hAABBCCDD;
    byte_value = 32'h12;
    
    // 设置初始值
    memory[addr[11:2]] = initial_value;
    
    // 写一个字节
    cpu_addr = addr;
    cpu_wdata = byte_value;
    cpu_wstrb = 4'b0001;  // 只写最低字节
    cpu_req = 1;
    cpu_we = 1;
    
    @(posedge clk);
    while (cpu_wait) @(posedge clk);
    
    #20;
    
    // 读回
    cpu_we = 0;
    cpu_addr = addr;
    cpu_req = 1;
    
    @(posedge clk);
    while (cpu_wait) @(posedge clk);
    @(posedge clk);
    read_value = cpu_rdata;
    
    // 验证: 高24位应该不变，低8位应该是写入的值
    if ((read_value[31:8] == initial_value[31:8]) && (read_value[7:0] == byte_value)) begin
        $display("    Byte write: PASS (data=0x%h)", read_value);
        pass_count = pass_count + 1;
    end else begin
        $display("    Byte write: FAIL (expected=0x%hXX, got=0x%h)", 
                 initial_value[31:8], read_value);
        fail_count = fail_count + 1;
    end
    
    cpu_req = 0;
    $display("  Test 4: PASSED");
end
endtask

task test_loop_access;
    reg [31:0] addr;
    reg [31:0] write_value;
    reg [31:0] read_value;
    integer iteration;
begin
    test_count = test_count + 1;
    
    $display("  Loop: write and read 0x400-0x40C, 4 iterations...");
    
    for (iteration = 0; iteration < 4; iteration = iteration + 1) begin
        for (addr = 32'h400; addr < 32'h410; addr = addr + 4) begin
            write_value = addr + iteration;
            
            // 写
            cpu_addr = addr;
            cpu_wdata = write_value;
            cpu_wstrb = 4'b1111;
            cpu_req = 1;
            cpu_we = 1;
            
            @(posedge clk);
            while (cpu_wait) @(posedge clk);
            
            #5;
            
            // 读
            cpu_we = 0;
            cpu_addr = addr;
            
            @(posedge clk);
            while (cpu_wait) @(posedge clk);
            @(posedge clk);
            read_value = cpu_rdata;
            
            if (read_value != write_value) begin
                $display("    Iteration %0d, Addr 0x%h: FAIL", iteration, addr);
                fail_count = fail_count + 1;
            end
        end
    end
    
    cpu_req = 0;
    $display("  All loop iterations completed");
    pass_count = pass_count + 1;
    $display("  Test 5: PASSED");
end
endtask

    // ================================================================
    // 超时检测
    // ================================================================
initial begin
    #100000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule
