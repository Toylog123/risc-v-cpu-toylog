# impl220 synth200 ExploreArea AdvancedSkewModeling sweep

Date: 2026-07-01

Purpose: reuse the `synth200_impl136_bhtidupd0_cpu50` DCP and test whether
`opt_design -directive ExploreArea` plus `route_design -directive
AdvancedSkewModeling` can improve setup margin versus `impl218`/`impl219`
without leaving the preferred `LUT < 10000` gate.

## Fast Gate

Fast gate is inherited from the `synth200` source family:

- CoreMark/MHz: 4.287521
- CRC: 0xfcaf
- Completion cycles: 2373904
- Acceptance: pass

## Implementation

Implementation source:

`../synth200_impl136_bhtidupd0_cpu50/dcp/cpu50_synth.dcp`

Implementation directives:

- opt_design: ExploreArea
- place_design: Explore
- phys_opt_design pre-route: Explore
- route_design: AdvancedSkewModeling
- phys_opt_design post-route: AggressiveExplore
- bitstream generation: disabled

Final routed signoff:

- Slice LUTs: 9965
- Slice registers: 6520
- BRAM tiles: 32
- DSPs: 8
- 50 MHz WNS: +0.056 ns
- 50 MHz WHS: +0.121 ns
- TNS/THS failing endpoints: 0
- Route errors: 0

Worst setup path:

- Source: `u_soc/u_cpu/gen_dcache.u_dcache/cache_tag_reg[95][0]/C`
- Destination: `u_soc/u_cpu/id_ex_alu_op_r_reg[3]_bret__0/D`
- Data path delay: 19.805 ns
- Logic levels: 22
- Route share: 15.803 ns / 79.793%

Worst hold path:

- Source: `u_soc/u_cpu/ex_mem_mem_addr_r_reg[26]/C`
- Destination: `u_soc/u_cpu/gen_dcache.u_dcache/miss_addr_r_reg[26]/D`
- Data path delay: 0.453 ns
- Logic levels: 0

## Decision

Valid strict routed pass and current best high-score preferred-gate candidate.
It preserves the `4.287521 CoreMark/MHz` score line, stays below `LUT < 10000`,
and improves setup slack versus `impl219` from `+0.008 ns` to `+0.056 ns`.

This is still a thin-margin route-dominated result. The dominant path has moved
from an EX/MEM address source in `impl219` to a DCache tag source in `impl220`,
but it still terminates at IF/ID or ID/EX front-end/decode controls. Continued
optimization should target the DCache/redirect-cache/front-end fan-in rather
than benchmark software changes.

Files:

- `reports_cpu50/`: implementation timing, utilization, methodology, and route
  status reports.
- `dcp/cpu50_impl.dcp`: routed checkpoint.
- `logs/`: Vivado implementation log, stdout log, journal, and run script.
