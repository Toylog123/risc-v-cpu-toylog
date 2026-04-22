module YH_rv_dmem_ram #(
    parameter integer XLEN = 32,
    parameter integer RAM_BYTES = 16384,
    parameter integer SYNC_READ = 0,
    parameter integer OUTPUT_REG = 0
) (
    input  wire            clk,
    input  wire            read_req,
    input  wire [31:0]     read_offset,
    output wire [XLEN-1:0] read_data,
    input  wire            write_en,
    input  wire [31:0]     write_offset,
    input  wire [XLEN-1:0] write_data,
    input  wire [XLEN/8-1:0] write_wstrb
);

// Derive byte-lane width, address alignment, and word depth from the selected XLEN.
localparam integer STRB_W = XLEN / 8;
localparam integer BUS_ALIGN_LSB = (XLEN == 64) ? 3 : 2;
localparam integer RAM_DEPTH = RAM_BYTES / STRB_W;

wire [31:0] read_index;
wire [31:0] write_index;

assign read_index = read_offset >> BUS_ALIGN_LSB;
assign write_index = write_offset >> BUS_ALIGN_LSB;

generate
    if (SYNC_READ != 0) begin : g_sync_ram
        // Synchronous-read mode maps cleanly onto block RAM style inference.
        (* ram_style = "block" *) reg [XLEN-1:0] ram_mem [0:RAM_DEPTH-1];
        reg [XLEN-1:0] read_data_r;
        reg [XLEN-1:0] read_data_pipe_r;
        integer idx;
        integer byte_idx;

        assign read_data = (OUTPUT_REG != 0) ? read_data_pipe_r : read_data_r;

        initial begin
`ifndef SYNTHESIS
            // Clear the model for simulation so uninitialized RAM does not hide software bugs.
            for (idx = 0; idx < RAM_DEPTH; idx = idx + 1) begin
                ram_mem[idx] = {XLEN{1'b0}};
            end
`endif
        end

        always @(posedge clk) begin
            // Apply byte strobes per lane so subword stores match the SoC bus contract.
            if (write_en && (write_index < RAM_DEPTH)) begin
                for (byte_idx = 0; byte_idx < STRB_W; byte_idx = byte_idx + 1) begin
                    if (write_wstrb[byte_idx]) begin
                        ram_mem[write_index][byte_idx * 8 +: 8] <= write_data[byte_idx * 8 +: 8];
                    end
                end
            end

            if (read_req && (read_index < RAM_DEPTH)) begin
                read_data_r <= ram_mem[read_index];
            end

            if (OUTPUT_REG != 0) begin
                // Optional extra output register models the FPGA-oriented memory timing point.
                read_data_pipe_r <= read_data_r;
            end
        end
    end else begin : g_async_ram
        // Asynchronous-read mode keeps simulation and lightweight FPGA probes fast.
        (* ram_style = "distributed" *) reg [XLEN-1:0] ram_mem [0:RAM_DEPTH-1];
        reg [XLEN-1:0] read_data_r;
        integer idx;
        integer byte_idx;

        assign read_data = read_data_r;

        initial begin
`ifndef SYNTHESIS
            // Zero the distributed RAM model during simulation for deterministic bring-up.
            for (idx = 0; idx < RAM_DEPTH; idx = idx + 1) begin
                ram_mem[idx] = {XLEN{1'b0}};
            end
`endif
        end

        always @* begin
            // Out-of-range or idle reads return zero rather than stale combinational data.
            if (read_req && (read_index < RAM_DEPTH)) begin
                read_data_r = ram_mem[read_index];
            end else begin
                read_data_r = {XLEN{1'b0}};
            end
        end

        always @(posedge clk) begin
            // Writes remain synchronous in both modes so store timing is consistent.
            if (write_en && (write_index < RAM_DEPTH)) begin
                for (byte_idx = 0; byte_idx < STRB_W; byte_idx = byte_idx + 1) begin
                    if (write_wstrb[byte_idx]) begin
                        ram_mem[write_index][byte_idx * 8 +: 8] <= write_data[byte_idx * 8 +: 8];
                    end
                end
            end
        end
    end
endgenerate

endmodule
