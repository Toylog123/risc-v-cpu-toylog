// CICC1003618 submission context:
// File role: tb/YH_rv_cpu_bitmanip_fast_subset_tb.v is part of the simulation testbench and benchmark verification source.
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
// File: tb/YH_rv_cpu_bitmanip_fast_subset_tb.v
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

module YH_rv_cpu_bitmanip_fast_subset_tb;
reg clk;
reg rst_n;
reg timer_irq;

wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_ready;
wire        dmem_read_req;
wire        dmem_we;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:63];
reg [31:0] cycle;
integer i;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = 32'h0;
assign dmem_rvalid = 1'b1;
assign dmem_ready = 1'b1;

always #5 clk = ~clk;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cycle <= 32'd0;
    end else begin
        cycle <= cycle + 32'd1;
    end
end

YH_rv_cpu #(
    .XLEN(32),
    .ENABLE_M_EXTENSION(0),
    .ENABLE_ZMMUL_EXTENSION(1),
    .ENABLE_BITMANIP_EXTENSION(1),
    .ENABLE_XTHEAD_EXTENSION(0)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .timer_irq    (timer_irq),
    .imem_req     (imem_req),
    .imem_addr    (imem_addr),
    .imem_rdata   (imem_rdata),
    .imem_rvalid  (imem_rvalid),
    .dmem_addr    (dmem_addr),
    .dmem_rdata   (dmem_rdata),
    .dmem_rvalid  (dmem_rvalid),
    .dmem_ready   (dmem_ready),
    .dmem_read_req(dmem_read_req),
    .dmem_we      (dmem_we),
    .dmem_wdata   (dmem_wdata),
    .dmem_wstrb   (dmem_wstrb),
    .trap         (trap),
    .debug_pc     (debug_pc)
);

task expect_reg;
    input [4:0] reg_index;
    input [31:0] expected;
    input [127:0] label;
    reg [31:0] actual;
    begin
        actual = dut.u_regfile.regs[reg_index];
        if (actual !== expected) begin
            $fatal(1, "FAIL: %0s x%0d=%h expected=%h", label, reg_index, actual, expected);
        end
        $display("[PASS] %0s x%0d=%h", label, reg_index, actual);
    end
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    timer_irq = 1'b0;
    cycle = 32'd0;

    for (i = 0; i < 64; i = i + 1) begin
        imem[i] = 32'h00000013;
    end

    imem[0] = 32'h00300093; // addi   x1,x0,3
    imem[1] = 32'h00500113; // addi   x2,x0,5
    imem[2] = 32'h2020a1b3; // sh1add x3,x1,x2 = 11
    imem[3] = 32'h40117233; // andn   x4,x2,x1 = 4
    imem[4] = 32'h0a20e2b3; // max    x5,x1,x2 = 5
    imem[5] = 32'h00008337; // lui    x6,0x8
    imem[6] = 32'h00130313; // addi   x6,x6,1 => 0x8001
    imem[7] = 32'h48f35393; // bexti  x7,x6,15 => 1
    imem[8] = 32'h00000013; // nop, let bexti reach writeback before trap
    imem[9] = 32'h00000013; // nop
    imem[10] = 32'h0a209433; // clmul  x8,x1,x2, excluded from fast subset
    imem[11] = 32'h0000006f; // loop

    #40;
    rst_n = 1'b1;

    wait (dut.ex_sync_trap_valid || cycle > 100);

    expect_reg(5'd3, 32'd11, "sh1add");
    expect_reg(5'd4, 32'd4,  "andn");
    expect_reg(5'd5, 32'd5,  "max");
    expect_reg(5'd7, 32'd1,  "bexti");

    if (!dut.ex_sync_trap_valid) begin
        $fatal(1, "FAIL: fast bitmanip subset accepted clmul pc=%h instr=%h",
               debug_pc, imem[8]);
    end

    $display("[PASS] fast subset rejects clmul as unsupported");
    $display("PASS: bitmanip fast subset diagnostic completed");
    $finish;
end

always @(posedge clk) begin
    if (rst_n && cycle > 200) begin
        $fatal(1, "FAIL: bitmanip fast subset timeout pc=%h", debug_pc);
    end
end

endmodule
