# Timing-Closed CPU25 Candidate 2026-06-05

## Decision

Selected a timing-closed PYNQ-Z2 candidate by keeping the current low-LUT RTL/front-end timing guards and lowering the FPGA CPU MMCM output to 25 MHz.

This version satisfies the current acceptance target:

| LUT | CoreMark/MHz | DMIPS/MHz | Technical optimization point |
|---:|---:|---:|---|
| 6791 post-route | 4.501191 | 1.205669 | DCache512 + RC64, frontend DCache load-use speculation cut, JALR/fold load-use cuts, EX operand frontend guard, 25 MHz PYNQ-Z2 MMCM timing closure |

## PYNQ-Z2 Implementation Result

- Flow: full implementation with bitstream generation.
- CPU clock: 25 MHz MMCM (`USE_CLK_MMCM_25M=1`, `CLK_FREQ_HZ=25000000`).
- Post-route timing: WNS `+0.291 ns`, WHS `+0.065 ns`.
- Timing status: `All user specified timing constraints are met.`
- Post-route utilization: `6791 LUT / 3151 FF / 20 BRAM / 8 DSP`.
- Bitstream: `project/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit`.
- Reports:
  - `project/reports/pynq_z2_sysclk_8p000ns_cpu25/impl_timing_summary.rpt`
  - `project/reports/pynq_z2_sysclk_8p000ns_cpu25/impl_utilization.rpt`
  - `project/reports/pynq_z2_sysclk_8p000ns_cpu25/synth_timing_summary.rpt`
  - `project/reports/pynq_z2_sysclk_8p000ns_cpu25/synth_utilization.rpt`

## Benchmark Evidence

- CoreMark summary:
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_exopfrontguard_foldldcut_jalrldcut_recheck_iter10_20260528.summary.txt`
  - `CoreMark/MHz = 4.501191`
- Dhrystone summary:
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_cpu25_timingclosed_frontguard_runs1000_20260528.summary.txt`
  - `DMIPS/MHz = 1.205669`

## Reproduction Commands

CoreMark functional score:

```powershell
$env:C_INCLUDE_PATH=''
$env:COREMARK_ZICOND_OVERRIDE='0'
$env:COREMARK_IMEM_OUTPUT_REG_OVERRIDE='0'
$env:COREMARK_ID_BRANCH_FOLD_OVERRIDE='1'
$env:COREMARK_ID_BRANCH_EX_FORWARD_OVERRIDE='0'
$env:COREMARK_IMAGE_OVERRIDE='YH_rv_cpu_coremark_rv32'
$env:COREMARK_FRONTEND_LOAD_SPEC_OVERRIDE='0'
$env:COREMARK_JALR_LOAD_SPEC_OVERRIDE='0'
$env:COREMARK_FOLD_LOAD_SPEC_OVERRIDE='0'
cmd /c _tmp\run_coremark_dcache_rc64_rctagtrim.cmd 512 1 0 1 exopfrontguard_foldldcut_jalrldcut 64
```

Dhrystone functional score:

```powershell
$env:C_INCLUDE_PATH=''
$env:DHRY_ZICOND_OVERRIDE='0'
$env:DHRY_ID_BRANCH_EX_FORWARD_OVERRIDE='0'
$env:DHRY_FRONTEND_LOAD_SPEC_OVERRIDE='0'
$env:DHRY_JALR_LOAD_SPEC_OVERRIDE='0'
$env:DHRY_FOLD_LOAD_SPEC_OVERRIDE='0'
cmd /c _tmp\run_dhrystone_dcache_rc64_rctagtrim.cmd 512 1 0 1 cpu25_timingclosed_frontguard 64 0
```

25 MHz implementation:

```powershell
$env:SYNTH_BUILD_MODE_OVERRIDE='impl'
$env:SYNTH_ZICOND_OVERRIDE='0'
$env:SYNTH_ID_BRANCH_EX_FORWARD_OVERRIDE='0'
$env:SYNTH_RETIMING_OVERRIDE='0'
$env:SYNTH_NO_TIMING_DRIVEN_OVERRIDE='1'
$env:SYNTH_QUICK_UTIL_ONLY_OVERRIDE='0'
$env:SYNTH_FRONTEND_LOAD_SPEC_OVERRIDE='0'
$env:PYNQ_ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC_OVERRIDE='0'
$env:PYNQ_ENABLE_FOLD_DCACHE_LOAD_USE_SPEC_OVERRIDE='0'
$env:SYNTH_CPU_CLK_FREQ_HZ_OVERRIDE='25000000'
$env:SYNTH_USE_CLK_MMCM_25M_OVERRIDE='1'
$env:SYNTH_USE_CLK_MMCM_62M5_OVERRIDE='0'
$env:SYNTH_USE_CLK_MMCM_50M_OVERRIDE='0'
cmd /c _tmp\synth_dcache_rc_rctagtrim.cmd 512 64 1 0 1 0
```

## Notes

- This is a board-facing timing-closed candidate, not the original 50 MHz baseline.
- The 50 MHz line remains timing-failing because the worst same-cycle DCache/front-end/PC path is about 33 ns after synthesis.
- The next evidence step is PYNQ-Z2 programming plus UART capture from this exact bitstream.
