`timescale 1ns / 1ps

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
wire ex_fetch_redirect_valid;
wire fetch_queue_empty;

reg [7:0] valid_msg [0:VALID_MSG_LEN-1];
reg [7:0] score_msg [0:SCORE_MSG_LEN-1];
integer cycle;
integer uart_count;
integer max_cycles_runtime;
integer valid_match_idx;
integer score_match_idx;
integer stall_decode_cycles;
integer mem_wait_cycles;
integer ex_fetch_redirect_valid_cycles;
integer fetch_queue_empty_cycles;
reg     valid_found;
reg     score_found;

YH_rv_cpu_soc #(
    .XLEN(XLEN),
    .SYNC_IMEM(1),
    .IMEM_OUTPUT_REG(0),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(0),
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
assign ex_fetch_redirect_valid = dut.u_cpu.ex_fetch_redirect_valid;
assign fetch_queue_empty = !dut.u_cpu.fetch_queue_valid;

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

        if (stall_decode) begin
            stall_decode_cycles <= stall_decode_cycles + 1;
        end

        if (mem_wait) begin
            mem_wait_cycles <= mem_wait_cycles + 1;
        end

        if (ex_fetch_redirect_valid) begin
            ex_fetch_redirect_valid_cycles <= ex_fetch_redirect_valid_cycles + 1;
        end

        if (fetch_queue_empty) begin
            fetch_queue_empty_cycles <= fetch_queue_empty_cycles + 1;
        end

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
            $display("PROFILE: ex_fetch_redirect_valid_cycles=%0d", ex_fetch_redirect_valid_cycles);
            $display("PROFILE: fetch_queue_empty_cycles=%0d", fetch_queue_empty_cycles);
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
    stall_decode_cycles = 0;
    mem_wait_cycles = 0;
    ex_fetch_redirect_valid_cycles = 0;
    fetch_queue_empty_cycles = 0;
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
