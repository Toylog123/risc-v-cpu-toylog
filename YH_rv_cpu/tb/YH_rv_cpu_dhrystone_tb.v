`timescale 1ns / 1ps

module YH_rv_cpu_dhrystone_tb #(
    parameter string ROM_HEX = "build/sw/YH_rv_cpu_dhrystone.hex",
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 0,
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1
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
reg     profile_seen_timer_reset;
reg     profile_active;
reg [31:0] profile_pc_counts [0:4095];

YH_rv_cpu_soc #(
    .SYNC_DMEM(1),
    .DMEM_NEGEDGE_READ(1),
    .RAM_BASE(32'h0001_0000),
    .RAM_BYTES(16384),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION),
    .ENABLE_XTHEAD_COND_MOVE(ENABLE_XTHEAD_COND_MOVE),
    .ENABLE_ID_BRANCH_EX_FORWARD(ENABLE_ID_BRANCH_EX_FORWARD),
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

        if (profile_pc) begin
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
            end else if (profile_active && debug_pc[31:14] == 18'd0) begin
                profile_cycles <= profile_cycles + 1;
                profile_pc_counts[debug_pc[13:2]] <= profile_pc_counts[debug_pc[13:2]] + 1;
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
    profile_seen_timer_reset = 1'b0;
    profile_active = 1'b0;
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
