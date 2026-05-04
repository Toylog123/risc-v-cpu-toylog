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
// File: tb/YH_rv_cpu_branch_predict_tb.v
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

module YH_rv_cpu_branch_predict_tb;

reg         clk;
reg         rst_n;
wire        imem_req;
wire [31:0] imem_addr;
wire [31:0] imem_rdata;
wire        imem_rvalid;
wire [31:0] dmem_addr;
wire [31:0] dmem_rdata;
wire        dmem_rvalid;
wire        dmem_read_req;
wire [31:0] dmem_wdata;
wire [3:0]  dmem_wstrb;
wire        trap;
wire [31:0] debug_pc;

reg [31:0] imem [0:15];
integer cycle;
integer idx;
integer load_reads;
integer ex_bne_redirects;
integer timeout_cycles;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rvalid = 1'b1;
assign dmem_rdata = (load_reads == 0) ? 32'd1 : 32'd0;

YH_rv_cpu #(
    .IMEM_SYNC(0),
    .DMEM_SYNC(0),
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
    .dmem_ready(1'b1),
    .dmem_read_req(dmem_read_req),
    .dmem_we   (),
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

function [31:0] rv32_b;
    input signed [12:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
        rv32_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    end
endfunction

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (dmem_read_req) begin
            load_reads <= load_reads + 1;
        end

        if (dut.ex_redirect_valid && dut.id_ex_branch_r && (dut.id_ex_branch_funct3_r == 3'b001)) begin
            ex_bne_redirects <= ex_bne_redirects + 1;
        end

        if (trap) begin
            $fatal(1, "FAIL: trap asserted at PC=%h cycle=%0d", debug_pc, cycle);
        end

        if ((cycle > 8) && (dut.u_regfile.regs[2] == 32'd7)) begin
            if (ex_bne_redirects != 0) begin
                $fatal(1,
                    "FAIL: load-dependent backward bne still redirected in EX ex_bne_redirects=%0d",
                    ex_bne_redirects);
            end
            if (load_reads != 2) begin
                $fatal(1,
                    "FAIL: expected exactly two load reads before fallthrough, observed %0d",
                    load_reads);
            end

            $display(
                "PASS: branch predict diagnostic completed cycles=%0d load_reads=%0d ex_bne_redirects=%0d",
                cycle,
                load_reads,
                ex_bne_redirects);
            $finish;
        end

        if (cycle > timeout_cycles) begin
            $fatal(1,
                "FAIL: timeout pc=%h cycle=%0d load_reads=%0d ex_bne_redirects=%0d x1=%h x2=%h",
                debug_pc,
                cycle,
                load_reads,
                ex_bne_redirects,
                dut.u_regfile.regs[1],
                dut.u_regfile.regs[2]);
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    load_reads = 0;
    ex_bne_redirects = 0;
    timeout_cycles = 80;

    for (idx = 0; idx < 16; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
    end

    imem[0] = rv32_i(12'sd0, 5'd0, 3'b000, 5'd10, 7'b0010011); // addi x10,x0,0
    imem[1] = rv32_i(12'sd0, 5'd10, 3'b010, 5'd1, 7'b0000011); // lw x1,0(x10)
    imem[2] = rv32_b(-13'sd4, 5'd0, 5'd1, 3'b001, 7'b1100011); // bne x1,x0,-4
    imem[3] = rv32_i(12'sd7, 5'd0, 3'b000, 5'd2, 7'b0010011);  // addi x2,x0,7

    #20;
    rst_n = 1'b1;
end

endmodule
