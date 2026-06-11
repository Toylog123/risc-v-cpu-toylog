# sim60_dhrystone_impl60_match

Matching Dhrystone/DMIPS simulation for the `impl60_rcache_raw_lookup_cpu50_wns+0p301` strict 50MHz candidate.

## Result

| Item | Value |
| --- | --- |
| Runs | 1000 |
| Dhrystones/s | 436568 |
| DMIPS/MHz | 2.484735 |
| Completion cycles | 272149 |
| Benchmark | Dhrystone 2.2 |
| Measurement mode | host-parsed-from-uart-log |

## Configuration Notes

- Hardware generics were explicitly set to match the `impl60` CoreMark candidate, including `DCACHE_EN=1`, `DCACHE_SIZE_BYTES=512`, `REDIRECT_CACHE_ENTRIES=128`, `ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP=1`, and `ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK=1`.
- ISA generics were set to the same candidate family: `ZMMUL=1`, `BITMANIP=1`, `ZBC=1`, `ZICOND=1`, `XTHEAD=1`, `XTHEAD_MUL=1`, `XTHEAD_COND_MOVE=1`, `ZBKB=0`, `XTHEAD_CRC=0`, `XTHEAD_MEMPAIR=0`, and `XTHEAD_BASE_UPDATE=0`.
- Dhrystone was built with `-O3 -flto -fwhole-program -fno-auto-inc-dec`, and generated sources had the no-inline pragma stripped.
- This is simulation evidence, not board UART evidence.

## Evidence Files

- `dhrystone_impl60_runs1000.summary.txt`
- `dhrystone_impl60_runs1000.log`
