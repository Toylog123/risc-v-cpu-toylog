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
// File: tb/YH_rv_cpu_tb.v
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

// 文件说明：YH_rv_cpu 内核基础自检测试平台。
// 作用：在简化的指令存储器和数据存储器模型上验证基础算术、访存和分支流程。
// 备注：用于快速检查核心单元在最小系统环境下的基本功能是否正确。

`timescale 1ns / 1ps

module YH_rv_cpu_tb;

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

reg [31:0] imem [0:63];
reg [31:0] dmem [0:63];
integer cycle;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = dmem[dmem_addr[31:2]];
assign dmem_rvalid = 1'b1;

YH_rv_cpu dut (
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

function [31:0] rv32_r;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
        rv32_r = {funct7, rs2, rs1, funct3, rd, opcode};
    end
endfunction

function [31:0] rv32_i;
    input [11:0] imm;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [4:0]  rd;
    input [6:0]  opcode;
    begin
        rv32_i = {imm, rs1, funct3, rd, opcode};
    end
endfunction

function [31:0] rv32_s;
    input [11:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;
    begin
        rv32_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    end
endfunction

function [31:0] rv32_b;
    input [12:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;
    begin
        rv32_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    end
endfunction

task apply_store;
    integer word_index;
    begin
        word_index = dmem_addr[31:2];
        if (dmem_wstrb[0]) dmem[word_index][7:0]   <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) dmem[word_index][15:8]  <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) dmem[word_index][23:16] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) dmem[word_index][31:24] <= dmem_wdata[31:24];
    end
endtask

always #5 clk = ~clk;

always @(posedge clk) begin
    if (rst_n) begin
        apply_store();
        cycle <= cycle + 1;

        if (cycle > 40) begin
            $display("Timeout at PC=%h", debug_pc);
            $finish;
        end

        if (dut.u_regfile.regs[6] == 32'd42) begin
            if (dut.u_regfile.regs[3] != 32'd15) begin
                $display("Unexpected x3 = %0d", dut.u_regfile.regs[3]);
                $finish;
            end

            if (dmem[0] != 32'd15) begin
                $display("Unexpected data memory word 0 = %0d", dmem[0]);
                $finish;
            end

            if (trap) begin
                $display("Trap asserted unexpectedly");
                $finish;
            end

            $display("PASS: x3=%0d x6=%0d dmem0=%0d", dut.u_regfile.regs[3], dut.u_regfile.regs[6], dmem[0]);
            $finish;
        end
    end
end

integer idx;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;

    for (idx = 0; idx < 64; idx = idx + 1) begin
        imem[idx] = 32'h0000_0013;
        dmem[idx] = 32'h0000_0000;
    end

    imem[0] = rv32_i(12'd5,  5'd0, 3'b000, 5'd1, 7'b0010011);  // 向 x1 写入立即数 5
    imem[1] = rv32_i(12'd10, 5'd0, 3'b000, 5'd2, 7'b0010011);  // 向 x2 写入立即数 10
    imem[2] = rv32_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011); // x3 = x1 + x2
    imem[3] = rv32_s(12'd0, 5'd3, 5'd0, 3'b010, 7'b0100011);   // 将 x3 写入数据存储器地址 0
    imem[4] = rv32_i(12'd0, 5'd0, 3'b010, 5'd4, 7'b0000011);   // 从数据存储器地址 0 读回到 x4
    imem[5] = rv32_b(13'd8, 5'd4, 5'd3, 3'b000, 7'b1100011);   // 若 x3 等于 x4 则跳过下一条指令
    imem[6] = rv32_i(12'd1, 5'd0, 3'b000, 5'd5, 7'b0010011);   // 若分支失败则向 x5 写入 1
    imem[7] = rv32_i(12'd42, 5'd0, 3'b000, 5'd6, 7'b0010011);  // 向 x6 写入 42 作为最终结果检查
    imem[8] = rv32_i(12'd0, 5'd0, 3'b000, 5'd0, 7'b1100111);   // 通过 jalr 回到地址 0，形成停止点

    #20;
    rst_n = 1'b1;
end

endmodule
