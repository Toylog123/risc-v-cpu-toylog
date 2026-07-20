// Debug MULHU test WITHOUT any branch/jal
`timescale 1ns / 1ps
module YH_rv_cpu_debug_tb;
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

initial begin
    clk=0; rst_n=0; timer_irq=0;
    for(int i=0;i<128;i++) imem[i]=32'h00000013;
    for(int i=0;i<64;i++) dmem[i]=0;

    $display("========================================");
    $display("MULHU TEST NO BRANCH");
    $display("========================================");

    #50; rst_n=1;

    // Only setup ADDI x1 and ADDI x2, then MULHU
    imem[0]=32'h7F800893; // ADDI x1=x0,2040
    imem[1]=32'h00200913; // ADDI x2=x0,2
    imem[2]=32'h0220a1b3; // MULHU x3=x1,x2
    imem[3]=32'h00000013; // NOP
    imem[4]=32'h00000013; // NOP
    imem[5]=32'h00000013; // NOP

    $display("imem[0]=%h imem[1]=%h imem[2]=%h", imem[0], imem[1], imem[2]);

    // Just wait and check after sufficient cycles
    wait(cycle > 100);

    $display("After 100 cycles:");
    $display("  PC=%h", debug_pc);
    $display("  x1=%h (expected 2040=0x7F8)", dut.u_regfile.regs[1]);
    $display("  x2=%h (expected 2)", dut.u_regfile.regs[2]);
    $display("  x3=%h (expected 0)", dut.u_regfile.regs[3]);

    $finish;
end
always @(posedge clk) if(rst_n && cycle>500) begin $display("[TIMEOUT]"); $finish; end
endmodule