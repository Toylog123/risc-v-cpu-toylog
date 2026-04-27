# Cache 和 AXI4-Lite 实现总结

> **Author**: Toylog
> **Version**: v1.2
> **Date**: 2026-04-22

---

## ✅ 已完成工作

### 1. Cache 功能实现

#### I-Cache (指令缓存)
- **文件**: `rtl/YH_rv_cpu_icache.v`
- **状态**: ✅ 实现完成
- **特性**:
  - 参数化直接映射/组相联缓存
  - 可配置缓存大小 (1KB-64KB)
  - 可配置块大小 (16B-128B)
  - LRU替换策略
  - 完整状态机 (IDLE → COMPARE → REFILL)

#### D-Cache (数据缓存)
- **文件**: `rtl/YH_rv_cpu_dcache.v`
- **状态**: ✅ 实现完成
- **特性**:
  - 参数化直接映射/组相联缓存
  - 支持写直达/写回策略
  - 支持字节/半字/字/双字访问
  - 完整的脏位管理
  - LRU替换策略

### 2. AXI4-Lite 接口实现

#### 主设备接口
- **文件**: `rtl/YH_rv_cpu_axi_lite_if.v` (上半部分)
- **状态**: ✅ 实现完成
- **特性**:
  - 标准AXI4-Lite协议
  - 完整的读/写事务
  - 错误响应处理
  - 可配置响应延迟

#### 从设备接口
- **文件**: `rtl/YH_rv_cpu_axi_lite_if.v` (下半部分)
- **状态**: ✅ 实现完成
- **特性**:
  - 标准AXI4-Lite从设备接口
  - 完整的握手协议
  - 响应生成

### 3. 测试平台

#### I-Cache 测试
- **文件**: `tb/YH_rv_cpu_icache_tb.v`
- **状态**: ✅ 实现完成
- **测试场景**:
  - 顺序取指
  - 随机访问
  - 循环访问
  - 大跨度访问

#### D-Cache 测试
- **文件**: `tb/YH_rv_cpu_dcache_tb.v`
- **状态**: ✅ 实现完成
- **测试场景**:
  - 基本读写
  - 字节写
  - 写后读
  - 循环访问

### 4. 文档

- **集成设计文档**: `doc/cache_axi_integration_design.md`
- **扩展说明文档**: `doc/CACHE_AXI_EXTENSION_ADDED.md`
- **测试脚本**: `scripts/run_cache_tests.bat`

---

## 📊 实现统计

### 代码行数

| 模块 | 代码行数 | 注释行数 | 注释率 |
|------|---------|---------|--------|
| I-Cache | ~350 | ~150 | 43% |
| D-Cache | ~450 | ~190 | 42% |
| AXI4-Lite | ~400 | ~170 | 43% |
| I-Cache TB | ~250 | ~100 | 40% |
| D-Cache TB | ~300 | ~120 | 40% |
| **总计** | **~1750** | **~730** | **42%** |

### 资源占用 (预估)

| 配置 | LUT | FF | BRAM |
|------|-----|-----|------|
| 无优化 | ~1700 | ~1200 | 4 |
| 2KB Cache | ~2300 | ~1700 | 6 |
| 4KB Cache | ~2900 | ~2200 | 8 |

---

## 🔄 集成到现有系统

### 当前 CPU 架构
```
┌─────────┐
│   CPU   │
└────┬────┘
     │
┌────▼────┐
│  imem   │
│  dmem   │
└─────────┘
```

### 目标架构 (Cache + AXI4-Lite)
```
┌─────────┐
│   CPU   │
└────┬────┘
     │
┌────▼────┐    ┌──────────┐    ┌──────────┐
│  I-Cache │──▶│ AXI Lite │──▶│   ROM    │
└─────────┘    └──────────┘    └──────────┘
     │
┌────▼────┐    ┌──────────┐    ┌──────────┐
│  D-Cache │──▶│ AXI Lite │──▶│   RAM    │
└─────────┘    └──────────┘    └──────────┘
```

---

## 📝 使用说明

### 1. 启用 Cache

在 `YH_rv_cpu_soc.v` 中添加：

```verilog
// I-Cache
YH_rv_cpu_icache #(
    .CACHE_SIZE(2048),
    .BLOCK_SIZE(32),
    .ASSOC(1)
) u_icache (...);

// D-Cache
YH_rv_cpu_dcache #(
    .CACHE_SIZE(2048),
    .BLOCK_SIZE(32),
    .ASSOC(1),
    .WRITE_POLICY(0)
) u_dcache (...);
```

### 2. 运行测试

```bash
cd YH_rv_cpu
scripts\run_cache_tests.bat
```

---

## 🎯 性能目标

### CoreMark 性能提升

| 配置 | 目标提升 | 说明 |
|------|---------|------|
| 2KB Cache | +30-50% | 适合资源受限场景 |
| 4KB Cache | +50-80% | 性能优先场景 |

### 时序目标

| 配置 | 目标频率 | 说明 |
|------|---------|------|
| 无Cache | ≥100MHz | 基准 |
| 2KB Cache | ≥80MHz | 需要优化 |
| 4KB Cache | ≥60MHz | 复杂路径 |

---

## 📋 待完成工作

### 高优先级
- [ ] 将Cache集成到YH_rv_cpu核
- [ ] 将AXI4-Lite集成到SoC
- [ ] 运行完整验证测试
- [ ] 更新赛题要求清单

### 中优先级
- [ ] 优化Cache时序
- [ ] 降低资源占用
- [ ] 添加性能分析脚本
- [ ] 编写用户手册

### 低优先级
- [ ] 添加更多测试用例
- [ ] 优化功耗
- [ ] 添加调试功能
- [ ] 形式验证

---

## 🐛 已知限制

1. **Cache一致性**: 当前实现不支持多核一致性协议
2. **非对齐访问**: 对非对齐访问的支持有限
3. **实时性能**: 未实现实时性能监控

---

## 📈 未来改进方向

1. **性能优化**
   - 添加指令预取
   - 实现victim cache
   - 优化替换算法

2. **功能扩展**
   - 多核一致性支持
   - 硬件一致性管理
   - 性能计数器

3. **工具链改进**
   - 自动化参数优化
   - 性能分析脚本
   - 可视化调试工具

---

## ✅ 验证清单

### 功能验证
- [x] I-Cache基本功能
- [x] D-Cache基本功能
- [x] 缓存命中/缺失
- [x] LRU替换
- [x] 字节访问
- [x] AXI4-Lite协议

### 性能验证
- [ ] CoreMark基准测试
- [ ] 缓存命中率统计
- [ ] 时序分析
- [ ] 资源利用率

### 集成验证
- [ ] CPU集成测试
- [ ] SoC集成测试
- [ ] FPGA综合测试
- [ ] 实板运行测试

---

## 📚 参考文档

1. [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
2. [AMBA AXI4-Lite Specification](https://developer.arm.com/documentation/ihi0022/h/)
3. [Cache性能优化技术](various papers)

---

**Last Updated**: 2026-04-22  
**Status**: Implementation Complete  
**Next Steps**: Integration and Validation
