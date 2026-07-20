// YH_rv_cpu_m_extension_tb.v - RISC-V M扩展测试
`timescale 1ns / 1ps
module YH_rv_cpu_m_ext_test;
reg clk, rst_n;
wire imem_req, imem_rvalid, dmem_rvalid, dmem_read_req, trap;
wire [31:0] imem_addr, imem_rdata, dmem_addr, dmem_rdata, dmem_wdata, debug_pc;
wire [3:0] dmem_wstrb;
reg timer_irq;
reg [31:0] imem [0:127];
reg [31:0] dmem [0:63];
assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = dmem[dmem_addr[31:2]];
assign dmem_rvalid = 1'b1;
task apply_store; integer wi; begin wi=dmem_addr[31:2]; if(dmem_wstrb[0]) dmem[wi][7:0]<=dmem_wdata[7:0]; if(dmem_wstrb[1]) dmem[wi][15:8]<=dmem_wdata[15:8]; if(dmem_wstrb[2]) dmem[wi][23:16]<=dmem_wdata[23:16]; if(dmem_wstrb[3]) dmem[wi][31:24]<=dmem_wdata[31:24]; end endtask
always #5 clk=~clk;
reg [31:0] cycle;
always @(posedge clk) begin if(!rst_n) cycle<=0; else begin cycle<=cycle+1; apply_store(); end end
YH_rv_cpu dut(.clk(clk),.rst_n(rst_n),.timer_irq(timer_irq),.imem_req(imem_req),.imem_addr(imem_addr),.imem_rdata(imem_rdata),.imem_rvalid(imem_rvalid),.dmem_addr(dmem_addr),.dmem_rdata(dmem_rdata),.dmem_rvalid(dmem_rvalid),.dmem_read_req(dmem_read_req),.dmem_wdata(dmem_wdata),.dmem_wstrb(dmem_wstrb),.trap(trap),.debug_pc(debug_pc));
integer pass_count=0, test_count=0;
reg [31:0] result;
initial begin clk=0; rst_n=0; timer_irq=0; for(int i=0;i<128;i++) imem[i]=32'h00000013; for(int i=0;i<64;i++) dmem[i]=0; $display("========================================"); $display("RISC-V M扩展指令测试"); $display("========================================"); #50; rst_n=1;
// TEST 1: MUL 5*3=15
imem[0]=32'h00500093; imem[1]=32'h00300113; imem[2]=32'h022081b3; imem[3]=32'h00000063;
wait(cycle>50); result=dut.u_regfile.regs[3]; test_count++; if(result==15) begin $display("[PASS] TEST %0d: MUL 5*3=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: MUL 5*3 got %0d expected 15",test_count,result);
// TEST 2: MULH (-2)*(-3) high=0
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'hFFE00893; imem[1]=32'hFFD00913; imem[2]=32'h022091b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>120); result=dut.u_regfile.regs[3]; test_count++; if(result==0) begin $display("[PASS] TEST %0d: MULH (-2)*(-3) high=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: MULH got %0d expected 0",test_count,result);
// TEST 3: MULHU 0x80000000*2 high=1
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'h80000137; imem[1]=32'h00200913; imem[2]=32'h0220a1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>190); result=dut.u_regfile.regs[3]; test_count++; if(result==1) begin $display("[PASS] TEST %0d: MULHU 0x80000000*2 high=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: MULHU got %0d expected 1",test_count,result);
// TEST 4: MULHSU (-1)*2 high=0xFFFFFFFF
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'hFFF00893; imem[1]=32'h00200913; imem[2]=32'h0220b1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>260); result=dut.u_regfile.regs[3]; test_count++; if(result==32'hFFFFFFFF) begin $display("[PASS] TEST %0d: MULHSU (-1)*2 high=0xFFFFFFFF",test_count); pass_count++; end else $display("[FAIL] TEST %0d: MULHSU got 0x%h expected 0xFFFFFFFF",test_count,result);
// TEST 5: DIV 10/3=3
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'h00A00893; imem[1]=32'h00300913; imem[2]=32'h0220c1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>330); result=dut.u_regfile.regs[3]; test_count++; if(result==3) begin $display("[PASS] TEST %0d: DIV 10/3=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: DIV got %0d expected 3",test_count,result);
// TEST 6: DIV (-10)/3=-3
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'hFF600893; imem[1]=32'h00300913; imem[2]=32'h0220c1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>400); result=dut.u_regfile.regs[3]; test_count++; if(result==32'hFFFFFFFD) begin $display("[PASS] TEST %0d: DIV (-10)/3=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: DIV got %0d expected -3",test_count,result);
// TEST 7: DIVU 10/3=3
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'h00A00893; imem[1]=32'h00300913; imem[2]=32'h0220d1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>470); result=dut.u_regfile.regs[3]; test_count++; if(result==3) begin $display("[PASS] TEST %0d: DIVU 10/3=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: DIVU got %0d expected 3",test_count,result);
// TEST 8: REM 10%3=1
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'h00A00893; imem[1]=32'h00300913; imem[2]=32'h0220e1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>540); result=dut.u_regfile.regs[3]; test_count++; if(result==1) begin $display("[PASS] TEST %0d: REM 10%%3=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: REM got %0d expected 1",test_count,result);
// TEST 9: REMU 10%3=1
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'h00A00893; imem[1]=32'h00300913; imem[2]=32'h0220f1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>610); result=dut.u_regfile.regs[3]; test_count++; if(result==1) begin $display("[PASS] TEST %0d: REMU 10%%3=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: REMU got %0d expected 1",test_count,result);
// TEST 10: DIV 10/0=0xFFFFFFFF
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'h00A00893; imem[1]=32'h00000913; imem[2]=32'h0220c1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>680); result=dut.u_regfile.regs[3]; test_count++; if(result==32'hFFFFFFFF) begin $display("[PASS] TEST %0d: DIV 10/0=0xFFFFFFFF",test_count); pass_count++; end else $display("[FAIL] TEST %0d: DIV 10/0 got 0x%h expected 0xFFFFFFFF",test_count,result);
// TEST 11: REM 10%0=10
rst_n=0; #20; for(int i=0;i<4;i++) imem[i]=32'h00000013; #20;
imem[0]=32'h00A00893; imem[1]=32'h00000913; imem[2]=32'h0220e1b3; imem[3]=32'h00000063; #20; rst_n=1;
wait(cycle>750); result=dut.u_regfile.regs[3]; test_count++; if(result==10) begin $display("[PASS] TEST %0d: REM 10%%0=%0d",test_count,result); pass_count++; end else $display("[FAIL] TEST %0d: REM 10%%0 got %0d expected 10",test_count,result);
#100; $display("\n========================================"); $display("测试完成: %0d/%0d 通过",pass_count,test_count); $display("========================================"); $finish; end
always @(posedge clk) if(rst_n && cycle>10000) begin $display("[TIMEOUT] PC=%h",debug_pc); $finish; end
endmodule
