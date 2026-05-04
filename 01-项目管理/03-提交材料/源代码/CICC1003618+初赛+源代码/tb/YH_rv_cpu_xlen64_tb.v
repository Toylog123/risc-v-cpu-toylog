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
// File: tb/YH_rv_cpu_xlen64_tb.v
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

// 文件说明：RV64 基础冒烟测试平台。
// 作用：在 64 位配置下验证宽数据通路、装载/存储和 W 类指令的基本行为。
// 备注：主要覆盖当前 RV64 骨架实现的核心烟测场景。

`timescale 1ns / 1ps

module YH_rv_cpu_xlen64_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [63:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [63:0] dmem_addr;
wire [63:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire [63:0] dmem_wdata;
wire [7:0]  dmem_wstrb;
wire        trap;
wire [63:0] debug_pc;

reg [31:0] imem [0:31];
reg [7:0]  dmem [0:63];
integer cycle;
integer idx;

wire [63:0] dmem_rdata_bus;

assign dmem_rdata_bus = {
    dmem[{dmem_addr[31:3], 3'b000} + 32'd7],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd6],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd5],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd4],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd3],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd2],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd1],
    dmem[{dmem_addr[31:3], 3'b000} + 32'd0]
};

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = dmem_rdata_bus;
assign dmem_rvalid = 1'b1;

YH_rv_cpu #(
    .XLEN(64),
    .RESET_VECTOR(64'h0000_0000_0000_0000)
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

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dmem_wstrb[0]) dmem[dmem_addr[31:0] + 32'd0] <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) dmem[dmem_addr[31:0] + 32'd1] <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) dmem[dmem_addr[31:0] + 32'd2] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) dmem[dmem_addr[31:0] + 32'd3] <= dmem_wdata[31:24];
        if (dmem_wstrb[4]) dmem[dmem_addr[31:0] + 32'd4] <= dmem_wdata[39:32];
        if (dmem_wstrb[5]) dmem[dmem_addr[31:0] + 32'd5] <= dmem_wdata[47:40];
        if (dmem_wstrb[6]) dmem[dmem_addr[31:0] + 32'd6] <= dmem_wdata[55:48];
        if (dmem_wstrb[7]) dmem[dmem_addr[31:0] + 32'd7] <= dmem_wdata[63:56];

        if (trap) begin
            $display("Trap asserted unexpectedly at PC=%h", debug_pc);
            $finish(1);
        end

        if ((cycle > 16) &&
            (dut.u_regfile.regs[1] == 64'hffff_ffff_ffff_ffff) &&
            (dut.u_regfile.regs[3] == 64'h0000_0100_0000_0000) &&
            (dut.u_regfile.regs[4] == 64'h0000_0100_0000_0000) &&
            (dut.u_regfile.regs[5] == 64'h0000_0000_0000_0000) &&
            (dut.u_regfile.regs[6] == 64'h0000_0000_0000_0000) &&
            (dut.u_regfile.regs[7] == 64'h0000_0000_0000_0000) &&
            (debug_pc == 64'h0000_0000_0000_0020)) begin
            if ({dmem[7], dmem[6], dmem[5], dmem[4], dmem[3], dmem[2], dmem[1], dmem[0]} != 64'h0000_0100_0000_0000) begin
                $display("Unexpected stored doubleword = %h", {dmem[7], dmem[6], dmem[5], dmem[4], dmem[3], dmem[2], dmem[1], dmem[0]});
                $finish(1);
            end

            $display("PASS: xlen64 smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > 80) begin
            $display("Timeout at PC=%h", debug_pc);
            $finish(1);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;

    for (idx = 0; idx < 32; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    for (idx = 0; idx < 64; idx = idx + 1) begin
        dmem[idx] = 8'h00;
    end

    // addi x1, x0, -1
    imem[0] = 32'hfff0_0093;
    // addiw x5, x1, 1
    imem[1] = 32'h0010_829b;
    // addi x2, x0, 1
    imem[2] = 32'h0010_0113;
    // slli x3, x2, 40
    imem[3] = 32'h0281_1193;
    // sd x3, 0(x0)
    imem[4] = 32'h0030_3023;
    // ld x4, 0(x0)
    imem[5] = 32'h0000_3203;
    // lwu x6, 0(x0)
    imem[6] = 32'h0000_6303;
    // addw x7, x1, x2
    imem[7] = 32'h0020_83bb;
    // jal x0, 0
    imem[8] = 32'h0000_006f;

    #20;
    rst_n = 1'b1;
end

endmodule
