# Reproduce 6872 LUT Baseline

Run from:

`D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark7-dmips5-20260508`

## CoreMark

```powershell
$env:COREMARK_ZICOND_OVERRIDE='0'
$env:COREMARK_IMEM_OUTPUT_REG_OVERRIDE='0'
$env:COREMARK_ID_BRANCH_FOLD_OVERRIDE='1'
$env:COREMARK_ID_BRANCH_EX_FORWARD_OVERRIDE='0'
$env:COREMARK_IMAGE_OVERRIDE='YH_rv_cpu_coremark_rv32'
cmd /c _tmp\run_coremark_dcache_rc64_rctagtrim.cmd 512 1 0 1 rc64_nonext_nozicond_noexfwd 64
```

Expected summary:

`5.023480 CoreMark/MHz`

## Dhrystone

```powershell
$env:DHRY_ZICOND_OVERRIDE='0'
$env:DHRY_ID_BRANCH_EX_FORWARD_OVERRIDE='0'
cmd /c _tmp\run_dhrystone_dcache_rc64_rctagtrim.cmd 512 1 0 1 rc64_nonext_nozicond_noexfwd 64 0
```

Expected summary:

`1.275942 DMIPS/MHz`

## Quick Synthesis Utilization

```powershell
$env:SYNTH_ZICOND_OVERRIDE='0'
$env:SYNTH_ID_BRANCH_EX_FORWARD_OVERRIDE='0'
$env:SYNTH_RETIMING_OVERRIDE='0'
$env:SYNTH_NO_TIMING_DRIVEN_OVERRIDE='1'
cmd /c _tmp\synth_dcache_rc_rctagtrim.cmd 512 64 1 0 1 0
```

Expected utilization:

`6872 LUT / 3153 FF / 20 BRAM / 8 DSP`

## Full Implementation To Add

Full implementation evidence is not yet available for this exact baseline.
When it is run, copy the resulting reports into `reports/` and update
`TEST_STATUS.md`.

