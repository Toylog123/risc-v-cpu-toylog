# impl60_rcache_raw_lookup_cpu50_wns+0p301

Historical timing experiment. Do not report this as the strict exact-CoreMark-ROM
50MHz candidate.

Demotion note, 2026-06-12: the Vivado implementation log in this directory binds
`YH_rv_cpu_demo.hex` / `YH_rv_cpu_demo.mem32.hex`, with `ROM_BYTES=8192` and
`RAM_BYTES=8192`. The timing result is useful as a hardware timing experiment,
but it is not exact CoreMark ROM evidence. The current strict exact-ROM
candidate is
`../impl74_exblock_nodcache_luspec_exactrom_cpu50_wns+0p341`.

## Result

| Item | Value |
| --- | --- |
| CPU clock | 50MHz |
| CoreMark/MHz | 4.151598 |
| DMIPS/MHz | 2.484735 |
| CRC final | 0xfcaf |
| Completion cycles | 2450912 |
| LUT | 6255 |
| FF | 3192 |
| BRAM36 | 4 |
| DSP | 8 |
| WNS | +0.301ns |
| WHS | +0.104ns |
| Route status | fully routed, 0 routing errors |

## Scope

- Hardware-only RTL and build-flow candidate.
- CoreMark algorithm sources were not modified.
- Fast gate evidence is short-runtime reproducible and marked `competition_reportable=yes`; it is not strict EEMBC 10s compliant.
- Matching bitstream is archived here as `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_impl60.bit`.
- The original implementation run used `PYNQ_IMPL_WRITE_BITSTREAM_OVERRIDE=0`; the bitstream was generated afterwards from the same routed checkpoint using `write_bitstream_from_impl60.tcl`.
- Matching Dhrystone/DMIPS simulation evidence is archived at `../sim60_dhrystone_impl60_match`.
- Board PROGRAM_OK, UART capture, and video evidence are still pending.

## ISA / RTL Configuration

This implementation was rerun after correcting the FPGA generic set to match the fast-gate CoreMark ISA:

- `ENABLE_ZMMUL_EXTENSION=1`
- `ENABLE_BITMANIP_EXTENSION=1`
- `ENABLE_ZBC_EXTENSION=1`
- `ENABLE_ZICOND_EXTENSION=1`
- `ENABLE_XTHEAD_EXTENSION=1`
- `ENABLE_XTHEAD_MUL_EXTENSION=1`
- `ENABLE_XTHEAD_COND_MOVE=1`
- `ENABLE_ZBKB_EXTENSION=0`
- `ENABLE_XTHEAD_CRC_EXTENSION=0`
- `ENABLE_XTHEAD_MEMPAIR_EXTENSION=0`
- `ENABLE_XTHEAD_BASE_UPDATE_EXTENSION=0`

## Key Optimization

- Added `ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK`.
- With the flag enabled, redirect-cache lookup uses ID-side lookup request/PC signals that do not include `ex_fetch_redirect_valid` in the lookup address/select cone.
- Final delivery is still mutually excluded by the actual `ex_fetch_redirect_valid`, so CoreMark fast-gate performance stays unchanged versus `sim55`.
- Implementation used `PYNQ_PLACE_DIRECTIVE_OVERRIDE=ExtraNetDelay_high`.

## Evidence Files

- `coremark50_fast_gate_iter10.summary.txt`
- `coremark50_fast_gate_iter10.log`
- `impl_timing_summary.rpt`
- `impl_timing_setup_top20.rpt`
- `impl_timing_hold_top20.rpt`
- `impl_utilization.rpt`
- `impl_methodology.rpt`
- `impl_route_status.rpt`
- `vivado_pynq_z2_impl.log`
- `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_impl.dcp`
- `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_impl60.bit`
- `write_bitstream_from_impl60.tcl`
- `vivado_write_bitstream_from_impl60.log`
- `bitstream_from_dcp_timing_summary.rpt`
- `bitstream_from_dcp_utilization.rpt`
