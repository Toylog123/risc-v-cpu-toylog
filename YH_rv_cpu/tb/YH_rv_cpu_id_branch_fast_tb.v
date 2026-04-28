`timescale 1ns / 1ps

module YH_rv_cpu_id_branch_fast_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:31];
integer cycle;
integer idx;
integer ex_bne_redirects;
integer ex_bltu_redirects;
integer ex_jalr_redirects;
integer timeout_cycles;
reg     require_no_ex_bne_redirect;
reg     require_no_ex_bltu_redirect;
reg     require_no_ex_jalr_redirect;
reg     debug_trace;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = 32'h0000_0000;
assign dmem_rvalid = 1'b1;

YH_rv_cpu #(
    .IMEM_SYNC(0),
    .DMEM_SYNC(0),
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

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dut.ex_redirect_valid && dut.id_ex_branch_r && (dut.id_ex_branch_funct3_r == 3'b110)) begin
            ex_bltu_redirects <= ex_bltu_redirects + 1;
        end
        if (dut.ex_redirect_valid && dut.id_ex_branch_r && (dut.id_ex_branch_funct3_r == 3'b001)) begin
            ex_bne_redirects <= ex_bne_redirects + 1;
        end
        if (dut.ex_redirect_valid && dut.id_ex_jump_r && dut.id_ex_jalr_r) begin
            ex_jalr_redirects <= ex_jalr_redirects + 1;
        end

        if (debug_trace && (cycle < 50)) begin
            $display(
                "TRACE cycle=%0d pc=%h if_id_v=%0d if_id_pc=%h id_ex_v=%0d id_ex_pc=%h id_ex_branch=%0d f3=%0d id_ex_jump=%0d id_ex_jalr=%0d ex_redirect=%0d redir_pc=%h x1=%h x2=%h x3=%h x4=%h x5=%h x6=%h x7=%h",
                cycle,
                debug_pc,
                dut.if_id_valid_r,
                dut.if_id_pc_r,
                dut.id_ex_valid_r,
                dut.id_ex_pc_r,
                dut.id_ex_branch_r,
                dut.id_ex_branch_funct3_r,
                dut.id_ex_jump_r,
                dut.id_ex_jalr_r,
                dut.ex_redirect_valid,
                dut.ex_redirect_pc,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[4],
                dut.u_regfile.regs[5],
                dut.u_regfile.regs[6],
                dut.u_regfile.regs[7]
            );
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 10) &&
            (dut.u_regfile.regs[1] == 32'd1) &&
            (dut.u_regfile.regs[2] == 32'd2) &&
            (dut.u_regfile.regs[3] == 32'd7) &&
            (dut.u_regfile.regs[4] == 32'd9) &&
            (dut.u_regfile.regs[5] == 32'd5) &&
            (dut.u_regfile.regs[6] == 32'd56) &&
            (dut.u_regfile.regs[7] == 32'd11)) begin
            if (require_no_ex_bne_redirect && (ex_bne_redirects != 0)) begin
                $fatal(1,
                    "FAIL: require_no_ex_bne_redirect set but observed ex_bne_redirects=%0d",
                    ex_bne_redirects);
            end
            if (require_no_ex_bltu_redirect && (ex_bltu_redirects != 0)) begin
                $fatal(1,
                    "FAIL: require_no_ex_bltu_redirect set but observed ex_bltu_redirects=%0d",
                    ex_bltu_redirects);
            end
            if (require_no_ex_jalr_redirect && (ex_jalr_redirects != 0)) begin
                $fatal(1,
                    "FAIL: require_no_ex_jalr_redirect set but observed ex_jalr_redirects=%0d",
                    ex_jalr_redirects);
            end

            $display(
                "PASS: id branch fast diagnostic completed at PC=%h cycles=%0d ex_bne_redirects=%0d ex_bltu_redirects=%0d ex_jalr_redirects=%0d require_no_ex_bne_redirect=%0d require_no_ex_bltu_redirect=%0d require_no_ex_jalr_redirect=%0d",
                debug_pc,
                cycle,
                ex_bne_redirects,
                ex_bltu_redirects,
                ex_jalr_redirects,
                require_no_ex_bne_redirect,
                require_no_ex_bltu_redirect,
                require_no_ex_jalr_redirect);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d ex_bne_redirects=%0d ex_bltu_redirects=%0d ex_jalr_redirects=%0d x1=%h x2=%h x3=%h x4=%h x5=%h x6=%h x7=%h",
                debug_pc,
                cycle,
                ex_bne_redirects,
                ex_bltu_redirects,
                ex_jalr_redirects,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[4],
                dut.u_regfile.regs[5],
                dut.u_regfile.regs[6],
                dut.u_regfile.regs[7]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    ex_bne_redirects = 0;
    ex_bltu_redirects = 0;
    ex_jalr_redirects = 0;
    timeout_cycles = 100;
    require_no_ex_bne_redirect = 1'b0;
    require_no_ex_bltu_redirect = 1'b0;
    require_no_ex_jalr_redirect = 1'b0;
    debug_trace = 1'b0;

    if ($test$plusargs("require_no_ex_bne_redirect")) begin
        require_no_ex_bne_redirect = 1'b1;
    end
    if ($test$plusargs("require_no_ex_bltu_redirect")) begin
        require_no_ex_bltu_redirect = 1'b1;
    end
    if ($test$plusargs("require_no_ex_jalr_redirect")) begin
        require_no_ex_jalr_redirect = 1'b1;
    end
    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end
    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 100;
    end

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    imem[0] = rv32_i(12'sd1, 5'd0, 3'b000, 5'd1, 7'b0010011);
    // bne depends on the immediately preceding addi result. It should be resolved in ID once operand forwarding is available.
    imem[1] = rv32_b(13'sd8, 5'd0, 5'd1, 3'b001, 7'b1100011);
    imem[2] = rv32_i(12'sd99, 5'd0, 3'b000, 5'd5, 7'b0010011);
    imem[3] = rv32_i(12'sd5, 5'd0, 3'b000, 5'd5, 7'b0010011);
    imem[4] = rv32_i(12'sd2, 5'd0, 3'b000, 5'd2, 7'b0010011);
    // Keep two independent instructions between producers and branch so operands are ready in ID.
    imem[5] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);
    imem[6] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);
    // bltu x1, x2, +8 skips the poison instruction.
    imem[7] = rv32_b(13'sd8, 5'd2, 5'd1, 3'b110, 7'b1100011);
    imem[8] = rv32_i(12'sd99, 5'd0, 3'b000, 5'd3, 7'b0010011);
    imem[9] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd3, 7'b0010011);
    imem[10] = rv32_i(12'sd9, 5'd0, 3'b000, 5'd4, 7'b0010011);
    imem[11] = rv32_i(12'sd56, 5'd0, 3'b000, 5'd6, 7'b0010011);
    // jalr x0 depends on the immediately preceding addi target and has no link writeback.
    imem[12] = rv32_i(12'sd0, 5'd6, 3'b000, 5'd0, 7'b1100111);
    imem[13] = rv32_i(12'sd99, 5'd0, 3'b000, 5'd7, 7'b0010011);
    imem[14] = rv32_i(12'sd11, 5'd0, 3'b000, 5'd7, 7'b0010011);
    imem[15] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);

    #20;
    rst_n = 1'b1;
end

endmodule
