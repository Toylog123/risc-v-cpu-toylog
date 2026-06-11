module YH_rv_cpu_fpga_top #(
    parameter integer XLEN = 32,
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer UART_BAUD = 115200,
    parameter integer USE_CLK_MMCM_25M = 0,
    parameter integer USE_CLK_MMCM_28M = 0,
    parameter integer USE_CLK_MMCM_30M = 0,
    parameter integer USE_CLK_MMCM_33M = 0,
    parameter integer USE_CLK_MMCM_62M5 = 0,
    parameter integer USE_CLK_MMCM_50M = 0,
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_CRC_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_MUL_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 1,
    parameter integer ENABLE_XTHEAD_ADDSL_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_MEMPAIR_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_BASE_UPDATE_EXTENSION = 1,
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1,
    parameter integer ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD = 1,
    parameter integer ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD = 1,
    parameter integer ENABLE_ID_BRANCH_FOLD = 0,
    parameter integer ENABLE_ID_BRANCH_FOLD_NEXT_CACHE = 1,
    parameter integer ENABLE_EX_REDIRECT_FOLD = 1,
    parameter integer ENABLE_ID_BRANCH_NT_NEXT_CACHE = 1,
    parameter integer ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD = 0,
    parameter integer ENABLE_ID_ALU_PAIR_FOLD = 0,
    parameter integer ENABLE_ID_ALU_DEP_FOLD = 0,
    parameter integer ENABLE_REDIRECT_TARGET_CACHE = 1,
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP = 1,
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP = 0,
    parameter integer ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK = 0,
    parameter integer ENABLE_FETCH_REDIRECT_REUSE = 0,
    parameter integer ENABLE_FETCH_LIVE_BYPASS = 1,
    parameter integer ENABLE_FETCH_REDIRECT_SAME_CYCLE_REQ = 1,
    parameter integer ENABLE_REDIRECT_CACHE_HIT_EXTRA_IMEM_REQ = 0,
    parameter integer ENABLE_REDIRECT_CACHE_PC_SKIP = 1,
    parameter integer ENABLE_IF_ID_PAYLOAD_SIMPLE_CE = 0,
    parameter integer REDIRECT_CACHE_ENTRIES = 1024,
    parameter integer REDIRECT_CACHE_XOR_INDEX = 0,
    parameter integer ENABLE_DYNAMIC_BRANCH_PREDICT = 0,
    parameter integer BRANCH_BHT_ENTRIES = 64,
    parameter integer BRANCH_STATIC_PREDICT_MODE = 0,
    parameter integer BRANCH_BHT_STRONG_ONLY = 0,
    parameter integer IMEM_OUTPUT_REG = 0,
    parameter integer DMEM_OUTPUT_REG = 0,
    parameter integer DMEM_NEGEDGE_READ = 0,
    parameter integer DMEM_READ_PREISSUE = 0,
    parameter integer DCACHE_EN = 0,
    parameter integer DCACHE_SIZE_BYTES = 4096,
    parameter integer ENABLE_DCACHE_LOAD_USE_SPEC = 0,
    parameter integer ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_FOLD_DCACHE_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_FOLD_EXMEM_LOAD_USE_SPEC = 1,
    parameter integer ENABLE_EXMEM_LOAD_MUL_FORWARD = 1,
    parameter integer ENABLE_DCACHE_NEXT_PREFETCH = 0,
    parameter integer ENABLE_DCACHE_WORD_ONLY = 0,
    parameter integer ICACHE_EN = 0,
    parameter [31:0]  RAM_BASE = 32'h0000_4000,
    parameter integer ROM_BYTES = 4096,
    parameter integer RAM_BYTES = 4096,
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

wire unused_uart_rx;

assign led[0] = soc_rst_n;
assign led[1] = done;
assign led[2] = trap;
assign led[3] = timer_irq;
assign uart_tx_busy = !uart_tx_ready;
assign unused_uart_rx = uart_txd_in;

generate
if (USE_CLK_MMCM_25M != 0) begin : gen_pynq_clk_25m
    wire clkfb;
    wire clkfb_buf;
    wire clkout0;
    wire mmcm_locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(8.000),
        .CLKFBOUT_MULT_F(7.500),
        .CLKFBOUT_PHASE(0.000),
        .DIVCLK_DIVIDE(1),
        .CLKOUT0_DIVIDE_F(40.000),
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
end else if (USE_CLK_MMCM_50M != 0) begin : gen_pynq_clk_50m
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
end else if (USE_CLK_MMCM_28M != 0) begin : gen_pynq_clk_28m
    wire clkfb;
    wire clkfb_buf;
    wire clkout0;
    wire mmcm_locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(8.000),
        .CLKFBOUT_MULT_F(9.000),
        .CLKFBOUT_PHASE(0.000),
        .DIVCLK_DIVIDE(1),
        .CLKOUT0_DIVIDE_F(40.000),
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
end else if (USE_CLK_MMCM_30M != 0) begin : gen_pynq_clk_30m
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
        .CLKOUT0_DIVIDE_F(31.250),
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
end else if (USE_CLK_MMCM_33M != 0) begin : gen_pynq_clk_33m
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
        .CLKOUT0_DIVIDE_F(30.000),
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

