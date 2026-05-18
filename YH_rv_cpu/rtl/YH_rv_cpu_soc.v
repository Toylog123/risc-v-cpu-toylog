// ============================================================
// YH_rv_cpu_soc.v
// Author: Toylog
// Version: v1.1
// Function: RISC-V SoC 系统级封装
// Description: 集成 CPU 内核、指令 ROM、数据 RAM、UART 和定时器
//   提供完整的片上系统功能，支持 RV32/RV64 仿真和 FPGA 运行
//   包含以下外设：
//     - 指令 ROM (可加载十六进制文件)
//     - 数据 RAM (支持同步/异步读写)
//     - UART 发送器 (用于仿真输出)
//     - 定时器 (带中断功能)
//     - MMIO 存储映射接口
// ============================================================

module YH_rv_cpu_soc #(
    parameter integer XLEN = 32,           // 数据通路宽度: 32 (RV32) 或 64 (RV64)
    parameter integer SYNC_IMEM = 0,        // 指令存储器同步模式
    parameter integer IMEM_OUTPUT_REG = 0,  // 指令存储器输出寄存器
    parameter integer SYNC_DMEM = 0,        // 数据存储器同步模式
    parameter integer DMEM_OUTPUT_REG = 0,  // 数据存储器输出寄存器
    parameter integer DMEM_NEGEDGE_READ = 0, // fast half-cycle data RAM read
    parameter integer DCACHE_EN = 0,         // 数据缓存使能: 0=禁用, 1=启用
    parameter integer ICACHE_EN = 0,         // 指令缓存使能: 0=禁用, 1=启用
    parameter integer ENABLE_M_EXTENSION = 1,
    parameter integer ENABLE_ZMMUL_EXTENSION = 0,
    parameter integer ENABLE_BITMANIP_EXTENSION = 1,
    parameter integer ENABLE_ZBC_EXTENSION = 0,
    parameter integer ENABLE_ZICOND_EXTENSION = 0,
    parameter integer ENABLE_ZBKB_EXTENSION = 0,
    parameter integer ENABLE_XTHEAD_EXTENSION = 1,
    parameter integer ENABLE_XTHEAD_COND_MOVE = 1, // XThead 条件移动写回门控使能
    parameter integer ENABLE_ID_BRANCH_EX_FORWARD = 1, // ID 早分支允许使用 EX 本周期结果
    parameter integer ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP = 1,
    parameter integer ENABLE_ID_BRANCH_FOLD = 0,
    parameter integer ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD = 0,
    parameter integer ENABLE_ID_ALU_PAIR_FOLD = 0,
    parameter integer ENABLE_FETCH_REDIRECT_REUSE = 0,
    parameter integer REDIRECT_CACHE_ENTRIES = 1024,
    parameter integer REDIRECT_CACHE_XOR_INDEX = 0,
    parameter integer ENABLE_DYNAMIC_BRANCH_PREDICT = 0,
    parameter integer BRANCH_BHT_ENTRIES = 64,
    parameter integer BRANCH_STATIC_PREDICT_MODE = 0,
    parameter integer BRANCH_BHT_STRONG_ONLY = 0,
    parameter [XLEN-1:0] RESET_VECTOR = {XLEN{1'b0}}, // 复位向量
    parameter [31:0] ROM_BASE = 32'h0000_0000,  // ROM 基地址
    parameter [31:0] RAM_BASE = 32'h0000_4000,  // RAM 基地址
    parameter integer ROM_BYTES = 16384,        // ROM 大小 (字节)
    parameter integer RAM_BYTES = 16384,        // RAM 大小 (字节)
    parameter string ROM_INIT_HEX = "",        // ROM 初始化文件 (字节格式)
    parameter string ROM_INIT_MEM32_HEX = ""    // ROM 初始化文件 (32 位字格式)
) (
    // ------------------------------------------------------------
    // 时钟和复位
    // ------------------------------------------------------------
    input  wire            clk,              // 时钟信号
    input  wire            rst_n,            // 异步低有效复位

    // ------------------------------------------------------------
    // 调试和状态信号
    // ------------------------------------------------------------
    output wire            trap,             // trap 标志
    output wire [XLEN-1:0] debug_pc,      // 调试 PC

    // ------------------------------------------------------------
    // UART 接口
    // ------------------------------------------------------------
    output reg             uart_tx_valid,     // UART 发送有效
    output reg  [7:0]      uart_tx_data,     // UART 发送数据

    // ------------------------------------------------------------
    // 完成和中断信号
    // ------------------------------------------------------------
    output wire            done,             // 程序完成标志
    output wire            timer_irq        // 定时器中断请求
);

    // ================================================================
    // MMIO 地址映射
    // ================================================================
localparam [31:0] UART_TX_ADDR    = 32'h1000_0000; // UART 发送数据寄存器
localparam [31:0] DONE_ADDR       = 32'h1000_0004; // 完成标志寄存器
localparam [31:0] TIMER_VALUE_LO  = 32'h1000_0008; // 定时器值低 32 位
localparam [31:0] TIMER_VALUE_HI  = 32'h1000_000c; // 定时器值高 32 位
localparam [31:0] TIMER_CMP_LO   = 32'h1000_0010; // 定时器比较值低 32 位
localparam [31:0] TIMER_CMP_HI   = 32'h1000_0014; // 定时器比较值高 32 位
localparam [31:0] TIMER_CTRL_ADDR = 32'h1000_0018; // 定时器控制寄存器

    // ================================================================
    // CPU 存储器接口信号
    // ================================================================
wire [XLEN-1:0] imem_addr;      // 指令存储器地址
wire            imem_req;       // 指令读取请求
wire [31:0]     imem_rdata;     // 指令数据
wire            imem_rvalid;    // 指令读取有效
wire [XLEN-1:0] dmem_addr;     // 数据存储器地址
wire [XLEN-1:0] dmem_rdata;    // 数据存储器读数据
wire [XLEN-1:0] dmem_pair_rdata;
wire            dmem_rvalid;    // 数据读取有效
wire            dmem_read_req;   // 数据读取请求
wire            dmem_pair_read_req;
wire            dmem_we;        // 数据写使能
wire            dmem_ready;     // 写完成/内存就绪
wire [XLEN-1:0] dmem_wdata;    // 数据写入数据
wire [XLEN/8-1:0] dmem_wstrb; // 写字节使能
wire [XLEN-1:0] dmem_pair_wdata;
wire [XLEN/8-1:0] dmem_pair_wstrb;

    // ================================================================
    // 地址和数据转换信号
    // ================================================================
wire [31:0] imem_addr32;       // 指令地址 (32 位)
wire [31:0] imem_word_index;   // 指令字索引
wire [31:0] dmem_addr32;       // 数据地址 (32 位)
wire [31:0] dmem_pair_addr32;
wire [31:0] dmem_bus_base32;   // 总线对齐后的地址
wire [31:0] dmem_pair_bus_base32;
wire [31:0] rom_read_word_index; // ROM 读取字索引
wire [63:0] dmem_wdata_ext;    // 扩展的写数据
wire [7:0]  dmem_wstrb_ext;    // 扩展的字节使能
wire [31:0] dmem_mmio_addr32; // MMIO 地址
wire [31:0] dmem_mmio_wdata32; // MMIO 写数据
wire [3:0]  dmem_mmio_wstrb4;  // MMIO 写字节使能

    // ================================================================
    // ROM 存储器
    // 使用分布式 RAM 实现
    // ================================================================
(* rom_style = "distributed" *) reg [7:0] rom_mem [0:ROM_BYTES-1];

    // ================================================================
    // MMIO 寄存器
    // ================================================================
reg  [31:0] done_value_r;       // 完成标志
reg  [63:0] timer_value_r;       // 定时器计数器
reg  [63:0] timer_cmp_r;        // 定时器比较值
reg         timer_irq_en_r;     // 定时器中断使能

    // ================================================================
    // 总线访问控制信号
    // ================================================================
wire        dmem_write_en;       // 数据写使能
wire        imem_hit;            // 指令地址命中 ROM
wire        rom_read_hit;        // ROM 读取命中
wire        ram_read_hit;        // RAM 读取命中
wire        ram_pair_read_hit;
wire        ram_write_hit;       // RAM 写入命中
wire        ram_pair_write_hit;
wire        mmio_word_hit;       // MMIO 访问命中
wire [31:0] rom_read_offset;    // ROM 读取偏移
wire [31:0] ram_read_offset;    // RAM 读取偏移
wire [31:0] ram_pair_read_offset;
wire [31:0] ram_bus_offset;     // RAM 总线偏移
wire [31:0] ram_pair_bus_offset;
wire        ram_read_issue;      // RAM 读取发起
wire        dmem_read_accept;    // 数据读取接受

    // ================================================================
    // 数据信号
    // ================================================================
wire [XLEN-1:0] rom_read_data;          // ROM 读取数据
wire [31:0] sync_shared_imem_rdata;     // 同步共享指令数据
wire        sync_shared_imem_rvalid;     // 同步共享指令有效
wire [31:0] sync_shared_rom_read_data;  // 同步共享 ROM 数据
wire [XLEN-1:0] ram_read_data;         // RAM 读取数据
wire [XLEN-1:0] ram_pair_read_data;
wire [31:0] sync_imem_rdata;            // 同步指令数据
wire        sync_imem_rvalid;            // 同步指令有效
wire [XLEN-1:0] dmem_rdata_comb;       // 数据读数据组合
wire [XLEN-1:0] nonram_read_data_comb; // 非 RAM 读数据组合
reg  [31:0] mmio_read_word;             // MMIO 读取字
reg  [63:0] mmio_read_data_ext;         // MMIO 读取数据扩展

    // ================================================================
    // 同步/异步内存控制信号
    // ================================================================
reg  [1:0]      dmem_read_src_r;      // 数据读取源
reg  [1:0]      dmem_read_src_d1_r;   // 数据读取源延迟 1 拍
reg  [XLEN-1:0] dmem_nonram_rdata_r; // 非 RAM 读数据
reg  [XLEN-1:0] dmem_nonram_rdata_d1_r; // 非 RAM 读数据延迟 1 拍
reg             dmem_rvalid_sync_r;    // 读有效同步
reg             dmem_rvalid_sync_d1_r; // 读有效同步延迟 1 拍
reg             dmem_read_busy_r;     // 读忙标志
wire [31:0] timer_ctrl_next;           // 定时器控制下一值

integer idx;

    // ================================================================
    // 常量定义
    // ================================================================
localparam integer STRB_W = XLEN / 8;
localparam integer ROM_WORDS = ROM_BYTES / 4;
localparam integer BUS_ALIGN_LSB = (XLEN == 64) ? 3 : 2;
localparam integer USE_SHARED_SYNC_ROM = ((XLEN == 32) && (SYNC_IMEM != 0) && (SYNC_DMEM != 0)) ? 1 : 0;
localparam integer USE_IMEM_OUTPUT_REG = ((SYNC_IMEM != 0) && (IMEM_OUTPUT_REG != 0)) ? 1 : 0;
localparam integer USE_DMEM_OUTPUT_REG = ((SYNC_DMEM != 0) && (DMEM_OUTPUT_REG != 0)) ? 1 : 0;
localparam integer USE_DMEM_NEGEDGE_READ = ((SYNC_DMEM != 0) && (DMEM_OUTPUT_REG == 0) && (DMEM_NEGEDGE_READ != 0)) ? 1 : 0;
localparam integer USE_LOAD_USE_FAST_FORWARD = ((DCACHE_EN == 0) && ((SYNC_DMEM == 0) || (USE_DMEM_NEGEDGE_READ != 0))) ? 1 : 0;
localparam [1:0] DMEM_SRC_NONE = 2'b00; // 无数据源
localparam [1:0] DMEM_SRC_RAM  = 2'b01; // RAM 数据源
localparam [1:0] DMEM_SRC_ROM  = 2'b10; // ROM 数据源
localparam [1:0] DMEM_SRC_MMIO = 2'b11; // MMIO 数据源

    // ================================================================
    // 函数定义: apply_wstrb
    // 根据字节使能更新 32 位数据
    // ================================================================
function automatic [31:0] apply_wstrb;
    input [31:0] current_value;  // 当前值
    input [31:0] write_value;   // 写入值
    input [3:0]  write_strobe;  // 字节使能
    begin
        apply_wstrb = current_value;
        if (write_strobe[0]) apply_wstrb[7:0]   = write_value[7:0];
        if (write_strobe[1]) apply_wstrb[15:8]  = write_value[15:8];
        if (write_strobe[2]) apply_wstrb[23:16] = write_value[23:16];
        if (write_strobe[3]) apply_wstrb[31:24] = write_value[31:24];
    end
endfunction

    // ================================================================
    // 地址计算
    // ================================================================
assign imem_addr32 = imem_addr[31:0];
assign imem_word_index = (imem_addr32 - ROM_BASE) >> 2;
assign dmem_addr32 = dmem_addr[31:0];
assign dmem_pair_addr32 = dmem_addr32 + 32'd4;
assign dmem_wdata_ext = {{(64-XLEN){1'b0}}, dmem_wdata};
assign dmem_wstrb_ext = {{(8-STRB_W){1'b0}}, dmem_wstrb};
assign dmem_write_en = |dmem_wstrb;
assign dmem_we = dmem_write_en;  // 写使能信号
assign dmem_ready = 1'b1;        // 同步内存始终就绪

    // ================================================================
    // 总线地址对齐
    // ================================================================
assign dmem_bus_base32 = {dmem_addr32[31:BUS_ALIGN_LSB], {BUS_ALIGN_LSB{1'b0}}};
assign dmem_pair_bus_base32 = {dmem_pair_addr32[31:BUS_ALIGN_LSB], {BUS_ALIGN_LSB{1'b0}}};
assign dmem_mmio_addr32 = (XLEN == 64) ? {dmem_addr32[31:3], dmem_addr32[2], 2'b00} : {dmem_addr32[31:2], 2'b00};
assign dmem_mmio_wdata32 = ((XLEN == 64) && dmem_addr32[2]) ? dmem_wdata_ext[63:32] : dmem_wdata_ext[31:0];
assign dmem_mmio_wstrb4 = ((XLEN == 64) && dmem_addr32[2]) ? dmem_wstrb_ext[7:4] : dmem_wstrb_ext[3:0];

    // ================================================================
    // 定时器控制
    // ================================================================
assign timer_ctrl_next = apply_wstrb({31'b0, timer_irq_en_r}, dmem_mmio_wdata32, dmem_mmio_wstrb4);

    // ================================================================
    // 地址空间命中检测
    // ================================================================
assign imem_hit      = (imem_addr32 >= ROM_BASE) && (imem_addr32 <= (ROM_BASE + ROM_BYTES - 4));
assign rom_read_hit  = (dmem_bus_base32 >= ROM_BASE) && (dmem_bus_base32 <= (ROM_BASE + ROM_BYTES - STRB_W));
assign ram_read_hit  = (dmem_bus_base32 >= RAM_BASE) && (dmem_bus_base32 <= (RAM_BASE + RAM_BYTES - STRB_W));
assign ram_pair_read_hit  = (dmem_pair_bus_base32 >= RAM_BASE) && (dmem_pair_bus_base32 <= (RAM_BASE + RAM_BYTES - STRB_W));
assign ram_write_hit = (dmem_addr32 >= RAM_BASE) && (dmem_addr32 < (RAM_BASE + RAM_BYTES));
assign ram_pair_write_hit = (dmem_pair_addr32 >= RAM_BASE) && (dmem_pair_addr32 < (RAM_BASE + RAM_BYTES));
assign mmio_word_hit = (dmem_mmio_addr32 == UART_TX_ADDR) || (dmem_mmio_addr32 == DONE_ADDR) ||
    (dmem_mmio_addr32 == TIMER_VALUE_LO) || (dmem_mmio_addr32 == TIMER_VALUE_HI) ||
    (dmem_mmio_addr32 == TIMER_CMP_LO) || (dmem_mmio_addr32 == TIMER_CMP_HI) ||
    (dmem_mmio_addr32 == TIMER_CTRL_ADDR);

    // ================================================================
    // 偏移计算
    // ================================================================
assign rom_read_offset = dmem_bus_base32 - ROM_BASE;
assign rom_read_word_index = rom_read_offset >> 2;
assign ram_read_offset = dmem_bus_base32 - RAM_BASE;
assign ram_pair_read_offset = dmem_pair_bus_base32 - RAM_BASE;
assign ram_bus_offset = dmem_bus_base32 - RAM_BASE;
assign ram_pair_bus_offset = dmem_pair_bus_base32 - RAM_BASE;

    // ================================================================
    // 读取接受和发起
    // ================================================================
assign dmem_read_accept = (SYNC_DMEM != 0) ?
    (dmem_read_req && ((USE_DMEM_NEGEDGE_READ != 0) ? 1'b1 : !dmem_read_busy_r)) :
    dmem_read_req;
assign ram_read_issue = ram_read_hit && ((SYNC_DMEM != 0) ? dmem_read_accept : 1'b1);

    // ================================================================
    // ROM 实例化 (支持多种配置)
    // ================================================================
generate
    // 共享同步 ROM 配置 (32 位同步)
    if (USE_SHARED_SYNC_ROM != 0) begin : g_shared_sync_rom
        YH_rv_sync_rom32 #(
            .ROM_WORDS       (ROM_WORDS),
            .ROM_INIT_HEX    (ROM_INIT_MEM32_HEX),
            .IMEM_OUTPUT_REG (USE_IMEM_OUTPUT_REG),
            .DATA_READ_NEGEDGE(USE_DMEM_NEGEDGE_READ)
        ) u_sync_rom (
            .clk            (clk),
            .rst_n          (rst_n),
            .imem_req       (imem_hit && imem_req),
            .imem_word_index(imem_word_index),
            .imem_rdata     (sync_shared_imem_rdata),
            .imem_rvalid    (sync_shared_imem_rvalid),
            .data_req       (rom_read_hit && dmem_read_accept),
            .data_word_index(rom_read_word_index),
            .data_rdata     (sync_shared_rom_read_data)
        );

        assign imem_rdata = sync_shared_imem_rdata;
        assign imem_rvalid = sync_shared_imem_rvalid;
        assign rom_read_data = {{(XLEN-32){1'b0}}, sync_shared_rom_read_data};
    end else begin : g_legacy_rom
        // 64 位总线配置
        if (XLEN == 64) begin : g_bus64
            assign rom_read_data = {
                rom_mem[rom_read_offset + 32'd7],
                rom_mem[rom_read_offset + 32'd6],
                rom_mem[rom_read_offset + 32'd5],
                rom_mem[rom_read_offset + 32'd4],
                rom_mem[rom_read_offset + 32'd3],
                rom_mem[rom_read_offset + 32'd2],
                rom_mem[rom_read_offset + 32'd1],
                rom_mem[rom_read_offset + 32'd0]
            };
        end else begin : g_bus32
            assign rom_read_data = {
                rom_mem[rom_read_offset + 32'd3],
                rom_mem[rom_read_offset + 32'd2],
                rom_mem[rom_read_offset + 32'd1],
                rom_mem[rom_read_offset + 32'd0]
            };
        end

        // 同步指令存储器
        if (SYNC_IMEM != 0) begin : g_sync_imem
            YH_rv_sync_imem_rom #(
                .ROM_WORDS (ROM_WORDS),
                .ROM_INIT_HEX(ROM_INIT_MEM32_HEX),
                .OUTPUT_REG(USE_IMEM_OUTPUT_REG)
            ) u_sync_imem_rom (
                .clk       (clk),
                .rst_n     (rst_n),
                .req_hit   (imem_hit && imem_req),
                .word_index(imem_word_index),
                .rdata     (sync_imem_rdata),
                .rvalid    (sync_imem_rvalid)
            );

            assign imem_rdata = sync_imem_rdata;
            assign imem_rvalid = sync_imem_rvalid;
        end else begin : g_async_imem
            assign imem_rdata = imem_hit ? {
                rom_mem[imem_addr32 + 32'd3],
                rom_mem[imem_addr32 + 32'd2],
                rom_mem[imem_addr32 + 32'd1],
                rom_mem[imem_addr32 + 32'd0]
            } : 32'h0000_0013;
            assign imem_rvalid = 1'b1;
        end
    end
endgenerate

    // ================================================================
    // 数据 RAM 实例化
    // ================================================================
YH_rv_dmem_ram #(
    .XLEN      (XLEN),
    .RAM_BYTES (RAM_BYTES),
    .SYNC_READ (SYNC_DMEM),
    .OUTPUT_REG(DMEM_OUTPUT_REG),
    .READ_NEGEDGE(USE_DMEM_NEGEDGE_READ)
) u_dmem_ram (
    .clk        (clk),
    .read_req   (ram_read_issue),
    .read_offset(ram_read_offset),
    .read_data  (ram_read_data),
    .pair_read_req(ram_pair_read_hit && dmem_pair_read_req && dmem_read_accept),
    .pair_read_offset(ram_pair_read_offset),
    .pair_read_data(ram_pair_read_data),
    .write_en   (ram_write_hit && dmem_write_en),
    .write_offset(ram_bus_offset),
    .write_data (dmem_wdata),
    .write_wstrb(dmem_wstrb),
    .pair_write_en(ram_pair_write_hit && (|dmem_pair_wstrb)),
    .pair_write_offset(ram_pair_bus_offset),
    .pair_write_data(dmem_pair_wdata),
    .pair_write_wstrb(dmem_pair_wstrb)
);

    // ================================================================
    // MMIO 读取数据选择
    // ================================================================
always @* begin
    case (dmem_mmio_addr32)
        DONE_ADDR:       mmio_read_word = done_value_r;
        TIMER_VALUE_LO:  mmio_read_word = timer_value_r[31:0];
        TIMER_VALUE_HI:  mmio_read_word = timer_value_r[63:32];
        TIMER_CMP_LO:    mmio_read_word = timer_cmp_r[31:0];
        TIMER_CMP_HI:    mmio_read_word = timer_cmp_r[63:32];
        TIMER_CTRL_ADDR: mmio_read_word = {30'b0, timer_irq, timer_irq_en_r};
        default:         mmio_read_word = 32'h0000_0000;
    endcase
end

    // ================================================================
    // MMIO 读取数据扩展 (32/64 位)
    // ================================================================
always @* begin
    if (XLEN == 64) begin
        mmio_read_data_ext = dmem_addr32[2] ? {mmio_read_word, 32'h0000_0000} : {32'h0000_0000, mmio_read_word};
    end else begin
        mmio_read_data_ext = {32'h0000_0000, mmio_read_word};
    end
end

    // ================================================================
    // 数据读取数据组合选择
    // ================================================================
assign nonram_read_data_comb =
    rom_read_hit  ? rom_read_data :
    mmio_word_hit ? mmio_read_data_ext[XLEN-1:0] :
    {XLEN{1'b0}};
assign dmem_rdata_comb =
    ram_read_hit ? ram_read_data : nonram_read_data_comb;

    // ================================================================
    // 同步/异步数据读取处理
    // ================================================================
assign dmem_rdata = (SYNC_DMEM != 0) ?
    ((USE_DMEM_OUTPUT_REG != 0) ?
        ((dmem_read_src_d1_r == DMEM_SRC_RAM) ? ram_read_data :
         (dmem_read_src_d1_r == DMEM_SRC_ROM) ? rom_read_data :
         dmem_nonram_rdata_d1_r) :
        ((dmem_read_src_r == DMEM_SRC_RAM) ? ram_read_data :
         (dmem_read_src_r == DMEM_SRC_ROM) ? rom_read_data :
         dmem_nonram_rdata_r)) :
    dmem_rdata_comb;
assign dmem_pair_rdata = ram_pair_read_data;
assign dmem_rvalid = (SYNC_DMEM != 0) ?
    ((USE_DMEM_OUTPUT_REG != 0) ? dmem_rvalid_sync_d1_r : dmem_rvalid_sync_r) :
    1'b1;

    // ================================================================
    // 完成和定时器中断
    // ================================================================
assign done = done_value_r[0];
assign timer_irq = timer_irq_en_r && (timer_value_r >= timer_cmp_r);

    // ================================================================
    // CPU 内核实例化
    // ================================================================
YH_rv_cpu #(
    .XLEN           (XLEN),
    .IMEM_SYNC      (SYNC_IMEM),
    .IMEM_OUTPUT_REG(USE_IMEM_OUTPUT_REG),
    .DMEM_SYNC      (SYNC_DMEM),
    .LOAD_USE_FAST_FORWARD(USE_LOAD_USE_FAST_FORWARD),
    .DCACHE_EN      (DCACHE_EN),
    .ICACHE_EN      (ICACHE_EN),
    .ENABLE_M_EXTENSION(ENABLE_M_EXTENSION),
    .ENABLE_ZMMUL_EXTENSION(ENABLE_ZMMUL_EXTENSION),
    .ENABLE_BITMANIP_EXTENSION(ENABLE_BITMANIP_EXTENSION),
    .ENABLE_ZBC_EXTENSION(ENABLE_ZBC_EXTENSION),
    .ENABLE_ZICOND_EXTENSION(ENABLE_ZICOND_EXTENSION),
    .ENABLE_ZBKB_EXTENSION(ENABLE_ZBKB_EXTENSION),
    .ENABLE_XTHEAD_EXTENSION(ENABLE_XTHEAD_EXTENSION),
    .ENABLE_XTHEAD_COND_MOVE(ENABLE_XTHEAD_COND_MOVE),
    .ENABLE_ID_BRANCH_EX_FORWARD(ENABLE_ID_BRANCH_EX_FORWARD),
    .ENABLE_ID_BRANCH_FOLD(ENABLE_ID_BRANCH_FOLD),
    .ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD(ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD),
    .ENABLE_ID_ALU_PAIR_FOLD(ENABLE_ID_ALU_PAIR_FOLD),
    .ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP(ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP),
    .ENABLE_FETCH_REDIRECT_REUSE(ENABLE_FETCH_REDIRECT_REUSE),
    .REDIRECT_CACHE_ENTRIES(REDIRECT_CACHE_ENTRIES),
    .REDIRECT_CACHE_XOR_INDEX(REDIRECT_CACHE_XOR_INDEX),
    .ENABLE_DYNAMIC_BRANCH_PREDICT(ENABLE_DYNAMIC_BRANCH_PREDICT),
    .BRANCH_BHT_ENTRIES(BRANCH_BHT_ENTRIES),
    .BRANCH_STATIC_PREDICT_MODE(BRANCH_STATIC_PREDICT_MODE),
    .BRANCH_BHT_STRONG_ONLY(BRANCH_BHT_STRONG_ONLY),
    .RESET_VECTOR   (RESET_VECTOR)
) u_cpu (
    .clk       (clk),
    .rst_n     (rst_n),
    .timer_irq (timer_irq),
    .imem_req  (imem_req),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .imem_rvalid(imem_rvalid),
    .dmem_addr (dmem_addr),
    .dmem_rdata(dmem_rdata),
    .dmem_pair_rdata(dmem_pair_rdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_ready(dmem_ready),
    .dmem_read_req(dmem_read_req),
    .dmem_pair_read_req(dmem_pair_read_req),
    .dmem_we   (dmem_we),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .dmem_pair_wdata(dmem_pair_wdata),
    .dmem_pair_wstrb(dmem_pair_wstrb),
    .trap      (trap),
    .debug_pc  (debug_pc)
);

    // ================================================================
    // ROM 初始化 (非共享同步 ROM)
    // ================================================================
generate
    if (USE_SHARED_SYNC_ROM == 0) begin : g_legacy_rom_init
        initial begin
            for (idx = 0; idx < ROM_BYTES; idx = idx + 1) begin
                rom_mem[idx] = 8'h13;  // 默认填充 NOP 指令
            end
            if (ROM_INIT_HEX != "") begin
                $readmemh(ROM_INIT_HEX, rom_mem);
            end
        end
    end
endgenerate

    // ================================================================
    // 数据读取源跟踪 (同步模式)
    // ================================================================
generate
    if (USE_DMEM_NEGEDGE_READ != 0) begin : g_dmem_negedge_tracking
        always @(negedge clk or negedge rst_n) begin
            if (!rst_n) begin
                dmem_read_src_r <= DMEM_SRC_NONE;
                dmem_read_src_d1_r <= DMEM_SRC_NONE;
                dmem_nonram_rdata_r <= {XLEN{1'b0}};
                dmem_nonram_rdata_d1_r <= {XLEN{1'b0}};
                dmem_rvalid_sync_r <= 1'b0;
                dmem_rvalid_sync_d1_r <= 1'b0;
                dmem_read_busy_r <= 1'b0;
            end else begin
                dmem_read_src_d1_r <= dmem_read_src_r;
                dmem_nonram_rdata_d1_r <= dmem_nonram_rdata_r;
                dmem_rvalid_sync_d1_r <= dmem_rvalid_sync_r;
                dmem_rvalid_sync_r <= dmem_read_accept;
                dmem_read_busy_r <= 1'b0;

                if (dmem_read_accept) begin
                    if (ram_read_hit) begin
                        dmem_read_src_r <= DMEM_SRC_RAM;
                        dmem_nonram_rdata_r <= {XLEN{1'b0}};
                    end else if (rom_read_hit) begin
                        dmem_read_src_r <= DMEM_SRC_ROM;
                        dmem_nonram_rdata_r <= {XLEN{1'b0}};
                    end else if (mmio_word_hit) begin
                        dmem_read_src_r <= DMEM_SRC_MMIO;
                        dmem_nonram_rdata_r <= mmio_read_data_ext[XLEN-1:0];
                    end else begin
                        dmem_read_src_r <= DMEM_SRC_NONE;
                        dmem_nonram_rdata_r <= {XLEN{1'b0}};
                    end
                end else begin
                    dmem_read_src_r <= DMEM_SRC_NONE;
                    dmem_nonram_rdata_r <= {XLEN{1'b0}};
                end
            end
        end
    end else begin : g_dmem_posedge_tracking
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                dmem_read_src_r <= DMEM_SRC_NONE;
                dmem_read_src_d1_r <= DMEM_SRC_NONE;
                dmem_nonram_rdata_r <= {XLEN{1'b0}};
                dmem_nonram_rdata_d1_r <= {XLEN{1'b0}};
                dmem_rvalid_sync_r <= 1'b0;
                dmem_rvalid_sync_d1_r <= 1'b0;
                dmem_read_busy_r <= 1'b0;
            end else begin
                dmem_read_src_d1_r <= dmem_read_src_r;
                dmem_nonram_rdata_d1_r <= dmem_nonram_rdata_r;
                dmem_rvalid_sync_d1_r <= dmem_rvalid_sync_r;
                dmem_rvalid_sync_r <= dmem_read_accept;
                if (dmem_rvalid) begin
                    dmem_read_busy_r <= 1'b0;
                end
                if (dmem_read_accept) begin
                    dmem_read_busy_r <= 1'b1;
                    if (ram_read_hit) begin
                        dmem_read_src_r <= DMEM_SRC_RAM;
                        dmem_nonram_rdata_r <= {XLEN{1'b0}};
                    end else if (rom_read_hit) begin
                        dmem_read_src_r <= DMEM_SRC_ROM;
                        dmem_nonram_rdata_r <= {XLEN{1'b0}};
                    end else if (mmio_word_hit) begin
                        dmem_read_src_r <= DMEM_SRC_MMIO;
                        dmem_nonram_rdata_r <= mmio_read_data_ext[XLEN-1:0];
                    end else begin
                        dmem_read_src_r <= DMEM_SRC_NONE;
                        dmem_nonram_rdata_r <= {XLEN{1'b0}};
                    end
                end else begin
                    dmem_read_src_r <= DMEM_SRC_NONE;
                end
            end
        end
    end
endgenerate

    // ================================================================
    // MMIO 寄存器更新
    // 包括 UART、定时器和完成标志
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        uart_tx_valid  <= 1'b0;
        uart_tx_data   <= 8'h00;
        done_value_r   <= 32'h0000_0000;
        timer_value_r  <= 64'h0000_0000_0000_0000;
        timer_cmp_r    <= 64'hffff_ffff_ffff_ffff;
        timer_irq_en_r <= 1'b0;
    end else begin
        uart_tx_valid <= 1'b0;
        timer_value_r <= timer_value_r + 64'd1;

        if (!ram_write_hit && dmem_write_en) begin
            case (dmem_mmio_addr32)
                UART_TX_ADDR: begin
                    uart_tx_valid <= 1'b1;
                    if (dmem_mmio_wstrb4[0]) begin
                        uart_tx_data <= dmem_mmio_wdata32[7:0];
                    end else if (dmem_mmio_wstrb4[1]) begin
                        uart_tx_data <= dmem_mmio_wdata32[15:8];
                    end else if (dmem_mmio_wstrb4[2]) begin
                        uart_tx_data <= dmem_mmio_wdata32[23:16];
                    end else begin
                        uart_tx_data <= dmem_mmio_wdata32[31:24];
                    end
                end

                DONE_ADDR: begin
                    done_value_r <= apply_wstrb(done_value_r, dmem_mmio_wdata32, dmem_mmio_wstrb4);
                end

                TIMER_CMP_LO: begin
                    timer_cmp_r[31:0] <= apply_wstrb(timer_cmp_r[31:0], dmem_mmio_wdata32, dmem_mmio_wstrb4);
                end

                TIMER_CMP_HI: begin
                    timer_cmp_r[63:32] <= apply_wstrb(timer_cmp_r[63:32], dmem_mmio_wdata32, dmem_mmio_wstrb4);
                end

                TIMER_CTRL_ADDR: begin
                    if (dmem_mmio_wstrb4[0]) begin
                        timer_irq_en_r <= timer_ctrl_next[0];
                    end
                    if (dmem_mmio_wstrb4[0] && dmem_mmio_wdata32[1]) begin
                        timer_value_r <= 64'h0000_0000_0000_0000;
                    end
                end

                default: begin
                end
            endcase
        end
    end
end

endmodule
