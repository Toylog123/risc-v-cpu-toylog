`timescale 1ns / 1ps

module YH_rv_cpu_coremark_tb #(
    parameter integer XLEN = 32,
    parameter string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex",
    parameter [31:0] RAM_BASE = 32'h0001_0000,
    parameter integer ROM_BYTES = 65536,
    parameter integer RAM_BYTES = 65536,
    parameter integer MAX_CYCLES = 1000000000,
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 0,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_MUL_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 0,
    parameter integer ENABLE_XTHEAD_ADDSL_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_MEMPAIR_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_BASE_UPDATE_EXTENSION = 1,
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1,
    parameter integer ENABLE_REDIRECT_TARGET_CACHE = 1,
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP = 1,
    parameter integer ENABLE_FETCH_REDIRECT_REUSE = 0,
    parameter integer REDIRECT_CACHE_ENTRIES = 1024,
    parameter integer REDIRECT_CACHE_XOR_INDEX = 0,
    parameter integer ENABLE_DYNAMIC_BRANCH_PREDICT = 0,
    parameter integer BRANCH_BHT_ENTRIES = 64,
    parameter integer BRANCH_STATIC_PREDICT_MODE = 0,
    parameter integer BRANCH_BHT_STRONG_ONLY = 0,
    parameter integer DMEM_NEGEDGE_READ = 0,
    parameter integer DMEM_READ_PREISSUE = 0
) ();

localparam integer VALID_MSG_LEN = 13;
localparam integer SCORE_MSG_LEN = 16;

reg                clk;
reg                rst_n;
wire               trap;
wire [XLEN-1:0]    debug_pc;
wire               uart_tx_valid;
wire [7:0]        uart_tx_data;
wire               done;
wire               timer_irq;

reg [7:0] valid_msg [0:VALID_MSG_LEN-1];
reg [7:0] score_msg [0:SCORE_MSG_LEN-1];
integer cycle;
integer uart_count;
integer max_cycles_runtime;
integer valid_match_idx;
integer score_match_idx;
reg     valid_found;
reg     score_found;
integer trace_cycles;
integer trace_stride;
integer trace_start;
integer trace_end;
integer plusarg_seen;
reg     debug_trace;
reg     profile_counts;
integer profile_stall_decode_cycles;
integer profile_mem_wait_cycles;
integer profile_if_id_valid_cycles;
integer profile_id_ex_valid_cycles;
integer profile_ex_mem_valid_cycles;
integer profile_mem_wb_valid_cycles;
integer profile_load_issues;
integer profile_store_issues;
integer profile_dmem_read_reqs;
integer profile_dmem_write_reqs;
integer profile_ex_redirects;
integer profile_id_redirects;
integer profile_jal_predicts;
integer profile_branch_predicts;

YH_rv_cpu_soc #(
    .XLEN(XLEN),
    .SYNC_DMEM(1),
    .DMEM_NEGEDGE_READ(DMEM_NEGEDGE_READ),
    .DMEM_READ_PREISSUE(DMEM_READ_PREISSUE),
    .RAM_BASE(RAM_BASE),
    .ROM_BYTES(ROM_BYTES),
    .RAM_BYTES(RAM_BYTES),
    .ROM_INIT_HEX(ROM_HEX),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION),
    .ENABLE_XTHEAD_MUL_EXTENSION(ENABLE_XTHEAD_MUL_EXTENSION),
    .ENABLE_XTHEAD_COND_MOVE(ENABLE_XTHEAD_COND_MOVE),
    .ENABLE_XTHEAD_ADDSL_EXTENSION(ENABLE_XTHEAD_ADDSL_EXTENSION),
    .ENABLE_XTHEAD_MEMPAIR_EXTENSION(ENABLE_XTHEAD_MEMPAIR_EXTENSION),
    .ENABLE_XTHEAD_BASE_UPDATE_EXTENSION(ENABLE_XTHEAD_BASE_UPDATE_EXTENSION),
    .ENABLE_ID_BRANCH_EX_FORWARD(ENABLE_ID_BRANCH_EX_FORWARD),
    .ENABLE_REDIRECT_TARGET_CACHE(ENABLE_REDIRECT_TARGET_CACHE),
    .ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP(ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP),
    .ENABLE_FETCH_REDIRECT_REUSE(ENABLE_FETCH_REDIRECT_REUSE),
    .REDIRECT_CACHE_ENTRIES(REDIRECT_CACHE_ENTRIES),
    .REDIRECT_CACHE_XOR_INDEX(REDIRECT_CACHE_XOR_INDEX),
    .ENABLE_DYNAMIC_BRANCH_PREDICT(ENABLE_DYNAMIC_BRANCH_PREDICT),
    .BRANCH_BHT_ENTRIES(BRANCH_BHT_ENTRIES),
    .BRANCH_STATIC_PREDICT_MODE(BRANCH_STATIC_PREDICT_MODE),
    .BRANCH_BHT_STRONG_ONLY(BRANCH_BHT_STRONG_ONLY)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .trap         (trap),
    .debug_pc     (debug_pc),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data (uart_tx_data),
    .done         (done),
    .timer_irq    (timer_irq)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (uart_tx_valid) begin
            uart_count <= uart_count + 1;
            $write("%c", uart_tx_data);

            if (!valid_found) begin
                if (uart_tx_data == valid_msg[valid_match_idx]) begin
                    valid_match_idx <= valid_match_idx + 1;
                    if (valid_match_idx + 1 == VALID_MSG_LEN) begin
                        valid_found <= 1'b1;
                    end
                end else if (uart_tx_data == valid_msg[0]) begin
                    valid_match_idx <= 1;
                end else begin
                    valid_match_idx <= 0;
                end
            end

            if (!score_found) begin
                if (uart_tx_data == score_msg[score_match_idx]) begin
                    score_match_idx <= score_match_idx + 1;
                    if (score_match_idx + 1 == SCORE_MSG_LEN) begin
                        score_found <= 1'b1;
                    end
                end else if (uart_tx_data == score_msg[0]) begin
                    score_match_idx <= 1;
                end else begin
                    score_match_idx <= 0;
                end
            end
        end

        if (profile_counts) begin
            if (dut.u_cpu.stall_decode) profile_stall_decode_cycles <= profile_stall_decode_cycles + 1;
            if (dut.u_cpu.mem_wait) profile_mem_wait_cycles <= profile_mem_wait_cycles + 1;
            if (dut.u_cpu.if_id_valid_r) profile_if_id_valid_cycles <= profile_if_id_valid_cycles + 1;
            if (dut.u_cpu.id_ex_valid_r) profile_id_ex_valid_cycles <= profile_id_ex_valid_cycles + 1;
            if (dut.u_cpu.ex_mem_valid_r) profile_ex_mem_valid_cycles <= profile_ex_mem_valid_cycles + 1;
            if (dut.u_cpu.mem_wb_valid_r) profile_mem_wb_valid_cycles <= profile_mem_wb_valid_cycles + 1;
            if (dut.u_cpu.id_ex_valid_r && dut.u_cpu.id_ex_load_r && !dut.u_cpu.stall_decode) profile_load_issues <= profile_load_issues + 1;
            if (dut.u_cpu.id_ex_valid_r && dut.u_cpu.id_ex_store_r && !dut.u_cpu.stall_decode) profile_store_issues <= profile_store_issues + 1;
            if (dut.dmem_read_req) profile_dmem_read_reqs <= profile_dmem_read_reqs + 1;
            if (dut.dmem_wstrb != 4'b0000) profile_dmem_write_reqs <= profile_dmem_write_reqs + 1;
            if (dut.u_cpu.ex_fetch_redirect_valid) profile_ex_redirects <= profile_ex_redirects + 1;
            if (dut.u_cpu.id_decode_redirect_valid) profile_id_redirects <= profile_id_redirects + 1;
            if (dut.u_cpu.id_jal_predict_redirect_valid) profile_jal_predicts <= profile_jal_predicts + 1;
            if (dut.u_cpu.id_branch_predict_redirect_valid) profile_branch_predicts <= profile_branch_predicts + 1;
        end

        if (cycle > 0 && cycle % 10000000 == 0) begin
            $display("CYCLE=%0d PC=%h", cycle, debug_pc);
        end

        if (debug_trace && (
            (cycle < trace_cycles) ||
            ((trace_stride > 0) && ((cycle % trace_stride) == 0)) ||
            ((cycle >= trace_start) && (cycle <= trace_end))
        )) begin
            $display(
                "TRACE cycle=%0d pc=%h trap=%b done=%b x10=%h x11=%h x12=%h daddr=%h dwdata=%h dwstrb=%h stall=%b memwait=%b pre=%b rv=%b ifpc=%h idpc=%h pcr=%h idload=%b idbr=%b idjmp=%b idpred=%b memload=%b pre_r=%b red=%b exred=%b idred=%b jalp=%b brp=%b redpc=%h nextpc=%h extrap=%b sync=%b misal=%b exaddr=%h size=%0d rs1=%0d rs2=%0d rd=%0d exrs1=%h exrs2=%h imm=%h",
                cycle,
                debug_pc,
                trap,
                done,
                dut.u_cpu.u_regfile.regs[10],
                dut.u_cpu.u_regfile.regs[11],
                dut.u_cpu.u_regfile.regs[12],
                dut.dmem_addr,
                dut.dmem_wdata,
                dut.dmem_wstrb,
                dut.u_cpu.stall_decode,
                dut.u_cpu.mem_wait,
                dut.u_cpu.ex_dmem_preissue_valid,
                dut.dmem_rvalid,
                dut.u_cpu.if_id_pc_r,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.pc_r,
                dut.u_cpu.id_ex_load_r,
                dut.u_cpu.id_ex_branch_r,
                dut.u_cpu.id_ex_jump_r,
                dut.u_cpu.id_ex_branch_predict_taken_r,
                dut.u_cpu.ex_mem_load_r,
                dut.u_cpu.ex_mem_load_preissued_r,
                dut.u_cpu.fetch_control_redirect_valid,
                dut.u_cpu.ex_fetch_redirect_valid,
                dut.u_cpu.id_decode_redirect_valid,
                dut.u_cpu.id_jal_predict_redirect_valid,
                dut.u_cpu.id_branch_predict_redirect_valid,
                dut.u_cpu.fetch_control_redirect_pc,
                dut.u_cpu.if_pc_next,
                dut.u_cpu.ex_trap_valid,
                dut.u_cpu.ex_sync_trap_valid,
                dut.u_cpu.ex_mem_misaligned,
                dut.u_cpu.ex_mem_addr,
                dut.u_cpu.id_ex_mem_size_r,
                dut.u_cpu.id_ex_rs1_addr_r,
                dut.u_cpu.id_ex_rs2_addr_r,
                dut.u_cpu.id_ex_rd_addr_r,
                dut.u_cpu.ex_rs1_forwarded,
                dut.u_cpu.ex_rs2_forwarded,
                dut.u_cpu.id_ex_imm_r
            );
        end

        if (debug_trace &&
            dut.u_cpu.mem_wb_valid_r &&
            dut.u_cpu.mem_wb_rd_en_r &&
            ((dut.u_cpu.mem_wb_rd_addr_r == 5'd6) ||
             (dut.u_cpu.mem_wb_rd_addr_r == 5'd11) ||
             (dut.u_cpu.mem_wb_rd_addr_r == 5'd13))) begin
            $display(
                "WTRACE cycle=%0d pc=%h rd=x%0d data=%h wbsel=%0d memload=%b pre_r=%b dvalid=%b exmemrd=%0d",
                cycle,
                debug_pc,
                dut.u_cpu.mem_wb_rd_addr_r,
                dut.u_cpu.wb_data,
                dut.u_cpu.mem_wb_wb_sel_r,
                dut.u_cpu.ex_mem_load_r,
                dut.u_cpu.ex_mem_load_preissued_r,
                dut.dmem_rvalid,
                dut.u_cpu.ex_mem_rd_addr_r
            );
        end

        if (debug_trace &&
            (dut.u_cpu.id_ex_pc_r >= 32'h0000_19b0) &&
            (dut.u_cpu.id_ex_pc_r <= 32'h0000_19c4)) begin
            $display(
                "PTRACE cycle=%0d idpc=%h ifpc=%h pcr=%h stall=%b memwait=%b pre=%b rv=%b trap=%b misal=%b addr=%h rs1=%0d rs2=%0d rd=%0d rs1v=%h rs2v=%h x6=%h x11=%h x13=%h x15=%h",
                cycle,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.if_id_pc_r,
                dut.u_cpu.pc_r,
                dut.u_cpu.stall_decode,
                dut.u_cpu.mem_wait,
                dut.u_cpu.ex_dmem_preissue_valid,
                dut.dmem_rvalid,
                dut.u_cpu.ex_trap_valid,
                dut.u_cpu.ex_mem_misaligned,
                dut.u_cpu.ex_mem_addr,
                dut.u_cpu.id_ex_rs1_addr_r,
                dut.u_cpu.id_ex_rs2_addr_r,
                dut.u_cpu.id_ex_rd_addr_r,
                dut.u_cpu.ex_rs1_forwarded,
                dut.u_cpu.ex_rs2_forwarded,
                dut.u_cpu.u_regfile.regs[6],
                dut.u_cpu.u_regfile.regs[11],
                dut.u_cpu.u_regfile.regs[13],
                dut.u_cpu.u_regfile.regs[15]
            );
        end

        if (trap) begin
            $fatal(1, "\nFAIL: coremark trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (done) begin
            if (!valid_found) begin
                $fatal(1, "\nFAIL: coremark missing summary banner at PC=%h", debug_pc);
            end

            if (!score_found) begin
                $fatal(1, "\nFAIL: coremark missing compiler banner at PC=%h", debug_pc);
            end

            if (profile_counts) begin
                $display("PROFILE: cycles=%0d stall_decode=%0d mem_wait=%0d if_id_valid=%0d id_ex_valid=%0d ex_mem_valid=%0d mem_wb_valid=%0d loads=%0d stores=%0d dmem_reads=%0d dmem_writes=%0d ex_redirects=%0d id_redirects=%0d jal_predicts=%0d branch_predicts=%0d",
                    cycle,
                    profile_stall_decode_cycles,
                    profile_mem_wait_cycles,
                    profile_if_id_valid_cycles,
                    profile_id_ex_valid_cycles,
                    profile_ex_mem_valid_cycles,
                    profile_mem_wb_valid_cycles,
                    profile_load_issues,
                    profile_store_issues,
                    profile_dmem_read_reqs,
                    profile_dmem_write_reqs,
                    profile_ex_redirects,
                    profile_id_redirects,
                    profile_jal_predicts,
                    profile_branch_predicts
                );
            end

            $display("\nPASS: coremark completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > max_cycles_runtime) begin
            $display("\nFAIL: coremark timeout at PC=%h after %0d cycles", debug_pc, cycle);
            $fatal(1, "\nFAIL: coremark timeout");
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    uart_count = 0;
    max_cycles_runtime = MAX_CYCLES;
    valid_match_idx = 0;
    score_match_idx = 0;
    valid_found = 1'b0;
    score_found = 1'b0;
    debug_trace = 1'b0;
    trace_cycles = 200;
    trace_stride = 0;
    trace_start = 1;
    trace_end = 0;
    plusarg_seen = 0;
    profile_counts = 1'b0;
    profile_stall_decode_cycles = 0;
    profile_mem_wait_cycles = 0;
    profile_if_id_valid_cycles = 0;
    profile_id_ex_valid_cycles = 0;
    profile_ex_mem_valid_cycles = 0;
    profile_mem_wb_valid_cycles = 0;
    profile_load_issues = 0;
    profile_store_issues = 0;
    profile_dmem_read_reqs = 0;
    profile_dmem_write_reqs = 0;
    profile_ex_redirects = 0;
    profile_id_redirects = 0;
    profile_jal_predicts = 0;
    profile_branch_predicts = 0;

    valid_msg[0]  = "C";
    valid_msg[1]  = "o";
    valid_msg[2]  = "r";
    valid_msg[3]  = "e";
    valid_msg[4]  = "M";
    valid_msg[5]  = "a";
    valid_msg[6]  = "r";
    valid_msg[7]  = "k";
    valid_msg[8]  = " ";
    valid_msg[9]  = "S";
    valid_msg[10] = "i";
    valid_msg[11] = "z";
    valid_msg[12] = "e";

    score_msg[0]  = "C";
    score_msg[1]  = "o";
    score_msg[2]  = "m";
    score_msg[3]  = "p";
    score_msg[4]  = "i";
    score_msg[5]  = "l";
    score_msg[6]  = "e";
    score_msg[7]  = "r";
    score_msg[8]  = " ";
    score_msg[9]  = "v";
    score_msg[10] = "e";
    score_msg[11] = "r";
    score_msg[12] = "s";
    score_msg[13] = "i";
    score_msg[14] = "o";
    score_msg[15] = "n";

    if (!$value$plusargs("max_cycles=%d", max_cycles_runtime)) begin
        max_cycles_runtime = MAX_CYCLES;
    end

    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end
    if ($test$plusargs("profile_counts")) begin
        profile_counts = 1'b1;
    end
    plusarg_seen = $value$plusargs("trace_cycles=%d", trace_cycles);
    plusarg_seen = $value$plusargs("trace_stride=%d", trace_stride);
    plusarg_seen = $value$plusargs("trace_start=%d", trace_start);
    plusarg_seen = $value$plusargs("trace_end=%d", trace_end);

    #100;
    rst_n = 1'b1;

    $display("Starting CoreMark simulation (MAX_CYCLES=%0d)...", max_cycles_runtime);
end

endmodule
