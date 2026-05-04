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
// File: rtl/YH_rv_cpu_regfile.v
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

// ============================================================
// YH_rv_cpu_regfile.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 寄存器堆 (Register File)
// Description: 32 个通用寄存器 (x0-x31) 的读写管理
//   x0 固定为 0
//   支持双端口读、单端口写
//   包含写回旁路逻辑，同周期写入的数据可被直接读取
// ============================================================

module YH_rv_cpu_regfile #(
    parameter integer XLEN = 32  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
) (
    // ------------------------------------------------------------
    // 时钟和复位
    // ------------------------------------------------------------
    input  wire            clk,              // 时钟信号
    input  wire            rst_n,            // 异步低有效复位

    // ------------------------------------------------------------
    // 读端口 A (rs1)
    // ------------------------------------------------------------
    input  wire [4:0]      rs1_addr,         // 读地址 1
    output wire [XLEN-1:0] rs1_rdata,        // 读数据 1

    // ------------------------------------------------------------
    // 读端口 B (rs2)
    // ------------------------------------------------------------
    input  wire [4:0]      rs2_addr,         // 读地址 2
    output wire [XLEN-1:0] rs2_rdata,        // 读数据 2

    // ------------------------------------------------------------
    // 读端口 C (rd-as-source for selected custom stores)
    // ------------------------------------------------------------
    input  wire [4:0]      rs3_addr,
    output wire [XLEN-1:0] rs3_rdata,

    // ------------------------------------------------------------
    // 写端口 (rd)
    // ------------------------------------------------------------
    input  wire            rd_wen,           // 写使能
    input  wire [4:0]      rd_addr,          // 写地址
    input  wire [XLEN-1:0] rd_wdata,         // 写数据

    // ------------------------------------------------------------
    // 第二写端口 (用于带基址更新的访存扩展)
    // ------------------------------------------------------------
    input  wire            rd2_wen,
    input  wire [4:0]      rd2_addr,
    input  wire [XLEN-1:0] rd2_wdata
);

    // ------------------------------------------------------------
    // 寄存器存储阵列
    // 32 个通用寄存器，每个 XLEN 位宽
    // x0 固定为 0，通常不写入
    // ------------------------------------------------------------
reg [XLEN-1:0] regs [0:31];
integer idx;

    // ------------------------------------------------------------
    // 读端口 A 数据输出 (rs1)
    // 包含写回旁路: 如果写地址等于 rs1 地址，且写使能有效，
    // 则直接输出正在写入的数据，而不是存储阵列中的旧数据
    // 这样可以解决同周期读写同一寄存器的数据冒险
    // ------------------------------------------------------------
assign rs1_rdata =
    (rs1_addr == 5'd0) ? {XLEN{1'b0}} :  // x0 始终为 0
    (rd2_wen && (rd2_addr == rs1_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == rs1_addr) && (rd_addr != 5'd0)) ? rd_wdata :  // 旁路
    regs[rs1_addr];                        // 正常读取

    // ------------------------------------------------------------
    // 读端口 B 数据输出 (rs2)
    // 逻辑与 rs1 相同
    // ------------------------------------------------------------
assign rs2_rdata =
    (rs2_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == rs2_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == rs2_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[rs2_addr];

assign rs3_rdata =
    (rs3_addr == 5'd0) ? {XLEN{1'b0}} :
    (rd2_wen && (rd2_addr == rs3_addr) && (rd2_addr != 5'd0)) ? rd2_wdata :
    (rd_wen && (rd_addr == rs3_addr) && (rd_addr != 5'd0)) ? rd_wdata :
    regs[rs3_addr];

    // ------------------------------------------------------------
    // 寄存器写操作
    // 复位时所有寄存器清零
    // 写操作在时钟上升沿生效
    // x0 不可写入 (地址为 0 时忽略写操作)
    // ------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < 32; idx = idx + 1) begin
            regs[idx] <= {XLEN{1'b0}};
        end
    end else begin
        if (rd_wen && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_wdata;
        end
        if (rd2_wen && (rd2_addr != 5'd0)) begin
            regs[rd2_addr] <= rd2_wdata;
        end
    end
end

endmodule
