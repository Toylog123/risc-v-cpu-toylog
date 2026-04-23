// ============================================================
// YH_rv_cpu_axi_lite_if.v
// Author: Toylog
// Version: v1.2
// Function: AXI4-Lite 总线接口模块
// Description: 将CPU的简单存储器接口转换为标准AXI4-Lite接口
//   支持：
//     - 读/写事务处理
//     - 字节/半字/字/双字访问
//     - 错误响应处理
//     - 可配置的等待周期
// ============================================================

`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_axi_lite_if #(
    parameter integer XLEN = 32,           // 数据通路宽度: 32 (RV32) 或 64 (RV64)
    parameter integer DATA_WIDTH = 32,     // 数据总线宽度
    parameter integer ADDR_WIDTH = XLEN,   // 地址总线宽度
    parameter integer STRB_WIDTH = DATA_WIDTH / 8,  // 字节使能宽度
    parameter integer RESP_DELAY = 0       // 响应延迟周期数
) (
    // ------------------------------------------------------------
    // 时钟和复位
    // ------------------------------------------------------------
    input  wire            clk,              // 时钟信号
    input  wire            rst_n,            // 异步低有效复位

    // ------------------------------------------------------------
    // CPU 存储器接口
    // ------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0] cpu_addr,      // 内存地址
    input  wire            cpu_req,         // 内存请求
    input  wire            cpu_we,          // 写使能
    input  wire [DATA_WIDTH-1:0] cpu_wdata,    // 写数据
    input  wire [STRB_WIDTH-1:0] cpu_wstrb,   // 字节使能
    output wire [DATA_WIDTH-1:0] cpu_rdata,     // 读数据
    output wire            cpu_rvalid,       // 读有效
    output wire            cpu_ready,        // 就绪信号
    output wire            cpu_error,        // 错误响应

    // ------------------------------------------------------------
    // AXI4-Lite 主设备接口 - 读地址通道
    // ------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0] m_axi_araddr,  // 读地址
    output wire [2:0]          m_axi_arprot,   // 保护类型
    output wire                 m_axi_arvalid,  // 读地址有效
    input  wire                 m_axi_arready,  // 读地址就绪

    // ------------------------------------------------------------
    // AXI4-Lite 主设备接口 - 读数据通道
    // ------------------------------------------------------------
    input  wire [DATA_WIDTH-1:0] m_axi_rdata,   // 读数据
    input  wire [1:0]           m_axi_rresp,    // 读响应
    input  wire                 m_axi_rvalid,   // 读数据有效
    output wire                 m_axi_rready,    // 读数据就绪

    // ------------------------------------------------------------
    // AXI4-Lite 主设备接口 - 写地址通道
    // ------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0] m_axi_awaddr,  // 写地址
    output wire [2:0]          m_axi_awprot,   // 保护类型
    output wire                 m_axi_awvalid,  // 写地址有效
    input  wire                 m_axi_awready,  // 写地址就绪

    // ------------------------------------------------------------
    // AXI4-Lite 主设备接口 - 写数据通道
    // ------------------------------------------------------------
    output wire [DATA_WIDTH-1:0] m_axi_wdata,    // 写数据
    output wire [STRB_WIDTH-1:0] m_axi_wstrb,   // 字节使能
    output wire                 m_axi_wvalid,   // 写数据有效
    input  wire                 m_axi_wready,   // 写数据就绪

    // ------------------------------------------------------------
    // AXI4-Lite 主设备接口 - 写响应通道
    // ------------------------------------------------------------
    input  wire [1:0]           m_axi_bresp,    // 写响应
    input  wire                 m_axi_bvalid,   // 写响应有效
    output wire                 m_axi_bready    // 写响应就绪
);

    // ================================================================
    // 状态机定义
    // ================================================================
localparam [3:0]
    STATE_IDLE       = 4'd0,  // 空闲状态
    STATE_AR_WAIT    = 4'd1,  // 等待读地址握手
    STATE_R_WAIT     = 4'd2,  // 等待读数据
    STATE_AW_WAIT    = 4'd3,  // 等待写地址握手
    STATE_W_WAIT     = 4'd4,  // 等待写数据握手
    STATE_B_WAIT     = 4'd5;  // 等待写响应

    // ================================================================
    // 内部信号定义
    // ================================================================
reg [3:0] state_r, state_next;
reg [DATA_WIDTH-1:0] rdata_r;
reg rvalid_r;
reg ready_r;
reg error_r;

    // ================================================================
    // 状态寄存器
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_r <= STATE_IDLE;
    end else begin
        state_r <= state_next;
    end
end

    // ================================================================
    // 状态转移逻辑
    // ================================================================
always @* begin
    state_next = state_r;
    case (state_r)
        STATE_IDLE: begin
            if (cpu_req && cpu_we) begin
                state_next = STATE_AW_WAIT;
            end else if (cpu_req && !cpu_we) begin
                state_next = STATE_AR_WAIT;
            end
        end
        
        STATE_AR_WAIT: begin
            if (m_axi_arvalid && m_axi_arready) begin
                state_next = STATE_R_WAIT;
            end
        end
        
        STATE_R_WAIT: begin
            if (m_axi_rvalid && m_axi_rready) begin
                state_next = STATE_IDLE;
            end
        end
        
        STATE_AW_WAIT: begin
            if (m_axi_awvalid && m_axi_awready) begin
                state_next = STATE_W_WAIT;
            end
        end
        
        STATE_W_WAIT: begin
            if (m_axi_wvalid && m_axi_wready) begin
                state_next = STATE_B_WAIT;
            end
        end
        
        STATE_B_WAIT: begin
            if (m_axi_bvalid && m_axi_bready) begin
                state_next = STATE_IDLE;
            end
        end
        
        default: state_next = STATE_IDLE;
    endcase
end

    // ================================================================
    // 输出和控制信号
    // ================================================================

    // 读地址通道
assign m_axi_araddr  = cpu_addr;
assign m_axi_arprot  = 3'b000;  // 数据访问，无特权
assign m_axi_arvalid = (state_r == STATE_AR_WAIT);

    // 读数据通道
assign m_axi_rready  = (state_r == STATE_R_WAIT);

    // 写地址通道
assign m_axi_awaddr  = cpu_addr;
assign m_axi_awprot  = 3'b000;
assign m_axi_awvalid = (state_r == STATE_AW_WAIT);

    // 写数据通道
assign m_axi_wdata   = cpu_wdata;
assign m_axi_wstrb   = cpu_wstrb;
assign m_axi_wvalid  = (state_r == STATE_W_WAIT);

    // 写响应通道
assign m_axi_bready  = (state_r == STATE_B_WAIT);

    // ================================================================
    // 读数据寄存
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata_r <= {DATA_WIDTH{1'b0}};
        rvalid_r <= 1'b0;
        error_r <= 1'b0;
    end else begin
        case (state_r)
            STATE_R_WAIT: begin
                if (m_axi_rvalid && m_axi_rready) begin
                    rdata_r <= m_axi_rdata;
                    rvalid_r <= 1'b1;
                    error_r <= (m_axi_rresp != 2'b00);  // 00=OKAY, 10=SLVERR
                end
            end
            
            STATE_IDLE: begin
                rvalid_r <= 1'b0;
                error_r <= 1'b0;
            end
            
            default: begin
                rvalid_r <= 1'b0;
            end
        endcase
    end
end

    // ================================================================
    // 就绪信号生成
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ready_r <= 1'b0;
    end else begin
        case (state_r)
            STATE_IDLE: begin
                ready_r <= 1'b1;
            end
            
            STATE_B_WAIT: begin
                if (m_axi_bvalid && m_axi_bready) begin
                    ready_r <= 1'b1;
                end else begin
                    ready_r <= 1'b0;
                end
            end
            
            STATE_R_WAIT: begin
                if (m_axi_rvalid && m_axi_rready) begin
                    ready_r <= 1'b1;
                end else begin
                    ready_r <= 1'b0;
                end
            end
            
            default: begin
                ready_r <= 1'b0;
            end
        endcase
    end
end

    // ================================================================
    // 输出信号
    // ================================================================
assign cpu_rdata = rdata_r;
assign cpu_rvalid = rvalid_r;
assign cpu_ready = ready_r;
assign cpu_error = error_r;

endmodule


// ============================================================
// YH_rv_cpu_axi_lite_slave_if.v
// Author: Toylog
// Version: v1.2
// Function: AXI4-Lite 从设备接口模块
// Description: 将标准AXI4-Lite接口转换为简单存储器接口
//   支持从设备连接到AXI4-Lite总线
// ============================================================

module YH_rv_cpu_axi_lite_slave_if #(
    parameter integer XLEN = 32,           // 数据通路宽度
    parameter integer DATA_WIDTH = 32,     // 数据总线宽度
    parameter integer ADDR_WIDTH = XLEN,   // 地址总线宽度
    parameter integer STRB_WIDTH = DATA_WIDTH / 8  // 字节使能宽度
) (
    // ------------------------------------------------------------
    // 时钟和复位
    // ------------------------------------------------------------
    input  wire            clk,              // 时钟信号
    input  wire            rst_n,            // 异步低有效复位

    // ------------------------------------------------------------
    // 简单存储器接口 (连接到内部外设)
    // ------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0] mem_addr,      // 内存地址
    output wire            mem_req,         // 内存请求
    output wire            mem_we,          // 写使能
    output wire [DATA_WIDTH-1:0] mem_wdata,    // 写数据
    output wire [STRB_WIDTH-1:0] mem_wstrb,   // 字节使能
    input  wire [DATA_WIDTH-1:0] mem_rdata,     // 读数据
    input  wire            mem_ready,       // 就绪信号
    input  wire            mem_error,       // 错误响应

    // ------------------------------------------------------------
    // AXI4-Lite 从设备接口 - 读地址通道
    // ------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,  // 读地址
    input  wire [2:0]          s_axi_arprot,   // 保护类型
    input  wire                 s_axi_arvalid,  // 读地址有效
    output wire                 s_axi_arready,  // 读地址就绪

    // ------------------------------------------------------------
    // AXI4-Lite 从设备接口 - 读数据通道
    // ------------------------------------------------------------
    output wire [DATA_WIDTH-1:0] s_axi_rdata,   // 读数据
    output wire [1:0]           s_axi_rresp,    // 读响应
    output wire                 s_axi_rvalid,   // 读数据有效
    input  wire                 s_axi_rready,   // 读数据就绪

    // ------------------------------------------------------------
    // AXI4-Lite 从设备接口 - 写地址通道
    // ------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,  // 写地址
    input  wire [2:0]          s_axi_awprot,   // 保护类型
    input  wire                 s_axi_awvalid,  // 写地址有效
    output wire                 s_axi_awready,  // 写地址就绪

    // ------------------------------------------------------------
    // AXI4-Lite 从设备接口 - 写数据通道
    // ------------------------------------------------------------
    input  wire [DATA_WIDTH-1:0] s_axi_wdata,    // 写数据
    input  wire [STRB_WIDTH-1:0] s_axi_wstrb,   // 字节使能
    input  wire                 s_axi_wvalid,   // 写数据有效
    output wire                 s_axi_wready,   // 写数据就绪

    // ------------------------------------------------------------
    // AXI4-Lite 从设备接口 - 写响应通道
    // ------------------------------------------------------------
    output wire [1:0]           s_axi_bresp,    // 写响应
    output wire                 s_axi_bvalid,   // 写响应有效
    input  wire                 s_axi_bready    // 写响应就绪
);

    // ================================================================
    // 状态机定义
    // ================================================================
localparam [3:0]
    STATE_IDLE       = 4'd0,
    STATE_AR_WAIT    = 4'd1,
    STATE_R_DATA     = 4'd2,
    STATE_AW_WAIT    = 4'd3,
    STATE_W_WAIT     = 4'd4,
    STATE_B_RESP     = 4'd5;

    // ================================================================
    // 内部信号
    // ================================================================
reg [3:0] state_r, state_next;
reg [ADDR_WIDTH-1:0] araddr_r;
reg [ADDR_WIDTH-1:0] awaddr_r;
reg [DATA_WIDTH-1:0] wdata_r;
reg [STRB_WIDTH-1:0] wstrb_r;

    // ================================================================
    // 状态寄存器
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_r <= STATE_IDLE;
    end else begin
        state_r <= state_next;
    end
end

    // ================================================================
    // 状态转移逻辑
    // ================================================================
always @* begin
    state_next = state_r;
    case (state_r)
        STATE_IDLE: begin
            if (s_axi_arvalid) begin
                state_next = STATE_AR_WAIT;
            end else if (s_axi_awvalid) begin
                state_next = STATE_AW_WAIT;
            end
        end
        
        STATE_AR_WAIT: begin
            if (s_axi_arvalid && s_axi_arready) begin
                state_next = STATE_R_DATA;
            end
        end
        
        STATE_R_DATA: begin
            if (s_axi_rvalid && s_axi_rready) begin
                state_next = STATE_IDLE;
            end
        end
        
        STATE_AW_WAIT: begin
            if (s_axi_awvalid && s_axi_awready) begin
                state_next = STATE_W_WAIT;
            end
        end
        
        STATE_W_WAIT: begin
            if (s_axi_wvalid && s_axi_wready) begin
                state_next = STATE_B_RESP;
            end
        end
        
        STATE_B_RESP: begin
            if (s_axi_bvalid && s_axi_bready) begin
                state_next = STATE_IDLE;
            end
        end
        
        default: state_next = STATE_IDLE;
    endcase
end

    // ================================================================
    // 地址和数据寄存
    // ================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        araddr_r <= {ADDR_WIDTH{1'b0}};
        awaddr_r <= {ADDR_WIDTH{1'b0}};
        wdata_r <= {DATA_WIDTH{1'b0}};
        wstrb_r <= {STRB_WIDTH{1'b0}};
    end else begin
        case (state_r)
            STATE_AR_WAIT: begin
                if (s_axi_arvalid) begin
                    araddr_r <= s_axi_araddr;
                end
            end
            
            STATE_AW_WAIT: begin
                if (s_axi_awvalid) begin
                    awaddr_r <= s_axi_awaddr;
                end
            end
            
            STATE_W_WAIT: begin
                if (s_axi_wvalid) begin
                    wdata_r <= s_axi_wdata;
                    wstrb_r <= s_axi_wstrb;
                end
            end
        endcase
    end
end

    // ================================================================
    // 就绪信号
    // ================================================================
assign s_axi_arready = (state_r == STATE_AR_WAIT);
assign s_axi_awready = (state_r == STATE_AW_WAIT);
assign s_axi_wready = (state_r == STATE_W_WAIT);
assign s_axi_bvalid = (state_r == STATE_B_RESP);

    // ================================================================
    // 读数据输出
    // ================================================================
reg [DATA_WIDTH-1:0] rdata_r;
reg [1:0] rresp_r;
reg rvalid_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata_r <= {DATA_WIDTH{1'b0}};
        rresp_r <= 2'b00;
        rvalid_r <= 1'b0;
    end else begin
        case (state_r)
            STATE_R_DATA: begin
                rdata_r <= mem_rdata;
                rresp_r <= mem_error ? 2'b10 : 2'b00;
                rvalid_r <= 1'b1;
            end
            
            STATE_IDLE: begin
                rvalid_r <= 1'b0;
            end
            
            default: begin
                rvalid_r <= 1'b0;
            end
        endcase
    end
end

assign s_axi_rdata = rdata_r;
assign s_axi_rresp = rresp_r;
assign s_axi_rvalid = rvalid_r;

    // ================================================================
    // 写响应
    // ================================================================
reg [1:0] bresp_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bresp_r <= 2'b00;
    end else begin
        if (state_r == STATE_B_RESP) begin
            bresp_r <= mem_error ? 2'b10 : 2'b00;
        end
    end
end

assign s_axi_bresp = bresp_r;

    // ================================================================
    // 简单存储器接口输出
    // ================================================================
reg mem_req_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_req_r <= 1'b0;
    end else begin
        case (state_r)
            STATE_AR_WAIT: begin
                if (s_axi_arvalid) begin
                    mem_req_r <= 1'b1;
                end
            end
            
            STATE_AW_WAIT: begin
                if (s_axi_awvalid) begin
                    mem_req_r <= 1'b1;
                end
            end
            
            STATE_IDLE: begin
                mem_req_r <= 1'b0;
            end
            
            default: begin
                mem_req_r <= 1'b0;
            end
        endcase
    end
end

assign mem_addr = (state_r == STATE_AR_WAIT) ? s_axi_araddr :
                   (state_r == STATE_R_DATA) ? araddr_r :
                   (state_r == STATE_AW_WAIT) ? s_axi_awaddr :
                   (state_r == STATE_W_WAIT) ? awaddr_r :
                   (state_r == STATE_B_RESP) ? awaddr_r :
                   {ADDR_WIDTH{1'b0}};

assign mem_req = mem_req_r;
assign mem_we = (state_r == STATE_AW_WAIT) || (state_r == STATE_W_WAIT) || (state_r == STATE_B_RESP);
assign mem_wdata = wdata_r;
assign mem_wstrb = wstrb_r;

endmodule
