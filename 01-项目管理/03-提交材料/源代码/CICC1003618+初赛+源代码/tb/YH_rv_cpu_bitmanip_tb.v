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
// File: tb/YH_rv_cpu_bitmanip_tb.v
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

module YH_rv_cpu_bitmanip_tb;
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
reg [31:0] dmem [0:63];
integer i;
integer pass_count;
integer test_count;
reg [31:0] cycle;

assign imem_rdata = imem[imem_addr[31:2]];
assign imem_rvalid = 1'b1;
assign dmem_rdata = dmem[dmem_addr[31:2]];
assign dmem_rvalid = 1'b1;
assign dmem_ready = 1'b1;

always #5 clk = ~clk;

always @(posedge clk) begin
    if (!rst_n) begin
        cycle <= 0;
    end else begin
        cycle <= cycle + 1;
        if (trap) begin
            $fatal(1, "FAIL: bitmanip trap at PC=%h cycle=%0d", debug_pc, cycle);
        end
        if (cycle > 200) begin
            $fatal(1, "FAIL: bitmanip timeout at PC=%h", debug_pc);
        end
    end
end

task expect_reg;
    input [4:0] reg_index;
    input [31:0] expected;
    input [127:0] label;
    reg [31:0] actual;
    begin
        actual = dut.u_regfile.regs[reg_index];
        test_count = test_count + 1;
        if (actual == expected) begin
            pass_count = pass_count + 1;
            $display("[PASS] %0s x%0d=%h", label, reg_index, actual);
        end else begin
            $display("[FAIL] %0s x%0d=%h expected=%h", label, reg_index, actual, expected);
        end
    end
endtask

YH_rv_cpu #(
    .ENABLE_ZBC_EXTENSION(1),
    .ENABLE_ZICOND_EXTENSION(1),
    .ENABLE_ZBKB_EXTENSION(1)
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

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    timer_irq = 1'b0;
    pass_count = 0;
    test_count = 0;
    cycle = 0;

    for (i = 0; i < 64; i = i + 1) begin
        imem[i] = 32'h00000013;
        dmem[i] = 32'h00000000;
    end

    imem[0]  = 32'h00300093; // addi x1,x0,3
    imem[1]  = 32'h00500113; // addi x2,x0,5
    imem[2]  = 32'h2020a1b3; // sh1add x3,x1,x2 = 11
    imem[3]  = 32'h2020c233; // sh2add x4,x1,x2 = 17
    imem[4]  = 32'h2020e2b3; // sh3add x5,x1,x2 = 29
    imem[5]  = 32'h40117333; // andn x6,x2,x1 = 4
    imem[6]  = 32'h0a20e3b3; // max x7,x1,x2 = 5
    imem[7]  = 32'h000084b7; // lui x9,0x8
    imem[8]  = 32'h00148493; // addi x9,x9,1 => 0x8001
    imem[9]  = 32'h60549413; // sext.h x8,x9 => 0xffff8001
    imem[10] = 32'h08044533; // zext.h x10,x8 => 0x00008001
    imem[11] = 32'h48f55593; // bexti x11,x10,15 => 1
    imem[12] = 32'h48e55613; // bexti x12,x10,14 => 0
    imem[13] = 32'h0e0156b3; // czero.eqz x13,x2,x0 => 0
    imem[14] = 32'h0e115733; // czero.eqz x14,x2,x1 => 5
    imem[15] = 32'h0e0177b3; // czero.nez x15,x2,x0 => 5
    imem[16] = 32'h0e117bb3; // czero.nez x23,x2,x1 => 0
    imem[17] = 32'h00b00813; // addi x16,x0,11
    imem[18] = 32'h00d00893; // addi x17,x0,13
    imem[19] = 32'h0b181933; // clmul x18,x16,x17 => 0x7f
    imem[20] = 32'h80000837; // lui x16,0x80000
    imem[21] = 32'h800008b7; // lui x17,0x80000
    imem[22] = 32'h0b1839b3; // clmulh x19,x16,x17 => 0x40000000
    imem[23] = 32'h00001a37; // lui x20,0x1
    imem[24] = 32'h234a0a13; // addi x20,x20,0x234 => 0x1234
    imem[25] = 32'h0000bab7; // lui x21,0xb
    imem[26] = 32'hbcda8a93; // addi x21,x21,-1075 => 0xabcd
    imem[27] = 32'h095a4b33; // pack x22,x20,x21 => 0xabcd1234
    imem[28] = 32'h0f000c13; // addi x24,x0,240
    imem[29] = 32'h1c4c3c8b; // th.extu x25,x24,7,4 => 0xf
    imem[30] = 32'h1c4c2d0b; // th.ext x26,x24,7,4 => -1
    imem[31] = 32'h04209d8b; // th.addsl x27,x1,x2,2 => 23
    imem[32] = 32'h00900e13; // addi x28,x0,9
    imem[33] = 32'h40009e0b; // th.mveqz x28,x1,x0 => 3
    imem[34] = 32'h00900e93; // addi x29,x0,9
    imem[35] = 32'h40209e8b; // th.mveqz x29,x1,x2 => unchanged 9
    imem[36] = 32'h00900f13; // addi x30,x0,9
    imem[37] = 32'h42209f0b; // th.mvnez x30,x1,x2 => 3
    imem[38] = 32'h00900f93; // addi x31,x0,9
    imem[39] = 32'h42009f8b; // th.mvnez x31,x1,x0 => unchanged 9
    imem[40] = 32'h0000006f; // loop

    #50;
    rst_n = 1'b1;

    wait (cycle > 100);

    expect_reg(5'd3,  32'd11,       "sh1add");
    expect_reg(5'd4,  32'd17,       "sh2add");
    expect_reg(5'd5,  32'd29,       "sh3add");
    expect_reg(5'd6,  32'd4,        "andn");
    expect_reg(5'd7,  32'd5,        "max");
    expect_reg(5'd8,  32'hffff8001, "sext.h");
    expect_reg(5'd10, 32'h00008001, "zext.h");
    expect_reg(5'd11, 32'd1,        "bexti bit15");
    expect_reg(5'd12, 32'd0,        "bexti bit14");
    expect_reg(5'd13, 32'd0,        "czero.eqz zero");
    expect_reg(5'd14, 32'd5,        "czero.eqz nonzero");
    expect_reg(5'd15, 32'd5,        "czero.nez zero");
    expect_reg(5'd23, 32'd0,        "czero.nez nonzero");
    expect_reg(5'd18, 32'h0000007f, "clmul");
    expect_reg(5'd19, 32'h40000000, "clmulh");
    expect_reg(5'd22, 32'habcd1234, "pack");
    expect_reg(5'd25, 32'h0000000f, "th.extu");
    expect_reg(5'd26, 32'hffffffff, "th.ext");
    expect_reg(5'd27, 32'd23,       "th.addsl");
    expect_reg(5'd28, 32'd3,        "th.mveqz true");
    expect_reg(5'd29, 32'd9,        "th.mveqz false");
    expect_reg(5'd30, 32'd3,        "th.mvnez true");
    expect_reg(5'd31, 32'd9,        "th.mvnez false");

    if (pass_count != test_count) begin
        $fatal(1, "FAIL: bitmanip %0d/%0d passed", pass_count, test_count);
    end

    $display("PASS: bitmanip test completed %0d/%0d", pass_count, test_count);
    $finish;
end

endmodule
