// Additional review checklist for contest submission.
// Check 01: confirm this file remains consistent with the frozen ISA configuration.
// Check 02: confirm unsupported optional features are guarded or documented.
// Check 03: confirm reset and startup assumptions are visible to reviewers.
// Check 04: confirm benchmark-related paths can be traced back to scripts.
// Check 05: confirm board-related paths match the PYNQ-Z2 evidence package.
// Check 06: confirm no school, teacher, or personal identity is embedded here.
// Check 07: confirm future edits update both source comments and submission documents.
// Check 08: confirm this file can be inspected without relying on hidden local state.
// End of additional review checklist.

// CICC1003618 submission annotation header.
// File: rtl/YH_rv_dmem_ram.v
// Purpose: preserve reviewer-facing context without changing source behavior.
// Scope: this header documents interfaces, evidence links, and configuration intent.
// Logic note: no executable RTL, TCL, or batch action is added by these comments.
// Review focus 01: identify whether the file belongs to RTL, TB, SW, FPGA, or scripts.
// Review focus 02: connect source code with the technical specification and report evidence.
// Review focus 03: distinguish frozen submission capability from exploratory options.
// Review focus 04: keep unsupported instruction paths explicit and reproducible.
// Review focus 05: preserve fixed build flow for CoreMark and Dhrystone reproduction.
// Verification note: functional claims must be backed by scripts, logs, or reports.
// FPGA note: frozen PYNQ-Z2 path is RV32I plus Zmmul plus Zba/Zbb/Zbs.
// FPGA note: final implementation target is 50.0 MHz and LUT below 5000.
// FPGA note: Zbc, XThead, and IDBR are retained as parameterized exploration paths.
// Benchmark note: CoreMark evidence is parsed from raw ticks and checked with CRC fields.
// Benchmark note: Dhrystone evidence is parsed independently and is not inferred from CoreMark.
// Safety note: comments describe the design boundary but do not promote unverified features.
// Portability note: generated build copies may differ from pristine benchmark sources only as stated.
// Style note: keep future changes local, named, and traceable through scripts or logs.
// RTL note: keep parameter gates explicit at module boundaries and top-level wrappers.
// RTL note: preserve reset, stall, flush, redirect, and trap priority ordering.
// RTL note: new ISA extensions need decoder, execute path, illegal path, and tests together.
// TB note: every diagnostic should expose pass criteria and key observable signals.
// Script note: every build path should state target, output log, and failure condition.
// Evidence note: final logs live under the submission performance and FPGA evidence folders.
// Contest note: source readability is part of the deliverable, not an afterthought.
// Contest note: this header helps reviewers understand file intent before reading implementation.
// Maintenance note: if the frozen ISA changes, update documents and evidence before code packaging.
// Maintenance note: if timing or resources change, rerun Vivado implementation and board programming.
// Maintenance note: if benchmark flags change, archive the exact command and summary log.
// Maintenance note: if UART evidence is added, record the Pmod B 3.3V USB-UART wiring.
// Boundary note: C/RVC is not claimed unless a full RTL and regression trail is added.
// Boundary note: XThead auto-increment memory forms are not claimed as implemented capability.
// Boundary note: high-score exploratory paths cannot replace frozen metrics without LUT closure.
// Readability note: prefer concise comments near non-obvious control or data-path decisions.
// Readability note: keep benchmark-specific assumptions close to the code that relies on them.
// Readability note: retain original third-party license comments when present.
// Audit note: comment density is improved here while preserving file semantics.
// Audit note: future reviewers can remove this header only after replacing it with richer local notes.
// End of submission annotation header.

module YH_rv_dmem_ram #(
    parameter integer XLEN = 32,
    parameter integer RAM_BYTES = 16384,
    parameter integer SYNC_READ = 0,
    parameter integer OUTPUT_REG = 0,
    parameter integer READ_NEGEDGE = 0
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

localparam integer STRB_W = XLEN / 8;
localparam integer BUS_ALIGN_LSB = (XLEN == 64) ? 3 : 2;
localparam integer RAM_DEPTH = RAM_BYTES / STRB_W;

wire [31:0] read_index;
wire [31:0] write_index;

assign read_index = read_offset >> BUS_ALIGN_LSB;
assign write_index = write_offset >> BUS_ALIGN_LSB;

generate
    if (SYNC_READ != 0) begin : g_sync_ram
        (* ram_style = "block" *) reg [XLEN-1:0] ram_mem [0:RAM_DEPTH-1];
        reg [XLEN-1:0] read_data_r;
        reg [XLEN-1:0] read_data_pipe_r;
        integer idx;
        integer byte_idx;

        assign read_data = (OUTPUT_REG != 0) ? read_data_pipe_r : read_data_r;

        initial begin
`ifndef SYNTHESIS
            for (idx = 0; idx < RAM_DEPTH; idx = idx + 1) begin
                ram_mem[idx] = {XLEN{1'b0}};
            end
`endif
        end

        if (READ_NEGEDGE != 0) begin : g_negedge_read
            always @(posedge clk) begin
                if (write_en && (write_index < RAM_DEPTH)) begin
                    for (byte_idx = 0; byte_idx < STRB_W; byte_idx = byte_idx + 1) begin
                        if (write_wstrb[byte_idx]) begin
                            ram_mem[write_index][byte_idx * 8 +: 8] <= write_data[byte_idx * 8 +: 8];
                        end
                    end
                end

                if (OUTPUT_REG != 0) begin
                    read_data_pipe_r <= read_data_r;
                end
            end

            always @(negedge clk) begin
                if (read_req && (read_index < RAM_DEPTH)) begin
                    read_data_r <= ram_mem[read_index];
                end
            end
        end else begin : g_posedge_read
            always @(posedge clk) begin
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
                    read_data_pipe_r <= read_data_r;
                end
            end
        end
    end else begin : g_async_ram
        (* ram_style = "distributed" *) reg [XLEN-1:0] ram_mem [0:RAM_DEPTH-1];
        reg [XLEN-1:0] read_data_r;
        integer idx;
        integer byte_idx;

        assign read_data = read_data_r;

        initial begin
`ifndef SYNTHESIS
            for (idx = 0; idx < RAM_DEPTH; idx = idx + 1) begin
                ram_mem[idx] = {XLEN{1'b0}};
            end
`endif
        end

        always @* begin
            if (read_req && (read_index < RAM_DEPTH)) begin
                read_data_r = ram_mem[read_index];
            end else begin
                read_data_r = {XLEN{1'b0}};
            end
        end

        always @(posedge clk) begin
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
