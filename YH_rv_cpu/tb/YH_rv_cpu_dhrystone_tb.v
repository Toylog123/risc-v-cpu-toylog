`timescale 1ns / 1ps

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_dhrystone_tb #(
    parameter string ROM_HEX = "build/sw/YH_rv_cpu_dhrystone.hex",
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_CRC_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_MUL_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 0,
    parameter integer ENABLE_XTHEAD_ADDSL_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_MEMPAIR_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_BASE_UPDATE_EXTENSION = 1,
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1,
    parameter integer ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD = 1,
    parameter integer ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD = 1,
    parameter integer ENABLE_ID_BRANCH_FOLD = 0,
    parameter integer ENABLE_ID_BRANCH_FOLD_LIGHT_DECODE = 0,
    parameter integer ENABLE_REDIRECT_CACHE_FOLD_PREDECODE = 0,
    parameter integer ENABLE_ID_BRANCH_NOT_TAKEN_FOLD = 1,
    parameter integer ENABLE_ID_BRANCH_NOT_TAKEN_FOLD_DELAYED = 0,
    parameter integer ENABLE_ID_BRANCH_FOLD_NEXT_CACHE = 1,
    parameter integer ENABLE_EX_REDIRECT_FOLD = 1,
    parameter integer ENABLE_ID_BRANCH_NT_NEXT_CACHE = 1,
    parameter integer ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD = 0,
    parameter integer ENABLE_ID_ALU_PAIR_FOLD = 0,
    parameter integer ENABLE_ID_ALU_DEP_FOLD = 0,
    parameter integer ENABLE_REDIRECT_TARGET_CACHE = 1,
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP = 1,
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP = 0,
    parameter integer ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK = 0,
    parameter integer ENABLE_REDIRECT_CACHE_UPDATE_ON_REDIRECT = 0,
    parameter integer ENABLE_FETCH_REDIRECT_REUSE = 0,
    parameter integer ENABLE_FETCH_LIVE_BYPASS = 1,
    parameter integer ENABLE_FETCH_REDIRECT_SAME_CYCLE_REQ = 1,
    parameter integer ENABLE_REDIRECT_CACHE_HIT_EXTRA_IMEM_REQ = 0,
    parameter integer ENABLE_REDIRECT_CACHE_PC_SKIP = 1,
    parameter integer ENABLE_IF_ID_PAYLOAD_SIMPLE_CE = 0,
    parameter integer REDIRECT_CACHE_ENTRIES = 1024,
    parameter integer REDIRECT_CACHE_XOR_INDEX = 0,
    parameter integer ENABLE_DYNAMIC_BRANCH_PREDICT = 0,
    parameter integer BRANCH_BHT_ENTRIES = 64,
    parameter integer BRANCH_STATIC_PREDICT_MODE = 0,
    parameter integer BRANCH_BHT_STRONG_ONLY = 0,
    parameter integer BRANCH_BHT_DIRECT_UPDATE = 0,
    parameter integer DMEM_NEGEDGE_READ = 0,
    parameter integer DMEM_READ_PREISSUE = 0,
    parameter integer DCACHE_EN = 0,
    parameter integer DCACHE_SIZE_BYTES = 4096,
    parameter integer ENABLE_DCACHE_LOAD_USE_SPEC = 0,
    parameter integer ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_FOLD_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_FOLD_EXMEM_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_EXMEM_LOAD_MUL_FORWARD = 1,
    parameter integer ENABLE_DCACHE_NEXT_PREFETCH = 0,
    parameter integer ENABLE_DCACHE_WORD_ONLY = 0,
    parameter integer ICACHE_EN = 0,
    parameter integer ROM_BYTES = 16384,
    parameter integer RAM_BYTES = 16384
);

localparam integer MAX_CYCLES = 250000000;

reg         clk;
reg         rst_n;
wire        trap;
wire [31:0] debug_pc;
wire        uart_tx_valid;
wire [7:0]  uart_tx_data;
wire        done;
wire        timer_irq;

integer cycle;
integer max_cycles_runtime;
integer func2_trace_count;
integer event_trace_count;
integer dhrystone_runs_runtime;
integer pc_index;
integer profile_timer_reads;
integer profile_cycles;
integer profile_print_index;
reg     trace_func2;
reg     trace_boot_zero;
reg     profile_pc;
reg     profile_pipe;
reg     profile_seen_timer_reset;
reg     profile_active;
reg [31:0] profile_pc_counts [0:4095];
integer profile_pipe_stall_decode_cycles;
integer profile_pipe_mem_wait_cycles;
integer profile_pipe_ex_redirect_cycles;
integer profile_pipe_decode_redirect_cycles;
integer profile_pipe_branch_predict_redirect_cycles;
integer profile_pipe_jal_predict_redirect_cycles;
integer profile_pipe_decode_flush_cycles;
integer profile_pipe_ex_decode_flush_cycles;
integer profile_pipe_if_id_invalid_cycles;
integer profile_pipe_if_id_bubble_cycles;
integer profile_pipe_id_ex_valid_cycles;
integer profile_pipe_id_ex_load_cycles;
integer profile_pipe_id_ex_store_cycles;
integer profile_pipe_id_ex_branch_cycles;
integer profile_pipe_id_ex_jump_cycles;
integer profile_pipe_id_ex_mul_cycles;
integer profile_pipe_id_ex_mulh_cycles;
integer profile_pipe_id_ex_mulhsu_cycles;
integer profile_pipe_id_ex_mulhu_cycles;
integer profile_pipe_id_ex_div_cycles;
integer profile_pipe_id_ex_divu_cycles;
integer profile_pipe_id_ex_rem_cycles;
integer profile_pipe_id_ex_remu_cycles;

YH_rv_cpu_soc #(
    .SYNC_DMEM(1),
    .DMEM_NEGEDGE_READ(DMEM_NEGEDGE_READ),
    .DMEM_READ_PREISSUE(DMEM_READ_PREISSUE),
    .DCACHE_EN(DCACHE_EN),
    .DCACHE_SIZE_BYTES(DCACHE_SIZE_BYTES),
    .ENABLE_DCACHE_LOAD_USE_SPEC(ENABLE_DCACHE_LOAD_USE_SPEC),
    .ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC(ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC),
    .ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC(ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC),
    .ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC(ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC),
    .ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC(ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC),
    .ENABLE_FOLD_DCACHE_LOAD_USE_SPEC(ENABLE_FOLD_DCACHE_LOAD_USE_SPEC),
    .ENABLE_FOLD_EXMEM_LOAD_USE_SPEC(ENABLE_FOLD_EXMEM_LOAD_USE_SPEC),
    .ENABLE_EXMEM_LOAD_MUL_FORWARD(ENABLE_EXMEM_LOAD_MUL_FORWARD),
    .ENABLE_DCACHE_NEXT_PREFETCH(ENABLE_DCACHE_NEXT_PREFETCH),
    .ENABLE_DCACHE_WORD_ONLY(ENABLE_DCACHE_WORD_ONLY),
    .ICACHE_EN(ICACHE_EN),
    .RAM_BASE(32'h0001_0000),
    .RAM_BYTES(RAM_BYTES),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION),
    .ENABLE_XTHEAD_CRC_EXTENSION(ENABLE_XTHEAD_CRC_EXTENSION),
    .ENABLE_XTHEAD_MUL_EXTENSION(ENABLE_XTHEAD_MUL_EXTENSION),
    .ENABLE_XTHEAD_COND_MOVE(ENABLE_XTHEAD_COND_MOVE),
    .ENABLE_XTHEAD_ADDSL_EXTENSION(ENABLE_XTHEAD_ADDSL_EXTENSION),
    .ENABLE_XTHEAD_MEMPAIR_EXTENSION(ENABLE_XTHEAD_MEMPAIR_EXTENSION),
    .ENABLE_XTHEAD_BASE_UPDATE_EXTENSION(ENABLE_XTHEAD_BASE_UPDATE_EXTENSION),
    .ENABLE_ID_BRANCH_EX_FORWARD(ENABLE_ID_BRANCH_EX_FORWARD),
    .ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD(ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD),
    .ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD(ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD),
    .ENABLE_ID_BRANCH_FOLD(ENABLE_ID_BRANCH_FOLD),
    .ENABLE_ID_BRANCH_FOLD_LIGHT_DECODE(ENABLE_ID_BRANCH_FOLD_LIGHT_DECODE),
    .ENABLE_REDIRECT_CACHE_FOLD_PREDECODE(ENABLE_REDIRECT_CACHE_FOLD_PREDECODE),
    .ENABLE_ID_BRANCH_NOT_TAKEN_FOLD(ENABLE_ID_BRANCH_NOT_TAKEN_FOLD),
    .ENABLE_ID_BRANCH_NOT_TAKEN_FOLD_DELAYED(ENABLE_ID_BRANCH_NOT_TAKEN_FOLD_DELAYED),
    .ENABLE_ID_BRANCH_FOLD_NEXT_CACHE(ENABLE_ID_BRANCH_FOLD_NEXT_CACHE),
    .ENABLE_EX_REDIRECT_FOLD(ENABLE_EX_REDIRECT_FOLD),
    .ENABLE_ID_BRANCH_NT_NEXT_CACHE(ENABLE_ID_BRANCH_NT_NEXT_CACHE),
    .ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD(ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD),
    .ENABLE_ID_ALU_PAIR_FOLD(ENABLE_ID_ALU_PAIR_FOLD),
    .ENABLE_ID_ALU_DEP_FOLD(ENABLE_ID_ALU_DEP_FOLD),
    .ENABLE_REDIRECT_TARGET_CACHE(ENABLE_REDIRECT_TARGET_CACHE),
    .ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP(ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP),
    .ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP(ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP),
    .ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK(ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK),
    .ENABLE_REDIRECT_CACHE_UPDATE_ON_REDIRECT(ENABLE_REDIRECT_CACHE_UPDATE_ON_REDIRECT),
    .ENABLE_FETCH_REDIRECT_REUSE(ENABLE_FETCH_REDIRECT_REUSE),
    .ENABLE_FETCH_LIVE_BYPASS(ENABLE_FETCH_LIVE_BYPASS),
    .ENABLE_FETCH_REDIRECT_SAME_CYCLE_REQ(ENABLE_FETCH_REDIRECT_SAME_CYCLE_REQ),
    .ENABLE_REDIRECT_CACHE_HIT_EXTRA_IMEM_REQ(ENABLE_REDIRECT_CACHE_HIT_EXTRA_IMEM_REQ),
    .ENABLE_REDIRECT_CACHE_PC_SKIP(ENABLE_REDIRECT_CACHE_PC_SKIP),
    .ENABLE_IF_ID_PAYLOAD_SIMPLE_CE(ENABLE_IF_ID_PAYLOAD_SIMPLE_CE),
    .REDIRECT_CACHE_ENTRIES(REDIRECT_CACHE_ENTRIES),
    .REDIRECT_CACHE_XOR_INDEX(REDIRECT_CACHE_XOR_INDEX),
    .ENABLE_DYNAMIC_BRANCH_PREDICT(ENABLE_DYNAMIC_BRANCH_PREDICT),
    .BRANCH_BHT_ENTRIES(BRANCH_BHT_ENTRIES),
    .BRANCH_STATIC_PREDICT_MODE(BRANCH_STATIC_PREDICT_MODE),
    .BRANCH_BHT_STRONG_ONLY(BRANCH_BHT_STRONG_ONLY),
    .BRANCH_BHT_DIRECT_UPDATE(BRANCH_BHT_DIRECT_UPDATE),
    .ROM_BYTES(ROM_BYTES),
    .ROM_INIT_HEX(ROM_HEX)
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

        if (cycle > 0 && cycle % 1000000 == 0) begin
            $display(
                "CYCLE=%0d PC=%h a0=%h a1=%h sp=%h ra=%h mem_wait=%b dcache_wait=%b ex_mem_valid=%b ex_mem_store=%b ex_wstrb=%h dmem_ready=%b",
                cycle,
                debug_pc,
                dut.u_cpu.u_regfile.regs[10],
                dut.u_cpu.u_regfile.regs[11],
                dut.u_cpu.u_regfile.regs[2],
                dut.u_cpu.u_regfile.regs[1],
                dut.u_cpu.mem_wait,
                dut.u_cpu.dcache_cpu_wait,
                dut.u_cpu.ex_mem_valid_r,
                dut.u_cpu.ex_mem_store_r,
                dut.u_cpu.ex_mem_store_wstrb_r,
                dut.u_cpu.dmem_ready
            );
        end

        if (uart_tx_valid) begin
            $write("%c", uart_tx_data);
        end

        if (profile_pc || profile_pipe) begin
            if (dut.dmem_write_en &&
                (dut.dmem_mmio_addr32 == 32'h1000_0018) &&
                dut.dmem_mmio_wdata32[1]) begin
                profile_seen_timer_reset <= 1'b1;
                profile_active <= 1'b0;
                profile_timer_reads <= 0;
                profile_cycles <= 0;
            end else if (profile_seen_timer_reset &&
                         dut.dmem_read_accept &&
                         ((dut.dmem_mmio_addr32 == 32'h1000_0008) ||
                          (dut.dmem_mmio_addr32 == 32'h1000_000c))) begin
                if (profile_active) begin
                    profile_active <= 1'b0;
                end else begin
                    profile_timer_reads <= profile_timer_reads + 1;
                    if (profile_timer_reads >= 2) begin
                        profile_active <= 1'b1;
                    end
                end
            end else if (profile_active) begin
                profile_cycles <= profile_cycles + 1;
                if (profile_pc && debug_pc[31:14] == 18'd0) begin
                    profile_pc_counts[debug_pc[13:2]] <= profile_pc_counts[debug_pc[13:2]] + 1;
                end
                if (profile_pipe) begin
                    if (dut.u_cpu.stall_decode) begin
                        profile_pipe_stall_decode_cycles <= profile_pipe_stall_decode_cycles + 1;
                    end
                    if (dut.u_cpu.mem_wait) begin
                        profile_pipe_mem_wait_cycles <= profile_pipe_mem_wait_cycles + 1;
                    end
                    if (dut.u_cpu.ex_redirect_valid) begin
                        profile_pipe_ex_redirect_cycles <= profile_pipe_ex_redirect_cycles + 1;
                    end
                    if (dut.u_cpu.id_decode_redirect_valid) begin
                        profile_pipe_decode_redirect_cycles <= profile_pipe_decode_redirect_cycles + 1;
                    end
                    if (dut.u_cpu.id_branch_predict_redirect_valid) begin
                        profile_pipe_branch_predict_redirect_cycles <= profile_pipe_branch_predict_redirect_cycles + 1;
                    end
                    if (dut.u_cpu.id_jal_predict_redirect_valid) begin
                        profile_pipe_jal_predict_redirect_cycles <= profile_pipe_jal_predict_redirect_cycles + 1;
                    end
                    if (dut.u_cpu.decode_flush_valid) begin
                        profile_pipe_decode_flush_cycles <= profile_pipe_decode_flush_cycles + 1;
                    end
                    if (dut.u_cpu.ex_decode_flush_valid) begin
                        profile_pipe_ex_decode_flush_cycles <= profile_pipe_ex_decode_flush_cycles + 1;
                    end
                    if (!dut.u_cpu.if_id_valid_r) begin
                        profile_pipe_if_id_invalid_cycles <= profile_pipe_if_id_invalid_cycles + 1;
                    end
                    if (dut.u_cpu.if_id_load_bubble) begin
                        profile_pipe_if_id_bubble_cycles <= profile_pipe_if_id_bubble_cycles + 1;
                    end
                    if (dut.u_cpu.id_ex_valid_r) begin
                        profile_pipe_id_ex_valid_cycles <= profile_pipe_id_ex_valid_cycles + 1;
                        if (dut.u_cpu.id_ex_load_r) begin
                            profile_pipe_id_ex_load_cycles <= profile_pipe_id_ex_load_cycles + 1;
                        end
                        if (dut.u_cpu.id_ex_store_r) begin
                            profile_pipe_id_ex_store_cycles <= profile_pipe_id_ex_store_cycles + 1;
                        end
                        if (dut.u_cpu.id_ex_branch_r) begin
                            profile_pipe_id_ex_branch_cycles <= profile_pipe_id_ex_branch_cycles + 1;
                        end
                        if (dut.u_cpu.id_ex_jump_r) begin
                            profile_pipe_id_ex_jump_cycles <= profile_pipe_id_ex_jump_cycles + 1;
                        end
                        case (dut.u_cpu.id_ex_alu_op_r)
                            `YH_rv_cpu_ALU_MUL:   profile_pipe_id_ex_mul_cycles <= profile_pipe_id_ex_mul_cycles + 1;
                            `YH_rv_cpu_ALU_MULH:  profile_pipe_id_ex_mulh_cycles <= profile_pipe_id_ex_mulh_cycles + 1;
                            `YH_rv_cpu_ALU_MULHSU: profile_pipe_id_ex_mulhsu_cycles <= profile_pipe_id_ex_mulhsu_cycles + 1;
                            `YH_rv_cpu_ALU_MULHU: profile_pipe_id_ex_mulhu_cycles <= profile_pipe_id_ex_mulhu_cycles + 1;
                            `YH_rv_cpu_ALU_DIV:   profile_pipe_id_ex_div_cycles <= profile_pipe_id_ex_div_cycles + 1;
                            `YH_rv_cpu_ALU_DIVU:  profile_pipe_id_ex_divu_cycles <= profile_pipe_id_ex_divu_cycles + 1;
                            `YH_rv_cpu_ALU_REM:   profile_pipe_id_ex_rem_cycles <= profile_pipe_id_ex_rem_cycles + 1;
                            `YH_rv_cpu_ALU_REMU:  profile_pipe_id_ex_remu_cycles <= profile_pipe_id_ex_remu_cycles + 1;
                            default: begin
                            end
                        endcase
                    end
                end
            end
        end

        if (((dut.u_cpu.ex_interrupt_valid) || (dut.u_cpu.ex_mret_valid) || (dut.u_cpu.ex_sync_trap_valid)) &&
            (event_trace_count < 32)) begin
            $display(
                "EVENT cycle=%0d pc=%h irq=%b mret=%b sync_trap=%b trap=%b mepc=%h mtvec=%h",
                cycle,
                debug_pc,
                dut.u_cpu.ex_interrupt_valid,
                dut.u_cpu.ex_mret_valid,
                dut.u_cpu.ex_sync_trap_valid,
                trap,
                dut.u_cpu.csr_mepc_r,
                dut.u_cpu.csr_mtvec_r
            );
            event_trace_count <= event_trace_count + 1;
        end

        if (trace_func2 && (debug_pc == 32'h0000_096c) && (func2_trace_count < 16)) begin
            $display(
                "TRACE_FUNC2 cycle=%0d a0=%h s2=%h s0=%h s1=%h mem_s0_word=%h mem_s1_word=%h",
                cycle,
                dut.u_cpu.u_regfile.regs[10],
                dut.u_cpu.u_regfile.regs[18],
                dut.u_cpu.u_regfile.regs[8],
                dut.u_cpu.u_regfile.regs[9],
                dut.u_dmem_ram.g_sync_ram.ram_mem[(dut.u_cpu.u_regfile.regs[8] - 32'h0001_0000) >> 2],
                dut.u_dmem_ram.g_sync_ram.ram_mem[(dut.u_cpu.u_regfile.regs[9] - 32'h0001_0000) >> 2]
            );
            func2_trace_count <= func2_trace_count + 1;
        end

        if (trap) begin
            $fatal(1, "\nFAIL: dhrystone trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (done) begin
            if (profile_pc) begin
                $display("PROFILE_PC_BEGIN cycles=%0d", profile_cycles);
                for (profile_print_index = 0; profile_print_index < 4096; profile_print_index = profile_print_index + 1) begin
                    if (profile_pc_counts[profile_print_index] != 0) begin
                        $display("PROFILE_PC pc=%08h count=%0d", profile_print_index << 2, profile_pc_counts[profile_print_index]);
                    end
                end
                $display("PROFILE_PC_END");
            end
            if (profile_pipe) begin
                $display("PROFILE_PIPE_BEGIN cycles=%0d", profile_cycles);
                $display("PROFILE_PIPE stall_decode=%0d", profile_pipe_stall_decode_cycles);
                $display("PROFILE_PIPE mem_wait=%0d", profile_pipe_mem_wait_cycles);
                $display("PROFILE_PIPE ex_redirect=%0d", profile_pipe_ex_redirect_cycles);
                $display("PROFILE_PIPE decode_redirect=%0d", profile_pipe_decode_redirect_cycles);
                $display("PROFILE_PIPE branch_predict_redirect=%0d", profile_pipe_branch_predict_redirect_cycles);
                $display("PROFILE_PIPE jal_predict_redirect=%0d", profile_pipe_jal_predict_redirect_cycles);
                $display("PROFILE_PIPE decode_flush=%0d", profile_pipe_decode_flush_cycles);
                $display("PROFILE_PIPE ex_decode_flush=%0d", profile_pipe_ex_decode_flush_cycles);
                $display("PROFILE_PIPE if_id_invalid=%0d", profile_pipe_if_id_invalid_cycles);
                $display("PROFILE_PIPE if_id_bubble=%0d", profile_pipe_if_id_bubble_cycles);
                $display("PROFILE_PIPE id_ex_valid=%0d", profile_pipe_id_ex_valid_cycles);
                $display("PROFILE_PIPE id_ex_load=%0d", profile_pipe_id_ex_load_cycles);
                $display("PROFILE_PIPE id_ex_store=%0d", profile_pipe_id_ex_store_cycles);
                $display("PROFILE_PIPE id_ex_branch=%0d", profile_pipe_id_ex_branch_cycles);
                $display("PROFILE_PIPE id_ex_jump=%0d", profile_pipe_id_ex_jump_cycles);
                $display("PROFILE_PIPE id_ex_mul=%0d", profile_pipe_id_ex_mul_cycles);
                $display("PROFILE_PIPE id_ex_mulh=%0d", profile_pipe_id_ex_mulh_cycles);
                $display("PROFILE_PIPE id_ex_mulhsu=%0d", profile_pipe_id_ex_mulhsu_cycles);
                $display("PROFILE_PIPE id_ex_mulhu=%0d", profile_pipe_id_ex_mulhu_cycles);
                $display("PROFILE_PIPE id_ex_div=%0d", profile_pipe_id_ex_div_cycles);
                $display("PROFILE_PIPE id_ex_divu=%0d", profile_pipe_id_ex_divu_cycles);
                $display("PROFILE_PIPE id_ex_rem=%0d", profile_pipe_id_ex_rem_cycles);
                $display("PROFILE_PIPE id_ex_remu=%0d", profile_pipe_id_ex_remu_cycles);
                $display("PROFILE_PIPE_END");
            end
            $display("\nPASS: dhrystone completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > max_cycles_runtime) begin
            $fatal(1, "\nFAIL: dhrystone timeout at PC=%h after %0d cycles", debug_pc, cycle);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    func2_trace_count = 0;
    event_trace_count = 0;
    dhrystone_runs_runtime = 0;
    pc_index = 0;
    profile_timer_reads = 0;
    profile_cycles = 0;
    profile_print_index = 0;
    trace_func2 = 1'b0;
    trace_boot_zero = 1'b0;
    profile_pc = 1'b0;
    profile_pipe = 1'b0;
    profile_seen_timer_reset = 1'b0;
    profile_active = 1'b0;
    profile_pipe_stall_decode_cycles = 0;
    profile_pipe_mem_wait_cycles = 0;
    profile_pipe_ex_redirect_cycles = 0;
    profile_pipe_decode_redirect_cycles = 0;
    profile_pipe_branch_predict_redirect_cycles = 0;
    profile_pipe_jal_predict_redirect_cycles = 0;
    profile_pipe_decode_flush_cycles = 0;
    profile_pipe_ex_decode_flush_cycles = 0;
    profile_pipe_if_id_invalid_cycles = 0;
    profile_pipe_if_id_bubble_cycles = 0;
    profile_pipe_id_ex_valid_cycles = 0;
    profile_pipe_id_ex_load_cycles = 0;
    profile_pipe_id_ex_store_cycles = 0;
    profile_pipe_id_ex_branch_cycles = 0;
    profile_pipe_id_ex_jump_cycles = 0;
    profile_pipe_id_ex_mul_cycles = 0;
    profile_pipe_id_ex_mulh_cycles = 0;
    profile_pipe_id_ex_mulhsu_cycles = 0;
    profile_pipe_id_ex_mulhu_cycles = 0;
    profile_pipe_id_ex_div_cycles = 0;
    profile_pipe_id_ex_divu_cycles = 0;
    profile_pipe_id_ex_rem_cycles = 0;
    profile_pipe_id_ex_remu_cycles = 0;
    max_cycles_runtime = MAX_CYCLES;

    for (pc_index = 0; pc_index < 4096; pc_index = pc_index + 1) begin
        profile_pc_counts[pc_index] = 0;
    end

    if (!$value$plusargs("max_cycles=%d", max_cycles_runtime)) begin
        max_cycles_runtime = MAX_CYCLES;
    end
    if (!$value$plusargs("dhrystone_runs=%d", dhrystone_runs_runtime)) begin
        dhrystone_runs_runtime = 0;
    end
    if ($test$plusargs("trace_func2")) begin
        trace_func2 = 1'b1;
    end
    if ($test$plusargs("trace_boot_zero")) begin
        trace_boot_zero = 1'b1;
    end
    if ($test$plusargs("profile_pc")) begin
        profile_pc = 1'b1;
    end
    if ($test$plusargs("profile_pipe")) begin
        profile_pipe = 1'b1;
    end
    if ($test$plusargs("dump_vcd")) begin
        $dumpfile("YH_rv_cpu_dhrystone_tb.vcd");
        $dumpvars(0, YH_rv_cpu_dhrystone_tb);
    end

    #100;
    rst_n = 1'b1;

    $display("Starting Dhrystone simulation (MAX_CYCLES=%0d)...", max_cycles_runtime);
    if (dhrystone_runs_runtime > 0) begin
        $display("DHRYSTONE_RUNS=%0d", dhrystone_runs_runtime);
    end
end

endmodule
