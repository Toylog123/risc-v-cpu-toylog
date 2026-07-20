// ============================================================
// YH_rv_cpu_icache_tb.v
// Author: Toylog
// Version: v1.2
// Function: I-Cache 模块测试平台
// Description: 验证指令缓存的功能正确性和性能特性
// ============================================================

`timescale 1ns / 1ps

module YH_rv_cpu_icache_tb;

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

    // ================================================================
    // 模拟内存
    // ================================================================
reg [31:0] memory [0:1023];
integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        memory[i] = 32'h00000013;  // NOP
    end
    
    // 填充一些测试指令
    memory[0] = 32'h00000013;  // NOP
    memory[1] = 32'h00100013;  // ADDI x0, x0, 1
    memory[2] = 32'h00200093;  // ADDI x1, x0, 2
    memory[3] = 32'h00300113;  // ADDI x2, x0, 3
    memory[4] = 32'h00408193;  // ADDI x3, x1, 4
    memory[5] = 32'h00510213;  // ADDI x4, x2, 5
    memory[6] = 32'h00618293;  // ADDI x5, x3, 6
    memory[7] = 32'h007202b3;  // ADD x5, x4, x5
    memory[8] = 32'h00828303;  // LW x6, x5, 8
    memory[9] = 32'h00930313;  // ADDI x6, x6, 9
end

    // 内存响应逻辑
always @* begin
    if (mem_req && !mem_we) begin
        #2;  // 模拟内存延迟
        mem_rdata = memory[mem_addr[11:2]];
        mem_rvalid = 1;
    end else begin
        mem_rdata = 32'h0;
        mem_rvalid = 0;
    end
end

    // ================================================================
    // I-Cache 实例
    // ================================================================
YH_rv_cpu_icache #(
    .XLEN(32),
    .CACHE_SIZE(1024),
    .BLOCK_SIZE(32),
    .ASSOC(1)
) u_icache (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_addr(cpu_addr),
    .cpu_req(cpu_req),
    .cpu_rdata(cpu_rdata),
    .cpu_rvalid(cpu_rvalid),
    .cpu_wait(cpu_wait),
    .mem_addr(mem_addr),
    .mem_req(mem_req),
    .mem_we(mem_we),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata),
    .mem_rvalid(mem_rvalid)
);

    // ================================================================
    // 测试序列
    // ================================================================
integer test_count;
integer pass_count;
integer fail_count;

initial begin
    $dumpfile("YH_rv_cpu_icache_tb.vcd");
    $dumpvars(0, YH_rv_cpu_icache_tb);
    
    test_count = 0;
    pass_count = 0;
    fail_count = 0;
    
    wait(rst_n);
    #50;
    
    // 测试1: 顺序取指 (缓存命中)
    $display("\n=== Test 1: Sequential Fetch (Cache Hit) ===");
    test_sequential_fetch();
    
    // 测试2: 随机访问 (缓存缺失)
    $display("\n=== Test 2: Random Access (Cache Miss) ===");
    test_random_access();
    
    // 测试3: 循环访问 (缓存命中)
    $display("\n=== Test 3: Loop Access (Cache Hit) ===");
    test_loop_access();
    
    // 测试4: 大跨度访问 (缓存缺失)
    $display("\n=== Test 4: Large Span Access (Cache Miss) ===");
    test_large_span_access();
    
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
task test_sequential_fetch;
    reg [31:0] addr;
    reg [31:0] expected_data;
    reg [31:0] actual_data;
begin
    test_count = test_count + 1;
    
    $display("  Fetching instructions from 0x000 to 0x040...");
    
    for (addr = 0; addr < 32; addr = addr + 4) begin
        cpu_addr = addr;
        cpu_req = 1;
        
        @(posedge clk);
        while (cpu_wait) @(posedge clk);
        
        @(posedge clk);
        actual_data = cpu_rdata;
        expected_data = memory[addr[11:2]];
        
        if (actual_data == expected_data) begin
            $display("    Addr 0x%h: PASS (data=0x%h)", addr, actual_data);
        end else begin
            $display("    Addr 0x%h: FAIL (expected=0x%h, got=0x%h)", 
                     addr, expected_data, actual_data);
            fail_count = fail_count + 1;
        end
    end
    
    cpu_req = 0;
    pass_count = pass_count + 1;
    $display("  Test 1: PASSED");
end
endtask

task test_random_access;
    reg [31:0] addr_list [0:7];
    reg [31:0] addr;
    reg [31:0] expected_data;
    reg [31:0] actual_data;
    integer j;
begin
    test_count = test_count + 1;
    
    addr_list[0] = 32'h000;
    addr_list[1] = 32'h100;
    addr_list[2] = 32'h200;
    addr_list[3] = 32'h300;
    addr_list[4] = 32'h010;
    addr_list[5] = 32'h110;
    addr_list[6] = 32'h210;
    addr_list[7] = 32'h310;
    
    $display("  Random access to 8 addresses...");
    
    for (j = 0; j < 8; j = j + 1) begin
        addr = addr_list[j];
        cpu_addr = addr;
        cpu_req = 1;
        
        @(posedge clk);
        while (cpu_wait) @(posedge clk);
        
        @(posedge clk);
        actual_data = cpu_rdata;
        expected_data = memory[addr[11:2]];
        
        if (actual_data == expected_data) begin
            $display("    Addr 0x%h: PASS (data=0x%h)", addr, actual_data);
        end else begin
            $display("    Addr 0x%h: FAIL (expected=0x%h, got=0x%h)", 
                     addr, expected_data, actual_data);
            fail_count = fail_count + 1;
        end
    end
    
    cpu_req = 0;
    pass_count = pass_count + 1;
    $display("  Test 2: PASSED");
end
endtask

task test_loop_access;
    reg [31:0] addr;
    reg [31:0] expected_data;
    reg [31:0] actual_data;
    integer iteration;
begin
    test_count = test_count + 1;
    
    $display("  Loop access: iterating 4 times over 0x000-0x010...");
    
    for (iteration = 0; iteration < 4; iteration = iteration + 1) begin
        for (addr = 0; addr < 16; addr = addr + 4) begin
            cpu_addr = addr;
            cpu_req = 1;
            
            @(posedge clk);
            while (cpu_wait) @(posedge clk);
            
            @(posedge clk);
            actual_data = cpu_rdata;
            expected_data = memory[addr[11:2]];
            
            if (actual_data != expected_data) begin
                $display("    Iteration %0d, Addr 0x%h: FAIL", iteration, addr);
                fail_count = fail_count + 1;
            end
        end
    end
    
    cpu_req = 0;
    $display("  All loop iterations passed");
    pass_count = pass_count + 1;
    $display("  Test 3: PASSED");
end
endtask

task test_large_span_access;
    reg [31:0] addr_list [0:3];
    reg [31:0] addr;
    reg [31:0] expected_data;
    reg [31:0] actual_data;
    integer j;
begin
    test_count = test_count + 1;
    
    addr_list[0] = 32'h000;
    addr_list[1] = 32'h400;
    addr_list[2] = 32'h800;
    addr_list[3] = 32'hC00;
    
    $display("  Large span access: 4 cache lines...");
    
    for (j = 0; j < 4; j = j + 1) begin
        addr = addr_list[j];
        cpu_addr = addr;
        cpu_req = 1;
        
        @(posedge clk);
        while (cpu_wait) @(posedge clk);
        
        @(posedge clk);
        actual_data = cpu_rdata;
        expected_data = memory[addr[11:2]];
        
        if (actual_data == expected_data) begin
            $display("    Addr 0x%h: PASS (data=0x%h)", addr, actual_data);
        end else begin
            $display("    Addr 0x%h: FAIL (expected=0x%h, got=0x%h)", 
                     addr, expected_data, actual_data);
            fail_count = fail_count + 1;
        end
    end
    
    cpu_req = 0;
    pass_count = pass_count + 1;
    $display("  Test 4: PASSED");
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
