`timescale 1ns / 1ps

module YH_rv_cpu_id_alu_pair_fold_tb;

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
integer pair_fold_count;

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
    .ENABLE_ID_ALU_PAIR_FOLD(1),
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

function [31:0] rv32_r;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_r = {funct7, rs2, rs1, funct3, rd, opcode};
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

function [31:0] rv32_b;
    input signed [12:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
        rv32_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
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

        if (dut.id_early_alu_pair_valid) begin
            pair_fold_count <= pair_fold_count + 1;
        end

        if (dmem_wstrb[0]) begin
            dmem[{dmem_addr[7:2], 2'b00}] <= dmem_wdata[7:0];
        end
        if (dmem_wstrb[1]) begin
            dmem[{dmem_addr[7:2], 2'b00} + 1] <= dmem_wdata[15:8];
        end
        if (dmem_wstrb[2]) begin
            dmem[{dmem_addr[7:2], 2'b00} + 2] <= dmem_wdata[23:16];
        end
        if (dmem_wstrb[3]) begin
            dmem[{dmem_addr[7:2], 2'b00} + 3] <= dmem_wdata[31:24];
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 30) &&
            (dmem[96] == 8'd12) &&
            (dut.u_regfile.regs[1] == 32'd5)) begin
            if (pair_fold_count == 0) begin
                $fatal(1, "FAIL: ID ALU pair fold never fired; cycles=%0d", cycle);
            end
            $display(
                "PASS: ID ALU pair fold diagnostic cycles=%0d pair_folds=%0d x1=%0d x10=%0d x11=%0d x12=%0d",
                cycle,
                pair_fold_count,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[10],
                dut.u_regfile.regs[11],
                dut.u_regfile.regs[12]);
            $finish;
        end

        if (cycle > 260) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d x1=%0d x10=%0d x11=%0d x12=%0d pair_folds=%0d dmem96=%02x",
                debug_pc,
                cycle,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[10],
                dut.u_regfile.regs[11],
                dut.u_regfile.regs[12],
                pair_fold_count,
                dmem[96]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    pair_fold_count = 0;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end
    for (idx = 0; idx < 256; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    imem[0] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd1, 7'b0010011);   // addi x1,x0,0
    imem[1] = rv32_i(12'sd5, 5'd0, 3'b000, 5'd3, 7'b0010011);   // addi x3,x0,5
    imem[2] = rv32_i(12'sd96, 5'd0, 3'b000, 5'd4, 7'b0010011);  // addi x4,x0,96
    imem[3] = rv32_i(12'sd5, 5'd0, 3'b000, 5'd10, 7'b0010011);  // addi x10,x0,5
    imem[4] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd11, 7'b0010011);  // addi x11,x0,7
    imem[5] = rv32_r(7'b0000000, 5'd11, 5'd10, 3'b000, 5'd12, 7'b0110011); // add x12,x10,x11
    imem[6] = rv32_i(12'sd1, 5'd1, 3'b000, 5'd1, 7'b0010011);   // addi x1,x1,1
    imem[7] = rv32_b(-13'sd16, 5'd3, 5'd1, 3'b100, 7'b1100011); // blt x1,x3,loop
    imem[8] = rv32_s(12'sd0, 5'd12, 5'd4, 3'b010, 7'b0100011);  // sw x12,0(x4)
    imem[9] = rv32_j(21'sd0, 5'd0, 7'b1101111);                 // park

    #20;
    rst_n = 1'b1;
end

endmodule
