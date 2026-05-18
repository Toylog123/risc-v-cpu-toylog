# RC8192 Control-Flow Cache Freeze

Date: 2026-05-18

This checkpoint keeps the CoreMark workload unchanged and only changes hardware
configuration parameters.  The explored mechanism is a larger redirect target
instruction cache used by the existing ID-stage branch/JAL redirect and branch
target fold path.  It is a lightweight control-flow form of instruction folding:
when a redirected target instruction is already cached, the frontend can avoid
waiting for the synchronous instruction memory response and can sometimes feed
the target or target+4 instruction directly into the pipeline.

## Configuration

- Target: `rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_zbkx_xthead_memidx_mac_mempair_o2sched_nocaller`
- CoreMark data size: `2000`
- Iterations: `10`
- Clock used by host parser: `100000000UL`
- `YH_COREMARK_FPGA_ID_BRANCH_FOLD=1`
- `YH_COREMARK_FPGA_DMEM_NEGEDGE_READ=1`
- `YH_COREMARK_FPGA_REDIRECT_CACHE_XOR_INDEX=1`
- CoreMark core source files: unchanged

## Result Table

| Version | CoreMark/MHz | DMIPS/MHz | CoreMark Ticks | Completion Cycles | LUT | FF | BRAM | DSP | CRC | Strict EEMBC 10s |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| RC4096 + negedge DMem baseline | 5.718962 | 1.371423 | 1,748,569 | 1,781,838 | pending | pending | pending | pending | 0xfcaf | no |
| RC8192 + negedge DMem | 5.729438 | pending | 1,745,372 | 1,778,653 | pending | pending | pending | pending | 0xfcaf | no |
| RC8192 + fetch redirect reuse | 5.729438 | pending | 1,745,372 | 1,778,653 | pending | pending | pending | pending | 0xfcaf | no |
| RC8192 + BHT512 | 5.729438 | pending | 1,745,372 | 1,778,653 | pending | pending | pending | pending | 0xfcaf | no |

## Interpretation

RC8192 slightly improves the current best CoreMark result by reducing redirect
cache conflict misses.  Fetch redirect reuse and dynamic BHT do not add benefit
on this workload after RC8192, so the retained candidate is the simpler
`RC8192 + XOR index + DMem negedge + ID branch fold` configuration.

The score is still a short reproducible engineering run, not a strict EEMBC
10-second run.  A fresh PYNQ-Z2 synthesis/implementation pass is still required
before reporting LUT, FF, BRAM, DSP, timing, and power for this candidate.

## Technical Note For Later Documentation

This is a control-flow locality optimization.  It does not alter CoreMark
algorithm files.  The useful highlight is that the frontend exploits repeated
branch and jump targets in CoreMark's list/state loops, using a tagged target
instruction cache to reduce synchronous instruction-memory bubbles while keeping
the CPU in an in-order, low-power-friendly pipeline.
