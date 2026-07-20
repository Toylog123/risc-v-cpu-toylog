`timescale 1ns / 1ps

module YH_rv_cpu_id_alu_dep_fold_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
reg  [31:0] imem_rdata_r;
reg         imem_rvalid_r;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire        dmem_pair_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        dmem_we;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
reg [7:0]  dmem [0:255];
integer cycle;
integer idx;
integer dep_fold_count;

assign dmem_rdata = {
    dmem[{dmem_addr[31:2], 2'b00} + 3],
    dmem[{dmem_addr[31:2], 2'b00} + 2],
    dmem[{dmem_addr[31:2], 2'b00} + 1],
    dmem[{dmem_addr[31:2], 2'b00} + 0]
};
assign dmem_rvalid = dmem_read_req;

YH_rv_cpu #(
    .IMEM_SYNC(1),
    .IMEM_OUTPUT_REG(0),
    .DMEM_SYNC(1),
    .LOAD_USE_FAST_FORWARD(1),
    .ENABLE_ID_BRANCH_EX_FORWARD(1),
    .ENABLE_ID_BRANCH_FOLD(1),
    .ENABLE_ID_ALU_DEP_FOLD(1),
    .REDIRECT_CACHE_ENTRIES(64),
    .REDIRECT_CACHE_XOR_INDEX(1),
    .RESET_VECTOR(32'h0000_0000)
) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
    .imem_req  (imem_req),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata_r),
    .imem_rvalid(imem_rvalid_r),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_pair_rdata(32'h0000_0000),
    .dmem_rvalid(dmem_rvalid),
    .dmem_ready(1'b1),
    .dmem_read_req(dmem_read_req),
    .dmem_pair_read_req(dmem_pair_read_req),
    .dmem_we(dmem_we),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .dmem_pair_wdata(),
    .dmem_pair_wstrb(),
    .trap      (trap),
    .debug_pc  (debug_pc)
);

function [31:0] rv32_i;
    input signed [11:0] imm;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_i = {imm[11:0], rs1, funct3, rd, opcode};
    end
endfunction

function [31:0] rv32_s;
    input signed [11:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
        rv32_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    end
endfunction

function [31:0] rv32_j;
    input signed [20:0] imm;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        imem_rvalid_r <= 1'b0;
        imem_rdata_r <= 32'h0000_0013;
    end else begin
        imem_rvalid_r <= imem_req;
        imem_rdata_r <= imem[imem_addr[31:2]];
    end
end

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dut.id_alu_dep_fold_valid) begin
            dep_fold_count <= dep_fold_count + 1;
        end

        if (dmem_wstrb[0]) dmem[{dmem_addr[7:2], 2'b00}] <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) dmem[{dmem_addr[7:2], 2'b00} + 1] <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) dmem[{dmem_addr[7:2], 2'b00} + 2] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) dmem[{dmem_addr[7:2], 2'b00} + 3] <= dmem_wdata[31:24];

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 20) && (dmem[96] == 8'd12)) begin
            if (dep_fold_count == 0) begin
                $fatal(1, "FAIL: dependent ALU fold never fired; cycles=%0d", cycle);
            end
            if (dut.u_regfile.regs[5] != 32'd12) begin
                $fatal(1, "FAIL: x5=%0d expected 12", dut.u_regfile.regs[5]);
            end
            $display(
                "PASS: ID ALU dependent fold diagnostic cycles=%0d dep_folds=%0d x5=%0d",
                cycle,
                dep_fold_count,
                dut.u_regfile.regs[5]);
            $finish;
        end

        if (cycle > 220) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d x5=%0d dep_folds=%0d dmem96=%02x",
                debug_pc,
                cycle,
                dut.u_regfile.regs[5],
                dep_fold_count,
                dmem[96]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    dep_fold_count = 0;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end
    for (idx = 0; idx < 256; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    imem[0] = rv32_i(12'sd96, 5'd0, 3'b000, 5'd4, 7'b0010011);  // addi x4,x0,96
    imem[1] = rv32_i(12'sd5, 5'd0, 3'b000, 5'd5, 7'b0010011);   // addi x5,x0,5
    imem[2] = rv32_i(12'sd7, 5'd5, 3'b000, 5'd5, 7'b0010011);   // addi x5,x5,7
    imem[3] = rv32_s(12'sd0, 5'd5, 5'd4, 3'b010, 7'b0100011);   // sw x5,0(x4)
    imem[4] = rv32_j(21'sd0, 5'd0, 7'b1101111);                 // park

    #20;
    rst_n = 1'b1;
end

endmodule
