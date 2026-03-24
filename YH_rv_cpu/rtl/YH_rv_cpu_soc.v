// 文件说明：YH_rv_cpu SoC 顶层封装。
// 作用：集成 CPU 内核、指令 ROM、数据 RAM 和基础存储映射接口。
// 备注：用于仿真平台与 FPGA 顶层之间的统一系统级连接。

module YH_rv_cpu_soc #(
    parameter integer XLEN = 32,
    parameter integer SYNC_IMEM = 0,
    parameter integer IMEM_OUTPUT_REG = 0,
    parameter integer SYNC_DMEM = 0,
    parameter integer DMEM_OUTPUT_REG = 0,
    parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}},
    parameter [31:0] ROM_BASE = 32'h0000_0000,
    parameter [31:0] RAM_BASE = 32'h0000_4000,
    parameter integer ROM_BYTES = 16384,
    parameter integer RAM_BYTES = 16384,
    parameter string ROM_INIT_HEX = "",
    parameter string ROM_INIT_MEM32_HEX = ""
) (
    input  wire            clk,
    input  wire            rst_n,
    output wire            trap,
    output wire [XLEN-1:0] debug_pc,
    output reg             uart_tx_valid,
    output reg  [7:0]      uart_tx_data,
    output wire            done,
    output wire            timer_irq
);

localparam [31:0] UART_TX_ADDR    = 32'h1000_0000;
localparam [31:0] DONE_ADDR       = 32'h1000_0004;
localparam [31:0] TIMER_VALUE_LO  = 32'h1000_0008;
localparam [31:0] TIMER_VALUE_HI  = 32'h1000_000c;
localparam [31:0] TIMER_CMP_LO    = 32'h1000_0010;
localparam [31:0] TIMER_CMP_HI    = 32'h1000_0014;
localparam [31:0] TIMER_CTRL_ADDR = 32'h1000_0018;

wire [XLEN-1:0] imem_addr;
wire            imem_req;
wire [31:0]     imem_rdata;
wire            imem_rvalid;
wire [XLEN-1:0] dmem_addr;
wire [XLEN-1:0] dmem_rdata;
wire            dmem_rvalid;
wire            dmem_read_req;
wire [XLEN-1:0] dmem_wdata;
wire [XLEN/8-1:0] dmem_wstrb;

wire [31:0] imem_addr32;
wire [31:0] imem_word_index;
wire [31:0] dmem_addr32;
wire [31:0] dmem_bus_base32;
wire [31:0] rom_read_word_index;
wire [63:0] dmem_wdata_ext;
wire [7:0]  dmem_wstrb_ext;
wire [31:0] dmem_mmio_addr32;
wire [31:0] dmem_mmio_wdata32;
wire [3:0]  dmem_mmio_wstrb4;

(* rom_style = "distributed" *) reg [7:0] rom_mem [0:ROM_BYTES-1];
reg  [31:0] done_value_r;
reg  [63:0] timer_value_r;
reg  [63:0] timer_cmp_r;
reg         timer_irq_en_r;

wire        dmem_write_en;
wire        imem_hit;
wire        rom_read_hit;
wire        ram_read_hit;
wire        ram_write_hit;
wire        mmio_word_hit;
wire [31:0] rom_read_offset;
wire [31:0] ram_read_offset;
wire [31:0] ram_bus_offset;
wire        ram_read_issue;
wire        dmem_read_accept;
wire [XLEN-1:0] rom_read_data;
wire [31:0] sync_shared_imem_rdata;
wire        sync_shared_imem_rvalid;
wire [31:0] sync_shared_rom_read_data;
wire [XLEN-1:0] ram_read_data;
wire [31:0] sync_imem_rdata;
wire        sync_imem_rvalid;
wire [XLEN-1:0] dmem_rdata_comb;
wire [XLEN-1:0] nonram_read_data_comb;
reg  [31:0] mmio_read_word;
reg  [63:0] mmio_read_data_ext;
reg  [1:0]      dmem_read_src_r;
reg  [1:0]      dmem_read_src_d1_r;
reg  [XLEN-1:0] dmem_nonram_rdata_r;
reg  [XLEN-1:0] dmem_nonram_rdata_d1_r;
reg             dmem_rvalid_sync_r;
reg             dmem_rvalid_sync_d1_r;
reg             dmem_read_busy_r;
wire [31:0] timer_ctrl_next;

