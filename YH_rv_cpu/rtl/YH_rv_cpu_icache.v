// ============================================================
// YH_rv_cpu_icache.v
// Author: Toylog
// Version: v1.2
// Function: RISC-V 指令缓存 (Instruction Cache)
// Description: 参数化直接映射指令缓存
//   - 支持可配置的缓存大小和关联度
//   - 支持LRU替换策略
//   - 支持字节使能和数据对齐
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_icache #(
    parameter integer XLEN = 32,           // 数据通路宽度: 32 (RV32) 或 64 (RV64)
    parameter integer CACHE_SIZE = 4096,    // 缓存大小 (字节)
    parameter integer BLOCK_SIZE = 32,      // 缓存块大小 (字节)
    parameter integer ASSOC = 1,            // 关联度 (1=直接映射)
    parameter integer CACHE_ID = 0         // 缓存ID (用于多核)
) (
    // ------------------------------------------------------------
    // 时钟和复位
    // ------------------------------------------------------------
    input  wire            clk,              // 时钟信号
    input  wire            rst_n,            // 异步低有效复位

    // ------------------------------------------------------------
    // CPU 取指接口
    // ------------------------------------------------------------
    input  wire [XLEN-1:0] cpu_addr,       // 取指地址
    input  wire            cpu_req,         // 取指请求
    output wire [31:0]     cpu_rdata,       // 指令数据
    output wire            cpu_rvalid,       // 取指有效
    output wire            cpu_wait,         // CPU等待信号

    // ------------------------------------------------------------
    // 内存接口 (AXI4-Lite 或简单总线)
    // ------------------------------------------------------------
    output wire [XLEN-1:0] mem_addr,       // 内存地址
    output wire            mem_req,         // 内存请求
    output wire            mem_we,          // 写使能 (指令缓存只读)
    output wire [31:0]     mem_wdata,      // 写数据
    output wire [3:0]      mem_wstrb,      // 字节使能
    input  wire [31:0]     mem_rdata,       // 读数据
    input  wire            mem_rvalid       // 读有效
);

    // ================================================================
    // 常量计算
    // ================================================================
localparam integer BLOCK_WORDS = BLOCK_SIZE / 4;                    // 每个块的字数
localparam integer NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * ASSOC);   // 组数
localparam integer SET_INDEX_W = (NUM_SETS <= 1) ? 1 : $clog2(NUM_SETS);  // 组索引位宽
localparam integer OFFSET_W = (BLOCK_SIZE <= 1) ? 1 : $clog2(BLOCK_SIZE);  // 块内偏移位宽
localparam integer TAG_W = XLEN - SET_INDEX_W - OFFSET_W;           // 标签位宽
localparam integer LRU_W = (ASSOC <= 1) ? 1 : (ASSOC - 1);         // LRU位宽

    // ================================================================
    // 状态机定义
    // ================================================================
localparam [2:0]
    STATE_IDLE    = 3'd0,  // 空闲状态
    STATE_COMPARE = 3'd1,  // 标签比较
    STATE_REFILL  = 3'd2,  // 填充缺失行
    STATE_WRITE   = 3'd3;  // 写回(如需要)

    // ================================================================
    // 缓存存储
    // ================================================================
(* ram_style = "block" *) reg [31:0]     cache_data [0:CACHE_SIZE/4-1];  // 缓存数据
(* ram_style = "block" *) reg [TAG_W-1:0] cache_tag   [0:NUM_SETS*ASSOC-1];  // 缓存标签
(* ram_style = "block" *) reg             cache_valid [0:NUM_SETS*ASSOC-1];  // 有效位
(* ram_style = "block" *) reg             cache_dirty [0:NUM_SETS*ASSOC-1];  // 脏位
(* ram_style = "block" *) reg [LRU_W-1:0] cache_lru   [0:NUM_SETS-1];       // LRU信息

    // ================================================================
    // 地址解析
    // ================================================================
wire [TAG_W-1:0]       addr_tag;      // 地址标签
wire [SET_INDEX_W-1:0] addr_index;    // 组索引
wire [OFFSET_W-1:0]    addr_offset;   // 块内偏移
wire [XLEN-1:0]         addr_line_base; // 行基地址

