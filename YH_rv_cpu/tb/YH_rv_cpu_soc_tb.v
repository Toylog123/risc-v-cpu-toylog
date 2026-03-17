`timescale 1ns / 1ps

module YH_rv_cpu_soc_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_demo.hex";
localparam integer EXPECTED_LEN = 15;
localparam integer DEBUG_TRACE = 0;

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

        if (DEBUG_TRACE && (cycle < 40)) begin
            $display(
                "TRACE cycle=%0d pc=%h if_id_v=%0d if_id_pc=%h id_ex_v=%0d id_ex_pc=%h ex_mem_v=%0d mem_wb_v=%0d trap=%0d done=%0d x12=%h x13=%h x14=%h x15=%h daddr=%h dwdata=%h wstrb=%h",
                cycle,
                debug_pc,
                dut.u_cpu.if_id_valid_r,
                dut.u_cpu.if_id_pc_r,
                dut.u_cpu.id_ex_valid_r,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.ex_mem_valid_r,
                dut.u_cpu.mem_wb_valid_r,
                trap,
                done,
                dut.u_cpu.u_regfile.regs[12],
                dut.u_cpu.u_regfile.regs[13],
                dut.u_cpu.u_regfile.regs[14],
                dut.u_cpu.u_regfile.regs[15],
                dut.u_cpu.dmem_addr,
                dut.u_cpu.dmem_wdata,
                dut.u_cpu.dmem_wstrb
            );
        end

        if (uart_tx_valid) begin
            captured_uart[uart_count] <= uart_tx_data;
            uart_count <= uart_count + 1;
            $write("%c", uart_tx_data);

            if (DEBUG_TRACE) begin
                $display(
                    "\nUART byte[%0d]=0x%02h (%c) a2=%h daddr=%h dwdata=%h",
                    uart_count,
                    uart_tx_data,
                    uart_tx_data,
                    dut.u_cpu.u_regfile.regs[12],
                    dut.u_cpu.dmem_addr,
                    dut.u_cpu.dmem_wdata
                );
            end
        end

        if (trap) begin
            $display("\nFAIL: trap asserted at PC=%h", debug_pc);
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

            if (timer_irq) begin
                $display("\nFAIL: timer_irq asserted unexpectedly");
                $finish;
            end

            $display("\nPASS: SoC smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
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

    expected_uart[0]  = "Y";
    expected_uart[1]  = "H";
    expected_uart[2]  = "_";
    expected_uart[3]  = "r";
    expected_uart[4]  = "v";
    expected_uart[5]  = "_";
    expected_uart[6]  = "c";
    expected_uart[7]  = "p";
    expected_uart[8]  = "u";
    expected_uart[9]  = " ";
    expected_uart[10] = "b";
    expected_uart[11] = "o";
    expected_uart[12] = "o";
    expected_uart[13] = "t";
    expected_uart[14] = "\n";

    #20;
    rst_n = 1'b1;
end

endmodule
