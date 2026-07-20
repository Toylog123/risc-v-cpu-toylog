module YH_rv_cpu_fpga_top #(
    parameter integer XLEN = 32,
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer UART_BAUD = 115200,
    parameter integer USE_CLK_MMCM_62M5 = 0,
    parameter integer USE_CLK_MMCM_50M = 0,
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 1,
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1,
    parameter integer IMEM_OUTPUT_REG = 1,
    parameter integer DMEM_OUTPUT_REG = 0,
    parameter integer DEBUG_LED_MODE = 0,
    parameter integer DEBUG_UART_DIAG_MODE = 0,
    parameter integer ROM_BYTES = 16384,
    parameter integer RAM_BYTES = 16384,
    parameter string  ROM_INIT_HEX = "",
    parameter string  ROM_INIT_MEM32_HEX = ""
) (
    input  wire       CLK100MHZ,
    input  wire       cpu_resetn,
    input  wire       uart_txd_in,
    output wire       uart_rxd_out,
    output wire [3:0] led
);

wire       cpu_clk;
wire       clk_locked;
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
wire       uart_tx_valid_mux;
wire [7:0] uart_tx_data_mux;

wire unused_uart_rx;
reg [XLEN-1:0] debug_pc_d1_r;
reg [23:0] pc_activity_counter_r;
reg uart_tx_seen_r;
reg [31:0] diag_timer_r;
reg [6:0] diag_idx_r;
reg [15:0] diag_gap_r;
reg diag_active_r;
reg diag_valid_r;
reg [7:0] diag_data_r;
reg [7:0] diag_data_hold_r;
reg [31:0] diag_pc_snapshot_r;
reg [7:0] diag_tick_snapshot_r;
reg diag_rst_snapshot_r;
reg diag_trap_snapshot_r;
reg diag_uart_snapshot_r;
reg [7:0] diag_tick_r;

assign led[0] = soc_rst_n;
assign led[1] = (DEBUG_LED_MODE != 0) ? trap : done;
assign led[2] = (DEBUG_LED_MODE != 0) ? uart_tx_seen_r : trap;
assign led[3] = (DEBUG_LED_MODE != 0) ? pc_activity_counter_r[23] : timer_irq;
assign uart_tx_busy = !uart_tx_ready;
assign unused_uart_rx = uart_txd_in;
assign uart_tx_valid_mux = (DEBUG_UART_DIAG_MODE != 0) ? diag_valid_r : uart_tx_valid;
assign uart_tx_data_mux = (DEBUG_UART_DIAG_MODE != 0) ? diag_data_hold_r : uart_tx_data;

function [7:0] hex_char;
    input [3:0] nibble;
    begin
        hex_char = (nibble < 4'd10) ? (8'h30 + nibble) : (8'h41 + (nibble - 4'd10));
    end
endfunction

