`timescale 1ns / 1ps

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_coremark_profile_tb #(
    parameter integer XLEN = 32,
    parameter string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex",
    parameter string ROM_MEM32_HEX = "build/sw/YH_rv_cpu_coremark_rv32.mem32.hex",
    parameter [31:0] RAM_BASE = 32'h0001_0000,
    parameter integer ROM_BYTES = 65536,
    parameter integer RAM_BYTES = 65536,
    parameter integer MAX_CYCLES = 1000000000
) ();

localparam integer VALID_MSG_LEN = 13;
localparam integer SCORE_MSG_LEN = 16;

// Observe the SoC's UART banner and a set of internal pipeline counters in one run.
reg                clk;
reg                rst_n;
wire               trap;
wire [XLEN-1:0]    debug_pc;
wire               uart_tx_valid;
wire [7:0]         uart_tx_data;
wire               done;
wire               timer_irq;

wire stall_decode;
wire mem_wait;
wire ex_trap_valid;
wire ex_mret_valid;
wire ex_redirect_valid;
wire ex_fetch_redirect_valid;
wire fetch_queue_empty;
wire id_ex_jump;
wire id_ex_jalr;
wire [2:0] id_ex_branch_funct3;
wire fetch_redirect_reuse_valid;
wire fetch_redirect_buf0_hit;
wire fetch_redirect_buf1_hit;
wire id_ex_valid;
wire id_ex_load;
wire id_ex_store;
wire id_ex_branch;
wire id_ex_csr_valid;
wire [4:0] id_ex_alu_op;
wire [31:0] id_ex_pc32;
wire id_branch_decode_candidate;
wire id_branch_decode_operands_ready;
wire id_branch_decode_redirect_valid;
wire id_branch_decode_rs1_pending;
wire id_branch_decode_rs2_pending;
wire id_branch_decode_rs1_idex_pending;
wire id_branch_decode_rs2_idex_pending;
wire id_branch_decode_rs1_exmem_pending;
wire id_branch_decode_rs2_exmem_pending;
wire [2:0] id_branch_funct3;

reg [7:0] valid_msg [0:VALID_MSG_LEN-1];
reg [7:0] score_msg [0:SCORE_MSG_LEN-1];
integer cycle;
integer uart_count;
integer max_cycles_runtime;
integer valid_match_idx;
integer score_match_idx;
integer stall_decode_cycles;
integer mem_wait_cycles;
integer ex_trap_valid_cycles;
integer ex_mret_valid_cycles;
integer ex_branch_redirect_cycles;
integer ex_beq_redirect_cycles;
integer ex_bne_redirect_cycles;
integer ex_blt_redirect_cycles;
integer ex_bge_redirect_cycles;
integer ex_bltu_redirect_cycles;
integer ex_bgeu_redirect_cycles;
integer ex_jal_redirect_cycles;
integer ex_jalr_redirect_cycles;
integer ex_fetch_redirect_valid_cycles;
integer fetch_queue_empty_cycles;
integer fetch_redirect_reuse_cycles;
integer fetch_redirect_reuse_miss_cycles;
integer fetch_redirect_buf0_hit_cycles;
integer fetch_redirect_buf1_hit_cycles;
integer id_ex_valid_cycles;
integer id_ex_load_cycles;
integer id_ex_store_cycles;
integer id_ex_branch_cycles;
integer id_ex_jump_cycles;
integer id_ex_jal_cycles;
integer id_ex_jalr_cycles;
integer id_ex_csr_cycles;
integer id_ex_mul_cycles;
integer id_ex_mulh_cycles;
integer id_ex_mulhsu_cycles;
integer id_ex_mulhu_cycles;
integer id_ex_div_cycles;
integer id_ex_divu_cycles;
integer id_ex_rem_cycles;
integer id_ex_remu_cycles;
integer pc_startup_cycles;
integer pc_calc_cycles;
integer pc_list_cycles;
integer pc_list_init_cycles;
integer pc_list_runtime_cycles;
integer pc_iterate_cycles;
integer pc_main_cycles;
integer pc_matrix_cycles;
integer pc_matrix_test_cycles;
integer pc_core_bench_matrix_cycles;
integer pc_core_init_matrix_cycles;
integer pc_matrix_sum_cycles;
integer pc_matrix_mul_const_cycles;
integer pc_matrix_add_const_cycles;
integer pc_matrix_mul_vect_cycles;
integer pc_matrix_mul_matrix_cycles;
integer pc_matrix_bitextract_cycles;
integer pc_state_cycles;
integer pc_core_init_state_cycles;
integer pc_state_transition_cycles;
integer pc_core_bench_state_cycles;
integer pc_crc_cycles;
integer pc_port_cycles;
integer pc_unknown_cycles;
integer pc_exec_bins [0:65535];
integer hist_i;
integer hist_j;
integer hist_top_count;
integer hist_top_index;
integer id_branch_decode_candidate_cycles;
integer id_branch_decode_ready_cycles;
integer id_branch_decode_pending_cycles;
integer id_branch_decode_redirect_cycles;
integer id_branch_decode_rs1_pending_cycles;
integer id_branch_decode_rs2_pending_cycles;
integer id_branch_decode_rs1_idex_pending_cycles;
integer id_branch_decode_rs2_idex_pending_cycles;
integer id_branch_decode_rs1_exmem_pending_cycles;
integer id_branch_decode_rs2_exmem_pending_cycles;
integer id_beq_decode_candidate_cycles;
integer id_bne_decode_candidate_cycles;
integer id_blt_decode_candidate_cycles;
integer id_bge_decode_candidate_cycles;
integer id_bltu_decode_candidate_cycles;
integer id_bgeu_decode_candidate_cycles;
integer id_beq_decode_pending_cycles;
integer id_bne_decode_pending_cycles;
integer id_blt_decode_pending_cycles;
integer id_bge_decode_pending_cycles;
integer id_bltu_decode_pending_cycles;
integer id_bgeu_decode_pending_cycles;
reg     valid_found;
reg     score_found;

// Profile runs reuse the same SoC wrapper as the score flow so comparisons stay fair.
YH_rv_cpu_soc #(
    .XLEN(XLEN),
    .SYNC_IMEM(0),
    .IMEM_OUTPUT_REG(0),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(0),
    .DMEM_NEGEDGE_READ(1),
    .RAM_BASE(RAM_BASE),
    .ROM_BYTES(ROM_BYTES),
    .RAM_BYTES(RAM_BYTES),
    .ROM_INIT_HEX(ROM_HEX),
    .ROM_INIT_MEM32_HEX(ROM_MEM32_HEX)
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

assign stall_decode = dut.u_cpu.stall_decode;
assign mem_wait = dut.u_cpu.mem_wait;
assign ex_trap_valid = dut.u_cpu.ex_trap_valid;
assign ex_mret_valid = dut.u_cpu.ex_mret_valid;
assign ex_redirect_valid = dut.u_cpu.ex_redirect_valid;
assign ex_fetch_redirect_valid = dut.u_cpu.ex_fetch_redirect_valid;
assign fetch_queue_empty = !dut.u_cpu.fetch_queue_valid;
assign id_ex_jump = dut.u_cpu.id_ex_jump_r;
assign id_ex_jalr = dut.u_cpu.id_ex_jalr_r;
assign id_ex_branch_funct3 = dut.u_cpu.id_ex_branch_funct3_r;
assign id_ex_valid = dut.u_cpu.id_ex_valid_r;
assign id_ex_load = dut.u_cpu.id_ex_load_r;
assign id_ex_store = dut.u_cpu.id_ex_store_r;
assign id_ex_branch = dut.u_cpu.id_ex_branch_r;
assign id_ex_csr_valid = dut.u_cpu.id_ex_csr_valid_r;
assign id_ex_alu_op = dut.u_cpu.id_ex_alu_op_r;
assign id_ex_pc32 = dut.u_cpu.id_ex_pc_r[31:0];
assign fetch_redirect_reuse_valid = dut.u_cpu.fetch_redirect_reuse_valid;
assign fetch_redirect_buf0_hit = dut.u_cpu.fetch_redirect_buf0_hit;
assign fetch_redirect_buf1_hit = dut.u_cpu.fetch_redirect_buf1_hit;
assign id_branch_decode_candidate = dut.u_cpu.id_branch_decode_candidate;
assign id_branch_decode_operands_ready = dut.u_cpu.id_branch_decode_operands_ready;
assign id_branch_decode_redirect_valid = dut.u_cpu.id_branch_decode_redirect_valid;
assign id_branch_decode_rs1_pending = dut.u_cpu.id_branch_decode_rs1_pending;
assign id_branch_decode_rs2_pending = dut.u_cpu.id_branch_decode_rs2_pending;
assign id_branch_funct3 = dut.u_cpu.id_branch_funct3;
assign id_branch_decode_rs1_idex_pending =
    dut.u_cpu.id_branch_decode_rs1_idex_match &&
    !dut.u_cpu.id_branch_decode_idex_value_available;
assign id_branch_decode_rs2_idex_pending =
    dut.u_cpu.id_branch_decode_rs2_idex_match &&
    !dut.u_cpu.id_branch_decode_idex_value_available;
assign id_branch_decode_rs1_exmem_pending =
    dut.u_cpu.id_branch_decode_rs1_exmem_match &&
    !dut.u_cpu.id_branch_decode_exmem_value_available;
assign id_branch_decode_rs2_exmem_pending =
    dut.u_cpu.id_branch_decode_rs2_exmem_match &&
    !dut.u_cpu.id_branch_decode_exmem_value_available;

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (uart_tx_valid) begin
            // Match the key CoreMark UART banners without buffering the full stream.
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

        if (stall_decode) begin
            stall_decode_cycles <= stall_decode_cycles + 1;
        end

        if (mem_wait) begin
            mem_wait_cycles <= mem_wait_cycles + 1;
        end

        if (ex_trap_valid) begin
            ex_trap_valid_cycles <= ex_trap_valid_cycles + 1;
        end

        if (ex_mret_valid) begin
            ex_mret_valid_cycles <= ex_mret_valid_cycles + 1;
        end

        if (ex_fetch_redirect_valid) begin
            ex_fetch_redirect_valid_cycles <= ex_fetch_redirect_valid_cycles + 1;
        end

        // Track redirect composition so branch/jump behavior can be correlated with score changes.
        if (ex_redirect_valid) begin
            if (id_ex_jump) begin
                if (id_ex_jalr) begin
                    ex_jalr_redirect_cycles <= ex_jalr_redirect_cycles + 1;
                end else begin
                    ex_jal_redirect_cycles <= ex_jal_redirect_cycles + 1;
                end
            end else begin
                ex_branch_redirect_cycles <= ex_branch_redirect_cycles + 1;
                case (id_ex_branch_funct3)
                    3'b000: ex_beq_redirect_cycles <= ex_beq_redirect_cycles + 1;
                    3'b001: ex_bne_redirect_cycles <= ex_bne_redirect_cycles + 1;
                    3'b100: ex_blt_redirect_cycles <= ex_blt_redirect_cycles + 1;
                    3'b101: ex_bge_redirect_cycles <= ex_bge_redirect_cycles + 1;
                    3'b110: ex_bltu_redirect_cycles <= ex_bltu_redirect_cycles + 1;
                    3'b111: ex_bgeu_redirect_cycles <= ex_bgeu_redirect_cycles + 1;
                    default: begin
                    end
                endcase
            end

            if (fetch_redirect_reuse_valid) begin
                fetch_redirect_reuse_cycles <= fetch_redirect_reuse_cycles + 1;
                if (fetch_redirect_buf0_hit) begin
                    fetch_redirect_buf0_hit_cycles <= fetch_redirect_buf0_hit_cycles + 1;
                end
                if (fetch_redirect_buf1_hit) begin
                    fetch_redirect_buf1_hit_cycles <= fetch_redirect_buf1_hit_cycles + 1;
                end
            end else begin
                fetch_redirect_reuse_miss_cycles <= fetch_redirect_reuse_miss_cycles + 1;
            end
        end

        if (fetch_queue_empty) begin
            fetch_queue_empty_cycles <= fetch_queue_empty_cycles + 1;
        end

        if (id_ex_valid) begin
            id_ex_valid_cycles <= id_ex_valid_cycles + 1;
            if (id_ex_pc32[31:18] == 14'd0) begin
                pc_exec_bins[id_ex_pc32[17:2]] <= pc_exec_bins[id_ex_pc32[17:2]] + 1;
            end
            if (id_ex_load) id_ex_load_cycles <= id_ex_load_cycles + 1;
            if (id_ex_store) id_ex_store_cycles <= id_ex_store_cycles + 1;
            if (id_ex_branch) id_ex_branch_cycles <= id_ex_branch_cycles + 1;
            if (id_ex_jump) begin
                id_ex_jump_cycles <= id_ex_jump_cycles + 1;
                if (id_ex_jalr) id_ex_jalr_cycles <= id_ex_jalr_cycles + 1;
                else id_ex_jal_cycles <= id_ex_jal_cycles + 1;
            end
            if (id_ex_csr_valid) id_ex_csr_cycles <= id_ex_csr_cycles + 1;

            case (id_ex_alu_op)
                `YH_rv_cpu_ALU_MUL: id_ex_mul_cycles <= id_ex_mul_cycles + 1;
                `YH_rv_cpu_ALU_MULH: id_ex_mulh_cycles <= id_ex_mulh_cycles + 1;
                `YH_rv_cpu_ALU_MULHSU: id_ex_mulhsu_cycles <= id_ex_mulhsu_cycles + 1;
                `YH_rv_cpu_ALU_MULHU: id_ex_mulhu_cycles <= id_ex_mulhu_cycles + 1;
                `YH_rv_cpu_ALU_DIV: id_ex_div_cycles <= id_ex_div_cycles + 1;
                `YH_rv_cpu_ALU_DIVU: id_ex_divu_cycles <= id_ex_divu_cycles + 1;
                `YH_rv_cpu_ALU_REM: id_ex_rem_cycles <= id_ex_rem_cycles + 1;
                `YH_rv_cpu_ALU_REMU: id_ex_remu_cycles <= id_ex_remu_cycles + 1;
                default: begin
                end
            endcase

            case (1'b1)
                (id_ex_pc32 < 32'h0000_0060): pc_startup_cycles <= pc_startup_cycles + 1;
                (id_ex_pc32 < 32'h0000_0458): pc_calc_cycles <= pc_calc_cycles + 1;
                (id_ex_pc32 < 32'h0000_10c4): begin
                    pc_list_cycles <= pc_list_cycles + 1;
                    pc_list_runtime_cycles <= pc_list_runtime_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_16c8): begin
                    pc_list_cycles <= pc_list_cycles + 1;
                    pc_list_init_cycles <= pc_list_init_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_1d30): begin
                    pc_list_cycles <= pc_list_cycles + 1;
                    pc_list_runtime_cycles <= pc_list_runtime_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_1f38): pc_iterate_cycles <= pc_iterate_cycles + 1;
                (id_ex_pc32 < 32'h0000_2938): pc_main_cycles <= pc_main_cycles + 1;
                (id_ex_pc32 < 32'h0000_3620): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_matrix_test_cycles <= pc_matrix_test_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_365c): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_core_bench_matrix_cycles <= pc_core_bench_matrix_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_3920): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_core_init_matrix_cycles <= pc_core_init_matrix_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_39b8): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_matrix_sum_cycles <= pc_matrix_sum_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_3b48): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_matrix_mul_const_cycles <= pc_matrix_mul_const_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_3c8c): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_matrix_add_const_cycles <= pc_matrix_add_const_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_3e98): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_matrix_mul_vect_cycles <= pc_matrix_mul_vect_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_4108): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_matrix_mul_matrix_cycles <= pc_matrix_mul_matrix_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_4308): begin
                    pc_matrix_cycles <= pc_matrix_cycles + 1;
                    pc_matrix_bitextract_cycles <= pc_matrix_bitextract_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_4698): begin
                    pc_state_cycles <= pc_state_cycles + 1;
                    pc_core_init_state_cycles <= pc_core_init_state_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_4980): begin
                    pc_state_cycles <= pc_state_cycles + 1;
                    pc_state_transition_cycles <= pc_state_transition_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_4e50): begin
                    pc_state_cycles <= pc_state_cycles + 1;
                    pc_core_bench_state_cycles <= pc_core_bench_state_cycles + 1;
                end
                (id_ex_pc32 < 32'h0000_5858): pc_crc_cycles <= pc_crc_cycles + 1;
                (id_ex_pc32 < 32'h0000_8950): pc_port_cycles <= pc_port_cycles + 1;
                default: pc_unknown_cycles <= pc_unknown_cycles + 1;
            endcase
        end

        if (id_branch_decode_candidate) begin
            id_branch_decode_candidate_cycles <= id_branch_decode_candidate_cycles + 1;
            if (id_branch_decode_operands_ready) begin
                id_branch_decode_ready_cycles <= id_branch_decode_ready_cycles + 1;
            end else begin
                id_branch_decode_pending_cycles <= id_branch_decode_pending_cycles + 1;
            end
            if (id_branch_decode_rs1_pending) begin
                id_branch_decode_rs1_pending_cycles <= id_branch_decode_rs1_pending_cycles + 1;
            end
            if (id_branch_decode_rs2_pending) begin
                id_branch_decode_rs2_pending_cycles <= id_branch_decode_rs2_pending_cycles + 1;
            end
            if (id_branch_decode_rs1_idex_pending) begin
                id_branch_decode_rs1_idex_pending_cycles <= id_branch_decode_rs1_idex_pending_cycles + 1;
            end
            if (id_branch_decode_rs2_idex_pending) begin
                id_branch_decode_rs2_idex_pending_cycles <= id_branch_decode_rs2_idex_pending_cycles + 1;
            end
            if (id_branch_decode_rs1_exmem_pending) begin
                id_branch_decode_rs1_exmem_pending_cycles <= id_branch_decode_rs1_exmem_pending_cycles + 1;
            end
            if (id_branch_decode_rs2_exmem_pending) begin
                id_branch_decode_rs2_exmem_pending_cycles <= id_branch_decode_rs2_exmem_pending_cycles + 1;
            end

            case (id_branch_funct3)
                3'b000: begin
                    id_beq_decode_candidate_cycles <= id_beq_decode_candidate_cycles + 1;
                    if (!id_branch_decode_operands_ready) id_beq_decode_pending_cycles <= id_beq_decode_pending_cycles + 1;
                end
                3'b001: begin
                    id_bne_decode_candidate_cycles <= id_bne_decode_candidate_cycles + 1;
                    if (!id_branch_decode_operands_ready) id_bne_decode_pending_cycles <= id_bne_decode_pending_cycles + 1;
                end
                3'b100: begin
                    id_blt_decode_candidate_cycles <= id_blt_decode_candidate_cycles + 1;
                    if (!id_branch_decode_operands_ready) id_blt_decode_pending_cycles <= id_blt_decode_pending_cycles + 1;
                end
                3'b101: begin
                    id_bge_decode_candidate_cycles <= id_bge_decode_candidate_cycles + 1;
                    if (!id_branch_decode_operands_ready) id_bge_decode_pending_cycles <= id_bge_decode_pending_cycles + 1;
                end
                3'b110: begin
                    id_bltu_decode_candidate_cycles <= id_bltu_decode_candidate_cycles + 1;
                    if (!id_branch_decode_operands_ready) id_bltu_decode_pending_cycles <= id_bltu_decode_pending_cycles + 1;
                end
                3'b111: begin
                    id_bgeu_decode_candidate_cycles <= id_bgeu_decode_candidate_cycles + 1;
                    if (!id_branch_decode_operands_ready) id_bgeu_decode_pending_cycles <= id_bgeu_decode_pending_cycles + 1;
                end
                default: begin
                end
            endcase
        end

        if (id_branch_decode_redirect_valid) begin
            id_branch_decode_redirect_cycles <= id_branch_decode_redirect_cycles + 1;
        end

        // Emit coarse progress for very long profile runs.
        if (cycle > 0 && cycle % 10000000 == 0) begin
            $display("CYCLE=%0d PC=%h", cycle, debug_pc);
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

            $display("\nPASS: coremark profile completed at PC=%h in %0d cycles", debug_pc, cycle);
            $display("PROFILE: total_cycles=%0d", cycle);
            $display("PROFILE: stall_decode_cycles=%0d", stall_decode_cycles);
            $display("PROFILE: mem_wait_cycles=%0d", mem_wait_cycles);
            $display("PROFILE: ex_trap_valid_cycles=%0d", ex_trap_valid_cycles);
            $display("PROFILE: ex_mret_valid_cycles=%0d", ex_mret_valid_cycles);
            $display("PROFILE: ex_branch_redirect_cycles=%0d", ex_branch_redirect_cycles);
            $display("PROFILE: ex_beq_redirect_cycles=%0d", ex_beq_redirect_cycles);
            $display("PROFILE: ex_bne_redirect_cycles=%0d", ex_bne_redirect_cycles);
            $display("PROFILE: ex_blt_redirect_cycles=%0d", ex_blt_redirect_cycles);
            $display("PROFILE: ex_bge_redirect_cycles=%0d", ex_bge_redirect_cycles);
            $display("PROFILE: ex_bltu_redirect_cycles=%0d", ex_bltu_redirect_cycles);
            $display("PROFILE: ex_bgeu_redirect_cycles=%0d", ex_bgeu_redirect_cycles);
            $display("PROFILE: ex_jal_redirect_cycles=%0d", ex_jal_redirect_cycles);
            $display("PROFILE: ex_jalr_redirect_cycles=%0d", ex_jalr_redirect_cycles);
            $display("PROFILE: ex_fetch_redirect_valid_cycles=%0d", ex_fetch_redirect_valid_cycles);
            $display("PROFILE: fetch_queue_empty_cycles=%0d", fetch_queue_empty_cycles);
            $display("PROFILE: fetch_redirect_reuse_cycles=%0d", fetch_redirect_reuse_cycles);
            $display("PROFILE: fetch_redirect_reuse_miss_cycles=%0d", fetch_redirect_reuse_miss_cycles);
            $display("PROFILE: fetch_redirect_buf0_hit_cycles=%0d", fetch_redirect_buf0_hit_cycles);
            $display("PROFILE: fetch_redirect_buf1_hit_cycles=%0d", fetch_redirect_buf1_hit_cycles);
            $display("PROFILE: id_ex_valid_cycles=%0d", id_ex_valid_cycles);
            $display("PROFILE: id_ex_load_cycles=%0d", id_ex_load_cycles);
            $display("PROFILE: id_ex_store_cycles=%0d", id_ex_store_cycles);
            $display("PROFILE: id_ex_branch_cycles=%0d", id_ex_branch_cycles);
            $display("PROFILE: id_ex_jump_cycles=%0d", id_ex_jump_cycles);
            $display("PROFILE: id_ex_jal_cycles=%0d", id_ex_jal_cycles);
            $display("PROFILE: id_ex_jalr_cycles=%0d", id_ex_jalr_cycles);
            $display("PROFILE: id_ex_csr_cycles=%0d", id_ex_csr_cycles);
            $display("PROFILE: id_ex_mul_cycles=%0d", id_ex_mul_cycles);
            $display("PROFILE: id_ex_mulh_cycles=%0d", id_ex_mulh_cycles);
            $display("PROFILE: id_ex_mulhsu_cycles=%0d", id_ex_mulhsu_cycles);
            $display("PROFILE: id_ex_mulhu_cycles=%0d", id_ex_mulhu_cycles);
            $display("PROFILE: id_ex_div_cycles=%0d", id_ex_div_cycles);
            $display("PROFILE: id_ex_divu_cycles=%0d", id_ex_divu_cycles);
            $display("PROFILE: id_ex_rem_cycles=%0d", id_ex_rem_cycles);
            $display("PROFILE: id_ex_remu_cycles=%0d", id_ex_remu_cycles);
            $display("PROFILE: pc_startup_cycles=%0d", pc_startup_cycles);
            $display("PROFILE: pc_calc_cycles=%0d", pc_calc_cycles);
            $display("PROFILE: pc_list_cycles=%0d", pc_list_cycles);
            $display("PROFILE: pc_list_init_cycles=%0d", pc_list_init_cycles);
            $display("PROFILE: pc_list_runtime_cycles=%0d", pc_list_runtime_cycles);
            $display("PROFILE: pc_iterate_cycles=%0d", pc_iterate_cycles);
            $display("PROFILE: pc_main_cycles=%0d", pc_main_cycles);
            $display("PROFILE: pc_matrix_cycles=%0d", pc_matrix_cycles);
            $display("PROFILE: pc_matrix_test_cycles=%0d", pc_matrix_test_cycles);
            $display("PROFILE: pc_core_bench_matrix_cycles=%0d", pc_core_bench_matrix_cycles);
            $display("PROFILE: pc_core_init_matrix_cycles=%0d", pc_core_init_matrix_cycles);
            $display("PROFILE: pc_matrix_sum_cycles=%0d", pc_matrix_sum_cycles);
            $display("PROFILE: pc_matrix_mul_const_cycles=%0d", pc_matrix_mul_const_cycles);
            $display("PROFILE: pc_matrix_add_const_cycles=%0d", pc_matrix_add_const_cycles);
            $display("PROFILE: pc_matrix_mul_vect_cycles=%0d", pc_matrix_mul_vect_cycles);
            $display("PROFILE: pc_matrix_mul_matrix_cycles=%0d", pc_matrix_mul_matrix_cycles);
            $display("PROFILE: pc_matrix_bitextract_cycles=%0d", pc_matrix_bitextract_cycles);
            $display("PROFILE: pc_state_cycles=%0d", pc_state_cycles);
            $display("PROFILE: pc_core_init_state_cycles=%0d", pc_core_init_state_cycles);
            $display("PROFILE: pc_state_transition_cycles=%0d", pc_state_transition_cycles);
            $display("PROFILE: pc_core_bench_state_cycles=%0d", pc_core_bench_state_cycles);
            $display("PROFILE: pc_crc_cycles=%0d", pc_crc_cycles);
            $display("PROFILE: pc_port_cycles=%0d", pc_port_cycles);
            $display("PROFILE: pc_unknown_cycles=%0d", pc_unknown_cycles);
            for (hist_j = 0; hist_j < 40; hist_j = hist_j + 1) begin
                hist_top_count = 0;
                hist_top_index = 0;
                for (hist_i = 0; hist_i < 65536; hist_i = hist_i + 1) begin
                    if (pc_exec_bins[hist_i] > hist_top_count) begin
                        hist_top_count = pc_exec_bins[hist_i];
                        hist_top_index = hist_i;
                    end
                end
                if (hist_top_count != 0) begin
                    $display("PROFILE: pc_top rank=%0d pc=%08x cycles=%0d",
                             hist_j, hist_top_index * 4, hist_top_count);
                    pc_exec_bins[hist_top_index] = 0;
                end
            end
            $display("PROFILE: id_branch_decode_candidate_cycles=%0d", id_branch_decode_candidate_cycles);
            $display("PROFILE: id_branch_decode_ready_cycles=%0d", id_branch_decode_ready_cycles);
            $display("PROFILE: id_branch_decode_pending_cycles=%0d", id_branch_decode_pending_cycles);
            $display("PROFILE: id_branch_decode_redirect_cycles=%0d", id_branch_decode_redirect_cycles);
            $display("PROFILE: id_branch_decode_rs1_pending_cycles=%0d", id_branch_decode_rs1_pending_cycles);
            $display("PROFILE: id_branch_decode_rs2_pending_cycles=%0d", id_branch_decode_rs2_pending_cycles);
            $display("PROFILE: id_branch_decode_rs1_idex_pending_cycles=%0d", id_branch_decode_rs1_idex_pending_cycles);
            $display("PROFILE: id_branch_decode_rs2_idex_pending_cycles=%0d", id_branch_decode_rs2_idex_pending_cycles);
            $display("PROFILE: id_branch_decode_rs1_exmem_pending_cycles=%0d", id_branch_decode_rs1_exmem_pending_cycles);
            $display("PROFILE: id_branch_decode_rs2_exmem_pending_cycles=%0d", id_branch_decode_rs2_exmem_pending_cycles);
            $display("PROFILE: id_beq_decode_candidate_cycles=%0d", id_beq_decode_candidate_cycles);
            $display("PROFILE: id_bne_decode_candidate_cycles=%0d", id_bne_decode_candidate_cycles);
            $display("PROFILE: id_blt_decode_candidate_cycles=%0d", id_blt_decode_candidate_cycles);
            $display("PROFILE: id_bge_decode_candidate_cycles=%0d", id_bge_decode_candidate_cycles);
            $display("PROFILE: id_bltu_decode_candidate_cycles=%0d", id_bltu_decode_candidate_cycles);
            $display("PROFILE: id_bgeu_decode_candidate_cycles=%0d", id_bgeu_decode_candidate_cycles);
            $display("PROFILE: id_beq_decode_pending_cycles=%0d", id_beq_decode_pending_cycles);
            $display("PROFILE: id_bne_decode_pending_cycles=%0d", id_bne_decode_pending_cycles);
            $display("PROFILE: id_blt_decode_pending_cycles=%0d", id_blt_decode_pending_cycles);
            $display("PROFILE: id_bge_decode_pending_cycles=%0d", id_bge_decode_pending_cycles);
            $display("PROFILE: id_bltu_decode_pending_cycles=%0d", id_bltu_decode_pending_cycles);
            $display("PROFILE: id_bgeu_decode_pending_cycles=%0d", id_bgeu_decode_pending_cycles);
            $finish;
        end

        // Timeout remains fatal so CI logs do not silently pass partial runs.
        if (cycle > max_cycles_runtime) begin
            $display("\nFAIL: coremark timeout at PC=%h after %0d cycles", debug_pc, cycle);
            $fatal(1, "\nFAIL: coremark timeout");
        end
    end
end

initial begin
    // Initialize counters and expected UART signatures before releasing reset.
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    uart_count = 0;
    max_cycles_runtime = MAX_CYCLES;
    valid_match_idx = 0;
    score_match_idx = 0;
    stall_decode_cycles = 0;
    mem_wait_cycles = 0;
    ex_trap_valid_cycles = 0;
    ex_mret_valid_cycles = 0;
    ex_branch_redirect_cycles = 0;
    ex_beq_redirect_cycles = 0;
    ex_bne_redirect_cycles = 0;
    ex_blt_redirect_cycles = 0;
    ex_bge_redirect_cycles = 0;
    ex_bltu_redirect_cycles = 0;
    ex_bgeu_redirect_cycles = 0;
    ex_jal_redirect_cycles = 0;
    ex_jalr_redirect_cycles = 0;
    ex_fetch_redirect_valid_cycles = 0;
    fetch_queue_empty_cycles = 0;
    fetch_redirect_reuse_cycles = 0;
    fetch_redirect_reuse_miss_cycles = 0;
    fetch_redirect_buf0_hit_cycles = 0;
    fetch_redirect_buf1_hit_cycles = 0;
    id_ex_valid_cycles = 0;
    id_ex_load_cycles = 0;
    id_ex_store_cycles = 0;
    id_ex_branch_cycles = 0;
    id_ex_jump_cycles = 0;
    id_ex_jal_cycles = 0;
    id_ex_jalr_cycles = 0;
    id_ex_csr_cycles = 0;
    id_ex_mul_cycles = 0;
    id_ex_mulh_cycles = 0;
    id_ex_mulhsu_cycles = 0;
    id_ex_mulhu_cycles = 0;
    id_ex_div_cycles = 0;
    id_ex_divu_cycles = 0;
    id_ex_rem_cycles = 0;
    id_ex_remu_cycles = 0;
    pc_startup_cycles = 0;
    pc_calc_cycles = 0;
    pc_list_cycles = 0;
    pc_list_init_cycles = 0;
    pc_list_runtime_cycles = 0;
    pc_iterate_cycles = 0;
    pc_main_cycles = 0;
    pc_matrix_cycles = 0;
    pc_matrix_test_cycles = 0;
    pc_core_bench_matrix_cycles = 0;
    pc_core_init_matrix_cycles = 0;
    pc_matrix_sum_cycles = 0;
    pc_matrix_mul_const_cycles = 0;
    pc_matrix_add_const_cycles = 0;
    pc_matrix_mul_vect_cycles = 0;
    pc_matrix_mul_matrix_cycles = 0;
    pc_matrix_bitextract_cycles = 0;
    pc_state_cycles = 0;
    pc_core_init_state_cycles = 0;
    pc_state_transition_cycles = 0;
    pc_core_bench_state_cycles = 0;
    pc_crc_cycles = 0;
    pc_port_cycles = 0;
    pc_unknown_cycles = 0;
    for (hist_i = 0; hist_i < 65536; hist_i = hist_i + 1) begin
        pc_exec_bins[hist_i] = 0;
    end
    hist_j = 0;
    hist_top_count = 0;
    hist_top_index = 0;
    id_branch_decode_candidate_cycles = 0;
    id_branch_decode_ready_cycles = 0;
    id_branch_decode_pending_cycles = 0;
    id_branch_decode_redirect_cycles = 0;
    id_branch_decode_rs1_pending_cycles = 0;
    id_branch_decode_rs2_pending_cycles = 0;
    id_branch_decode_rs1_idex_pending_cycles = 0;
    id_branch_decode_rs2_idex_pending_cycles = 0;
    id_branch_decode_rs1_exmem_pending_cycles = 0;
    id_branch_decode_rs2_exmem_pending_cycles = 0;
    id_beq_decode_candidate_cycles = 0;
    id_bne_decode_candidate_cycles = 0;
    id_blt_decode_candidate_cycles = 0;
    id_bge_decode_candidate_cycles = 0;
    id_bltu_decode_candidate_cycles = 0;
    id_bgeu_decode_candidate_cycles = 0;
    id_beq_decode_pending_cycles = 0;
    id_bne_decode_pending_cycles = 0;
    id_blt_decode_pending_cycles = 0;
    id_bge_decode_pending_cycles = 0;
    id_bltu_decode_pending_cycles = 0;
    id_bgeu_decode_pending_cycles = 0;
    valid_found = 1'b0;
    score_found = 1'b0;

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

    #100;
    rst_n = 1'b1;

    $display("Starting CoreMark profiling simulation (MAX_CYCLES=%0d)...", max_cycles_runtime);
end

endmodule

module YH_rv_cpu_coremark_profile_rv32_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex";
localparam string ROM_MEM32_HEX = "build/sw/YH_rv_cpu_coremark_rv32.mem32.hex";

YH_rv_cpu_coremark_profile_tb #(
    .XLEN(32),
    .ROM_HEX(ROM_HEX),
    .ROM_MEM32_HEX(ROM_MEM32_HEX)
) uut ();

endmodule

module YH_rv_cpu_coremark_profile_rv64_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv64.hex";

YH_rv_cpu_coremark_profile_tb #(
    .XLEN(64),
    .ROM_HEX(ROM_HEX)
) uut ();

endmodule
