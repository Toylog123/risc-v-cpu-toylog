`timescale 1ns / 1ps

module YH_rv_cpu_id_jal_fast_tb;

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
integer ex_jal_x0_redirects;
integer timeout_cycles;
reg     require_no_ex_jal_x0_redirect;
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

function [31:0] rv32_j;
    input signed [20:0] imm;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dut.ex_redirect_valid && dut.id_ex_jump_r && !dut.id_ex_jalr_r && (dut.id_ex_rd_addr_r == 5'd0)) begin
            ex_jal_x0_redirects <= ex_jal_x0_redirects + 1;
        end

        if (debug_trace && (cycle < 40)) begin
            $display(
                "TRACE cycle=%0d pc=%h if_id_v=%0d if_id_pc=%h id_ex_v=%0d id_ex_pc=%h id_ex_jump=%0d id_ex_rd=%0d ex_redirect=%0d redir_pc=%h x1=%h x2=%h x3=%h",
                cycle,
                debug_pc,
                dut.if_id_valid_r,
                dut.if_id_pc_r,
                dut.id_ex_valid_r,
                dut.id_ex_pc_r,
                dut.id_ex_jump_r,
                dut.id_ex_rd_addr_r,
                dut.ex_redirect_valid,
                dut.ex_redirect_pc,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[3]
            );
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 8) &&
            (dut.u_regfile.regs[1] == 32'd1) &&
            (dut.u_regfile.regs[2] == 32'd7) &&
            (dut.u_regfile.regs[3] == 32'd9)) begin
            if (require_no_ex_jal_x0_redirect && (ex_jal_x0_redirects != 0)) begin
                $fatal(1,
                    "FAIL: require_no_ex_jal_x0_redirect set but observed ex_jal_x0_redirects=%0d",
                    ex_jal_x0_redirects);
            end

            $display(
                "PASS: id jal fast diagnostic completed at PC=%h cycles=%0d ex_jal_x0_redirects=%0d require_no_ex_jal_x0_redirect=%0d",
                debug_pc,
                cycle,
                ex_jal_x0_redirects,
                require_no_ex_jal_x0_redirect);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d ex_jal_x0_redirects=%0d x1=%h x2=%h x3=%h",
                debug_pc,
                cycle,
                ex_jal_x0_redirects,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2],
                dut.u_regfile.regs[3]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    ex_jal_x0_redirects = 0;
    timeout_cycles = 80;
    require_no_ex_jal_x0_redirect = 1'b0;
    debug_trace = 1'b0;

    if ($test$plusargs("require_no_ex_jal_x0_redirect")) begin
        require_no_ex_jal_x0_redirect = 1'b1;
    end
    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end
    if ($test$plusargs("dump_vcd")) begin
        $dumpfile("YH_rv_cpu_id_jal_fast_tb.vcd");
        $dumpvars(0, YH_rv_cpu_id_jal_fast_tb);
    end
    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 80;
    end

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    // x1 = 1
    imem[0] = rv32_i(12'sd1, 5'd0, 3'b000, 5'd1, 7'b0010011);
    // jal x0, +8 skips the poison instruction without needing a link write.
    imem[1] = rv32_j(21'sd8, 5'd0, 7'b1101111);
    // poison: must be skipped
    imem[2] = rv32_i(12'sd99, 5'd0, 3'b000, 5'd1, 7'b0010011);
    // target
    imem[3] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd2, 7'b0010011);
    imem[4] = rv32_i(12'sd9, 5'd0, 3'b000, 5'd3, 7'b0010011);
    // park
    imem[5] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);

    #20;
    rst_n = 1'b1;
end

endmodule
