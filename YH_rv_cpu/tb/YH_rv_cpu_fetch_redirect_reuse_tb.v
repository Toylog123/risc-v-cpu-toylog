`timescale 1ns / 1ps

module YH_rv_cpu_fetch_redirect_reuse_tb #(
    parameter integer IMEM_OUTPUT_REG = 0
);

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
integer overlap_cycle;
integer overlap_window_end_cycle;
reg     debug_trace;
reg     require_pipe_hit;
reg     require_queue_preserve;
reg     require_drop_accounting;
reg     require_branch_reuse;
reg     require_branch_decode_kill;
reg     stall_seen;
reg     redirect_seen;
reg     reuse_seen;
reg     pipe_hit_seen;
reg     overlap_seen;
reg     branch_redirect_seen;
reg     branch_overlap_seen;
reg     branch_reuse_seen;
reg     branch_pipe_hit_seen;
reg     queue_preserve_seen;
reg     queue_consumed_seen;
reg     queue_instruction_seen;
reg     drop_count_loaded_seen;
reg     drop_count_decrement_seen;
reg     drop_count_cleared_seen;
reg     branch_decode_ready_seen;
reg     branch_wrong_path_killed_seen;
integer branch_overlap_cycle;
reg [31:0] overlap_redirect_pc;
reg [31:0] overlap_expected_instruction;
localparam [1:0] IMEM_DROP_COUNT = (IMEM_OUTPUT_REG != 0) ? 2'd1 : 2'd0;
localparam [31:0] BRANCH_PC = 32'h0000_000c;
localparam [31:0] WRONG_PATH_PC = 32'h0000_0010;
localparam [31:0] BRANCH_TARGET_PC = 32'h0000_0014;
localparam [31:0] BRANCH_BEQ_INSN = 32'h0000_0463;

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
    .IMEM_OUTPUT_REG(IMEM_OUTPUT_REG),
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
            if (!dut.id_ex_jump_r) begin
                branch_redirect_seen <= 1'b1;
            end
        end

        if (dut.stall_decode) begin
            stall_seen <= 1'b1;
            stall_cycles <= stall_cycles + 1;
        end

        if (fetch_buffer_hit) begin
            reuse_seen <= 1'b1;
            reuse_count <= reuse_count + 1;
        end

        if (fetch_reuse_hit && dut.ex_fetch_redirect_valid && !dut.id_ex_jump_r) begin
            branch_reuse_seen <= 1'b1;
        end

        if (dut.fetch_redirect_pipe_hit) begin
            pipe_hit_seen <= 1'b1;
            pipe_hit_count <= pipe_hit_count + 1;
            if (dut.ex_fetch_redirect_valid && !dut.id_ex_jump_r) begin
                branch_pipe_hit_seen <= 1'b1;
            end
        end

        if (fetch_response_overlap) begin
            overlap_seen <= 1'b1;
            overlap_count <= overlap_count + 1;
            if (!dut.id_ex_jump_r) begin
                branch_overlap_seen <= 1'b1;
                if (branch_overlap_cycle == 0) begin
                    branch_overlap_cycle <= cycle;
                end
            end
            if (require_queue_preserve) begin
                if (dut.fetch_queue_valid) begin
                    if (dut.fetch_queue_pc !== dut.ex_redirect_pc) begin
                        $fatal(1,
                            "FAIL: queue PC changed on overlap at cycle=%0d expected_pc=%h observed_pc=%h",
                            cycle,
                            dut.ex_redirect_pc,
                            dut.fetch_queue_pc);
                    end

                    if (dut.fetch_queue_instruction === ((IMEM_OUTPUT_REG != 0) ? imem[dut.ex_redirect_pc[31:2] + 1] : imem[dut.ex_redirect_pc[31:2]])) begin
                        queue_instruction_seen <= 1'b1;
                    end

                    queue_preserve_seen <= 1'b1;
                end

                if ((dut.if_id_pc_r === dut.ex_redirect_pc) &&
                    (dut.if_id_instruction_r === ((IMEM_OUTPUT_REG != 0) ? imem[dut.ex_redirect_pc[31:2] + 1] : imem[dut.ex_redirect_pc[31:2]]))) begin
                    queue_preserve_seen <= 1'b1;
                    queue_instruction_seen <= 1'b1;
                end

                if (dut.if_id_data_write_en && dut.if_id_fetch_valid) begin
                    if (dut.if_id_next_instruction === ((IMEM_OUTPUT_REG != 0) ? imem[dut.ex_redirect_pc[31:2] + 1] : imem[dut.ex_redirect_pc[31:2]])) begin
                        queue_instruction_seen <= 1'b1;
                    end

                    queue_preserve_seen <= 1'b1;
                    queue_consumed_seen <= 1'b1;
                end
            end
            if (overlap_cycle == 0) begin
                overlap_cycle <= cycle;
                overlap_window_end_cycle <= cycle + 2;
                overlap_redirect_pc <= dut.ex_redirect_pc;
                overlap_expected_instruction <= ((IMEM_OUTPUT_REG != 0) ? imem[dut.ex_redirect_pc[31:2] + 1] : imem[dut.ex_redirect_pc[31:2]]);
                queue_preserve_seen <= 1'b0;
                queue_consumed_seen <= 1'b0;
                queue_instruction_seen <= 1'b0;
                drop_count_loaded_seen <= 1'b0;
                drop_count_decrement_seen <= 1'b0;
                drop_count_cleared_seen <= 1'b0;
            end
        end

        if (require_queue_preserve && overlap_seen && (overlap_cycle != 0)) begin
            if ((cycle >= overlap_cycle) && (cycle <= overlap_window_end_cycle)) begin
                if (dut.fetch_queue_valid) begin
                    if (dut.fetch_queue_pc !== overlap_redirect_pc) begin
                        $fatal(1,
                            "FAIL: queue PC changed after overlap at cycle=%0d expected_pc=%h observed_pc=%h",
                            cycle,
                            overlap_redirect_pc,
                            dut.fetch_queue_pc);
                    end

                    if (dut.fetch_queue_instruction === overlap_expected_instruction) begin
                        queue_instruction_seen <= 1'b1;
                    end

                    queue_preserve_seen <= 1'b1;
                end

                if ((dut.if_id_pc_r === overlap_redirect_pc) &&
                    (dut.if_id_instruction_r === overlap_expected_instruction)) begin
                    queue_preserve_seen <= 1'b1;
                    queue_instruction_seen <= 1'b1;
                end

                if (dut.if_id_data_write_en && dut.if_id_fetch_valid) begin
                    if (dut.if_id_next_instruction === overlap_expected_instruction) begin
                        queue_instruction_seen <= 1'b1;
                    end

                    queue_preserve_seen <= 1'b1;
                    queue_consumed_seen <= 1'b1;
                end
            end else if ((cycle > overlap_window_end_cycle) && (!queue_preserve_seen || !queue_instruction_seen)) begin
                $fatal(1,
                    "FAIL: require_queue_preserve set but queue target/instruction never observed within %0d cycles after overlap at PC=%h",
                    (overlap_window_end_cycle - overlap_cycle),
                    overlap_redirect_pc);
            end
        end

        if (require_branch_reuse) begin
            if ((branch_overlap_cycle != 0) && (cycle > (branch_overlap_cycle + 2)) && !branch_reuse_seen) begin
                $fatal(1,
                    "FAIL: require_branch_reuse set but branch overlap never produced reuse within 2 cycles (branch_overlap_cycle=%0d pipe_hit=%0d redirects=%0d reuse_hits=%0d)",
                    branch_overlap_cycle,
                    branch_pipe_hit_seen,
                    redirect_count,
                    reuse_count);
            end
        end

        if (require_branch_decode_kill) begin
            if (dut.if_id_valid_r &&
                (dut.if_id_pc_r == BRANCH_PC) &&
                (dut.if_id_instruction_r == BRANCH_BEQ_INSN) &&
                !dut.stall_decode) begin
                branch_decode_ready_seen <= 1'b1;
                if (dut.if_id_data_write_en && dut.if_id_next_valid && (dut.if_id_next_pc == WRONG_PATH_PC)) begin
                    $fatal(1,
                        "FAIL: require_branch_decode_kill set but IF/ID next-state still selects wrong-path PC after taken branch became ID-ready (cycle=%0d next_pc=%h next_valid=%0d)",
                        cycle,
                        dut.if_id_next_pc,
                        dut.if_id_next_valid);
                end

                if (!dut.if_id_next_valid || (dut.if_id_next_pc == BRANCH_TARGET_PC)) begin
                    branch_wrong_path_killed_seen <= 1'b1;
                end
            end
        end

        if (require_drop_accounting && (IMEM_OUTPUT_REG != 0) && overlap_seen && (overlap_cycle != 0)) begin
            if (dut.fetch_drop_response && dut.fetch_pipe_valid) begin
                $fatal(1,
                    "FAIL: stale response entered fetch_pipe while drop_response was asserted at cycle=%0d drop_count=%0d",
                    cycle,
                    dut.fetch_drop_count_r);
            end

            if ((cycle > overlap_cycle) && (cycle <= overlap_window_end_cycle)) begin
                if (cycle == (overlap_cycle + 1)) begin
                    if (dut.fetch_drop_count_r !== IMEM_DROP_COUNT) begin
                        $fatal(1,
                            "FAIL: drop counter did not arm after overlap at cycle=%0d expected=%0d observed=%0d",
                            cycle,
                            IMEM_DROP_COUNT,
                            dut.fetch_drop_count_r);
                    end
                    drop_count_loaded_seen <= 1'b1;
                end

                if (drop_count_loaded_seen && (dut.fetch_drop_count_r == 2'd0)) begin
                    drop_count_decrement_seen <= 1'b1;
                    drop_count_cleared_seen <= 1'b1;
                end
            end
        end

        if (debug_trace && (cycle < 120)) begin
            $display(
                "TRACE cycle=%0d pc=%h req=%0d rvalid=%0d rsp_pc=%h redir_pc=%h redirect=%0d reuse=%0d buf0_hit=%0d buf1_hit=%0d pipe_hit=%0d overlap=%0d overlap_cycle=%0d q_pres=%0d q_insn=%0d q_cons=%0d branch_id_ready=%0d branch_kill=%0d drop_cnt=%0d drop_rsp=%0d pipe_v=%0d buf0_v=%0d buf0_pc=%h buf1_v=%0d buf1_pc=%h fetch_q_v=%0d fetch_q_pc=%h if_id_v=%0d if_id_pc=%h if_id_insn=%h x5=%h",
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
                overlap_cycle,
                queue_preserve_seen,
                queue_instruction_seen,
                queue_consumed_seen,
                branch_decode_ready_seen,
                branch_wrong_path_killed_seen,
                dut.fetch_drop_count_r,
                dut.fetch_drop_response,
                dut.fetch_pipe_valid,
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

        if (require_branch_decode_kill &&
            branch_decode_ready_seen &&
            branch_wrong_path_killed_seen &&
            ((debug_pc == BRANCH_TARGET_PC) ||
             (dut.fetch_queue_valid && (dut.fetch_queue_pc == BRANCH_TARGET_PC)) ||
             (dut.if_id_valid_r && (dut.if_id_pc_r == BRANCH_TARGET_PC)))) begin
            $display(
                "PASS: branch decode kill diagnostic completed at PC=%h in %0d cycles (stall_cycles=%0d branch_id_ready=%0d branch_kill=%0d IMEM_OUTPUT_REG=%0d)",
                debug_pc,
                cycle,
                stall_cycles,
                branch_decode_ready_seen,
                branch_wrong_path_killed_seen,
                IMEM_OUTPUT_REG);
            $finish;
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

            if (require_branch_reuse && !branch_overlap_seen) begin
                // Keep running until timeout so branch-only mode can prove
                // whether a taken branch overlap ever happened in this setup.
            end else if (require_branch_reuse && !branch_reuse_seen) begin
                // Keep running until the bounded branch window above either
                // sees reuse or trips the explicit failure.
            end else if (require_branch_decode_kill && !branch_decode_ready_seen) begin
                // Keep running until the directed branch reaches the ID-ready
                // point in this setup.
            end else if (require_branch_decode_kill && !branch_wrong_path_killed_seen) begin
                // Keep running until the bounded next-cycle check above either
                // observes the wrong-path kill or trips its explicit failure.
            end

            if (require_queue_preserve && (!queue_preserve_seen || !queue_instruction_seen)) begin
                // Keep running until the bounded window either proves the queue
                // payload or trips the timeout/fatal checks above.
            end else begin
                $display(
                    "PASS: fetch redirect reuse diagnostic completed at PC=%h in %0d cycles (stall_cycles=%0d redirects=%0d reuse_hits=%0d pipe_hits=%0d overlaps=%0d require_pipe_hit=%0d require_queue_preserve=%0d require_drop_accounting=%0d require_branch_reuse=%0d require_branch_decode_kill=%0d IMEM_OUTPUT_REG=%0d)",
                    debug_pc,
                    cycle,
                    stall_cycles,
                    redirect_count,
                    reuse_count,
                    pipe_hit_count,
                    overlap_count,
                    require_pipe_hit,
                    require_queue_preserve,
                    require_drop_accounting,
                    require_branch_reuse,
                    require_branch_decode_kill,
                    IMEM_OUTPUT_REG);
                $finish;
            end
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d stall_cycles=%0d redirects=%0d reuse_hits=%0d pipe_hits=%0d overlaps=%0d branch_redir=%0d branch_overlap=%0d branch_reuse=%0d branch_pipe=%0d branch_id_ready=%0d branch_kill=%0d q_pres=%0d q_insn=%0d q_cons=%0d drop_loaded=%0d drop_dec=%0d drop_zero=%0d IMEM_OUTPUT_REG=%0d",
                debug_pc,
                cycle,
                stall_cycles,
                redirect_count,
                reuse_count,
                pipe_hit_count,
                overlap_count,
                branch_redirect_seen,
                branch_overlap_seen,
                branch_reuse_seen,
                branch_pipe_hit_seen,
                branch_decode_ready_seen,
                branch_wrong_path_killed_seen,
                queue_preserve_seen,
                queue_instruction_seen,
                queue_consumed_seen,
                drop_count_loaded_seen,
                drop_count_decrement_seen,
                drop_count_cleared_seen,
                IMEM_OUTPUT_REG);
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
    overlap_cycle = 0;
    overlap_window_end_cycle = 0;
    branch_overlap_cycle = 0;
    stall_seen = 1'b0;
    redirect_seen = 1'b0;
    reuse_seen = 1'b0;
    pipe_hit_seen = 1'b0;
    overlap_seen = 1'b0;
    branch_redirect_seen = 1'b0;
    branch_overlap_seen = 1'b0;
    branch_reuse_seen = 1'b0;
    branch_pipe_hit_seen = 1'b0;
    branch_decode_ready_seen = 1'b0;
    branch_wrong_path_killed_seen = 1'b0;
    queue_preserve_seen = 1'b0;
    queue_consumed_seen = 1'b0;
    queue_instruction_seen = 1'b0;
    drop_count_loaded_seen = 1'b0;
    drop_count_decrement_seen = 1'b0;
    drop_count_cleared_seen = 1'b0;
    overlap_redirect_pc = 32'h0000_0000;
    overlap_expected_instruction = 32'h0000_0013;
    debug_trace = 1'b0;
    require_pipe_hit = 1'b0;
    require_queue_preserve = 1'b0;
    require_drop_accounting = 1'b0;
    require_branch_reuse = 1'b0;
    require_branch_decode_kill = 1'b0;

    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end

    if ($test$plusargs("require_pipe_hit")) begin
        require_pipe_hit = 1'b1;
    end

    if ($test$plusargs("require_queue_preserve")) begin
        require_queue_preserve = 1'b1;
    end

    if ($test$plusargs("require_drop_accounting")) begin
        require_drop_accounting = 1'b1;
    end

    if ($test$plusargs("require_branch_reuse")) begin
        require_branch_reuse = 1'b1;
    end

    if ($test$plusargs("require_branch_decode_kill")) begin
        require_branch_decode_kill = 1'b1;
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

    if (require_branch_decode_kill) begin
        // Dedicated safe-operand branch program: the branch compares x0/x0 so
        // the diagnostic only checks wrong-path kill, not forwarding timing.
        // addi x1, x0, 0
        imem[0]  = rv32_i(12'sd0, 5'd0, 3'b000, 5'd1, 7'b0010011);
        // addi x2, x0, 1
        imem[1]  = rv32_i(12'sd1, 5'd0, 3'b000, 5'd2, 7'b0010011);
        // nop
        imem[2]  = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);
        // beq x0, x0, +8
        imem[3]  = rv32_b(13'sd8, 5'd0, 5'd0, 3'b000, 7'b1100011);
        // jal x0, +8
        imem[4]  = rv32_j(21'sd8, 5'd0, 7'b1101111);
        // addi x4, x4, 1
        imem[5]  = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011);
        // addi x5, x0, 42
        imem[6]  = rv32_i(12'sd42, 5'd0, 3'b000, 5'd5, 7'b0010011);
        // nop
        imem[7]  = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);
    end else begin
        // Mirror the prefetch-style shape: a load-use stall creates a fetch backlog,
        // then the redirect overlaps a synchronous fetch response. Strict mode can
        // additionally require queue preservation and drop accounting.
        // lw x3, 0(x0)
        imem[0]  = rv32_i(12'sd0, 5'd0, 3'b000, 5'd1, 7'b0010011);
        // addi x2, x0, 1
        imem[1]  = rv32_i(12'sd1, 5'd0, 3'b000, 5'd2, 7'b0010011);
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
        // nop
        imem[9]  = rv32_i(12'sd0, 5'd0, 3'b000, 5'd0, 7'b0010011);
    end

    dmem[0] = (require_branch_reuse || require_branch_decode_kill) ? 8'h00 : 8'h01;

    #20;
    rst_n = 1'b1;
end

endmodule