integer idx;
localparam integer STRB_W = XLEN / 8;
localparam integer ROM_WORDS = ROM_BYTES / 4;
localparam integer BUS_ALIGN_LSB = (XLEN == 64) ? 3 : 2;
localparam integer USE_SHARED_SYNC_ROM = ((XLEN == 32) && (SYNC_IMEM != 0) && (SYNC_DMEM != 0)) ? 1 : 0;
localparam integer USE_IMEM_OUTPUT_REG = ((SYNC_IMEM != 0) && (IMEM_OUTPUT_REG != 0)) ? 1 : 0;
localparam integer USE_DMEM_OUTPUT_REG = ((SYNC_DMEM != 0) && (DMEM_OUTPUT_REG != 0)) ? 1 : 0;
localparam [1:0] DMEM_SRC_NONE = 2'b00;
localparam [1:0] DMEM_SRC_RAM  = 2'b01;
localparam [1:0] DMEM_SRC_ROM  = 2'b10;
localparam [1:0] DMEM_SRC_MMIO = 2'b11;

function automatic [31:0] apply_wstrb;
    input [31:0] current_value;
    input [31:0] write_value;
    input [3:0]  write_strobe;
    begin
        apply_wstrb = current_value;
        if (write_strobe[0]) apply_wstrb[7:0]   = write_value[7:0];
        if (write_strobe[1]) apply_wstrb[15:8]  = write_value[15:8];
        if (write_strobe[2]) apply_wstrb[23:16] = write_value[23:16];
        if (write_strobe[3]) apply_wstrb[31:24] = write_value[31:24];
    end
endfunction

