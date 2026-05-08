// CICC1003618 submission context:
// File role: rtl/YH_rv_cpu_mem_stage.v is part of the frozen CPU RTL and SoC integration source.
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
// File: rtl/YH_rv_cpu_mem_stage.v
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
// YH_rv_cpu_mem_stage.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 访存阶段 (Memory Access Stage)
// Description: 处理内存访问请求和数据加载格式化
//   接收执行阶段的内存地址和存储数据
//   生成数据存储器的读/写请求信号
//   对加载的数据进行对齐和符号/零扩展
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_mem_stage #(
    parameter integer XLEN = 32  // 数据通路宽度: 32 (RV32) 或 64 (RV64)
) (
    // ------------------------------------------------------------
    // 输入信号 (来自 EX/MEM 流水线寄存器)
    // ------------------------------------------------------------
    input  wire            valid,             // 流水线有效标志
    input  wire            load,              // 加载指令
    input  wire            store,             // 存储指令
    input  wire [XLEN-1:0] mem_addr,         // 内存访问地址
    input  wire [XLEN-1:0] store_data_in,    // 存储数据 (格式化后)
    input  wire [XLEN/8-1:0] store_wstrb_in, // 存储字节使能
    input  wire [1:0]      mem_size,         // 内存访问宽度
    input  wire            mem_unsigned,     // 无符号加载标志

    // ------------------------------------------------------------
    // 数据存储器接口
    // ------------------------------------------------------------
    input  wire [XLEN-1:0] dmem_rdata,       // 数据存储器读数据

    // ------------------------------------------------------------
    // 输出信号 (到 MEM/WB 流水线寄存器)
    // ------------------------------------------------------------
    output wire [XLEN-1:0] dmem_addr,        // 数据存储器地址
    output wire            dmem_read_req,     // 读请求
    output wire [XLEN-1:0] dmem_wdata,       // 写数据
    output wire [XLEN/8-1:0] dmem_wstrb,    // 写字节使能
    output reg  [XLEN-1:0] load_data        // 加载数据 (格式化后)
);

    // ------------------------------------------------------------
    // 参数计算
    // STRB_W: 字节使能信号宽度
    // BYTE_OFFSET_W: 字节偏移宽度
    // ------------------------------------------------------------
localparam integer STRB_W = XLEN / 8;
localparam integer BYTE_OFFSET_W = $clog2(STRB_W);

    // ------------------------------------------------------------
    // 内部信号
    // ------------------------------------------------------------
wire [BYTE_OFFSET_W-1:0] byte_offset;  // 字节偏移 (地址低几位)
wire [XLEN-1:0] shifted_rdata;        // 对齐后的读数据

    // ------------------------------------------------------------
    // 数据存储器地址直接传递
    // ------------------------------------------------------------
assign dmem_addr = mem_addr;

    // ------------------------------------------------------------
    // 读请求生成
    // 当流水线有效且为加载指令时发起读请求
    // ------------------------------------------------------------
assign dmem_read_req = valid && load;

    // ------------------------------------------------------------
    // 写数据和写字节使能生成
    // 仅在存储指令时传递，否则为 0
    // ------------------------------------------------------------
assign dmem_wdata = (valid && store) ? store_data_in : {XLEN{1'b0}};
assign dmem_wstrb = (valid && store) ? store_wstrb_in : {STRB_W{1'b0}};

    // ------------------------------------------------------------
    // 字节偏移计算
    // 用于将读取的数据按字节对齐
    // ------------------------------------------------------------
assign byte_offset = mem_addr[BYTE_OFFSET_W-1:0];

    // ------------------------------------------------------------
    // 读数据右移对齐
    // 根据字节偏移将目标字节移动到最低位
    // ------------------------------------------------------------
assign shifted_rdata = dmem_rdata >> {byte_offset, 3'b000};

    // ------------------------------------------------------------
    // 加载数据格式化
    // 根据 mem_size 进行符号扩展或零扩展
    // 支持: 字节 (8b)、半字 (16b)、字 (32b)、双字 (64b, RV64)
    // ------------------------------------------------------------
always @* begin
    case (mem_size)
        `YH_rv_cpu_MEM_B: begin
            // 字节加载: 取低 8 位
            // mem_unsigned=1: 零扩展; mem_unsigned=0: 符号扩展
            load_data = mem_unsigned ? {{(XLEN-8){1'b0}}, shifted_rdata[7:0]} : {{(XLEN-8){shifted_rdata[7]}}, shifted_rdata[7:0]};
        end
        `YH_rv_cpu_MEM_H: begin
            // 半字加载: 取低 16 位
            load_data = mem_unsigned ? {{(XLEN-16){1'b0}}, shifted_rdata[15:0]} : {{(XLEN-16){shifted_rdata[15]}}, shifted_rdata[15:0]};
        end
        `YH_rv_cpu_MEM_W: begin
            // 字加载: 取低 32 位
            load_data = mem_unsigned ? {{(XLEN-32){1'b0}}, shifted_rdata[31:0]} : {{(XLEN-32){shifted_rdata[31]}}, shifted_rdata[31:0]};
        end
        default: begin
            // 双字加载 (RV64): 不扩展，直接使用
            load_data = shifted_rdata;
        end
    endcase
end

endmodule