assign addr_tag     = cpu_addr[XLEN-1:XLEN-TAG_W];
assign addr_index   = cpu_addr[XLEN-TAG_W-1:OFFSET_W];
assign addr_offset  = cpu_addr[OFFSET_W-1:2];
assign addr_line_base = {cpu_addr[XLEN-1:OFFSET_W], {OFFSET_W{1'b0}}};

    // ================================================================
    // 查找比较逻辑
    // ================================================================
genvar i;
integer way_idx, set_base, j;

always @* begin
    way_idx = 0;
end

function automatic [ASSOC-1:0] find_matching_way;
    input [SET_INDEX_W-1:0] index;
    input [TAG_W-1:0] tag;
    input [ASSOC-1:0] valid_bits;
    input [TAG_W-1:0] tags [0:ASSOC-1];
    integer way;
    begin
        find_matching_way = {ASSOC{1'b0}};
        for (way = 0; way < ASSOC; way = way + 1) begin
            if (valid_bits[way] && (tags[way] == tag)) begin
                find_matching_way[way] = 1'b1;
            end
        end
    end
endfunction

function automatic [ASSOC-1:0] find_replacement_way;
    input [SET_INDEX_W-1:0] index;
    input [LRU_W-1:0] lru_info;
    input [ASSOC-1:0] valid_bits;
    integer way;
    begin
        find_replacement_way = {ASSOC{1'b0}};
        if (ASSOC == 1) begin
            find_replacement_way[0] = 1'b1;
        end else begin
            // 简单LRU: 替换最久未使用的路
            for (way = 0; way < ASSOC; way = way + 1) begin
                if (~valid_bits[way]) begin
                    find_replacement_way[way] = 1'b1;
                end
            end
            if (~(|find_replacement_way)) begin
                // 所有路都有效，使用LRU信息选择
                for (way = 0; way < ASSOC; way = way + 1) begin
                    if (lru_info[way]) begin
                        find_replacement_way[way] = 1'b1;
                    end
                end
                if (~(|find_replacement_way)) begin
                    find_replacement_way[0] = 1'b1;
                end
            end
        end
    end
endfunction

    // ================================================================
    // 状态机和控制逻辑
    // ================================================================
reg [2:0] state_r, state_next;
reg [XLEN-1:0] miss_addr_r;      // 缺失地址
reg [SET_INDEX_W-1:0] miss_index_r;  // 缺失组索引
reg [ASSOC-1:0] miss_way_r;     // 缺失路索引
reg [TAG_W-1:0] miss_tag_r;     // 缺失标签
reg [OFFSET_W-1:0] refill_offset_r; // 填充偏移计数
reg [ASSOC-1:0] hit_way_r;     // 命中路

wire cache_hit;
wire [ASSOC-1:0] hit_way;
reg [ASSOC-1:0] valid_bits_r;
reg [TAG_W-1:0] tags_r [0:ASSOC-1];
reg [ASSOC-1:0] dirty_bits_r;

always @* begin
    set_base = addr_index * ASSOC;
    valid_bits_r = {ASSOC{1'b0}};
    for (j = 0; j < ASSOC; j = j + 1) begin
        valid_bits_r[j] = cache_valid[set_base + j];
    end
end

assign hit_way = find_matching_way(addr_index, addr_tag, valid_bits_r, tags_r);
assign cache_hit = cpu_req && (|hit_way);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < ASSOC; j = j + 1) begin
            tags_r[j] <= {TAG_W{1'b0}};
        end
    end else begin
        for (j = 0; j < ASSOC; j = j + 1) begin
            if (hit_way[j]) begin
                tags_r[j] <= addr_tag;
            end
        end
    end
end

always @* begin
    dirty_bits_r = {ASSOC{1'b0}};
    set_base = addr_index * ASSOC;
    for (j = 0; j < ASSOC; j = j + 1) begin
        dirty_bits_r[j] = cache_dirty[set_base + j];
    end
end

    // ================================================================
    // 状态机转移
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_r <= STATE_IDLE;
    end else begin
        state_r <= state_next;
    end
end

always @* begin
    state_next = state_r;
    case (state_r)
        STATE_IDLE: begin
            if (cpu_req) begin
                state_next = STATE_COMPARE;
            end
        end
        
        STATE_COMPARE: begin
            if (cache_hit) begin
                state_next = STATE_IDLE;
            end else begin
                state_next = STATE_REFILL;
            end
        end
        
        STATE_REFILL: begin
            if (mem_rvalid && (refill_offset_r == BLOCK_WORDS - 1)) begin
                state_next = STATE_IDLE;
            end
        end
        
        default: state_next = STATE_IDLE;
    endcase
end

    // ================================================================
    // 缺失处理
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        miss_addr_r <= {XLEN{1'b0}};
        miss_index_r <= {SET_INDEX_W{1'b0}};
        miss_way_r <= {ASSOC{1'b0}};
        miss_tag_r <= {TAG_W{1'b0}};
        refill_offset_r <= {OFFSET_W{1'b0}};
        hit_way_r <= {ASSOC{1'b0}};
    end else begin
        case (state_r)
            STATE_COMPARE: begin
                if (~cache_hit) begin
                    miss_addr_r <= cpu_addr;
                    miss_index_r <= addr_index;
                    miss_way_r <= find_replacement_way(addr_index, cache_lru[addr_index], valid_bits_r);
                    miss_tag_r <= addr_tag;
                    refill_offset_r <= {OFFSET_W{1'b0}};
                end
            end
            
            STATE_REFILL: begin
                if (mem_rvalid) begin
                    refill_offset_r <= refill_offset_r + 1;
                end
            end
            
            STATE_IDLE: begin
                if (cpu_req) begin
                    hit_way_r <= hit_way;
                end
            end
        endcase
    end
end

    // ================================================================
    // 缓存更新
    // ================================================================
wire [SET_INDEX_W-1:0] refill_index;
wire [ASSOC-1:0] refill_way_oh;
reg  [SET_INDEX_W-1:0] refill_index_r;
reg  [ASSOC-1:0] refill_way_oh_r;

assign refill_index = miss_addr_r[XLEN-TAG_W-1:OFFSET_W];
assign refill_way_oh = miss_way_r;

always @(posedge clk) begin
    refill_index_r <= refill_index;
    refill_way_oh_r <= refill_way_oh;
end

integer cache_line_idx, way;
wire [SET_INDEX_W-1:0] write_index;
wire [ASSOC-1:0] write_way_oh;

assign write_index = (state_r == STATE_REFILL) ? refill_index_r : miss_index_r;
assign write_way_oh = (state_r == STATE_REFILL) ? refill_way_oh_r : miss_way_r;

always @(posedge clk) begin
    if (state_r == STATE_REFILL && mem_rvalid) begin
        // 写入缓存行
        for (way = 0; way < ASSOC; way = way + 1) begin
            if (write_way_oh[way]) begin
                cache_line_idx = write_index * ASSOC + way;
                cache_data[cache_line_idx + refill_offset_r] <= mem_rdata;
            end
        end
        
        // 如果是最后一批数据，更新标签和有效位
        if (refill_offset_r == BLOCK_WORDS - 1) begin
            for (way = 0; way < ASSOC; way = way + 1) begin
                if (write_way_oh[way]) begin
                    cache_line_idx = write_index * ASSOC + way;
                    cache_tag[cache_line_idx] <= miss_tag_r;
                    cache_valid[cache_line_idx] <= 1'b1;
                    cache_dirty[cache_line_idx] <= 1'b0;
                end
            end
        end
    end
end

    // ================================================================
    // 输出信号
    // ================================================================
reg [31:0] rdata_r;
reg rvalid_r;
reg wait_r;

wire [SET_INDEX_W-1:0] rdata_index;
wire [OFFSET_W-1:0] rdata_offset;
wire cache_data_idx;

assign rdata_index = (state_r == STATE_IDLE) ? addr_index : miss_index_r;
assign rdata_offset = (state_r == STATE_IDLE) ? addr_offset : refill_offset_r;
assign cache_data_idx = rdata_index * ASSOC + hit_way_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata_r <= 32'h00000013;  // NOP
        rvalid_r <= 1'b0;
        wait_r <= 1'b0;
    end else begin
        case (state_r)
            STATE_IDLE: begin
                if (cache_hit) begin
                    rdata_r <= cache_data[cache_data_idx];
                    rvalid_r <= 1'b1;
                    wait_r <= 1'b0;
                end else if (cpu_req) begin
                    wait_r <= 1'b1;
                    rvalid_r <= 1'b0;
                end else begin
                    rvalid_r <= 1'b0;
                    wait_r <= 1'b0;
                end
            end
            
            STATE_COMPARE: begin
                if (cache_hit) begin
                    rdata_r <= cache_data[cache_data_idx];
                    rvalid_r <= 1'b1;
                    wait_r <= 1'b0;
                end
            end
            
            STATE_REFILL: begin
                wait_r <= 1'b1;
                if (mem_rvalid && (refill_offset_r == addr_offset)) begin
                    rdata_r <= mem_rdata;
                    rvalid_r <= 1'b1;
                    wait_r <= 1'b0;
                end else begin
                    rvalid_r <= 1'b0;
                end
            end
            
            default: begin
                rvalid_r <= 1'b0;
                wait_r <= 1'b0;
            end
        endcase
    end
end

assign cpu_rdata = rdata_r;
assign cpu_rvalid = rvalid_r;
assign cpu_wait = wait_r;

    // ================================================================
    // 内存请求
    // ================================================================
reg mem_req_r;
reg [XLEN-1:0] mem_addr_r;
reg [31:0] mem_wdata_r;
reg [3:0] mem_wstrb_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_req_r <= 1'b0;
        mem_addr_r <= {XLEN{1'b0}};
        mem_wdata_r <= 32'h0;
        mem_wstrb_r <= 4'h0;
    end else begin
        case (state_r)
            STATE_REFILL: begin
                if (!mem_req_r || mem_rvalid) begin
                    mem_req_r <= 1'b1;
                    mem_addr_r <= {miss_addr_r[XLEN-1:OFFSET_W], refill_offset_r, 2'b00};
                end
            end
            
            default: begin
                if (state_r != STATE_REFILL) begin
                    mem_req_r <= 1'b0;
                end
            end
        endcase
    end
end

assign mem_addr = mem_addr_r;
assign mem_req = mem_req_r && (state_r == STATE_REFILL);
assign mem_we = 1'b0;  // 指令缓存只读
assign mem_wdata = 32'h0;
assign mem_wstrb = 4'h0;

endmodule
