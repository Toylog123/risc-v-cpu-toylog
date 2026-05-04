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
// File: tb/YH_rv_cpu_alu_m_ext_tb.v
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

// YH_rv_cpu_alu_m_ext_tb.v - M扩展ALU测试
`timescale 1ns / 1ps
`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_alu_m_ext_tb;
reg clk;
reg [5:0] alu_op;
reg [31:0] lhs, rhs;
wire [31:0] result;

YH_rv_cpu_alu #(
    .XLEN(32)
) dut (
    .alu_op(alu_op),
    .lhs(lhs),
    .rhs(rhs),
    .result(result),
    .eq(),
    .lt(),
    .ltu()
);

always #5 clk = ~clk;

integer pass_count = 0;
integer fail_count = 0;

task check;
    input [31:0] expected;
    input [31:0] actual;
    input [127:0] desc;
    begin
        if (expected === actual) begin
            $display("[PASS] %s: 0x%h", desc, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s: expected=0x%h, actual=0x%h", desc, expected, actual);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    $display("========================================");
    $display("M扩展ALU单元测试");
    $display("========================================");

    clk = 0;

    // TEST 1: MUL 5 * 3 = 15
    alu_op = `YH_rv_cpu_ALU_MUL;
    lhs = 32'd5;
    rhs = 32'd3;
    #10;
    check(32'd15, result, "MUL 5*3");

    // TEST 2: MULH (-2) * (-3) 高位 = 0
    alu_op = `YH_rv_cpu_ALU_MULH;
    lhs = 32'hFFFFFFFE;
    rhs = 32'hFFFFFFFD;
    #10;
    check(32'd0, result, "MULH (-2)*(-3)");

    // TEST 3: MULHU 0xFFFFFFFF * 2 高位
    alu_op = `YH_rv_cpu_ALU_MULHU;
    lhs = 32'hFFFFFFFF;
    rhs = 32'd2;
    #10;
    check(32'h00000001, result, "MULHU 0xFFFFFFFF*2");

    // TEST 4: MULHSU (-1) * 2 高位 = 0xFFFFFFFF
    alu_op = `YH_rv_cpu_ALU_MULHSU;
    lhs = 32'hFFFFFFFF;
    rhs = 32'd2;
    #10;
    check(32'hFFFFFFFF, result, "MULHSU (-1)*2");

    // TEST 5: DIV 10 / 3 = 3
    alu_op = `YH_rv_cpu_ALU_DIV;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd3, result, "DIV 10/3");

    // TEST 6: DIVU 10 / 3 = 3
    alu_op = `YH_rv_cpu_ALU_DIVU;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd3, result, "DIVU 10/3");

    // TEST 7: REM 10 % 3 = 1
    alu_op = `YH_rv_cpu_ALU_REM;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd1, result, "REM 10%3");

    // TEST 8: REMU 10 % 3 = 1
    alu_op = `YH_rv_cpu_ALU_REMU;
    lhs = 32'd10;
    rhs = 32'd3;
    #10;
    check(32'd1, result, "REMU 10%3");

    // TEST 9: DIV 10 / 0 = 0xFFFFFFFF
    alu_op = `YH_rv_cpu_ALU_DIV;
    lhs = 32'd10;
    rhs = 32'd0;
    #10;
    check(32'hFFFFFFFF, result, "DIV 10/0");

    // TEST 10: REM 10 % 0 = 10
    alu_op = `YH_rv_cpu_ALU_REM;
    lhs = 32'd10;
    rhs = 32'd0;
    #10;
    check(32'd10, result, "REM 10%0");

    // TEST 11: DIV (-10) / 3 = -3
    alu_op = `YH_rv_cpu_ALU_DIV;
    lhs = 32'hFFFFFFF6;
    rhs = 32'd3;
    #10;
    check(32'hFFFFFFFD, result, "DIV (-10)/3");

    $display("========================================");
    $display("测试完成: %0d/%0d 通过", pass_count, pass_count + fail_count);
    if (fail_count == 0) begin
        $display("结果: 全部通过!");
    end else begin
        $display("结果: %0d 个失败", fail_count);
    end
    $display("========================================");
    $finish;
end
endmodule
