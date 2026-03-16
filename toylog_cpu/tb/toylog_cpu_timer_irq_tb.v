`timescale 1ns / 1ps

module toylog_cpu_timer_irq_tb;

localparam string ROM_HEX = "build/sw/toylog_cpu_timer_irq_smoke.hex";
localparam integer EXPECTED_LEN = 7;

reg         clk;
reg         rst_n;
wire        trap;
wire [31:0] debug_pc;
wire        uart_tx_valid;
wire [7:0]  uart_tx_data;
wire        done;
wire        timer_irq;

reg [7:0] expected_uart [0:EXPECTED_LEN-1];
reg [7:0] captured_uart [0:127];
integer cycle;
integer uart_count;
integer idx;

toylog_cpu_soc #(
    .ROM_INIT_HEX(ROM_HEX)
) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .trap        (trap),
    .debug_pc    (debug_pc),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data(uart_tx_data),
    .done        (done),
    .timer_irq   (timer_irq)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (uart_tx_valid) begin
            captured_uart[uart_count] <= uart_tx_data;
            uart_count <= uart_count + 1;
            $write("%c", uart_tx_data);
        end

        if (trap) begin
            $display("\nFAIL: unexpected trap output at PC=%h", debug_pc);
            $finish;
        end

        if (done) begin
            if (uart_count != EXPECTED_LEN) begin
                $display("\nFAIL: unexpected UART length %0d", uart_count);
                $finish;
            end

            for (idx = 0; idx < EXPECTED_LEN; idx = idx + 1) begin
                if (captured_uart[idx] !== expected_uart[idx]) begin
                    $display("\nFAIL: UART mismatch at index %0d, got %0d expected %0d", idx, captured_uart[idx], expected_uart[idx]);
                    $finish;
                end
            end

            if (dut.u_cpu.csr_mcause_r != 32'h8000_0007) begin
                $display("\nFAIL: unexpected mcause %h", dut.u_cpu.csr_mcause_r);
                $finish;
            end

            if (dut.u_cpu.csr_mie_r != 32'h0000_0080) begin
                $display("\nFAIL: unexpected mie %h", dut.u_cpu.csr_mie_r);
                $finish;
            end

            $display("\nPASS: timer irq smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > 600) begin
            $display("\nFAIL: timeout at PC=%h", debug_pc);
            $finish;
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    uart_count = 0;

    expected_uart[0] = "i";
    expected_uart[1] = "r";
    expected_uart[2] = "q";
    expected_uart[3] = " ";
    expected_uart[4] = "o";
    expected_uart[5] = "k";
    expected_uart[6] = "\n";

    #20;
    rst_n = 1'b1;
end

endmodule
