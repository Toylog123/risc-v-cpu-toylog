`timescale 1ns / 1ps

module YH_rv_cpu_branch_load_ready_redirect_tb;

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
reg  [31:0] dmem_rdata_r;
wire        dmem_rvalid;
reg         dmem_rvalid_r;
wire        dmem_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:31];
reg [7:0]  dmem [0:255];
integer cycle;
integer idx;
integer timeout_cycles;
integer id_branch_redirect_cycles;
integer ex_branch_redirect_cycles;
reg     require_id_branch_load_ready_redirect;

assign imem_rdata = imem_rdata_r;
assign imem_rvalid = imem_rvalid_r;
assign dmem_rdata = dmem_rdata_r;
assign dmem_rvalid = dmem_rvalid_r;

YH_rv_cpu #(
    .IMEM_SYNC(1),
    .IMEM_OUTPUT_REG(0),
    .DMEM_SYNC(1),
    .ENABLE_ID_BRANCH_EX_FORWARD(1),
    .RESET_VECTOR(32'h0000_0000)
) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
    .imem_req  (imem_req),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_read_req(dmem_read_req),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
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
    integer word_index;
    if (!rst_n) begin
        imem_rvalid_r <= 1'b0;
        imem_rdata_r <= 32'h0000_0013;
        dmem_rvalid_r <= 1'b0;
        dmem_rdata_r <= 32'h0000_0000;
    end else begin
        imem_rvalid_r <= imem_req;
        imem_rdata_r <= imem[imem_addr[31:2]];

        dmem_rvalid_r <= dmem_read_req;
        word_index = {dmem_addr[31:2], 2'b00};
        dmem_rdata_r <= {
            dmem[word_index + 3],
            dmem[word_index + 2],
            dmem[word_index + 1],
            dmem[word_index + 0]
        };
    end
end

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dut.id_branch_decode_redirect_valid) begin
            id_branch_redirect_cycles <= id_branch_redirect_cycles + 1;
        end
        if (dut.ex_redirect_valid) begin
            ex_branch_redirect_cycles <= ex_branch_redirect_cycles + 1;
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 14) &&
            (dut.u_regfile.regs[2] == 32'd42) &&
            (dut.u_regfile.regs[3] == 32'd42) &&
            (dut.u_regfile.regs[5] == 32'd2)) begin
            if (require_id_branch_load_ready_redirect && (id_branch_redirect_cycles == 0)) begin
                $fatal(1,
                    "FAIL: load-ready BEQ did not redirect in ID stage; ex_branch_redirect_cycles=%0d",
                    ex_branch_redirect_cycles);
            end

            $display(
                "PASS: branch load-ready redirect diagnostic completed at PC=%h cycles=%0d id_branch_redirect_cycles=%0d ex_branch_redirect_cycles=%0d require_id_branch_load_ready_redirect=%0d",
                debug_pc,
                cycle,
                id_branch_redirect_cycles,
                ex_branch_redirect_cycles,
                require_id_branch_load_ready_redirect);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d x2=%h x3=%h x4=%h x5=%h id_redirect=%0d ex_redirect=%0d",
                debug_pc,
                cycle,
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[4],
                dut.u_regfile.regs[5],
                id_branch_redirect_cycles,
                ex_branch_redirect_cycles);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    timeout_cycles = 160;
    id_branch_redirect_cycles = 0;
    ex_branch_redirect_cycles = 0;
    require_id_branch_load_ready_redirect = 1'b0;

    if ($test$plusargs("require_id_branch_load_ready_redirect")) begin
        require_id_branch_load_ready_redirect = 1'b1;
    end
    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 160;
    end

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end
    for (idx = 0; idx < 256; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    imem[0] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd1, 7'b0010011);  // addi x1, x0, 0
    imem[1] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd3, 7'b0010011); // addi x3, x0, 42
    imem[2] = rv32_i(12'sd0, 5'd1, 3'b010, 5'd2, 7'b0000011);  // lw x2, 0(x1)
    imem[3] = rv32_b(13'sd8, 5'd3, 5'd2, 3'b000, 7'b1100011);  // beq x2, x3, target
    imem[4] = rv32_i(12'sd1, 5'd0, 3'b000, 5'd4, 7'b0010011);  // skipped if redirect works
    imem[5] = rv32_i(12'sd2, 5'd0, 3'b000, 5'd5, 7'b0010011);  // target
    imem[6] = rv32_j(21'sd0, 5'd0, 7'b1101111); // park

    dmem[0] = 8'h2a;
    dmem[1] = 8'h00;
    dmem[2] = 8'h00;
    dmem[3] = 8'h00;

    #20;
    rst_n = 1'b1;
end

endmodule
