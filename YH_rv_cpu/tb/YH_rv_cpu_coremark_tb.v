`timescale 1ns / 1ps

module YH_rv_cpu_coremark_tb #(
    parameter integer XLEN = 32,
    parameter string ROM_HEX = "build/sw/YH_rv_cpu_coremark_rv32.hex",
    parameter [31:0] RAM_BASE = 32'h0001_0000,
    parameter integer ROM_BYTES = 65536,
    parameter integer RAM_BYTES = 65536,
    parameter integer MAX_CYCLES_DEFAULT = 2000000
) ();

localparam integer VALID_MSG_LEN = 28;
localparam integer SCORE_MSG_LEN = 13;

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
integer max_cycles;
integer valid_match_idx;
integer score_match_idx;
reg     valid_found;
reg     score_found;

YH_rv_cpu_soc #(
    .XLEN(XLEN),
    .SYNC_DMEM(1),
    .RAM_BASE(RAM_BASE),
    .ROM_BYTES(ROM_BYTES),
    .RAM_BYTES(RAM_BYTES),
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

        if (trap) begin
            $fatal(1, "\nFAIL: coremark trap asserted at PC=%h", debug_pc);
        end

        if (done) begin
            if (!valid_found) begin
                $fatal(1, "\nFAIL: coremark missing validation banner at PC=%h", debug_pc);
            end

            if (!score_found) begin
                $fatal(1, "\nFAIL: coremark missing score banner at PC=%h", debug_pc);
            end

            $display("\nPASS: coremark smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > max_cycles) begin
            $fatal(1, "\nFAIL: coremark timeout at PC=%h after %0d cycles", debug_pc, cycle);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    uart_count = 0;
    max_cycles = MAX_CYCLES_DEFAULT;
    valid_match_idx = 0;
    score_match_idx = 0;
    valid_found = 1'b0;
    score_found = 1'b0;

    if (!$value$plusargs("max_cycles=%d", max_cycles)) begin
        max_cycles = MAX_CYCLES_DEFAULT;
    end

    valid_msg[0]  = "C";
    valid_msg[1]  = "o";
    valid_msg[2]  = "r";
    valid_msg[3]  = "r";
    valid_msg[4]  = "e";
    valid_msg[5]  = "c";
    valid_msg[6]  = "t";
    valid_msg[7]  = " ";
    valid_msg[8]  = "o";
    valid_msg[9]  = "p";
    valid_msg[10] = "e";
    valid_msg[11] = "r";
    valid_msg[12] = "a";
    valid_msg[13] = "t";
    valid_msg[14] = "i";
    valid_msg[15] = "o";
    valid_msg[16] = "n";
    valid_msg[17] = " ";
    valid_msg[18] = "v";
    valid_msg[19] = "a";
    valid_msg[20] = "l";
    valid_msg[21] = "i";
    valid_msg[22] = "d";
    valid_msg[23] = "a";
    valid_msg[24] = "t";
    valid_msg[25] = "e";
    valid_msg[26] = "d";
    valid_msg[27] = ".";

    score_msg[0]  = "C";
    score_msg[1]  = "o";
    score_msg[2]  = "r";
    score_msg[3]  = "e";
    score_msg[4]  = "M";
    score_msg[5]  = "a";
    score_msg[6]  = "r";
    score_msg[7]  = "k";
    score_msg[8]  = " ";
    score_msg[9]  = "1";
    score_msg[10] = ".";
    score_msg[11] = "0";
    score_msg[12] = " ";

    #20;
    rst_n = 1'b1;
end

endmodule
