`timescale 1ns / 1ps

module YH_rv_cpu_soc_uart_alive_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_uart_alive.hex";
localparam string ROM_MEM32_HEX = "build/sw/YH_rv_cpu_uart_alive.mem32.hex";

localparam integer BOOT_MARK_LEN = 9;
localparam integer COREMARK_LEN  = 12;
localparam integer DMIPS_LEN     = 9;
localparam integer FPGA_LEN      = 4;
localparam integer LIVE_LEN      = 5;

localparam [8*BOOT_MARK_LEN-1:0] BOOT_MARK = "YH_rv_cpu";
localparam [8*COREMARK_LEN-1:0]  COREMARK_MARK = "CoreMark/MHz";
localparam [8*DMIPS_LEN-1:0]     DMIPS_MARK = "DMIPS/MHz";
localparam [8*FPGA_LEN-1:0]      FPGA_MARK = "FPGA";
localparam [8*LIVE_LEN-1:0]      LIVE_MARK = "Live:";

reg         clk;
reg         rst_n;
wire        trap;
wire [31:0] debug_pc;
wire        uart_tx_valid;
wire [7:0]  uart_tx_data;
wire        uart_tx_ready;
wire        done;
wire        timer_irq;
reg [7:0]   uart_busy_count;

reg [8*BOOT_MARK_LEN-1:0] boot_window;
reg [8*BOOT_MARK_LEN-1:0] boot_window_next;
reg [8*COREMARK_LEN-1:0]  coremark_window;
reg [8*COREMARK_LEN-1:0]  coremark_window_next;
reg [8*DMIPS_LEN-1:0]     dmips_window;
reg [8*DMIPS_LEN-1:0]     dmips_window_next;
reg [8*FPGA_LEN-1:0]      fpga_window;
reg [8*FPGA_LEN-1:0]      fpga_window_next;
reg [8*LIVE_LEN-1:0]      live_window;
reg [8*LIVE_LEN-1:0]      live_window_next;

integer cycle;
integer uart_count;
reg boot_seen;
reg coremark_seen;
reg dmips_seen;
reg fpga_seen;
reg live_seen;

YH_rv_cpu_soc #(
    .SYNC_IMEM(1),
    .IMEM_OUTPUT_REG(1),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(0),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_XTHEAD_EXTENSION(0),
    .ENABLE_XTHEAD_COND_MOVE(0),
    .ENABLE_ID_BRANCH_EX_FORWARD(0),
    .ROM_BYTES(8192),
    .RAM_BYTES(16384),
    .ROM_INIT_HEX(ROM_HEX),
    .ROM_INIT_MEM32_HEX(ROM_MEM32_HEX)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .trap         (trap),
    .debug_pc     (debug_pc),
    .uart_tx_ready(uart_tx_ready),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data (uart_tx_data),
    .done         (done),
    .timer_irq    (timer_irq)
);

assign uart_tx_ready = (uart_busy_count == 8'd0);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (uart_tx_valid && uart_tx_ready) begin
            uart_busy_count <= 8'd24;
        end else if (uart_busy_count != 8'd0) begin
            uart_busy_count <= uart_busy_count - 8'd1;
        end

        if (uart_tx_valid && !uart_tx_ready) begin
            $fatal(1, "\nFAIL: UART write while transmitter busy at PC=%h, data=%0d", debug_pc, uart_tx_data);
        end

        if (uart_tx_valid && uart_tx_ready) begin
            uart_count <= uart_count + 1;
            $write("%c", uart_tx_data);

            boot_window_next = {boot_window[8*(BOOT_MARK_LEN-1)-1:0], uart_tx_data};
            coremark_window_next = {coremark_window[8*(COREMARK_LEN-1)-1:0], uart_tx_data};
            dmips_window_next = {dmips_window[8*(DMIPS_LEN-1)-1:0], uart_tx_data};
            fpga_window_next = {fpga_window[8*(FPGA_LEN-1)-1:0], uart_tx_data};
            live_window_next = {live_window[8*(LIVE_LEN-1)-1:0], uart_tx_data};

            boot_window <= boot_window_next;
            coremark_window <= coremark_window_next;
            dmips_window <= dmips_window_next;
            fpga_window <= fpga_window_next;
            live_window <= live_window_next;

            if (boot_window_next == BOOT_MARK) begin
                boot_seen <= 1'b1;
            end
            if (coremark_window_next == COREMARK_MARK) begin
                coremark_seen <= 1'b1;
            end
            if (dmips_window_next == DMIPS_MARK) begin
                dmips_seen <= 1'b1;
            end
            if (fpga_window_next == FPGA_MARK) begin
                fpga_seen <= 1'b1;
            end
            if (live_window_next == LIVE_MARK) begin
                live_seen <= 1'b1;
            end
        end

        if (trap) begin
            $fatal(1, "\nFAIL: trap asserted at PC=%h", debug_pc);
        end

        if (boot_seen && coremark_seen && dmips_seen && fpga_seen && live_seen) begin
            $display("\nPASS: uart_alive benchmark banner and live marker observed at PC=%h in %0d cycles, uart_count=%0d", debug_pc, cycle, uart_count);
            $finish;
        end

        if (cycle > 20000000) begin
            $fatal(1, "\nFAIL: timeout at PC=%h, uart_count=%0d", debug_pc, uart_count);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    uart_count = 0;
    boot_seen = 1'b0;
    coremark_seen = 1'b0;
    dmips_seen = 1'b0;
    fpga_seen = 1'b0;
    live_seen = 1'b0;
    uart_busy_count = 8'd0;
    boot_window = 0;
    boot_window_next = 0;
    coremark_window = 0;
    coremark_window_next = 0;
    dmips_window = 0;
    dmips_window_next = 0;
    fpga_window = 0;
    fpga_window_next = 0;
    live_window = 0;
    live_window_next = 0;

    #20;
    rst_n = 1'b1;
end

endmodule
