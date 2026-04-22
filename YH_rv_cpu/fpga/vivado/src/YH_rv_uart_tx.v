module YH_rv_uart_tx #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_valid,
    input  wire [7:0] tx_data,
    output wire       tx_ready,
    output reg        uart_txd
);

// Round the divider to the nearest integer baud period supported by the FPGA clock.
localparam integer BAUD_DIV = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;
localparam integer BAUD_CNT_W = (BAUD_DIV > 1) ? $clog2(BAUD_DIV) : 1;

reg [9:0] frame_r;
reg [3:0] bit_idx_r;
reg [BAUD_CNT_W-1:0] baud_cnt_r;
reg busy_r;

// A new byte can be accepted only when the transmitter is idle.
assign tx_ready = !busy_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_r    <= 10'h3ff;
        bit_idx_r  <= 4'd0;
        baud_cnt_r <= {BAUD_CNT_W{1'b0}};
        busy_r     <= 1'b0;
        uart_txd   <= 1'b1;
    end else if (!busy_r) begin
        // Idle line stays high until a valid byte arrives.
        uart_txd <= 1'b1;

        if (tx_valid) begin
            // Frame format is 1 start bit, 8 data bits, 1 stop bit.
            frame_r    <= {1'b1, tx_data, 1'b0};
            bit_idx_r  <= 4'd0;
            baud_cnt_r <= BAUD_DIV - 1;
            busy_r     <= 1'b1;
            uart_txd   <= 1'b0;
        end
    end else if (baud_cnt_r != {BAUD_CNT_W{1'b0}}) begin
        baud_cnt_r <= baud_cnt_r - 1'b1;
    end else begin
        // Shift out the next bit every baud interval until the stop bit completes.
        frame_r    <= {1'b1, frame_r[9:1]};
        baud_cnt_r <= BAUD_DIV - 1;

        if (bit_idx_r == 4'd9) begin
            busy_r    <= 1'b0;
            bit_idx_r <= 4'd0;
            uart_txd  <= 1'b1;
        end else begin
            bit_idx_r <= bit_idx_r + 1'b1;
            uart_txd  <= frame_r[1];
        end
    end
end

endmodule
