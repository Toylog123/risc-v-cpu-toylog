module YH_rv_cpu_soc #(
    parameter integer XLEN = 32,
    parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}},
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

localparam [31:0] ROM_BASE        = 32'h0000_0000;
localparam [31:0] RAM_BASE        = 32'h0000_4000;
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
wire [3:0]      dmem_wstrb;

wire [31:0] imem_addr32;
wire [31:0] dmem_addr32;
wire [31:0] dmem_aligned_addr32;
wire [31:0] dmem_wdata32;

reg  [7:0]  rom_mem [0:ROM_BYTES-1];
reg  [7:0]  ram_mem [0:RAM_BYTES-1];
reg  [31:0] done_value_r;
reg  [63:0] timer_value_r;
reg  [63:0] timer_cmp_r;
reg         timer_irq_en_r;

wire        dmem_write_en;
wire        imem_hit;
wire        rom_read_hit;
wire        ram_read_hit;
wire        ram_write_hit;
wire [31:0] rom_read_offset;
wire [31:0] ram_read_offset;
wire [31:0] ram_write_offset;
wire [31:0] rom_read_data;
wire [31:0] ram_read_data;
wire [31:0] timer_ctrl_next;

integer idx;

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
assign dmem_wdata32 = dmem_wdata[31:0];
assign dmem_write_en = |dmem_wstrb;
assign dmem_aligned_addr32 = {dmem_addr32[31:2], 2'b00};

assign timer_ctrl_next = apply_wstrb({31'b0, timer_irq_en_r}, dmem_wdata32, dmem_wstrb);
assign imem_hit      = (imem_addr32 >= ROM_BASE) && (imem_addr32 <= (ROM_BASE + ROM_BYTES - 4));
assign rom_read_hit  = (dmem_aligned_addr32 >= ROM_BASE) && (dmem_aligned_addr32 <= (ROM_BASE + ROM_BYTES - 4));
assign ram_read_hit  = (dmem_aligned_addr32 >= RAM_BASE) && (dmem_aligned_addr32 <= (RAM_BASE + RAM_BYTES - 4));
assign ram_write_hit = (dmem_addr32 >= RAM_BASE) && (dmem_addr32 < (RAM_BASE + RAM_BYTES));
assign rom_read_offset = dmem_aligned_addr32 - ROM_BASE;
assign ram_read_offset = dmem_aligned_addr32 - RAM_BASE;
assign ram_write_offset = dmem_addr32 - RAM_BASE;
assign rom_read_data = {
    rom_mem[rom_read_offset + 32'd3],
    rom_mem[rom_read_offset + 32'd2],
    rom_mem[rom_read_offset + 32'd1],
    rom_mem[rom_read_offset + 32'd0]
};
assign ram_read_data = {
    ram_mem[ram_read_offset + 32'd3],
    ram_mem[ram_read_offset + 32'd2],
    ram_mem[ram_read_offset + 32'd1],
    ram_mem[ram_read_offset + 32'd0]
};

assign imem_rdata = imem_hit ? {
    rom_mem[imem_addr32 + 32'd3],
    rom_mem[imem_addr32 + 32'd2],
    rom_mem[imem_addr32 + 32'd1],
    rom_mem[imem_addr32 + 32'd0]
} : 32'h0000_0013;

assign dmem_rdata =
    rom_read_hit                        ? {{(XLEN-32){1'b0}}, rom_read_data} :
    ram_read_hit                        ? {{(XLEN-32){1'b0}}, ram_read_data} :
    (dmem_aligned_addr32 == DONE_ADDR)  ? {{(XLEN-32){1'b0}}, done_value_r} :
    (dmem_aligned_addr32 == TIMER_VALUE_LO) ? {{(XLEN-32){1'b0}}, timer_value_r[31:0]} :
    (dmem_aligned_addr32 == TIMER_VALUE_HI) ? {{(XLEN-32){1'b0}}, timer_value_r[63:32]} :
    (dmem_aligned_addr32 == TIMER_CMP_LO) ? {{(XLEN-32){1'b0}}, timer_cmp_r[31:0]} :
    (dmem_aligned_addr32 == TIMER_CMP_HI) ? {{(XLEN-32){1'b0}}, timer_cmp_r[63:32]} :
    (dmem_aligned_addr32 == TIMER_CTRL_ADDR) ? {{(XLEN-32){1'b0}}, {30'b0, timer_irq, timer_irq_en_r}} :
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

    for (idx = 0; idx < RAM_BYTES; idx = idx + 1) begin
        ram_mem[idx] = 8'h00;
    end

    if (ROM_INIT_HEX != "") begin
        $readmemh(ROM_INIT_HEX, rom_mem);
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

        if (ram_write_hit && dmem_write_en) begin
            if (dmem_wstrb[0]) ram_mem[ram_write_offset + 32'd0] <= dmem_wdata32[7:0];
            if (dmem_wstrb[1] && (ram_write_offset + 32'd1 < RAM_BYTES)) ram_mem[ram_write_offset + 32'd1] <= dmem_wdata32[15:8];
            if (dmem_wstrb[2] && (ram_write_offset + 32'd2 < RAM_BYTES)) ram_mem[ram_write_offset + 32'd2] <= dmem_wdata32[23:16];
            if (dmem_wstrb[3] && (ram_write_offset + 32'd3 < RAM_BYTES)) ram_mem[ram_write_offset + 32'd3] <= dmem_wdata32[31:24];
        end else if (dmem_write_en) begin
            case (dmem_aligned_addr32)
                UART_TX_ADDR: begin
                    uart_tx_valid <= 1'b1;
                    if (dmem_wstrb[0]) begin
                        uart_tx_data <= dmem_wdata32[7:0];
                    end else if (dmem_wstrb[1]) begin
                        uart_tx_data <= dmem_wdata32[15:8];
                    end else if (dmem_wstrb[2]) begin
                        uart_tx_data <= dmem_wdata32[23:16];
                    end else begin
                        uart_tx_data <= dmem_wdata32[31:24];
                    end
                end

                DONE_ADDR: begin
                    done_value_r <= apply_wstrb(done_value_r, dmem_wdata32, dmem_wstrb);
                end

                TIMER_CMP_LO: begin
                    timer_cmp_r[31:0] <= apply_wstrb(timer_cmp_r[31:0], dmem_wdata32, dmem_wstrb);
                end

                TIMER_CMP_HI: begin
                    timer_cmp_r[63:32] <= apply_wstrb(timer_cmp_r[63:32], dmem_wdata32, dmem_wstrb);
                end

                TIMER_CTRL_ADDR: begin
                    timer_irq_en_r <= timer_ctrl_next[0];
                    if (dmem_wstrb[0] && dmem_wdata32[1]) begin
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
