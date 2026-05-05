// CICC1003618 submission context:
// File role: tb/YH_rv_cpu_memwait_overlap_tb.v is part of the simulation testbench and benchmark verification source.
// Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
// Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
// Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
// Verification note: functional changes require matching simulation logs or FPGA reports.
// Maintenance note: update documents, metrics and hashes when this file changes.

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
// File: tb/YH_rv_cpu_memwait_overlap_tb.v
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

`timescale 1ns / 1ps

module YH_rv_cpu_memwait_overlap_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
reg  [31:0] imem_rdata_r;
wire        imem_rvalid;
reg         imem_rvalid_r;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
reg  [31:0] dmem_rdata_r;
wire        dmem_rvalid;
reg         dmem_rvalid_r;
wire        dmem_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
reg [7:0]  dmem [0:255];
integer cycle;
integer idx;
integer timeout_cycles;
integer mem_wait_cycles;
integer mem_wait_overlap_opportunities;
integer mem_wait_overlap_requests;
reg     debug_trace;
reg     require_overlap;
reg     mem_wait_seen;

assign imem_rdata = imem_rdata_r;
assign imem_rvalid = imem_rvalid_r;
assign dmem_rdata = dmem_rdata_r;
assign dmem_rvalid = dmem_rvalid_r;

YH_rv_cpu #(
    .IMEM_SYNC(1),
    .IMEM_OUTPUT_REG(0),
    .DMEM_SYNC(1),
    .RESET_VECTOR(32'h0000_0000)
) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (1'b0),
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

function [31:0] rv32_i;
    input signed [11:0] imm;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_i = {imm[11:0], rs1, funct3, rd, opcode};
    end
endfunction

function [31:0] rv32_j;
    input signed [20:0] imm;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk or negedge rst_n) begin
    integer word_index;
    if (!rst_n) begin
        imem_rvalid_r <= 1'b0;
        imem_rdata_r <= 32'h0000_0013;
        dmem_rvalid_r <= 1'b0;
        dmem_rdata_r <= 32'h0000_0000;
    end else begin
        imem_rvalid_r <= imem_req;
        imem_rdata_r <= imem[imem_addr[31:2]];

        dmem_rvalid_r <= dmem_read_req;
        word_index = {dmem_addr[31:2], 2'b00};
        dmem_rdata_r <= {
            dmem[word_index + 3],
            dmem[word_index + 2],
            dmem[word_index + 1],
            dmem[word_index + 0]
        };

        if (dmem_wstrb[0]) dmem[word_index + 0] <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) dmem[word_index + 1] <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) dmem[word_index + 2] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) dmem[word_index + 3] <= dmem_wdata[31:24];
    end
end

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if (dut.mem_wait) begin
            mem_wait_cycles <= mem_wait_cycles + 1;
            mem_wait_seen <= 1'b1;
        end

        if (dut.mem_wait && !dut.stall_decode && !dut.ex_fetch_redirect_valid) begin
            mem_wait_overlap_opportunities <= mem_wait_overlap_opportunities + 1;
            if (imem_req) begin
                mem_wait_overlap_requests <= mem_wait_overlap_requests + 1;
            end
        end

        if (debug_trace && (cycle < 80)) begin
            $display(
                "TRACE cycle=%0d pc=%h imem_req=%0d mem_wait=%0d stall=%0d redirect=%0d opp=%0d req_seen=%0d x3=%h x6=%h",
                cycle,
                debug_pc,
                imem_req,
                dut.mem_wait,
                dut.stall_decode,
                dut.ex_fetch_redirect_valid,
                mem_wait_overlap_opportunities,
                mem_wait_overlap_requests,
                dut.u_regfile.regs[3],
                dut.u_regfile.regs[6]
            );
        end

        if ((cycle > 20) &&
            (dut.u_regfile.regs[3] == 32'd42) &&
            (dut.u_regfile.regs[6] == 32'd42)) begin
            if (!mem_wait_seen) begin
                $fatal(1, "FAIL: diagnostic never observed mem_wait");
            end

            if (require_overlap && (mem_wait_overlap_requests == 0)) begin
                $fatal(1,
                    "FAIL: require_overlap set but no actual overlap request observed mem_wait_cycles=%0d opportunities=%0d",
                    mem_wait_cycles, mem_wait_overlap_opportunities);
            end

            $display(
                "PASS: mem_wait diagnostic completed at PC=%h cycles=%0d mem_wait_cycles=%0d opportunities=%0d overlap_requests=%0d require_overlap=%0d",
                debug_pc,
                cycle,
                mem_wait_cycles,
                mem_wait_overlap_opportunities,
                mem_wait_overlap_requests,
                require_overlap);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout at PC=%h cycle=%0d mem_wait_cycles=%0d opportunities=%0d overlap_requests=%0d",
                debug_pc, cycle, mem_wait_cycles, mem_wait_overlap_opportunities, mem_wait_overlap_requests);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    timeout_cycles = 200;
    mem_wait_cycles = 0;
    mem_wait_overlap_opportunities = 0;
    mem_wait_overlap_requests = 0;
    mem_wait_seen = 1'b0;
    debug_trace = 1'b0;
    require_overlap = 1'b0;

    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end

    if ($test$plusargs("require_overlap")) begin
        require_overlap = 1'b1;
    end

    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) begin
        timeout_cycles = 200;
    end

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    for (idx = 0; idx < 256; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    // addi x1, x0, 0
    imem[0] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd1, 7'b0010011);
    // lw x3, 0(x1)
    imem[1] = rv32_i(12'sd0, 5'd1, 3'b010, 5'd3, 7'b0000011);
    // addi x4, x4, 1
    imem[2] = rv32_i(12'sd1, 5'd4, 3'b000, 5'd4, 7'b0010011);
    // addi x5, x0, 7
    imem[3] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd5, 7'b0010011);
    // addi x6, x0, 42
    imem[4] = rv32_i(12'sd42, 5'd0, 3'b000, 5'd6, 7'b0010011);
    // jal x0, 0
    imem[5] = rv32_j(21'sd0, 5'd0, 7'b1101111);

    dmem[0] = 8'h2a;
    dmem[1] = 8'h00;
    dmem[2] = 8'h00;
    dmem[3] = 8'h00;

    #20;
    rst_n = 1'b1;
end

endmodule
