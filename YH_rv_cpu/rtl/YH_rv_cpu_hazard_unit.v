// ============================================================
// YH_rv_cpu_hazard_unit.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V 数据冒险检测与转发控制单元
// Description: 检测流水线中的数据冒险 (Data Hazard) 和加载使用冒险 (Load-Use Hazard)
//   输出 stall 信号控制流水线暂停，输出 forward 信号控制数据转发
//   支持五级流水线 (IF/ID/EX/MEM/WB) 的数据前递
// ============================================================

module YH_rv_cpu_hazard_unit (
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
    output reg  [1:0]  forward_b_sel       // rs2 数据转发选择
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
    id_ex_valid && id_ex_load && id_ex_rd_en && (id_ex_rd_addr != 5'd0) &&
    (
        (if_id_rs1_en && (if_id_rs1_addr == id_ex_rd_addr)) ||
        (if_id_rs2_en && (if_id_rs2_addr == id_ex_rd_addr))
    );

    // 同步数据存储器路径下，额外等待周期由 mem_wait 冻住流水线，
    // 因此这里只保留真正的 ID/EX load-use 冒险停顿。
assign stall_decode = load_use_hazard;

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
    if (id_ex_rs1_en && ex_mem_valid && ex_mem_rd_en && !ex_mem_load &&
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
    if (id_ex_rs2_en && ex_mem_valid && ex_mem_rd_en && !ex_mem_load &&
        (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == id_ex_rs2_addr)) begin
        forward_b_sel = 2'b01;
    end else if (id_ex_rs2_en && mem_wb_valid && mem_wb_rd_en &&
                 (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == id_ex_rs2_addr)) begin
        forward_b_sel = 2'b10;
    end
end

endmodule