YH_rv_cpu_soc #(
    .XLEN             (XLEN),
    .SYNC_IMEM        (1),
    .IMEM_OUTPUT_REG  (IMEM_OUTPUT_REG),
    .SYNC_DMEM        (1),
    .DMEM_OUTPUT_REG  (DMEM_OUTPUT_REG),
    .DMEM_NEGEDGE_READ(DMEM_NEGEDGE_READ),
    .DMEM_READ_PREISSUE(DMEM_READ_PREISSUE),
    .DCACHE_EN        (DCACHE_EN),
    .DCACHE_SIZE_BYTES(DCACHE_SIZE_BYTES),
    .ENABLE_DCACHE_LOAD_USE_SPEC(ENABLE_DCACHE_LOAD_USE_SPEC),
    .ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC(ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC),
    .ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC(ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC),
    .ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC(ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC),
    .ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC(ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC),
    .ENABLE_FOLD_DCACHE_LOAD_USE_SPEC(ENABLE_FOLD_DCACHE_LOAD_USE_SPEC),
    .ENABLE_FOLD_EXMEM_LOAD_USE_SPEC(ENABLE_FOLD_EXMEM_LOAD_USE_SPEC),
    .ENABLE_EXMEM_LOAD_MUL_FORWARD(ENABLE_EXMEM_LOAD_MUL_FORWARD),
    .ENABLE_DCACHE_NEXT_PREFETCH(ENABLE_DCACHE_NEXT_PREFETCH),
    .ENABLE_DCACHE_WORD_ONLY(ENABLE_DCACHE_WORD_ONLY),
    .ICACHE_EN        (ICACHE_EN),
    .RESET_VECTOR     ({XLEN{1'b0}}),
    .RAM_BASE         (RAM_BASE),
    .ROM_BYTES        (ROM_BYTES),
    .RAM_BYTES        (RAM_BYTES),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION),
    .ENABLE_XTHEAD_CRC_EXTENSION(ENABLE_XTHEAD_CRC_EXTENSION),
    .ENABLE_XTHEAD_MUL_EXTENSION(ENABLE_XTHEAD_MUL_EXTENSION),
    .ENABLE_XTHEAD_COND_MOVE(ENABLE_XTHEAD_COND_MOVE),
    .ENABLE_XTHEAD_ADDSL_EXTENSION(ENABLE_XTHEAD_ADDSL_EXTENSION),
    .ENABLE_XTHEAD_MEMPAIR_EXTENSION(ENABLE_XTHEAD_MEMPAIR_EXTENSION),
    .ENABLE_XTHEAD_BASE_UPDATE_EXTENSION(ENABLE_XTHEAD_BASE_UPDATE_EXTENSION),
    .ENABLE_ID_BRANCH_EX_FORWARD(ENABLE_ID_BRANCH_EX_FORWARD),
    .ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD(ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD),
    .ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD(ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD),
    .ENABLE_ID_BRANCH_FOLD(ENABLE_ID_BRANCH_FOLD),
    .ENABLE_ID_BRANCH_FOLD_NEXT_CACHE(ENABLE_ID_BRANCH_FOLD_NEXT_CACHE),
    .ENABLE_EX_REDIRECT_FOLD(ENABLE_EX_REDIRECT_FOLD),
    .ENABLE_ID_BRANCH_NT_NEXT_CACHE(ENABLE_ID_BRANCH_NT_NEXT_CACHE),
    .ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD(ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD),
    .ENABLE_ID_ALU_PAIR_FOLD(ENABLE_ID_ALU_PAIR_FOLD),
    .ENABLE_ID_ALU_DEP_FOLD(ENABLE_ID_ALU_DEP_FOLD),
    .ENABLE_REDIRECT_TARGET_CACHE(ENABLE_REDIRECT_TARGET_CACHE),
    .ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP(ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP),
    .ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP(ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP),
    .ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK(ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK),
    .ENABLE_FETCH_REDIRECT_REUSE(ENABLE_FETCH_REDIRECT_REUSE),
    .ENABLE_FETCH_LIVE_BYPASS(ENABLE_FETCH_LIVE_BYPASS),
    .ENABLE_FETCH_REDIRECT_SAME_CYCLE_REQ(ENABLE_FETCH_REDIRECT_SAME_CYCLE_REQ),
    .ENABLE_REDIRECT_CACHE_HIT_EXTRA_IMEM_REQ(ENABLE_REDIRECT_CACHE_HIT_EXTRA_IMEM_REQ),
    .ENABLE_REDIRECT_CACHE_PC_SKIP(ENABLE_REDIRECT_CACHE_PC_SKIP),
    .ENABLE_IF_ID_PAYLOAD_SIMPLE_CE(ENABLE_IF_ID_PAYLOAD_SIMPLE_CE),
    .REDIRECT_CACHE_ENTRIES(REDIRECT_CACHE_ENTRIES),
    .REDIRECT_CACHE_XOR_INDEX(REDIRECT_CACHE_XOR_INDEX),
    .ENABLE_DYNAMIC_BRANCH_PREDICT(ENABLE_DYNAMIC_BRANCH_PREDICT),
    .BRANCH_BHT_ENTRIES(BRANCH_BHT_ENTRIES),
    .BRANCH_STATIC_PREDICT_MODE(BRANCH_STATIC_PREDICT_MODE),
    .BRANCH_BHT_STRONG_ONLY(BRANCH_BHT_STRONG_ONLY),
    .ROM_INIT_HEX     (ROM_INIT_HEX),
    .ROM_INIT_MEM32_HEX(ROM_INIT_MEM32_HEX)
) u_soc (
    .clk          (cpu_clk),
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
    .clk      (cpu_clk),
    .rst_n    (soc_rst_n),
    .tx_valid (uart_tx_valid),
    .tx_data  (uart_tx_data),
    .tx_ready (uart_tx_ready),
    .uart_txd (uart_rxd_out)
);

endmodule
