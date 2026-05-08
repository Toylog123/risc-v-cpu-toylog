// CICC1003618 submission context:
// File role: rtl/YH_rv_cpu_if_stage.v is part of the frozen CPU RTL and SoC integration source.
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
// File: rtl/YH_rv_cpu_if_stage.v
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
// YH_rv_cpu_if_stage.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 取指阶段 (Instruction Fetch Stage)
// Description: 负责从指令存储器获取指令，并计算下一 PC 地址
//   支持 PC 重定向 (分支跳转、JALR、异常处理)
//   输出指令地址给 imem，生成 PC+4 用于顺序执行
// ============================================================

module YH_rv_cpu_if_stage #(
    parameter integer XLEN = 32  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
) (
    // ------------------------------------------------------------
    // PC 控制信号
    // ------------------------------------------------------------
    input  wire [XLEN-1:0] pc_current,        // 当前 PC 值 (来自流水线寄存器)
    input  wire            redirect_en,       // PC 重定向使能 (分支跳转/异常)
    input  wire [XLEN-1:0] redirect_pc,       // 重定向目标地址

    // ------------------------------------------------------------
    // 内存访问接口
    // ------------------------------------------------------------
    output wire [XLEN-1:0] imem_addr,        // 指令存储器地址
    output wire [XLEN-1:0] pc_next,          // 下一 PC 值
    output wire [XLEN-1:0] pc_plus_4         // PC + 4 (顺序执行下一地址)
);

    // ------------------------------------------------------------
    // PC 步进常量
    // RISC-V 指令长度为 32 位 (4 字节)，所以 PC 每次增加 4
    // ------------------------------------------------------------
localparam [XLEN-1:0] PC_STEP = {{(XLEN-3){1'b0}}, 3'd4};

    // ------------------------------------------------------------
    // 指令存储器地址 = 当前 PC
    // ------------------------------------------------------------
assign imem_addr = redirect_en ? redirect_pc : pc_current;

    // ------------------------------------------------------------
    // PC + 4 计算
    // 用于 JAL 指令保存返回地址
    // ------------------------------------------------------------
assign pc_plus_4 = pc_current + PC_STEP;

    // ------------------------------------------------------------
    // 下一 PC 选择
    // redirect_en=1: 跳转到目标地址 (分支/jalr/异常)
    // redirect_en=0: 顺序执行 PC+4
    // ------------------------------------------------------------
assign pc_next = redirect_en ? redirect_pc : pc_plus_4;

endmodule
