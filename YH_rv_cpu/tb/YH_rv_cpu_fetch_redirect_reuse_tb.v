`timescale 1ns / 1ps

module YH_rv_cpu_fetch_redirect_reuse_tb;

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

reg [31:0] imem [0:63];
reg [7:0]  dmem [0:255];
integer cycle;
integer idx;
integer timeout_cycles;
integer stall_cycles;
integer redirect_count;
integer reuse_count;
integer pipe_hit_count;
integer overlap_count;
reg     debug_trace;
reg     require_pipe_hit;
reg     stall_seen;
reg     redirect_seen;
reg     reuse_seen;
reg     pipe_hit_seen;
reg     overlap_seen;

wire fetch_reuse_hit;
wire fetch_buffer_hit;
wire fetch_response_overlap;

assign fetch_buffer_hit = dut.fetch_redirect_buf0_hit || dut.fetch_redirect_buf1_hit;
assign fetch_reuse_hit = dut.fetch_redirect_reuse_valid;
assign fetch_response_overlap =
    dut.ex_fetch_redirect_valid &&
    imem_rvalid &&
    (dut.fetch_rsp_pc == dut.fetch_reuse_redirect_pc);

assign imem_rdata = imem_rdata_r;
assign imem_rvalid = imem_rvalid_r;
assign dmem_rdata = dmem_rdata_r;
assign dmem_rvalid = dmem_rvalid_r;

YH_rv_cpu #(
    .IMEM_SYNC(1),
    .IMEM_OUTPUT_REG(0),
    .DMEM_SYNC(1),
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

        if (dmem_wstrb[0]) dmem[word_index + 0] <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) dmem[word_index + 1] <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) dmem[word_index + 2] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) dmem[word_index + 3] <= dmem_wdata[31:24];
    end
end

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dut.ex_fetch_redirect_valid) begin
            redirect_seen <= 1'b1;
            redirect_count <= redirect_count + 1;
        end

        if (dut.stall_decode) begin
            stall_seen <= 1'b1;
            stall_cycles <= stall_cycles + 1;
        end

        if (fetch_buffer_hit) begin
            reuse_seen <= 1'b1;
            reuse_count <= reuse_count + 1;
        end

        if (dut.fetch_redirect_pipe_hit) begin
            pipe_hit_seen <= 1'b1;
            pipe_hit_count <= pipe_hit_count + 1;
        end

        if (fetch_response_overlap) begin
            overlap_seen <= 1'b1;
            overlap_count <= overlap_count + 1;
        end

        if (debug_trace && (cycle < 120)) begin
            $display(
                "TRACE cycle=%0d pc=%h req=%0d rvalid=%0d rsp_pc=%h redir_pc=%h redirect=%0d reuse=%0d buf0_hit=%0d buf1_hit=%0d pipe_hit=%0d overlap=%0d buf0_v=%0d buf0_pc=%h buf1_v=%0d buf1_pc=%h fetch_q_v=%0d fetch_q_pc=%h if_id_v=%0d if_id_pc=%h if_id_insn=%h x5=%h",
                cycle,
                debug_pc,
                imem_req,
                imem_rvalid,
                dut.fetch_rsp_pc,
                dut.fetch_reuse_redirect_pc,
                dut.ex_fetch_redirect_valid,
                fetch_reuse_hit,
                dut.fetch_redirect_buf0_hit,
                dut.fetch_redirect_buf1_hit,
                dut.fetch_redirect_pipe_hit,
                fetch_response_overlap,
                dut.fetch_buf0_valid_r,
                dut.fetch_buf0_pc_r,
                dut.fetch_buf1_valid_r,
                dut.fetch_buf1_pc_r,
                dut.fetch_queue_valid,
                dut.fetch_queue_pc,
                dut.if_id_valid_r,
                dut.if_id_pc_r,
                dut.if_id_instruction_r,
                dut.u_regfile.regs[5]
            );
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 20) && overlap_seen) begin
            if (!stall_seen) begin
                $fatal(1, "FAIL: diagnostic never triggered stall_decode");
            end

            if (!redirect_seen) begin
                $fatal(1, "FAIL: diagnostic never triggered fetch redirect");
            end

            if (!overlap_seen) begin
                $fatal(1, "FAIL: diagnostic never observed redirect/response overlap");
            end

            if (require_pipe_hit && !pipe_hit_seen) begin
                $fatal(1, "FAIL: strict plusarg require_pipe_hit set but fetch_redirect_pipe_hit never asserted");
            end

            $display(
                "PASS: fetch redirect reuse diagnostic completed at PC=%h in %0d cycles (stall_cycles=%0d redirects=%0d reuse_hits=%0d pipe_hits=%0d overlaps=%0d require_pipe_hit=%0d)",
                debug_pc,
                cycle,
                stall_cycles,
                redirect_count,
                reuse_count,
                pipe_hit_count,
                overlap_count,
                require_pipe_hit
            );
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d stall_cycles=%0d redirects=%0d reuse_hits=%0d pipe_hits=%0d overlaps=%0d",
                debug_pc,
                cycle,
                stall_cycles,
                redirect_count,
                reuse_count,
                pipe_hit_count,
                overlap_count);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    timeout_cycles = 240;
    stall_cycles = 0;
    redirect_count = 0;
    reuse_count = 0;
    pipe_hit_count = 0;
    overlap_count = 0;
    stall_seen = 1'b0;
    redirect_seen = 1'b0;
    reuse_seen = 1'b0;
    pipe_hit_seen = 1'b0;
    overlap_seen = 1'b0;
    debug_trace = 1'b0;
    require_pipe_hit = 1'b0;

    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end

    if ($test$plusargs("require_pipe_hit")) begin
        require_pipe_hit = 1'b1;
    end

    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 240;
    end

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    for (idx = 0; idx < 256; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    // Mirror the prefetch-style shape: a load-use stall creates a fetch backlog,
    // then the redirect overlaps a synchronous fetch response. This is the
    // baseline green path; strict mode can require future pipe-hit behavior.
    // lw x3, 0(x0)
    imem[0]  = rv32_i(12'sd0, 5'd0, 3'b000, 5'd1, 7'b0010011);
    // addi x2, x0, 6
    imem[1]  = rv32_i(12'sd6, 5'd0, 3'b000, 5'd2, 7'b0010011);
    // lw x3, 0(x1)
    imem[2]  = rv32_i(12'sd0, 5'd1, 3'b010, 5'd3, 7'b0000011);
    // beq x3, x0, +8
    imem[3]  = rv32_b(13'sd8, 5'd0, 5'd3, 3'b000, 7'b1100011);
    // jal x0, +8
    imem[4]  = rv32_j(21'sd8, 5'd0, 7'b1101111);
    // addi x4, x4, 1
    imem[5]  = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011);
    // addi x2, x2, -1
    imem[6]  = rv32_i(-12'sd1, 5'd2, 3'b000, 5'd2, 7'b0010011);
    // bne x2, x0, -20
    imem[7]  = rv32_b(-13'sd20, 5'd0, 5'd2, 3'b001, 7'b1100011);
    // addi x5, x0, 42
    imem[8]  = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011);
    // jal x0, 0
    imem[9]  = rv32_j(21'sd0, 5'd0, 7'b1101111);

    dmem[0] = 8'h01;

    #20;
    rst_n = 1'b1;
end

endmodule
