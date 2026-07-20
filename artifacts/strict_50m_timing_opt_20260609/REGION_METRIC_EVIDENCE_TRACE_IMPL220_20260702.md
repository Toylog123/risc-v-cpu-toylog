# strict50 impl220 指标证据追踪表 2026-07-02

本文档把当前分赛区主指标逐项绑定到原始报告和可复核命令。该表不新增实验结果，
只验证 `impl220` 已归档证据。

## 主指标与证据路径

| 指标 | 当前值 | 原始证据 | 解析位置 |
|---|---:|---|---|
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | `FREEZE_STRICT50_IMPL220_20260701.md` | freeze decision |
| Slice LUT | 9965 | `impl220.../reports_cpu50/impl_utilization.rpt` | `Slice LUTs` |
| Slice FF | 6520 | `impl220.../reports_cpu50/impl_utilization.rpt` | `Slice Registers` |
| BRAM Tile | 32 | `impl220.../reports_cpu50/impl_utilization.rpt` | `Block RAM Tile` |
| DSP | 8 | `impl220.../reports_cpu50/impl_utilization.rpt` | `DSPs` |
| CoreMark/MHz | 4.287521 | `fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt` | `coremark_per_mhz` |
| CoreMark CRC | `0xfcaf` | `fast210...summary.txt` | `crcfinal` |
| CoreMark acceptance | `yes` | `fast210...summary.txt` | `acceptance_pass` |
| DMIPS/MHz | 2.495618 | `sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt` | `dmips_per_mhz` |
| Dhrystones/s | 219240 | `sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt` | `dhrystones_per_second` |
| 50 MHz timing | closed | `impl220.../reports_cpu50/impl_timing_summary.rpt` | `All user specified timing constraints are met.` |
| WNS | +0.056 ns | `impl220.../reports_cpu50/impl_timing_summary.rpt` | design timing summary row |
| WHS | +0.121 ns | `impl220.../reports_cpu50/impl_timing_summary.rpt` | design timing summary row |
| EEMBC 10s compliance | no | `fast210...summary.txt` | `strict_eembc_10s_compliant=no` |

## 可复核命令

在 worktree 根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/verify_strict50_impl220_metrics.ps1
```

期望结尾：

```text
verification_status=PASS
```

## 当前验证输出

```text
candidate=impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50
lut=9965
ff=6520
bram_tile=32
dsp=8
coremark_per_mhz=4.287521
crcfinal=0xfcaf
acceptance_pass=yes
strict_eembc_10s_compliant=no
validation_mode=short_runtime_only
wns_ns=0.056
whs_ns=0.121
timing_closed=True
verification_status=PASS
```

## 边界说明

- 该验证只证明当前归档 implementation evidence 与报告口径一致。
- 该验证不证明 `impl220` 已经 board-proven。
- 当前 `impl220` DMIPS/MHz 来自同配置 `timer50` Dhrystone xsim 证据，不是板级 UART 证据。
- `strict_eembc_10s_compliant=no` 是预期结果；当前 CoreMark 是工程 short-gate，不是官方 EEMBC 10 秒合规结果。
