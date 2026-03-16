module YH_rv_cpu_fpga_top #(
    parameter integer XLEN = 32,
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer UART_BAUD = 115200,
    parameter integer ROM_BYTES = 4096,
    parameter integer RAM_BYTES = 4096,
    parameter string  ROM_INIT_HEX = ""
) (
    input  wire       CLK100MHZ,
    input  wire       cpu_resetn,
    input  wire       uart_txd_in,
    output wire       uart_rxd_out,
    output wire [3:0] led
);

reg [7:0] reset_sync_r;

wire       soc_rst_n;
wire       trap;
wire [XLEN-1:0] debug_pc;
wire       uart_tx_valid;
wire [7:0] uart_tx_data;
wire       done;
wire       timer_irq;
wire       uart_tx_ready;
wire       uart_tx_busy;

wire unused_uart_rx;

assign soc_rst_n = &reset_sync_r;
assign led[0] = soc_rst_n;
assign led[1] = done;
assign led[2] = trap;
assign led[3] = timer_irq;
assign uart_tx_busy = !uart_tx_ready;
assign unused_uart_rx = uart_txd_in;

always @(posedge CLK100MHZ or negedge cpu_resetn) begin
    if (!cpu_resetn) begin
        reset_sync_r <= 8'h00;
    end else begin
        reset_sync_r <= {reset_sync_r[6:0], 1'b1};
    end
end

YH_rv_cpu_soc #(
    .XLEN        (XLEN),
    .RESET_VECTOR({XLEN{1'b0}}),
    .ROM_BYTES   (ROM_BYTES),
    .RAM_BYTES   (RAM_BYTES),
    .ROM_INIT_HEX(ROM_INIT_HEX)
) u_soc (
    .clk          (CLK100MHZ),
    .rst_n        (soc_rst_n),
    .trap         (trap),
    .debug_pc     (debug_pc),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data (uart_tx_data),
    .done         (done),
    .timer_irq    (timer_irq)
);

YH_rv_uart_tx #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD_RATE  (UART_BAUD)
) u_uart_tx (
    .clk      (CLK100MHZ),
    .rst_n    (soc_rst_n),
    .tx_valid (uart_tx_valid),
    .tx_data  (uart_tx_data),
    .tx_ready (uart_tx_ready),
    .uart_txd (uart_rxd_out)
);

endmodule
