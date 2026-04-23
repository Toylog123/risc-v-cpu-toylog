# Cache 和 AXI4-Lite 接口集成设计文档

> **Author**: Toylog
> **Version**: v1.2
> **Date**: 2026-04-22
> **Status**: D-Cache集成完成（DCACHE_EN=1时启用），I-Cache预留

---

## 2026-04-23 更新

- **D-Cache已集成**：通过`DCACHE_EN`参数控制，已通过M扩展测试11/11验证
- **I-Cache预留**：模块已实现，待后续集成

---

## 1. 概述

本文档描述了如何在 YH_rv_cpu 项目中集成可选的 Cache 功能和 AXI4-Lite 接口。这些功能设计为可参数化配置，可以在不需要时禁用，以保持最小的资源占用。

### 1.1 新增模块

| 模块名 | 文件 | 功能 |
|--------|------|------|
| `YH_rv_cpu_icache` | `rtl/YH_rv_cpu_icache.v` | 参数化指令缓存 |
| `YH_rv_cpu_dcache` | `rtl/YH_rv_cpu_dcache.v` | 参数化数据缓存 |
| `YH_rv_cpu_axi_lite_if` | `rtl/YH_rv_cpu_axi_lite_if.v` | AXI4-Lite 主设备接口 |
| `YH_rv_cpu_axi_lite_slave_if` | `rtl/YH_rv_cpu_axi_lite_slave_if.v` | AXI4-Lite 从设备接口 |

---

## 2. Cache 功能设计

### 2.1 I-Cache (指令缓存)

#### 2.1.1 主要特性

- **直接映射**或**组相联**结构
- **可配置的缓存大小**: 1KB - 64KB
- **可配置的块大小**: 16B - 128B
- **LRU 替换策略** (多路组相联时)
- **支持指令预取** (通过缓存填充实现)

#### 2.1.2 参数定义

```verilog
parameter integer CACHE_SIZE = 4096;    // 缓存大小 (字节)
parameter integer BLOCK_SIZE = 32;     // 块大小 (字节)
parameter integer ASSOC = 1;          // 关联度
parameter integer CACHE_ID = 0;       // 缓存ID
```

#### 2.1.3 接口信号

```verilog
// CPU 接口
input  wire [XLEN-1:0] cpu_addr,
input  wire            cpu_req,
output wire [31:0]     cpu_rdata,
output wire            cpu_rvalid,
output wire            cpu_wait,

// 内存接口
output wire [XLEN-1:0] mem_addr,
output wire            mem_req,
input  wire [31:0]    mem_rdata,
input  wire            mem_rvalid
```

#### 2.1.4 状态机

```
STATE_IDLE → STATE_COMPARE → STATE_REFILL → STATE_IDLE
     ↑_____________↓
```

---

### 2.2 D-Cache (数据缓存)

#### 2.2.1 主要特性

- **直接映射**或**组相联**结构
- **可配置的缓存大小**: 1KB - 64KB
- **可配置的块大小**: 16B - 128B
- **写策略**: 写直达 (write-through) 或写回 (write-back)
- **LRU 替换策略**
- **支持字节/半字/字/双字访问**

#### 2.2.2 参数定义

```verilog
parameter integer CACHE_SIZE = 4096;    // 缓存大小 (字节)
parameter integer BLOCK_SIZE = 32;       // 块大小 (字节)
parameter integer ASSOC = 1;            // 关联度
parameter integer WRITE_POLICY = 0;      // 0=写直达, 1=写回
parameter integer CACHE_ID = 0;         // 缓存ID
```

#### 2.2.3 接口信号

```verilog
// CPU 接口
input  wire [XLEN-1:0] cpu_addr,
input  wire            cpu_req,
input  wire            cpu_we,
input  wire [XLEN-1:0] cpu_wdata,
input  wire [XLEN/8-1:0] cpu_wstrb,
output wire [XLEN-1:0] cpu_rdata,
output wire            cpu_rvalid,
output wire            cpu_wait,

// 内存接口
output wire [XLEN-1:0] mem_addr,
output wire            mem_req,
output wire           mem_we,
output wire [31:0]    mem_wdata,
input  wire [31:0]    mem_rdata,
input  wire           mem_rvalid,
input  wire           mem_ready
```

#### 2.2.4 状态机

```
STATE_IDLE → STATE_WRITE/COMPARE → STATE_REFILL/WRITEBACK → STATE_IDLE
                      ↓
              ┌──────┴──────┐
              ↓             ↓
         STATE_WB    STATE_WB_REFILL
```

---

## 3. AXI4-Lite 接口设计

### 3.1 主设备接口 (AXI Master)

将 CPU 的简单存储器接口转换为标准 AXI4-Lite 接口。

#### 3.1.1 主要特性

- **标准 AXI4-Lite 协议**兼容
- **支持所有访问大小**: 字节/半字/字/双字
- **可配置的响应延迟**
- **错误响应处理**

#### 3.1.2 AXI4-Lite 信号

