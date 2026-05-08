`timescale 1ns / 1ps

module YH_rv_cpu_soc_fpga_app_demo_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_fpga_app_demo.hex";
localparam string ROM_MEM32_HEX = "build/sw/YH_rv_cpu_fpga_app_demo.mem32.hex";

localparam integer BANNER_LEN = 23;
localparam integer SORT_LEN   = 9;
localparam integer CRC_LEN    = 8;
localparam integer MAT_LEN    = 14;
localparam integer DONE_LEN   = 13;

localparam [8*BANNER_LEN-1:0] BANNER_MARK = "YH_rv_cpu FPGA APP DEMO";
localparam [8*SORT_LEN-1:0]   SORT_MARK   = "Sort PASS";
localparam [8*CRC_LEN-1:0]    CRC_MARK    = "CRC PASS";
localparam [8*MAT_LEN-1:0]    MAT_MARK    = "MatrixMul PASS";
localparam [8*DONE_LEN-1:0]   DONE_MARK   = "APP_DEMO_DONE";

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

reg [8*BANNER_LEN-1:0] banner_window;
reg [8*BANNER_LEN-1:0] banner_window_next;
reg [8*SORT_LEN-1:0]   sort_window;
reg [8*SORT_LEN-1:0]   sort_window_next;
reg [8*CRC_LEN-1:0]    crc_window;
reg [8*CRC_LEN-1:0]    crc_window_next;
reg [8*MAT_LEN-1:0]    mat_window;
reg [8*MAT_LEN-1:0]    mat_window_next;
reg [8*DONE_LEN-1:0]   done_window;
reg [8*DONE_LEN-1:0]   done_window_next;

integer cycle;
integer uart_count;
reg banner_seen;
reg sort_seen;
reg crc_seen;
reg mat_seen;
reg done_seen;

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
    .ENABLE_ID_BRANCH_EX_FORWARD(1),
    .ROM_BYTES(16384),
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

            banner_window_next = {banner_window[8*(BANNER_LEN-1)-1:0], uart_tx_data};
            sort_window_next = {sort_window[8*(SORT_LEN-1)-1:0], uart_tx_data};
            crc_window_next = {crc_window[8*(CRC_LEN-1)-1:0], uart_tx_data};
            mat_window_next = {mat_window[8*(MAT_LEN-1)-1:0], uart_tx_data};
            done_window_next = {done_window[8*(DONE_LEN-1)-1:0], uart_tx_data};

            banner_window <= banner_window_next;
            sort_window <= sort_window_next;
            crc_window <= crc_window_next;
            mat_window <= mat_window_next;
            done_window <= done_window_next;

            if (banner_window_next == BANNER_MARK) begin
                banner_seen <= 1'b1;
            end
            if (sort_window_next == SORT_MARK) begin
                sort_seen <= 1'b1;
            end
            if (crc_window_next == CRC_MARK) begin
                crc_seen <= 1'b1;
            end
            if (mat_window_next == MAT_MARK) begin
                mat_seen <= 1'b1;
            end
            if (done_window_next == DONE_MARK) begin
                done_seen <= 1'b1;
            end
        end

        if (trap) begin
            $fatal(1, "\nFAIL: trap asserted at PC=%h", debug_pc);
        end

        if (banner_seen && sort_seen && crc_seen && mat_seen && done_seen && done) begin
            $display("\nPASS: fpga_app_demo UART markers observed at PC=%h in %0d cycles, uart_count=%0d", debug_pc, cycle, uart_count);
            $finish;
        end

        if (cycle > 30000000) begin
            $fatal(1, "\nFAIL: timeout at PC=%h, uart_count=%0d, banner=%0d sort=%0d crc=%0d mat=%0d done=%0d",
                   debug_pc, uart_count, banner_seen, sort_seen, crc_seen, mat_seen, done_seen);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    uart_count = 0;
    uart_busy_count = 8'd0;
    banner_seen = 1'b0;
    sort_seen = 1'b0;
    crc_seen = 1'b0;
    mat_seen = 1'b0;
    done_seen = 1'b0;
    banner_window = 0;
    banner_window_next = 0;
    sort_window = 0;
    sort_window_next = 0;
    crc_window = 0;
    crc_window_next = 0;
    mat_window = 0;
    mat_window_next = 0;
    done_window = 0;
    done_window_next = 0;

    #20;
    rst_n = 1'b1;
end

endmodule
