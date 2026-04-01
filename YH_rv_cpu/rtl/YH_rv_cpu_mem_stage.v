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
