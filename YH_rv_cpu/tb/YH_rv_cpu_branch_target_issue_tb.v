`timescale 1ns / 1ps

module YH_rv_cpu_branch_target_issue_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
reg  [31:0] imem_rdata_r;
wire        imem_rvalid;
reg         imem_rvalid_r;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire        dmem_we;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
integer idx;
integer cycle;
integer fold_seen;
reg [31:0] fold_target_pc_at_edge;

assign imem_rdata = imem_rdata_r;
assign imem_rvalid = imem_rvalid_r;
assign dmem_rdata = 32'h0000_0000;
assign dmem_rvalid = dmem_read_req;

YH_rv_cpu #(
    .IMEM_SYNC(1),
    .IMEM_OUTPUT_REG(0),
    .DMEM_SYNC(1),
    .LOAD_USE_FAST_FORWARD(1),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_ZICOND_EXTENSION(1),
    .ENABLE_XTHEAD_EXTENSION(1),
    .ENABLE_XTHEAD_COND_MOVE(1),
    .ENABLE_ID_BRANCH_EX_FORWARD(1),
    .ENABLE_ID_BRANCH_FOLD(1),
    .REDIRECT_CACHE_ENTRIES(64),
    .REDIRECT_CACHE_XOR_INDEX(1),
    .RESET_VECTOR(32'h0000_0000)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .timer_irq    (1'b0),
    .imem_req     (imem_req),
    .imem_addr    (imem_addr),
    .imem_rdata   (imem_rdata),
    .imem_rvalid  (imem_rvalid),
    .dmem_addr    (dmem_addr),
    .dmem_rdata   (dmem_rdata),
    .dmem_rvalid  (dmem_rvalid),
    .dmem_ready   (1'b1),
    .dmem_read_req(dmem_read_req),
    .dmem_we      (dmem_we),
    .dmem_wdata   (dmem_wdata),
    .dmem_wstrb   (dmem_wstrb),
    .trap         (trap),
    .debug_pc     (debug_pc)
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

        if (dut.id_branch_fold_valid) begin
            fold_seen <= fold_seen + 1;
            fold_target_pc_at_edge = dut.fetch_control_redirect_pc;
            #1;
            if (!dut.id_ex_valid_r || (dut.id_ex_pc_r !== fold_target_pc_at_edge)) begin
                $fatal(1,
                    "FAIL: branch target issue missing cycle=%0d target_pc=%h id_ex_valid=%0d id_ex_pc=%h",
                    cycle,
                    fold_target_pc_at_edge,
                    dut.id_ex_valid_r,
                    dut.id_ex_pc_r);
            end
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 24) && (dut.u_regfile.regs[5] == 32'd42)) begin
            if (fold_seen == 0) begin
                $fatal(1, "FAIL: branch target issue was never exercised");
            end
            $display(
                "PASS: branch target issue diagnostic completed at PC=%h cycles=%0d folds=%0d x2=%0d",
                debug_pc,
                cycle,
                fold_seen,
                dut.u_regfile.regs[2]);
            $finish;
        end

        if (cycle > 120) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d folds=%0d x1=%0d x2=%0d x5=%0d",
                debug_pc,
                cycle,
                fold_seen,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[5]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    fold_seen = 0;
    fold_target_pc_at_edge = 32'h0000_0000;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    imem[0] = rv32_i(12'sd4, 5'd0, 3'b000, 5'd1, 7'b0010011);  // addi x1, x0, 4
    imem[1] = rv32_i(12'sd1, 5'd2, 3'b000, 5'd2, 7'b0010011);  // loop: addi x2, x2, 1
    imem[2] = rv32_i(-12'sd1, 5'd1, 3'b000, 5'd1, 7'b0010011); // addi x1, x1, -1
    imem[3] = rv32_b(-13'sd8, 5'd0, 5'd1, 3'b001, 7'b1100011); // bne x1, x0, loop
    imem[4] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011); // addi x5, x0, 42
    imem[5] = rv32_j(21'sd0, 5'd0, 7'b1101111);                // park

    #20;
    rst_n = 1'b1;
end

endmodule