assign imem_addr32 = imem_addr[31:0];
assign imem_word_index = (imem_addr32 - ROM_BASE) >> 2;
assign dmem_addr32 = dmem_addr[31:0];
assign dmem_wdata_ext = {{(64-XLEN){1'b0}}, dmem_wdata};
assign dmem_wstrb_ext = {{(8-STRB_W){1'b0}}, dmem_wstrb};
assign dmem_write_en = |dmem_wstrb;
assign dmem_bus_base32 = {dmem_addr32[31:BUS_ALIGN_LSB], {BUS_ALIGN_LSB{1'b0}}};
assign dmem_mmio_addr32 = (XLEN == 64) ? {dmem_addr32[31:3], dmem_addr32[2], 2'b00} : {dmem_addr32[31:2], 2'b00};
assign dmem_mmio_wdata32 = ((XLEN == 64) && dmem_addr32[2]) ? dmem_wdata_ext[63:32] : dmem_wdata_ext[31:0];
assign dmem_mmio_wstrb4 = ((XLEN == 64) && dmem_addr32[2]) ? dmem_wstrb_ext[7:4] : dmem_wstrb_ext[3:0];

assign timer_ctrl_next = apply_wstrb({31'b0, timer_irq_en_r}, dmem_mmio_wdata32, dmem_mmio_wstrb4);
assign imem_hit      = (imem_addr32 >= ROM_BASE) && (imem_addr32 <= (ROM_BASE + ROM_BYTES - 4));
assign rom_read_hit  = (dmem_bus_base32 >= ROM_BASE) && (dmem_bus_base32 <= (ROM_BASE + ROM_BYTES - STRB_W));
assign ram_read_hit  = (dmem_bus_base32 >= RAM_BASE) && (dmem_bus_base32 <= (RAM_BASE + RAM_BYTES - STRB_W));
assign ram_write_hit = (dmem_addr32 >= RAM_BASE) && (dmem_addr32 < (RAM_BASE + RAM_BYTES));
assign mmio_word_hit = (dmem_mmio_addr32 == UART_TX_ADDR) || (dmem_mmio_addr32 == DONE_ADDR) ||
    (dmem_mmio_addr32 == TIMER_VALUE_LO) || (dmem_mmio_addr32 == TIMER_VALUE_HI) ||
    (dmem_mmio_addr32 == TIMER_CMP_LO) || (dmem_mmio_addr32 == TIMER_CMP_HI) ||
    (dmem_mmio_addr32 == TIMER_CTRL_ADDR);
assign rom_read_offset = dmem_bus_base32 - ROM_BASE;
assign rom_read_word_index = rom_read_offset >> 2;
assign ram_read_offset = dmem_bus_base32 - RAM_BASE;
assign ram_bus_offset = dmem_bus_base32 - RAM_BASE;
assign dmem_read_accept = (SYNC_DMEM != 0) ? (dmem_read_req && !dmem_read_busy_r) : dmem_read_req;
assign ram_read_issue = ram_read_hit && ((SYNC_DMEM != 0) ? dmem_read_accept : 1'b1);

generate
    if (USE_SHARED_SYNC_ROM != 0) begin : g_shared_sync_rom
        YH_rv_sync_rom32 #(
            .ROM_WORDS       (ROM_WORDS),
            .ROM_INIT_HEX    (ROM_INIT_MEM32_HEX),
            .IMEM_OUTPUT_REG (USE_IMEM_OUTPUT_REG)
        ) u_sync_rom (
            .clk            (clk),
            .rst_n          (rst_n),
            .imem_req       (imem_hit && imem_req),
            .imem_word_index(imem_word_index),
            .imem_rdata     (sync_shared_imem_rdata),
            .imem_rvalid    (sync_shared_imem_rvalid),
            .data_req       (rom_read_hit && dmem_read_accept),
            .data_word_index(rom_read_word_index),
            .data_rdata     (sync_shared_rom_read_data)
        );

        assign imem_rdata = sync_shared_imem_rdata;
        assign imem_rvalid = sync_shared_imem_rvalid;
        assign rom_read_data = {{(XLEN-32){1'b0}}, sync_shared_rom_read_data};
    end else begin : g_legacy_rom
        if (XLEN == 64) begin : g_bus64
            assign rom_read_data = {
                rom_mem[rom_read_offset + 32'd7],
                rom_mem[rom_read_offset + 32'd6],
                rom_mem[rom_read_offset + 32'd5],
                rom_mem[rom_read_offset + 32'd4],
                rom_mem[rom_read_offset + 32'd3],
                rom_mem[rom_read_offset + 32'd2],
                rom_mem[rom_read_offset + 32'd1],
                rom_mem[rom_read_offset + 32'd0]
            };
        end else begin : g_bus32
            assign rom_read_data = {
                rom_mem[rom_read_offset + 32'd3],
                rom_mem[rom_read_offset + 32'd2],
                rom_mem[rom_read_offset + 32'd1],
                rom_mem[rom_read_offset + 32'd0]
            };
        end

        if (SYNC_IMEM != 0) begin : g_sync_imem
            YH_rv_sync_imem_rom #(
                .ROM_WORDS (ROM_WORDS),
                .ROM_INIT_HEX(ROM_INIT_MEM32_HEX),
                .OUTPUT_REG(USE_IMEM_OUTPUT_REG)
            ) u_sync_imem_rom (
                .clk       (clk),
                .rst_n     (rst_n),
                .req_hit   (imem_hit && imem_req),
                .word_index(imem_word_index),
                .rdata     (sync_imem_rdata),
                .rvalid    (sync_imem_rvalid)
            );

            assign imem_rdata = sync_imem_rdata;
            assign imem_rvalid = sync_imem_rvalid;
        end else begin : g_async_imem
            assign imem_rdata = imem_hit ? {
                rom_mem[imem_addr32 + 32'd3],
                rom_mem[imem_addr32 + 32'd2],
                rom_mem[imem_addr32 + 32'd1],
                rom_mem[imem_addr32 + 32'd0]
            } : 32'h0000_0013;
            assign imem_rvalid = 1'b1;
        end
    end
endgenerate

YH_rv_dmem_ram #(
    .XLEN      (XLEN),
    .RAM_BYTES (RAM_BYTES),
    .SYNC_READ (SYNC_DMEM),
    .OUTPUT_REG(DMEM_OUTPUT_REG)
) u_dmem_ram (
    .clk        (clk),
    .read_req   (ram_read_issue),
    .read_offset(ram_read_offset),
    .read_data  (ram_read_data),
    .write_en   (ram_write_hit && dmem_write_en),
    .write_offset(ram_bus_offset),
    .write_data (dmem_wdata),
    .write_wstrb(dmem_wstrb)
);

always @* begin
    case (dmem_mmio_addr32)
        DONE_ADDR:       mmio_read_word = done_value_r;
        TIMER_VALUE_LO:  mmio_read_word = timer_value_r[31:0];
        TIMER_VALUE_HI:  mmio_read_word = timer_value_r[63:32];
        TIMER_CMP_LO:    mmio_read_word = timer_cmp_r[31:0];
        TIMER_CMP_HI:    mmio_read_word = timer_cmp_r[63:32];
        TIMER_CTRL_ADDR: mmio_read_word = {30'b0, timer_irq, timer_irq_en_r};
        default:         mmio_read_word = 32'h0000_0000;
    endcase
end

always @* begin
    if (XLEN == 64) begin
        mmio_read_data_ext = dmem_addr32[2] ? {mmio_read_word, 32'h0000_0000} : {32'h0000_0000, mmio_read_word};
    end else begin
        mmio_read_data_ext = {32'h0000_0000, mmio_read_word};
    end
end

assign nonram_read_data_comb =
    rom_read_hit  ? rom_read_data :
    mmio_word_hit ? mmio_read_data_ext[XLEN-1:0] :
    {XLEN{1'b0}};
assign dmem_rdata_comb =
    ram_read_hit ? ram_read_data : nonram_read_data_comb;
assign dmem_rdata = (SYNC_DMEM != 0) ?
    ((USE_DMEM_OUTPUT_REG != 0) ?
        ((dmem_read_src_d1_r == DMEM_SRC_RAM) ? ram_read_data :
         (dmem_read_src_d1_r == DMEM_SRC_ROM) ? rom_read_data :
         dmem_nonram_rdata_d1_r) :
        ((dmem_read_src_r == DMEM_SRC_RAM) ? ram_read_data :
         (dmem_read_src_r == DMEM_SRC_ROM) ? rom_read_data :
         dmem_nonram_rdata_r)) :
    dmem_rdata_comb;
assign dmem_rvalid = (SYNC_DMEM != 0) ?
    ((USE_DMEM_OUTPUT_REG != 0) ? dmem_rvalid_sync_d1_r : dmem_rvalid_sync_r) :
    1'b1;

assign done = done_value_r[0];
assign timer_irq = timer_irq_en_r && (timer_value_r >= timer_cmp_r);

YH_rv_cpu #(
    .XLEN           (XLEN),
    .IMEM_SYNC      (SYNC_IMEM),
    .IMEM_OUTPUT_REG(USE_IMEM_OUTPUT_REG),
    .DMEM_SYNC      (SYNC_DMEM),
    .RESET_VECTOR   (RESET_VECTOR)
) u_cpu (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (timer_irq),
    .imem_req  (imem_req),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_read_req(dmem_read_req),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .trap      (trap),
    .debug_pc  (debug_pc)
);

generate
    if (USE_SHARED_SYNC_ROM == 0) begin : g_legacy_rom_init
        initial begin
            for (idx = 0; idx < ROM_BYTES; idx = idx + 1) begin
                rom_mem[idx] = 8'h13;
            end
            if (ROM_INIT_HEX != "") begin
                $readmemh(ROM_INIT_HEX, rom_mem);
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dmem_read_src_r <= DMEM_SRC_NONE;
        dmem_read_src_d1_r <= DMEM_SRC_NONE;
        dmem_nonram_rdata_r <= {XLEN{1'b0}};
        dmem_nonram_rdata_d1_r <= {XLEN{1'b0}};
        dmem_rvalid_sync_r <= 1'b0;
        dmem_rvalid_sync_d1_r <= 1'b0;
        dmem_read_busy_r <= 1'b0;
    end else begin
        dmem_read_src_d1_r <= dmem_read_src_r;
        dmem_nonram_rdata_d1_r <= dmem_nonram_rdata_r;
        dmem_rvalid_sync_d1_r <= dmem_rvalid_sync_r;
        dmem_rvalid_sync_r <= dmem_read_accept;
        if (dmem_rvalid) begin
            dmem_read_busy_r <= 1'b0;
        end
        if (dmem_read_accept) begin
            dmem_read_busy_r <= 1'b1;
            if (ram_read_hit) begin
                dmem_read_src_r <= DMEM_SRC_RAM;
                dmem_nonram_rdata_r <= {XLEN{1'b0}};
            end else if (rom_read_hit) begin
                dmem_read_src_r <= DMEM_SRC_ROM;
                dmem_nonram_rdata_r <= {XLEN{1'b0}};
            end else if (mmio_word_hit) begin
                dmem_read_src_r <= DMEM_SRC_MMIO;
                dmem_nonram_rdata_r <= mmio_read_data_ext[XLEN-1:0];
            end else begin
                dmem_read_src_r <= DMEM_SRC_NONE;
                dmem_nonram_rdata_r <= {XLEN{1'b0}};
            end
        end else begin
            dmem_read_src_r <= DMEM_SRC_NONE;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        uart_tx_valid  <= 1'b0;
        uart_tx_data   <= 8'h00;
        done_value_r   <= 32'h0000_0000;
        timer_value_r  <= 64'h0000_0000_0000_0000;
        timer_cmp_r    <= 64'hffff_ffff_ffff_ffff;
        timer_irq_en_r <= 1'b0;
    end else begin
        uart_tx_valid <= 1'b0;
        timer_value_r <= timer_value_r + 64'd1;

        if (!ram_write_hit && dmem_write_en) begin
            case (dmem_mmio_addr32)
                UART_TX_ADDR: begin
                    uart_tx_valid <= 1'b1;
                    if (dmem_mmio_wstrb4[0]) begin
                        uart_tx_data <= dmem_mmio_wdata32[7:0];
                    end else if (dmem_mmio_wstrb4[1]) begin
                        uart_tx_data <= dmem_mmio_wdata32[15:8];
                    end else if (dmem_mmio_wstrb4[2]) begin
                        uart_tx_data <= dmem_mmio_wdata32[23:16];
                    end else begin
                        uart_tx_data <= dmem_mmio_wdata32[31:24];
                    end
                end

                DONE_ADDR: begin
                    done_value_r <= apply_wstrb(done_value_r, dmem_mmio_wdata32, dmem_mmio_wstrb4);
                end

                TIMER_CMP_LO: begin
                    timer_cmp_r[31:0] <= apply_wstrb(timer_cmp_r[31:0], dmem_mmio_wdata32, dmem_mmio_wstrb4);
                end

                TIMER_CMP_HI: begin
                    timer_cmp_r[63:32] <= apply_wstrb(timer_cmp_r[63:32], dmem_mmio_wdata32, dmem_mmio_wstrb4);
                end

                TIMER_CTRL_ADDR: begin
                    timer_irq_en_r <= timer_ctrl_next[0];
                    if (dmem_mmio_wstrb4[0] && dmem_mmio_wdata32[1]) begin
                        timer_value_r <= 64'h0000_0000_0000_0000;
                    end
                end

                default: begin
                end
            endcase
        end
    end
end

endmodule