```verilog
// 读地址通道
output wire [ADDR_WIDTH-1:0] m_axi_araddr,
output wire [2:0]           m_axi_arprot,
output wire                 m_axi_arvalid,
input  wire                 m_axi_arready,

// 读数据通道
input  wire [DATA_WIDTH-1:0] m_axi_rdata,
input  wire [1:0]           m_axi_rresp,
input  wire                 m_axi_rvalid,
output wire                 m_axi_rready,

// 写地址通道
output wire [ADDR_WIDTH-1:0] m_axi_awaddr,
output wire [2:0]           m_axi_awprot,
output wire                 m_axi_awvalid,
input  wire                 m_axi_awready,

// 写数据通道
output wire [DATA_WIDTH-1:0] m_axi_wdata,
output wire [STRB_WIDTH-1:0] m_axi_wstrb,
output wire                 m_axi_wvalid,
input  wire                 m_axi_wready,

// 写响应通道
input  wire [1:0]           m_axi_bresp,
input  wire                 m_axi_bvalid,
output wire                 m_axi_bready
```

### 3.2 从设备接口 (AXI Slave)

将标准 AXI4-Lite 接口转换为简单存储器接口，用于连接外设。

#### 3.2.1 主要特性

- **标准 AXI4-Lite 协议**兼容
- **完整的握手协议**处理
- **错误响应传播**

---

## 4. 集成方案

### 4.1 基础集成 (无 Cache)

```
┌─────────┐     ┌─────────────┐     ┌─────────┐
│  CPU    │────▶│ AXI Master  │────▶│  外设   │
└─────────┘     └─────────────┘     └─────────┘
```

### 4.2 带 Cache 的集成

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  CPU    │────▶│ I/D-Cache│────▶│ AXI Master │────▶│  外设   │
└─────────┘     └─────────┘     └─────────────┘     └─────────┘
```

### 4.3 推荐配置

#### 4.3.1 最小配置 (无 Cache)

```verilog
// CPU参数
parameter integer ENABLE_ICACHE = 0;
parameter integer ENABLE_DCACHE = 0;
```

#### 4.3.2 标准配置 (小 Cache)

```verilog
// CPU参数
parameter integer ENABLE_ICACHE = 1;
parameter integer ICACHE_SIZE = 2048;    // 2KB I-Cache
parameter integer ICACHE_BLOCK = 16;   // 16B块

parameter integer ENABLE_DCACHE = 1;
parameter integer DCACHE_SIZE = 2048;    // 2KB D-Cache
parameter integer DCACHE_BLOCK = 16;    // 16B块
parameter integer DCACHE_ASSOC = 1;     // 直接映射
parameter integer DCACHE_WPOLICY = 0;   // 写直达
```

#### 4.3.3 高性能配置

```verilog
// CPU参数
parameter integer ENABLE_ICACHE = 1;
parameter integer ICACHE_SIZE = 4096;    // 4KB I-Cache
parameter integer ICACHE_BLOCK = 32;    // 32B块
parameter integer ICACHE_ASSOC = 2;     // 2路组相联

parameter integer ENABLE_DCACHE = 1;
parameter integer DCACHE_SIZE = 4096;   // 4KB D-Cache
parameter integer DCACHE_BLOCK = 32;    // 32B块
parameter integer DCACHE_ASSOC = 2;    // 2路组相联
parameter integer DCACHE_WPOLICY = 1;   // 写回
```

---

## 5. 资源估算

### 5.1 Cache 资源占用

| 配置 | LUT | FF | BRAM |
|------|-----|-----|------|
| 无 Cache | 0 | 0 | 0 |
| 2KB I-Cache + 2KB D-Cache | ~500 | ~300 | 2 |
| 4KB I-Cache + 4KB D-Cache | ~800 | ~500 | 4 |
| 8KB I-Cache + 8KB D-Cache | ~1200 | ~800 | 8 |

### 5.2 AXI4-Lite 接口资源占用

| 配置 | LUT | FF |
|------|-----|-----|
| AXI Master | ~200 | ~150 |
| AXI Slave | ~180 | ~120 |

---

## 6. 验证计划

### 6.1 Cache 验证

1. **基本功能测试**
   - [ ] 缓存命中/缺失
   - [ ] 写直达/写回策略
   - [ ] LRU 替换
   - [ ] 字节/半字/字访问

2. **性能测试**
   - [ ] CoreMark 性能对比
   - [ ] 缓存命中率统计
   - [ ] 访问延迟测量

### 6.2 AXI4-Lite 验证

1. **协议一致性测试**
   - [ ] 读事务
   - [ ] 写事务
   - [ ] 错误响应

2. **集成测试**
   - [ ] Cache + AXI4-Lite 集成
   - [ ] 多外设连接

---

## 7. 下一步工作

### 7.1 立即任务

1. [ ] 在 `YH_rv_cpu.v` 中添加 Cache 参数
2. [ ] 在 `YH_rv_cpu_soc.v` 中集成 Cache 模块
3. [ ] 创建 Cache 验证 TestBench
4. [ ] 运行 CoreMark 性能测试

### 7.2 后续任务

1. [ ] 集成 AXI4-Lite 接口到 SoC
2. [ ] 创建 AXI4-Lite 外设示例
3. [ ] 优化 Cache 参数
4. [ ] 更新设计文档

---

## 8. 参考资料

- [RISC-V AXI4-Lite Specification](https://developer.arm.com/documentation/ihi0022/h/)
- [Xilinx AXI Reference Guide](https://www.xilinx.com/support/documentation/ip_documentation/axi_ref_guide/latest/ug1037-vivado-axi-reference-guide.pdf)
