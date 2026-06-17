# Reproduce Demoted 6872 LUT Reference

Cleanup note: this reproduces a historical quick-synth engineering reference,
not the current accepted baseline. The 2026-06-02 full implementation audit for
this configuration failed timing at `7063 post-route LUT / WNS -10.360 ns`.
After the 2026-06-09 cleanup, use CPU25 as the accepted timing-closed baseline.

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

## Full Implementation Audit

Full implementation evidence is already available and timing failed:

`7063 post-route LUT / WNS -10.360 ns / WHS +0.028 ns`

Reports:

- `../reports/impl_utilization_6872baseline_7063lut_wns-10p360.rpt`
- `../reports/impl_timing_6872baseline_7063lut_wns-10p360.rpt`
