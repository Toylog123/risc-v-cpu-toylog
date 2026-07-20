`timescale 1ns / 1ps

module YH_rv_cpu_trap_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_trap_smoke.hex";
localparam integer EXPECTED_LEN = 8;

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

YH_rv_cpu_soc #(
    .SYNC_DMEM(1),
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

            if (dut.u_cpu.csr_mcause_r != 32'd11) begin
                $display("\nFAIL: unexpected mcause %0d", dut.u_cpu.csr_mcause_r);
                $finish;
            end

            if (dut.u_cpu.csr_mepc_r == 32'h0000_0000) begin
                $display("\nFAIL: mepc not updated");
                $finish;
            end

            $display("\nPASS: trap smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > 500) begin
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

    expected_uart[0] = "t";
    expected_uart[1] = "r";
    expected_uart[2] = "a";
    expected_uart[3] = "p";
    expected_uart[4] = " ";
    expected_uart[5] = "o";
    expected_uart[6] = "k";
    expected_uart[7] = "\n";

    #20;
    rst_n = 1'b1;
end

endmodule
