module YH_rv_cpu_soc #(
    parameter integer XLEN = 32,
    parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}},
    parameter [31:0] ROM_BASE = 32'h0000_0000,
    parameter [31:0] RAM_BASE = 32'h0000_4000,
    parameter integer ROM_BYTES = 16384,
    parameter integer RAM_BYTES = 16384,
    parameter string ROM_INIT_HEX = ""
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
wire [31:0]     imem_rdata;
wire [XLEN-1:0] dmem_addr;
wire [XLEN-1:0] dmem_rdata;
wire [XLEN-1:0] dmem_wdata;
wire [XLEN/8-1:0] dmem_wstrb;

wire [31:0] imem_addr32;
wire [31:0] dmem_addr32;
wire [31:0] dmem_bus_base32;
wire [63:0] dmem_wdata_ext;
wire [7:0]  dmem_wstrb_ext;
wire [31:0] dmem_mmio_addr32;
wire [31:0] dmem_mmio_wdata32;
wire [3:0]  dmem_mmio_wstrb4;

(* rom_style = "distributed" *) reg [7:0] rom_mem [0:ROM_BYTES-1];
(* ram_style = "distributed" *) reg [31:0] ram_mem32 [0:((RAM_BYTES/4)-1)];
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
wire [31:0] ram_read_word_index0;
wire [31:0] ram_read_word_index1;
wire [31:0] ram_write_word_index0;
wire [31:0] ram_write_word_index1;
wire [XLEN-1:0] rom_read_data;
wire [XLEN-1:0] ram_read_data;
reg  [31:0] mmio_read_word;
reg  [63:0] mmio_read_data_ext;
wire [31:0] timer_ctrl_next;

integer idx;
localparam integer STRB_W = XLEN / 8;
localparam integer RAM_WORDS = RAM_BYTES / 4;
localparam integer BUS_ALIGN_LSB = (XLEN == 64) ? 3 : 2;

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
assign ram_read_offset = dmem_bus_base32 - RAM_BASE;
assign ram_read_word_index0 = ram_read_offset[31:2];
assign ram_read_word_index1 = ram_read_word_index0 + 32'd1;
assign ram_write_word_index0 = (dmem_bus_base32 - RAM_BASE) >> 2;
assign ram_write_word_index1 = ram_write_word_index0 + 32'd1;

generate
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
        assign ram_read_data = {
            ram_mem32[ram_read_word_index1],
            ram_mem32[ram_read_word_index0]
        };
    end else begin : g_bus32
        assign rom_read_data = {
            rom_mem[rom_read_offset + 32'd3],
            rom_mem[rom_read_offset + 32'd2],
            rom_mem[rom_read_offset + 32'd1],
            rom_mem[rom_read_offset + 32'd0]
        };
        assign ram_read_data = {
            ram_mem32[ram_read_word_index0]
        };
    end
endgenerate

assign imem_rdata = imem_hit ? {
    rom_mem[imem_addr32 + 32'd3],
    rom_mem[imem_addr32 + 32'd2],
    rom_mem[imem_addr32 + 32'd1],
    rom_mem[imem_addr32 + 32'd0]
} : 32'h0000_0013;

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

assign dmem_rdata =
    rom_read_hit  ? rom_read_data :
    ram_read_hit  ? ram_read_data :
    mmio_word_hit ? mmio_read_data_ext[XLEN-1:0] :
    {XLEN{1'b0}};

assign done = done_value_r[0];
assign timer_irq = timer_irq_en_r && (timer_value_r >= timer_cmp_r);

YH_rv_cpu #(
    .XLEN(XLEN),
    .RESET_VECTOR(RESET_VECTOR)
) u_cpu (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (timer_irq),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .trap      (trap),
    .debug_pc  (debug_pc)
);

initial begin
    for (idx = 0; idx < ROM_BYTES; idx = idx + 1) begin
        rom_mem[idx] = 8'h13;
    end
`ifndef SYNTHESIS
    for (idx = 0; idx < (RAM_BYTES / 4); idx = idx + 1) begin
        ram_mem32[idx] = 32'h0000_0000;
    end
`endif
    if (ROM_INIT_HEX != "") begin
        $readmemh(ROM_INIT_HEX, rom_mem);
    end
end

always @(posedge clk) begin
    if (ram_write_hit && dmem_write_en) begin
        if ((ram_write_word_index0 < RAM_WORDS) && (|dmem_wstrb_ext[3:0])) begin
            ram_mem32[ram_write_word_index0] <= apply_wstrb(ram_mem32[ram_write_word_index0], dmem_wdata_ext[31:0], dmem_wstrb_ext[3:0]);
        end

        if ((XLEN == 64) && (ram_write_word_index1 < RAM_WORDS) && (|dmem_wstrb_ext[7:4])) begin
            ram_mem32[ram_write_word_index1] <= apply_wstrb(ram_mem32[ram_write_word_index1], dmem_wdata_ext[63:32], dmem_wstrb_ext[7:4]);
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
