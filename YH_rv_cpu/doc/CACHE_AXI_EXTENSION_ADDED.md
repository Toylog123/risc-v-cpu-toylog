# Cache 和 AXI4-Lite 接口扩展说明

> **Author**: Toylog
> **Version**: v1.2
> **Date**: 2026-04-22
> **Status**: 新增功能完成

---

## 📋 新增文件清单

### RTL 模块

| 文件路径 | 功能 | 状态 |
|---------|------|------|
| `rtl/YH_rv_cpu_icache.v` | 指令缓存 (I-Cache) | ✅ 完成 |
| `rtl/YH_rv_cpu_dcache.v` | 数据缓存 (D-Cache) | ✅ 完成 |
| `rtl/YH_rv_cpu_axi_lite_if.v` | AXI4-Lite 主/从设备接口 | ✅ 完成 |

### 测试平台

| 文件路径 | 功能 | 状态 |
|---------|------|------|
| `tb/YH_rv_cpu_icache_tb.v` | I-Cache 测试平台 | ✅ 完成 |
| `tb/YH_rv_cpu_dcache_tb.v` | D-Cache 测试平台 | ✅ 完成 |

### 设计文档

| 文件路径 | 功能 | 状态 |
|---------|------|------|
| `doc/cache_axi_integration_design.md` | 集成设计文档 | ✅ 完成 |

---

## 🎯 功能特性

### 1. I-Cache (指令缓存)

#### 核心特性
- ✅ **参数化设计**: 支持可配置的缓存大小、块大小、关联度
- ✅ **直接映射/组相联**: 可选的1/2/4路组相联
- ✅ **LRU替换策略**: 多路组相联时的智能替换
- ✅ **状态机控制**: 完整的缓存命中/缺失处理

#### 参数配置
```verilog
parameter integer CACHE_SIZE = 4096;  // 缓存大小 (字节)
parameter integer BLOCK_SIZE = 32;     // 块大小 (字节)
parameter integer ASSOC = 1;          // 关联度 (1=直接映射)
parameter integer CACHE_ID = 0;        // 缓存ID
```

### 2. D-Cache (数据缓存)

#### 核心特性
- ✅ **参数化设计**: 支持可配置的缓存大小、块大小、关联度
- ✅ **写策略选择**: 支持写直达(0)和写回(1)两种策略
- ✅ **字节访问支持**: 完整的字节/半字/字/双字访问
- ✅ **脏位管理**: 写回策略下的脏数据管理

#### 参数配置
```verilog
parameter integer CACHE_SIZE = 4096;   // 缓存大小 (字节)
parameter integer BLOCK_SIZE = 32;      // 块大小 (字节)
parameter integer ASSOC = 1;            // 关联度
parameter integer WRITE_POLICY = 0;     // 0=写直达, 1=写回
parameter integer CACHE_ID = 0;          // 缓存ID
```

### 3. AXI4-Lite 接口

#### 主设备接口 (YH_rv_cpu_axi_lite_if)
- ✅ **标准AXI4-Lite协议**: 完全符合AMBA AXI4-Lite规范
- ✅ **读/写事务**: 支持完整的读和写操作
- ✅ **错误响应处理**: 正确处理SLVERR和DECERR
- ✅ **可配置延迟**: 支持添加可配置的等待周期

#### 从设备接口 (YH_rv_cpu_axi_lite_slave_if)
- ✅ **标准AXI4-Lite协议**: 符合从设备接口规范
- ✅ **完整握手**: 正确的地址和数据通道握手
- ✅ **响应生成**: 自动生成OKAY/SLVERR响应

---

## 📊 资源占用

### Cache 资源预估

| 配置 | LUT | FF | BRAM | 说明 |
|------|-----|-----|------|------|
| 无Cache | 0 | 0 | 0 | 基准 |
| 2KB I-Cache | ~250 | ~150 | 1 | 直接映射 |
| 2KB D-Cache | ~300 | ~180 | 1 | 直接映射 |
| 4KB 2路组相联 | ~600 | ~400 | 2 | 更高命中率 |

### AXI4-Lite 资源预估

| 模块 | LUT | FF | 说明 |
|------|-----|-----|------|
| AXI Master | ~200 | ~150 | 主设备接口 |
| AXI Slave | ~180 | ~120 | 从设备接口 |

---

## 🔧 使用方法

### 1. 启用 Cache

在 CPU 或 SoC 中实例化 Cache 模块：

```verilog
// I-Cache 实例化示例
YH_rv_cpu_icache #(
    .XLEN(32),
    .CACHE_SIZE(2048),
    .BLOCK_SIZE(32),
    .ASSOC(1)
) u_icache (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_addr(cpu_addr),
    .cpu_req(cpu_req),
    .cpu_rdata(cpu_rdata),
    .cpu_rvalid(cpu_rvalid),
    .cpu_wait(cpu_wait),
    .mem_addr(mem_addr),
    .mem_req(mem_req),
    .mem_we(mem_we),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata),
    .mem_rvalid(mem_rvalid)
);
```

### 2. 启用 AXI4-Lite 接口

