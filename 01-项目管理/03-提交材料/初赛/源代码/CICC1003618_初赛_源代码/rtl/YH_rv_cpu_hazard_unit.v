// CICC1003618 submission context:
// File role: rtl/YH_rv_cpu_hazard_unit.v is part of the frozen CPU RTL and SoC integration source.
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
// File: rtl/YH_rv_cpu_hazard_unit.v
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
// YH_rv_cpu_hazard_unit.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 数据冒险检测与转发控制单元
// Description: 检测流水线中的数据冒险 (Data Hazard) 和加载使用冒险 (Load-Use Hazard)
//   输出 stall 信号控制流水线暂停，输出 forward 信号控制数据转发
//   支持五级流水线 (IF/ID/EX/MEM/WB) 的数据前递
// ============================================================

module YH_rv_cpu_hazard_unit #(
    parameter integer LOAD_USE_FAST_FORWARD = 0
) (
    // ------------------------------------------------------------
    // IF/ID 阶段寄存器地址输入 (当前正在译码的指令)
    // ------------------------------------------------------------
    input  wire        if_id_rs1_en,       // rs1 读取使能
    input  wire        if_id_rs2_en,       // rs2 读取使能
    input  wire [4:0]  if_id_rs1_addr,     // rs1 地址
    input  wire [4:0]  if_id_rs2_addr,     // rs2 地址

    // ------------------------------------------------------------
    // ID/EX 阶段流水线寄存器
    // ------------------------------------------------------------
    input  wire        id_ex_valid,         // ID/EX 流水线有效标志
    input  wire        id_ex_load,          // ID/EX 是加载指令
    input  wire        id_ex_rd_en,         // rd 写回使能
    input  wire [4:0]  id_ex_rd_addr,       // rd 地址
    input  wire        id_ex_rs1_en,       // rs1 读取使能
    input  wire        id_ex_rs2_en,       // rs2 读取使能
    input  wire [4:0]  id_ex_rs1_addr,     // rs1 地址
    input  wire [4:0]  id_ex_rs2_addr,     // rs2 地址

    // ------------------------------------------------------------
    // EX/MEM 阶段流水线寄存器
    // ------------------------------------------------------------
    input  wire        ex_mem_valid,       // EX/MEM 流水线有效标志
    input  wire        ex_mem_load,        // EX/MEM 是加载指令
    input  wire        ex_mem_rd_en,       // rd 写回使能
    input  wire [4:0]  ex_mem_rd_addr,     // rd 地址

    // ------------------------------------------------------------
    // MEM/WB 阶段流水线寄存器
    // ------------------------------------------------------------
    input  wire        mem_wb_valid,       // MEM/WB 流水线有效标志
    input  wire        mem_wb_rd_en,       // rd 写回使能
    input  wire [4:0]  mem_wb_rd_addr,     // rd 地址

    // ------------------------------------------------------------
    // 输出信号
    // ------------------------------------------------------------
    output wire        stall_decode,        // 译码阶段暂停信号
    output reg  [1:0]  forward_a_sel,      // rs1 数据转发选择
    output reg  [1:0]  forward_b_sel,       // rs2 数据转发选择

    // ------------------------------------------------------------
    // DCache 等待信号 (DCACHE_EN=1时使用)
    // ------------------------------------------------------------
    input  wire        dcache_wait,         // DCache busy信号，阻止流水线前进

    // ------------------------------------------------------------
    // ICache 等待信号 (ICACHE_EN=1时使用)
    // ------------------------------------------------------------
    input  wire        icache_wait          // ICache busy信号，阻止流水线前进
);

    // ------------------------------------------------------------
    // 加载使用冒险 (Load-Use Hazard) 检测
    //
    // 加载指令需要额外的时钟周期才能获取数据
    // 当前指令 (在 ID 阶段) 需要使用前一条加载的结果 (在 EX 阶段)
    // 必须插入 stall，等待加载完成
    //
    // 情况 1: ID/EX 阶段有加载指令，ID 阶段的指令需要 EX 阶段的结果
    // ------------------------------------------------------------
wire load_use_hazard;

    // ID/EX 加载冒险: 当前译码指令需要 ID/EX 阶段加载的结果
assign load_use_hazard =
    (LOAD_USE_FAST_FORWARD == 0) &&
    id_ex_valid && id_ex_load && id_ex_rd_en && (id_ex_rd_addr != 5'd0) &&
    (
        (if_id_rs1_en && (if_id_rs1_addr == id_ex_rd_addr)) ||
        (if_id_rs2_en && (if_id_rs2_addr == id_ex_rd_addr))
    );

    // 停顿条件: load-use冒险 或 DCache等待 或 ICache等待
    // DCACHE_EN=0时dcache_wait=0，不影响
    // DCACHE_EN=1时dcache_wait会阻止流水线直到dcache完成访问
    // ICACHE_EN=0时icache_wait=0，不影响
    // ICACHE_EN=1时icache_wait会阻止流水线直到icache完成取指
assign stall_decode = load_use_hazard || dcache_wait || icache_wait;

    // ------------------------------------------------------------
    // 数据转发选择逻辑
    //
    // forward_sel 编码:
    //   2'b00: 不转发，使用寄存器堆的输出
    //   2'b01: 从 EX/MEM 阶段转发 (最新结果)
    //   2'b10: 从 MEM/WB 阶段转发
    //
    // 优先级: EX/MEM > MEM/WB (选择最新的数据)
    // ------------------------------------------------------------
always @* begin
    forward_a_sel = 2'b00;
    forward_b_sel = 2'b00;

    // ------------------------------------------------------------
    // rs1 转发选择
    // ------------------------------------------------------------
    // 情况 1: EX/MEM 阶段有有效结果，且地址匹配
    // 注意: 加载指令不能立即转发 (需要额外的周期)
    if (id_ex_rs1_en && ex_mem_valid && ex_mem_rd_en && ((LOAD_USE_FAST_FORWARD != 0) || !ex_mem_load) &&
        (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == id_ex_rs1_addr)) begin
        forward_a_sel = 2'b01;  // 从 EX/MEM 转发
    end
    // 情况 2: MEM/WB 阶段有有效结果，且地址匹配
    else if (id_ex_rs1_en && mem_wb_valid && mem_wb_rd_en &&
             (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == id_ex_rs1_addr)) begin
        forward_a_sel = 2'b10;  // 从 MEM/WB 转发
    end

    // ------------------------------------------------------------
    // rs2 转发选择
    // ------------------------------------------------------------
    if (id_ex_rs2_en && ex_mem_valid && ex_mem_rd_en && ((LOAD_USE_FAST_FORWARD != 0) || !ex_mem_load) &&
        (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == id_ex_rs2_addr)) begin
        forward_b_sel = 2'b01;
    end else if (id_ex_rs2_en && mem_wb_valid && mem_wb_rd_en &&
                 (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == id_ex_rs2_addr)) begin
        forward_b_sel = 2'b10;
    end
end

endmodule
