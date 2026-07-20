`timescale 1ns / 1ps

module YH_rv_cpu_perf_demo_tb #(
    parameter string ROM_HEX = "build/sw/YH_rv_cpu_perf_demo.hex",
    parameter string ROM_MEM32_HEX = "build/sw/YH_rv_cpu_perf_demo.mem32.hex",
    parameter integer MAX_CYCLES = 20000000
) ();

localparam integer PASS_LEN = 14;

reg         clk;
reg         rst_n;
wire        trap;
wire [31:0] debug_pc;
wire        uart_tx_valid;
wire [7:0]  uart_tx_data;
wire        done;
wire        timer_irq;

reg [7:0] pass_msg [0:PASS_LEN-1];
integer cycle;
integer pass_idx;
integer uart_count;
integer max_cycles_runtime;

YH_rv_cpu_soc #(
    .SYNC_IMEM(1),
    .IMEM_OUTPUT_REG(1),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(0),
    .RAM_BASE(32'h0001_0000),
    .ROM_BYTES(65536),
    .RAM_BYTES(16384),
    .ROM_INIT_HEX(ROM_HEX),
    .ROM_INIT_MEM32_HEX(ROM_MEM32_HEX),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_ZBC_EXTENSION(1),
    .ENABLE_ZICOND_EXTENSION(0),
    .ENABLE_ZBKB_EXTENSION(0),
    .ENABLE_XTHEAD_EXTENSION(1),
    .ENABLE_XTHEAD_CRC_EXTENSION(0),
    .ENABLE_XTHEAD_MUL_EXTENSION(1),
    .ENABLE_XTHEAD_COND_MOVE(1),
    .ENABLE_XTHEAD_ADDSL_EXTENSION(0),
    .ENABLE_XTHEAD_MEMPAIR_EXTENSION(0),
    .ENABLE_XTHEAD_BASE_UPDATE_EXTENSION(0),
    .ENABLE_ID_BRANCH_EX_FORWARD(0),
    .ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD(1),
    .ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD(1),
    .ENABLE_ID_BRANCH_FOLD(1),
    .ENABLE_ID_BRANCH_FOLD_NEXT_CACHE(0),
    .ENABLE_EX_REDIRECT_FOLD(1),
    .ENABLE_ID_BRANCH_NT_NEXT_CACHE(1),
    .ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD(1),
    .ENABLE_ID_ALU_PAIR_FOLD(0),
    .ENABLE_ID_ALU_DEP_FOLD(0),
    .ENABLE_REDIRECT_TARGET_CACHE(1),
    .ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP(1),
    .ENABLE_FETCH_REDIRECT_REUSE(0),
    .REDIRECT_CACHE_ENTRIES(64),
    .REDIRECT_CACHE_XOR_INDEX(0),
    .ENABLE_DYNAMIC_BRANCH_PREDICT(0),
    .BRANCH_BHT_ENTRIES(2),
    .BRANCH_STATIC_PREDICT_MODE(0),
    .BRANCH_BHT_STRONG_ONLY(0),
    .DMEM_NEGEDGE_READ(0),
    .DMEM_READ_PREISSUE(0),
    .DCACHE_EN(1),
    .DCACHE_SIZE_BYTES(512),
    .ENABLE_DCACHE_LOAD_USE_SPEC(1),
    .ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC(1),
    .ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC(1),
    .ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC(0),
    .ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC(0),
    .ENABLE_FOLD_DCACHE_LOAD_USE_SPEC(0),
    .ENABLE_FOLD_EXMEM_LOAD_USE_SPEC(1),
    .ENABLE_DCACHE_NEXT_PREFETCH(0),
    .ENABLE_DCACHE_WORD_ONLY(0),
    .ICACHE_EN(0)
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

            if (pass_idx < PASS_LEN) begin
                if (uart_tx_data == pass_msg[pass_idx]) begin
                    pass_idx <= pass_idx + 1;
                end else if (uart_tx_data == pass_msg[0]) begin
                    pass_idx <= 1;
                end else begin
                    pass_idx <= 0;
                end
            end
        end

        if (trap) begin
            $display("\nFAIL: trap asserted at PC=%h", debug_pc);
            $finish;
        end

        if (done) begin
            if (pass_idx >= PASS_LEN) begin
                $display("\nPASS: perf demo completed at PC=%h in %0d cycles, UART bytes=%0d", debug_pc, cycle, uart_count);
                $finish;
            end

            $display("\nFAIL: DONE without PERF_DEMO PASS at PC=%h, UART bytes=%0d", debug_pc, uart_count);
            $finish;
        end

        if (cycle > max_cycles_runtime) begin
            $display("\nFAIL: timeout at PC=%h after %0d cycles", debug_pc, cycle);
            $finish;
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    pass_idx = 0;
    uart_count = 0;
    max_cycles_runtime = MAX_CYCLES;

    if ($value$plusargs("max_cycles=%d", max_cycles_runtime)) begin
        $display("INFO: max_cycles=%0d", max_cycles_runtime);
    end

    pass_msg[0]  = "P";
    pass_msg[1]  = "E";
    pass_msg[2]  = "R";
    pass_msg[3]  = "F";
    pass_msg[4]  = "_";
    pass_msg[5]  = "D";
    pass_msg[6]  = "E";
    pass_msg[7]  = "M";
    pass_msg[8]  = "O";
    pass_msg[9]  = " ";
    pass_msg[10] = "P";
    pass_msg[11] = "A";
    pass_msg[12] = "S";
    pass_msg[13] = "S";

    #20;
    rst_n = 1'b1;
end

endmodule
