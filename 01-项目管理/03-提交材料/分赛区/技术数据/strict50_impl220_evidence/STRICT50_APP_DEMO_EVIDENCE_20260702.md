# Strict50 application demo evidence 2026-07-02

This document records the application-demo evidence added for the current
`impl220` strict 50 MHz candidate. This is simulation evidence only. It does
not replace bitstream, PROGRAM_OK, board UART, or video evidence.

## Scope

| Item | Value |
|---|---|
| Candidate identity | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Demo firmware | `YH_rv_cpu/sw/src/perf_demo.c` |
| Strict50 runner | `YH_rv_cpu/scripts/run_strict50_perf_demo.bat` |
| Strict50 testbench | `YH_rv_cpu/tb/YH_rv_cpu_strict50_perf_demo_tb.v` |
| Audit script | `audit_strict50_demo_evidence.ps1` |
| Evidence directory | `strict50_perf_demo_20260702/` |

## Hardware Configuration Anchor

The strict50 demo testbench binds the SoC to the same parameter family used by
`synth200_impl136_bhtidupd0_cpu50` / `impl220`:

| Parameter group | Bound value |
|---|---|
| Clock interpretation | 50 MHz, 20 ns simulation clock |
| ROM/RAM | `ROM_BYTES=65536`, `RAM_BYTES=65536`, `RAM_BASE=0x00010000` |
| Redirect cache | `REDIRECT_CACHE_ENTRIES=512`, simple regular lookup enabled |
| Branch control | `BRANCH_BHT_ENTRIES=64`, dynamic BHT enabled, strong-only/direct-update, ID update disabled |
| DCache/load-use | `DCACHE_EN=1`, `DCACHE_SIZE_BYTES=512`, DCache load-use speculation disabled |
| Extensions | `ZMMUL=1`, `ZBC=1`, `ZICOND=1`, `XThead=1`, `XThead CRC=0`, `XThead MUL=1` |

The audit script verifies these bindings against the strict50 demo testbench
and the archived synth200 Vivado log.

## Reproduction Command

```powershell
$env:PATH="<bundled-python-dir>;$env:PATH"
cmd /c YH_rv_cpu\scripts\run_strict50_perf_demo.bat 30000000
powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/audit_strict50_demo_evidence.ps1
```

## Result

Archived log:

`strict50_perf_demo_20260702/YH_rv_cpu_strict50_perf_demo_xsim_20260702.log`

Key lines:

```text
baseline=strict50 impl220 cpu_clk=50MHz
CRC32 cycles=0x00006e9f units=0x00000200 checksum=0x3287d9af PASS
MATMUL8 cycles=0x0000131d units=0x00000400 checksum=0x44da4cfb PASS
MEMCPYFILL cycles=0x0000b034 units=0x00001000 checksum=0x04053d00 PASS
BRANCH cycles=0x0000d872 units=0x00001000 checksum=0x8bad48bc PASS
LOADUSE cycles=0x0000be2f units=0x00000800 checksum=0x76962aa8 PASS
PERF_DEMO PASS checksum=0xe727358b total_cycles=0x0002c891
PASS: strict50 perf demo completed at PC=00000000 in 198587 cycles, UART bytes=542
```

Audit result:

```text
strict50_demo_audit_status=PASS
```

## Reporting Boundary

Allowed wording:

`The strict50 application demo passes xsim with the impl220-matched SoC
configuration and exercises CRC32, matrix multiply, memory fill/copy, branch,
and load-use workloads. Board evidence remains pending.`

Not allowed before board evidence is added:

- Do not call this demo board-proven.
- Do not use the xsim UART log as PYNQ-Z2 UART evidence.
- Do not report strict50 DMIPS/MHz from this demo.
- Do not treat the demo cycles as official CoreMark or EEMBC evidence.
