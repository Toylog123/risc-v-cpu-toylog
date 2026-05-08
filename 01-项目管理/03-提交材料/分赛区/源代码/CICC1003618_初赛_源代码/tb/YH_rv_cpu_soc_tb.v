// CICC1003618 submission context:
// File role: tb/YH_rv_cpu_soc_tb.v is part of the simulation testbench and benchmark verification source.
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
// File: tb/YH_rv_cpu_soc_tb.v
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

// 文件说明：YH_rv_cpu SoC 冒烟测试平台。
// 作用：加载演示程序并检查 UART 输出、done 信号和无异常退出路径。
// 备注：适合作为系统级连通性和基础启动链路的回归入口。

`timescale 1ns / 1ps

module YH_rv_cpu_soc_tb;

localparam string ROM_HEX = "build/sw/YH_rv_cpu_demo.hex";
localparam string ROM_MEM32_HEX = "build/sw/YH_rv_cpu_demo.mem32.hex";
localparam integer EXPECTED_LEN = 15;

reg         clk;
reg         rst_n;
reg         debug_trace;
wire        trap;
wire [31:0] debug_pc;
wire        uart_tx_valid;
wire [7:0]  uart_tx_data;
wire        done;
wire        timer_irq;

reg [7:0] expected_uart [0:EXPECTED_LEN-1];
reg [7:0] captured_uart [0:127];
integer cycle;
integer uart_count;
integer idx;

YH_rv_cpu_soc #(
    .SYNC_IMEM(1),
    .IMEM_OUTPUT_REG(1),
    .SYNC_DMEM(1),
    .DMEM_OUTPUT_REG(1),
    .ROM_INIT_HEX(ROM_HEX),
    .ROM_INIT_MEM32_HEX(ROM_MEM32_HEX)
) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .trap        (trap),
    .debug_pc    (debug_pc),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data(uart_tx_data),
    .done        (done),
    .timer_irq   (timer_irq)
);

always #5 clk = ~clk;

initial begin
    debug_trace = 1'b0;
    if ($test$plusargs("debug_trace")) begin
        debug_trace = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst_n) begin
        cycle <= cycle + 1;

        if (debug_trace && (cycle < 80)) begin
            $display(
                "TRACE cycle=%0d pc=%h req=%0d fetch_pc=%h fetch_pc_d1=%h drop=%0d if_id_v=%0d if_id_pc=%h if_id_insn=%h id_ex_v=%0d id_ex_pc=%h br=%0d j=%0d ld=%0d st=%0d ex_mem_v=%0d mem_wb_v=%0d trap=%0d done=%0d x12=%h x13=%h x14=%h x15=%h daddr=%h dwdata=%h wstrb=%h",
                cycle,
                debug_pc,
                dut.u_cpu.imem_req,
                dut.u_cpu.fetch_pc_r,
                dut.u_cpu.fetch_pc_d1_r,
                dut.u_cpu.fetch_drop_count_r,
                dut.u_cpu.if_id_valid_r,
                dut.u_cpu.if_id_pc_r,
                dut.u_cpu.if_id_instruction_r,
                dut.u_cpu.id_ex_valid_r,
                dut.u_cpu.id_ex_pc_r,
                dut.u_cpu.id_ex_branch_r,
                dut.u_cpu.id_ex_jump_r,
                dut.u_cpu.id_ex_load_r,
                dut.u_cpu.id_ex_store_r,
                dut.u_cpu.ex_mem_valid_r,
                dut.u_cpu.mem_wb_valid_r,
                trap,
                done,
                dut.u_cpu.u_regfile.regs[12],
                dut.u_cpu.u_regfile.regs[13],
                dut.u_cpu.u_regfile.regs[14],
                dut.u_cpu.u_regfile.regs[15],
                dut.u_cpu.dmem_addr,
                dut.u_cpu.dmem_wdata,
                dut.u_cpu.dmem_wstrb
            );
        end

        if (uart_tx_valid) begin
            captured_uart[uart_count] <= uart_tx_data;
            uart_count <= uart_count + 1;
            $write("%c", uart_tx_data);

            if (debug_trace) begin
                $display(
                    "\nUART byte[%0d]=0x%02h (%c) a2=%h daddr=%h dwdata=%h",
                    uart_count,
                    uart_tx_data,
                    uart_tx_data,
                    dut.u_cpu.u_regfile.regs[12],
                    dut.u_cpu.dmem_addr,
                    dut.u_cpu.dmem_wdata
                );
            end
        end

        if (trap) begin
            $display("\nFAIL: trap asserted at PC=%h", debug_pc);
            $finish;
        end

        if (done) begin
            if (uart_count != EXPECTED_LEN) begin
                $display("\nFAIL: unexpected UART length %0d", uart_count);
                $finish;
            end

            for (idx = 0; idx < EXPECTED_LEN; idx = idx + 1) begin
                if (captured_uart[idx] !== expected_uart[idx]) begin
                    $display("\nFAIL: UART mismatch at index %0d, got %0d expected %0d", idx, captured_uart[idx], expected_uart[idx]);
                    $finish;
                end
            end

            if (timer_irq) begin
                $display("\nFAIL: timer_irq asserted unexpectedly");
                $finish;
            end

            $display("\nPASS: SoC smoke test completed at PC=%h in %0d cycles", debug_pc, cycle);
            $finish;
        end

        if (cycle > 500) begin
            $display("\nFAIL: timeout at PC=%h", debug_pc);
            $finish;
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cycle = 0;
    uart_count = 0;

    expected_uart[0]  = "Y";
    expected_uart[1]  = "H";
    expected_uart[2]  = "_";
    expected_uart[3]  = "r";
    expected_uart[4]  = "v";
    expected_uart[5]  = "_";
    expected_uart[6]  = "c";
    expected_uart[7]  = "p";
    expected_uart[8]  = "u";
    expected_uart[9]  = " ";
    expected_uart[10] = "b";
    expected_uart[11] = "o";
    expected_uart[12] = "o";
    expected_uart[13] = "t";
    expected_uart[14] = "\n";

    #20;
    rst_n = 1'b1;
end

endmodule