```verilog
// AXI Master 接口实例化
YH_rv_cpu_axi_lite_if #(
    .XLEN(32),
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) u_axi_master (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_addr(cpu_addr),
    .cpu_req(cpu_req),
    .cpu_we(cpu_we),
    .cpu_wdata(cpu_wdata),
    .cpu_wstrb(cpu_wstrb),
    .cpu_rdata(cpu_rdata),
    .cpu_rvalid(cpu_rvalid),
    .cpu_ready(cpu_ready),
    .cpu_error(cpu_error),
    // AXI4-Lite 信号...
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    // ... 其他AXI信号
);
```

---

## 🧪 测试验证

### 运行 I-Cache 测试
```bash
cd YH_rv_cpu
iverilog -o tb/YH_rv_cpu_icache_tb.vvp \
    -I./rtl \
    tb/YH_rv_cpu_icache_tb.v \
    rtl/YH_rv_cpu_icache.v

vvp tb/YH_rv_cpu_icache_tb.vvp
```

### 运行 D-Cache 测试
```bash
iverilog -o tb/YH_rv_cpu_dcache_tb.vvp \
    -I./rtl \
    tb/YH_rv_cpu_dcache_tb.v \
    rtl/YH_rv_cpu_dcache.v

vvp tb/YH_rv_cpu_dcache_tb.vvp
```

### 测试覆盖场景

#### I-Cache 测试
- ✅ 顺序取指 (缓存命中)
- ✅ 随机访问 (缓存缺失)
- ✅ 循环访问 (缓存命中)
- ✅ 大跨度访问 (缓存缺失)

#### D-Cache 测试
- ✅ 基本读操作
- ✅ 基本写操作 (写直达)
- ✅ 写后读 (缓存命中)
- ✅ 字节写
- ✅ 循环访问

---

## ⚙️ 参数优化建议

### 缓存大小选择

| 应用场景 | 建议配置 | 说明 |
|---------|---------|------|
| 最小资源 | 无Cache | 0 LUT资源 |
| 资源受限 | 1KB I-Cache + 1KB D-Cache | ~500 LUT |
| 均衡方案 | 2KB I-Cache + 2KB D-Cache | ~800 LUT |
| 性能优先 | 4KB I-Cache + 4KB D-Cache | ~1200 LUT |

### 关联度选择

| 关联度 | 命中率 | 资源开销 | 适用场景 |
|--------|--------|---------|---------|
| 1 (直接映射) | 基础 | 最低 | 资源受限 |
| 2 (2路组相联) | +5-10% | +30% | 通用场景 |
| 4 (4路组相联) | +10-15% | +60% | 性能优先 |

### 写策略选择

| 策略 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| 写直达 | 简单、一致性好 | 写操作频繁 | 写入较少 |
| 写回 | 减少内存访问 | 复杂、需脏位管理 | 写入较多 |

---

## 📈 性能预期

### CoreMark 性能提升

根据缓存命中率预估性能提升：

| 缓存配置 | 预期命中率 | CoreMark提升 |
|---------|-----------|-------------|
| 无Cache | 0% | 基准 |
| 2KB I/D Cache | 70-80% | 30-50% |
| 4KB I/D Cache | 85-95% | 50-80% |

### 内存带宽节省

| 缓存配置 | 读带宽节省 | 写带宽节省 |
|---------|-----------|-----------|
| 写直达 | 取决于命中率 | 100% (所有写都到内存) |
| 写回 | 取决于命中率 | 取决于脏块比例 |

---

## 🔍 调试建议

### 常见问题

1. **缓存一致性问题**
   - 检查写策略是否正确
   - 验证脏位管理逻辑
   - 确认替换算法实现

2. **时序问题**
   - 检查Cache访问延迟
   - 优化关键路径
   - 考虑添加流水线寄存器

3. **资源占用过高**
   - 减小Cache大小
   - 降低关联度
   - 优化BRAM使用

### 调试工具

- 使用 `ifdef DEBUG_CACHE` 开启调试输出
- 监控 `cpu_wait` 信号判断Cache状态
- 分析仿真波形检查状态机转换

---

## 📝 更新历史

| 日期 | 版本 | 变更内容 |
|------|------|---------|
| 2026-04-22 | v1.2 | 完成Cache和AXI4-Lite模块实现 |
| 2026-04-22 | v1.1 | 基础架构设计 |
| 2026-04-09 | v1.0 | 项目初始化 |

---

## ✅ 待办事项

- [ ] 集成Cache到YH_rv_cpu核
- [ ] 集成AXI4-Lite到SoC
- [ ] 运行完整CoreMark测试
- [ ] 优化资源占用
- [ ] 添加性能分析脚本

---

## 📚 参考资料

1. [RISC-V Architecture Specification](https://riscv.org/technical/specifications/)
2. [AMBA AXI4-Lite Protocol Specification](https://developer.arm.com/documentation/ihi0022/h/)
3. [Computer Architecture: A Quantitative Approach](https://www.elsevier.com/books/computer-architecture/john-hennessy/978-0-12-811905-1)

---

## 📞 联系方式

如有问题或建议，请联系项目维护者。

**Author**: Toylog  
**Email**: (请在项目README中查找)
