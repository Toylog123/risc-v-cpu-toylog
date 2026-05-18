`timescale 1ns / 1ps

module YH_rv_cpu_coremark_fpga_tb #(
    parameter integer XLEN = 32,
    parameter string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex",
    parameter string ROM_MEM32_HEX = "build/sw/YH_rv_cpu_coremark_rv32.mem32.hex",
    parameter [31:0] RAM_BASE = 32'h0001_0000,
    parameter integer ROM_BYTES = 65536,
    parameter integer RAM_BYTES = 65536,
    parameter integer MAX_CYCLES = 1000000000,
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 1,
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1,
    parameter integer ENABLE_ID_BRANCH_FOLD = 0,
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP = 1,
    parameter integer ENABLE_FETCH_REDIRECT_REUSE = 0,
    parameter integer REDIRECT_CACHE_ENTRIES = 1024,
    parameter integer REDIRECT_CACHE_XOR_INDEX = 0,
    parameter integer ENABLE_DYNAMIC_BRANCH_PREDICT = 0,
    parameter integer BRANCH_BHT_ENTRIES = 64,
    parameter integer BRANCH_STATIC_PREDICT_MODE = 0,
    parameter integer BRANCH_BHT_STRONG_ONLY = 0,
    parameter integer DMEM_NEGEDGE_READ = 0,
    parameter integer ICACHE_EN = 0
) ();

localparam integer VALID_MSG_LEN = 13;
localparam integer SCORE_MSG_LEN = 16;

reg                clk;
reg                rst_n;
wire               trap;
wire [XLEN-1:0]    debug_pc;
wire               uart_tx_valid;
wire [7:0]         uart_tx_data;
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
reg     fail_on_low_pc_after_startup;
integer low_pc_min_cycle;

YH_rv_cpu_soc #(
    .XLEN(XLEN),
    .SYNC_IMEM(1),
    .IMEM_OUTPUT_REG(0),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(0),
    .DMEM_NEGEDGE_READ(DMEM_NEGEDGE_READ),
    .ICACHE_EN(ICACHE_EN),
    .RAM_BASE(RAM_BASE),
    .ROM_BYTES(ROM_BYTES),
    .RAM_BYTES(RAM_BYTES),
    .ROM_INIT_HEX(ROM_HEX),
    .ROM_INIT_MEM32_HEX(ROM_MEM32_HEX),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION),
    .ENABLE_XTHEAD_COND_MOVE(ENABLE_XTHEAD_COND_MOVE),
    .ENABLE_ID_BRANCH_EX_FORWARD(ENABLE_ID_BRANCH_EX_FORWARD),
    .ENABLE_ID_BRANCH_FOLD(ENABLE_ID_BRANCH_FOLD),
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

        if (cycle > 0 && cycle % 10000000 == 0) begin
            $display("CYCLE=%0d PC=%h", cycle, debug_pc);
        end

        if (debug_trace && (
            (cycle < trace_cycles) ||
            ((trace_stride > 0) && ((cycle % trace_stride) == 0)) ||
            ((cycle >= trace_start) && (cycle <= trace_end))
        )) begin
            $display(
                "TRACE_IF cycle=%0d pc=%h ifid_v=%b idex_v=%b exmem_v=%b memwb_v=%b wr=%b data_wr=%b next_v=%b load_bub=%b dup=%b stall=%b dflush=%b q_valid=%b pipe_valid=%b buffer_valid=%b buf0_v=%b buf1_v=%b rsp_valid=%b imem_rvalid=%b drop_count=%0d drop_rsp=%b live=%b consume=%b enqueue=%b data_issue=%b live_data=%b enqueue_data=%b redir=%b redir_pc=%h ifid_pc=%h idex_pc=%h q_pc=%h rsp_pc=%h buf0_pc=%h buf1_pc=%h ifid_instr=%h q_instr=%h",
                cycle,
                debug_pc,
                dut.u_cpu.if_id_valid_r,
                dut.u_cpu.id_ex_valid_r,
                dut.u_cpu.ex_mem_valid_r,
                dut.u_cpu.mem_wb_valid_r,
                dut.u_cpu.if_id_write_en,
                dut.u_cpu.if_id_data_write_en,
                dut.u_cpu.if_id_next_valid,
                dut.u_cpu.if_id_load_bubble,
                dut.u_cpu.if_id_duplicate_fetch,
                dut.u_cpu.stall_decode,
                dut.u_cpu.decode_flush_valid,
                dut.u_cpu.fetch_queue_valid,
                dut.u_cpu.fetch_pipe_valid,
                dut.u_cpu.fetch_buffer_valid,
                dut.u_cpu.fetch_buf0_valid_r,
                dut.u_cpu.fetch_buf1_valid_r,
                dut.u_cpu.fetch_rsp_valid,
                dut.imem_rvalid,
                dut.u_cpu.fetch_drop_count_r,
                dut.u_cpu.fetch_drop_response,
                dut.u_cpu.fetch_live_to_ifid,
                dut.u_cpu.fetch_queue_consume,
                dut.u_cpu.fetch_queue_enqueue,
                dut.u_cpu.fetch_data_issue,
                dut.u_cpu.fetch_live_to_ifid_data,
                dut.u_cpu.fetch_queue_enqueue_data,
                dut.u_cpu.fetch_control_redirect_valid,
                dut.u_cpu.fetch_control_redirect_pc,
                dut.u_cpu.if_id_pc_r,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.fetch_queue_pc,
                dut.u_cpu.fetch_rsp_pc,
                dut.u_cpu.fetch_buf0_pc_r,
                dut.u_cpu.fetch_buf1_pc_r,
                dut.u_cpu.if_id_instruction_r,
                dut.u_cpu.fetch_queue_instruction
            );
            $display(
                "TRACE cycle=%0d pc=%h ifid=%h idex=%h exmem_pc4=%h ex_redir=%b ex_redir_pc=%h fwdA=%b fwdB=%b idex_rs1=%0d idex_rs2=%0d idex_rd=%0d exmem_rd=%0d memwb_rd=%0d ex_rs1=%h ex_rs2=%h trap=%b done=%b x5=%h x6=%h x7=%h x10=%h x11=%h x12=%h x13=%h x14=%h x15=%h x16=%h x17=%h x28=%h x29=%h x30=%h x31=%h daddr=%h drdata=%h drvalid=%b dwdata=%h dwstrb=%h",
                cycle,
                debug_pc,
                dut.u_cpu.if_id_pc_r,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.ex_mem_pc4_r,
                dut.u_cpu.ex_redirect_en,
                dut.u_cpu.ex_redirect_pc,
                dut.u_cpu.forward_a_sel,
                dut.u_cpu.forward_b_sel,
                dut.u_cpu.id_ex_rs1_addr_r,
                dut.u_cpu.id_ex_rs2_addr_r,
                dut.u_cpu.id_ex_rd_addr_r,
                dut.u_cpu.ex_mem_rd_addr_r,
                dut.u_cpu.mem_wb_rd_addr_r,
                dut.u_cpu.ex_rs1_forwarded,
                dut.u_cpu.ex_rs2_forwarded,
                trap,
                done,
                dut.u_cpu.u_regfile.regs[5],
                dut.u_cpu.u_regfile.regs[6],
                dut.u_cpu.u_regfile.regs[7],
                dut.u_cpu.u_regfile.regs[10],
                dut.u_cpu.u_regfile.regs[11],
                dut.u_cpu.u_regfile.regs[12],
                dut.u_cpu.u_regfile.regs[13],
                dut.u_cpu.u_regfile.regs[14],
                dut.u_cpu.u_regfile.regs[15],
                dut.u_cpu.u_regfile.regs[16],
                dut.u_cpu.u_regfile.regs[17],
                dut.u_cpu.u_regfile.regs[28],
                dut.u_cpu.u_regfile.regs[29],
                dut.u_cpu.u_regfile.regs[30],
                dut.u_cpu.u_regfile.regs[31],
                dut.dmem_addr,
                dut.dmem_rdata,
                dut.dmem_rvalid,
                dut.dmem_wdata,
                dut.dmem_wstrb
            );
            $display(
                "TRACE_WB cycle=%0d exmem_v=%b exmem_load=%b exmem_rd_en=%b exmem_rd=%0d memwb_v=%b memwb_rd_en=%b memwb_sel=%b memwb_rd=%0d mem_load=%h memwb_load=%h wb_data=%h",
                cycle,
                dut.u_cpu.ex_mem_valid_r,
                dut.u_cpu.ex_mem_load_r,
                dut.u_cpu.ex_mem_rd_en_r,
                dut.u_cpu.ex_mem_rd_addr_r,
                dut.u_cpu.mem_wb_valid_r,
                dut.u_cpu.mem_wb_rd_en_r,
                dut.u_cpu.mem_wb_wb_sel_r,
                dut.u_cpu.mem_wb_rd_addr_r,
                dut.u_cpu.mem_load_data,
                dut.u_cpu.mem_wb_load_data_r,
                dut.u_cpu.wb_data
            );
        end

        if (debug_trace && (cycle == 260)) begin
            $display(
                "TRACE_RAM_INIT cycle=%0d ram0=%h ram1=%h ram2=%h ram3=%h ram4=%h ram5=%h",
                cycle,
                dut.u_dmem_ram.g_sync_ram.ram_mem[0],
                dut.u_dmem_ram.g_sync_ram.ram_mem[1],
                dut.u_dmem_ram.g_sync_ram.ram_mem[2],
                dut.u_dmem_ram.g_sync_ram.ram_mem[3],
                dut.u_dmem_ram.g_sync_ram.ram_mem[4],
                dut.u_dmem_ram.g_sync_ram.ram_mem[5]
            );
        end

        if (fail_on_low_pc_after_startup &&
            (cycle > low_pc_min_cycle) &&
            (debug_pc < 32'h0000_0060)) begin
            $display(
                "LOW_PC_DIAG cycle=%0d pc=%h ifid_pc=%h idex_pc=%h exmem_pc4=%h ex_redir=%b ex_redir_pc=%h ifid_instr=%h x1=%h x2=%h x5=%h x6=%h x7=%h x10=%h x11=%h x12=%h x13=%h x14=%h x15=%h x16=%h x17=%h x28=%h x29=%h x30=%h x31=%h daddr=%h drdata=%h drvalid=%b dwdata=%h dwstrb=%h",
                cycle,
                debug_pc,
                dut.u_cpu.if_id_pc_r,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.ex_mem_pc4_r,
                dut.u_cpu.ex_redirect_en,
                dut.u_cpu.ex_redirect_pc,
                dut.u_cpu.if_id_instruction_r,
                dut.u_cpu.u_regfile.regs[1],
                dut.u_cpu.u_regfile.regs[2],
                dut.u_cpu.u_regfile.regs[5],
                dut.u_cpu.u_regfile.regs[6],
                dut.u_cpu.u_regfile.regs[7],
                dut.u_cpu.u_regfile.regs[10],
                dut.u_cpu.u_regfile.regs[11],
                dut.u_cpu.u_regfile.regs[12],
                dut.u_cpu.u_regfile.regs[13],
                dut.u_cpu.u_regfile.regs[14],
                dut.u_cpu.u_regfile.regs[15],
                dut.u_cpu.u_regfile.regs[16],
                dut.u_cpu.u_regfile.regs[17],
                dut.u_cpu.u_regfile.regs[28],
                dut.u_cpu.u_regfile.regs[29],
                dut.u_cpu.u_regfile.regs[30],
                dut.u_cpu.u_regfile.regs[31],
                dut.dmem_addr,
                dut.dmem_rdata,
                dut.dmem_rvalid,
                dut.dmem_wdata,
                dut.dmem_wstrb
            );
            $fatal(1, "\nFAIL: low PC after startup");
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
    fail_on_low_pc_after_startup = 1'b0;
    low_pc_min_cycle = 9000;

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
    plusarg_seen = $value$plusargs("trace_cycles=%d", trace_cycles);
    plusarg_seen = $value$plusargs("trace_stride=%d", trace_stride);
    plusarg_seen = $value$plusargs("trace_start=%d", trace_start);
    plusarg_seen = $value$plusargs("trace_end=%d", trace_end);
    if ($test$plusargs("fail_on_low_pc_after_startup")) begin
        fail_on_low_pc_after_startup = 1'b1;
    end
    plusarg_seen = $value$plusargs("low_pc_min_cycle=%d", low_pc_min_cycle);

    #100;
    rst_n = 1'b1;

    $display("Starting FPGA-like CoreMark simulation (MAX_CYCLES=%0d)...", max_cycles_runtime);
end

endmodule