generate
if (USE_CLK_MMCM_50M != 0) begin : gen_pynq_clk_50m
    wire clkfb;
    wire clkfb_buf;
    wire clkout0;
    wire mmcm_locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(8.000),
        .CLKFBOUT_MULT_F(8.000),
        .CLKFBOUT_PHASE(0.000),
        .DIVCLK_DIVIDE(1),
        .CLKOUT0_DIVIDE_F(20.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT0_PHASE(0.000),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) u_clk_mmcm (
        .CLKIN1(CLK100MHZ),
        .CLKFBIN(clkfb_buf),
        .CLKFBOUT(clkfb),
        .CLKOUT0(clkout0),
        .CLKOUT1(),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .LOCKED(mmcm_locked),
        .PWRDWN(1'b0),
        .RST(!cpu_resetn)
    );

    BUFG u_clkfb_bufg (
        .I(clkfb),
        .O(clkfb_buf)
    );

    BUFG u_cpu_clk_bufg (
        .I(clkout0),
        .O(cpu_clk)
    );

    assign clk_locked = mmcm_locked;
end else if (USE_CLK_MMCM_62M5 != 0) begin : gen_pynq_clk_62m5
    wire clkfb;
    wire clkfb_buf;
    wire clkout0;
    wire mmcm_locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(8.000),
        .CLKFBOUT_MULT_F(8.000),
        .CLKFBOUT_PHASE(0.000),
        .DIVCLK_DIVIDE(1),
        .CLKOUT0_DIVIDE_F(16.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT0_PHASE(0.000),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) u_clk_mmcm (
        .CLKIN1(CLK100MHZ),
        .CLKFBIN(clkfb_buf),
        .CLKFBOUT(clkfb),
        .CLKOUT0(clkout0),
        .CLKOUT1(),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .LOCKED(mmcm_locked),
        .PWRDWN(1'b0),
        .RST(!cpu_resetn)
    );

    BUFG u_clkfb_bufg (
        .I(clkfb),
        .O(clkfb_buf)
    );

    BUFG u_cpu_clk_bufg (
        .I(clkout0),
        .O(cpu_clk)
    );

    assign clk_locked = mmcm_locked;
end else begin : gen_direct_clk
    assign cpu_clk = CLK100MHZ;
    assign clk_locked = 1'b1;
end
endgenerate

always @(posedge cpu_clk or negedge cpu_resetn) begin
    if (!cpu_resetn) begin
        reset_sync_r <= 8'h00;
    end else begin
        reset_sync_r <= {reset_sync_r[6:0], 1'b1};
    end
end

assign soc_rst_n = (&reset_sync_r) & clk_locked;

always @(posedge cpu_clk or negedge cpu_resetn) begin
    if (!cpu_resetn) begin
        debug_pc_d1_r <= {XLEN{1'b0}};
        pc_activity_counter_r <= 24'd0;
        uart_tx_seen_r <= 1'b0;
    end else if (!soc_rst_n) begin
        debug_pc_d1_r <= {XLEN{1'b0}};
        pc_activity_counter_r <= 24'd0;
        uart_tx_seen_r <= 1'b0;
    end else begin
        debug_pc_d1_r <= debug_pc;
        if (debug_pc != debug_pc_d1_r) begin
            pc_activity_counter_r <= pc_activity_counter_r + 24'd1;
        end
        if (uart_tx_valid) begin
            uart_tx_seen_r <= 1'b1;
        end
    end
end

always @(*) begin
    case (diag_idx_r)
        7'd0:  diag_data_r = "Y";
        7'd1:  diag_data_r = "H";
        7'd2:  diag_data_r = "_";
        7'd3:  diag_data_r = "r";
        7'd4:  diag_data_r = "v";
        7'd5:  diag_data_r = "_";
        7'd6:  diag_data_r = "c";
        7'd7:  diag_data_r = "p";
        7'd8:  diag_data_r = "u";
        7'd9:  diag_data_r = " ";
        7'd10: diag_data_r = "C";
        7'd11: diag_data_r = "o";
        7'd12: diag_data_r = "r";
        7'd13: diag_data_r = "e";
        7'd14: diag_data_r = "M";
        7'd15: diag_data_r = "a";
        7'd16: diag_data_r = "r";
        7'd17: diag_data_r = "k";
        7'd18: diag_data_r = "/";
        7'd19: diag_data_r = "M";
        7'd20: diag_data_r = "H";
        7'd21: diag_data_r = "z";
        7'd22: diag_data_r = "=";
        7'd23: diag_data_r = "4";
        7'd24: diag_data_r = ".";
        7'd25: diag_data_r = "1";
        7'd26: diag_data_r = "3";
        7'd27: diag_data_r = "7";
        7'd28: diag_data_r = "4";
        7'd29: diag_data_r = "6";
        7'd30: diag_data_r = "1";
        7'd31: diag_data_r = " ";
        7'd32: diag_data_r = "D";
        7'd33: diag_data_r = "M";
        7'd34: diag_data_r = "I";
        7'd35: diag_data_r = "P";
        7'd36: diag_data_r = "S";
        7'd37: diag_data_r = "/";
        7'd38: diag_data_r = "M";
        7'd39: diag_data_r = "H";
        7'd40: diag_data_r = "z";
        7'd41: diag_data_r = "=";
        7'd42: diag_data_r = "2";
        7'd43: diag_data_r = ".";
        7'd44: diag_data_r = "9";
        7'd45: diag_data_r = "0";
        7'd46: diag_data_r = "8";
        7'd47: diag_data_r = "2";
        7'd48: diag_data_r = "8";
        7'd49: diag_data_r = "7";
        7'd50: diag_data_r = " ";
        7'd51: diag_data_r = "t";
        7'd52: diag_data_r = "i";
        7'd53: diag_data_r = "c";
        7'd54: diag_data_r = "k";
        7'd55: diag_data_r = "=";
        7'd56: diag_data_r = hex_char(diag_tick_snapshot_r[7:4]);
        7'd57: diag_data_r = hex_char(diag_tick_snapshot_r[3:0]);
        7'd58: diag_data_r = " ";
        7'd59: diag_data_r = "p";
        7'd60: diag_data_r = "c";
        7'd61: diag_data_r = "=";
        7'd62: diag_data_r = hex_char(diag_pc_snapshot_r[31:28]);
        7'd63: diag_data_r = hex_char(diag_pc_snapshot_r[27:24]);
        7'd64: diag_data_r = hex_char(diag_pc_snapshot_r[23:20]);
        7'd65: diag_data_r = hex_char(diag_pc_snapshot_r[19:16]);
        7'd66: diag_data_r = hex_char(diag_pc_snapshot_r[15:12]);
        7'd67: diag_data_r = hex_char(diag_pc_snapshot_r[11:8]);
        7'd68: diag_data_r = hex_char(diag_pc_snapshot_r[7:4]);
        7'd69: diag_data_r = hex_char(diag_pc_snapshot_r[3:0]);
        7'd70: diag_data_r = "\n";
        default: diag_data_r = "\n";
    endcase
end

always @(posedge cpu_clk or negedge cpu_resetn) begin
    if (!cpu_resetn) begin
        diag_timer_r <= 32'd0;
        diag_idx_r <= 7'd0;
        diag_gap_r <= 16'd0;
        diag_active_r <= 1'b0;
        diag_valid_r <= 1'b0;
        diag_data_hold_r <= 8'h00;
        diag_pc_snapshot_r <= 32'd0;
        diag_tick_snapshot_r <= 8'd0;
        diag_rst_snapshot_r <= 1'b0;
        diag_trap_snapshot_r <= 1'b0;
        diag_uart_snapshot_r <= 1'b0;
        diag_tick_r <= 8'd0;
    end else begin
        diag_valid_r <= 1'b0;

        if (DEBUG_UART_DIAG_MODE != 0) begin
            if (diag_active_r) begin
                if (diag_gap_r != 16'd0) begin
                    diag_gap_r <= diag_gap_r - 16'd1;
                end else if (uart_tx_ready) begin
                    diag_data_hold_r <= diag_data_r;
                    diag_valid_r <= 1'b1;
                    diag_gap_r <= 16'd5000;
                    if (diag_idx_r == 7'd70) begin
                        diag_active_r <= 1'b0;
                        diag_idx_r <= 7'd0;
                    end else begin
                        diag_idx_r <= diag_idx_r + 7'd1;
                    end
                end
            end else if (diag_timer_r >= 32'd5_000_000) begin
                diag_timer_r <= 32'd0;
                diag_active_r <= 1'b1;
                diag_idx_r <= 7'd0;
                diag_pc_snapshot_r <= debug_pc[31:0];
                diag_tick_snapshot_r <= diag_tick_r;
                diag_tick_r <= diag_tick_r + 8'd1;
                diag_rst_snapshot_r <= soc_rst_n;
                diag_trap_snapshot_r <= trap;
                diag_uart_snapshot_r <= uart_tx_seen_r;
            end else begin
                diag_timer_r <= diag_timer_r + 32'd1;
            end
        end
    end
end

YH_rv_cpu_soc #(
    .XLEN             (XLEN),
    .SYNC_IMEM        (1),
    .IMEM_OUTPUT_REG  (IMEM_OUTPUT_REG),
    .SYNC_DMEM        (1),
    .DMEM_OUTPUT_REG  (DMEM_OUTPUT_REG),
    .RESET_VECTOR     ({XLEN{1'b0}}),
    .ROM_BYTES        (ROM_BYTES),
    .RAM_BYTES        (RAM_BYTES),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION),
    .ENABLE_XTHEAD_COND_MOVE(ENABLE_XTHEAD_COND_MOVE),
    .ENABLE_ID_BRANCH_EX_FORWARD(ENABLE_ID_BRANCH_EX_FORWARD),
    .ROM_INIT_HEX     (ROM_INIT_HEX),
    .ROM_INIT_MEM32_HEX(ROM_INIT_MEM32_HEX)
) u_soc (
    .clk          (cpu_clk),
    .rst_n        (soc_rst_n),
    .trap         (trap),
    .debug_pc     (debug_pc),
    .uart_tx_ready(uart_tx_ready),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data (uart_tx_data),
    .done         (done),
    .timer_irq    (timer_irq)
);

YH_rv_uart_tx #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD_RATE  (UART_BAUD)
) u_uart_tx (
    .clk      (cpu_clk),
    .rst_n    (soc_rst_n),
    .tx_valid (uart_tx_valid_mux),
    .tx_data  (uart_tx_data_mux),
    .tx_ready (uart_tx_ready),
    .uart_txd (uart_rxd_out)
);

endmodule
