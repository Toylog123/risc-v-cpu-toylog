# CPU25 Continuous Optimization Ledger

This ledger starts from the frozen CPU25 baseline and records only reproducible rows with report paths. Future experiments should append rows in the same format.

## Current Rows

| name | lut | ff | bram_tile | dsp | coremark_per_mhz | dmips_per_mhz | wns_ns | whs_ns | timing_met | tech |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| region_6872_impl_audit | 7063 | 3165 | 20 | 8 | 5.023480 | 1.275942 | -10.360 | 0.028 | no | 6872 low-resource reference; implementation timing failed |
| cpu25_baseline | 6791 | 3151 | 20 | 8 | 4.501191 | 1.205669 | 0.291 | 0.065 | yes | Timing-closed CPU25 baseline, CoreMark/Dhrystone ROM |
| cpu25_perf_demo | 6791 | 3151 | 20 | 8 | 4.501191 | 1.205669 | 0.291 | 0.065 | yes | CPU25 timing-closed performance demo bitstream |
| cpu25_rc128_validated | 7076 | 3216 | 20 | 8 | 4.627215 | 1.205669 | 0.514 | 0.056 | yes | RC64 to RC128 under CPU25 timing cuts; Dhrystone rebuilt with no-auto-inc target to match base-update-disabled hardware |
| cpu25_rc128_repro_20260605 | 7124 | 3211 | 20 | 8 | 4.627215 | 1.205669 | 1.881 | 0.100 | yes | Reproduced CPU25 RC128 CoreMark implementation wrapper; DCache512 RC128 timing cuts |
| cpu25_rc128_ntfold0_rejected | N/A | N/A | N/A | N/A | 4.468699 | not run | N/A | N/A | not run | Rejected before implementation: disabling not-taken load fold cuts timing path but drops below the 4.5 CoreMark/MHz gate |
| cpu25_rc128_bfnext_20260606 | 7505 | 3213 | 20 | 8 | 4.741458 | 1.205669 | 1.138 | 0.100 | yes | CPU25 RC128 with branch-fold next-cache restored; DCache512 timing cuts |
| cpu25_rc128_bfnext_nozbkb_20260606 | 7374 | 3214 | 20 | 8 | 4.741458 | 1.205669 | 0.282 | 0.062 | yes | CPU25 RC128 BFNext with ZBKB hardware disabled; DCache512 timing cuts |
| cpu25_rc128_bfnext_nozbkb_timingdriven_20260606 | 7473 | 3219 | 20 | 8 | 4.741458 | 1.205669 | 1.348 | 0.041 | yes | CPU25 RC128 BFNext no-ZBKB with timing-driven synthesis; DCache512 timing cuts |

## Evidence Paths

| name | utilization report | timing report | extra evidence |
|---|---|---|---|
| region_6872_impl_audit | `../region_baseline_6872_20260602/reports/impl_utilization_6872baseline_7063lut_wns-10p360.rpt` | `../region_baseline_6872_20260602/reports/impl_timing_6872baseline_7063lut_wns-10p360.rpt` | `../region_baseline_6872_20260602/TEST_STATUS.md` |
| cpu25_baseline | `reports/impl_utilization_cpu25_6791lut.rpt` | `reports/impl_timing_summary_cpu25_wns+0p291.rpt` | `evidence/coremark_summary_4p501191.txt`, `evidence/dhrystone_summary_1p205669.txt` |
| cpu25_perf_demo | `reports/impl_utilization_cpu25_perf_demo_6791lut.rpt` | `reports/impl_timing_summary_cpu25_perf_demo_wns+0p291.rpt` | `evidence/perf_demo_summary_20260605.txt` |
| cpu25_rc128_validated | `reports/impl_utilization_cpu25_rc128_coremark_7076lut.rpt` | `reports/impl_timing_summary_cpu25_rc128_coremark_wns+0p514.rpt` | `experiments/CPU25_RC128_EXPERIMENT_20260605.md`, `experiments/dhrystone_cpu25_rc128_noautoinc_runs1000_20260605.summary.txt` |
| cpu25_rc128_repro_20260605 | `reports/impl_utilization_cpu25_rc128_repro_7124lut_20260605.rpt` | `reports/impl_timing_summary_cpu25_rc128_repro_wns+1p881_20260605.rpt` | `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_coremark_repro_20260605.bit`, `experiments/repro_cpu25_rc128/*.summary.txt` |
| cpu25_rc128_ntfold0_rejected | not run | not run | `experiments/repro_cpu25_rc128_ntfold0/coremark_cpu25_rc128_ntfold0_iter10.summary.txt` |
| cpu25_rc128_bfnext_20260606 | `reports/impl_utilization_cpu25_rc128_bfnext_7505lut_20260606.rpt` | `reports/impl_timing_summary_cpu25_rc128_bfnext_wns+1p138_20260606.rpt` | `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_20260606.bit`, `experiments/repro_cpu25_rc128_bfnext1/*.summary.txt` |
| cpu25_rc128_bfnext_nozbkb_20260606 | `reports/impl_utilization_cpu25_rc128_bfnext_nozbkb_7374lut_20260606.rpt` | `reports/impl_timing_summary_cpu25_rc128_bfnext_nozbkb_wns+0p282_20260606.rpt` | `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_nozbkb_20260606.bit`, `experiments/repro_cpu25_rc128_bfnext_nozbkb/*.summary.txt` |
| cpu25_rc128_bfnext_nozbkb_timingdriven_20260606 | `reports/impl_utilization_cpu25_rc128_bfnext_nozbkb_timingdriven_7473lut_20260606.rpt` | `reports/impl_timing_summary_cpu25_rc128_bfnext_nozbkb_timingdriven_wns+1p348_20260606.rpt` | `YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_nozbkb_timingdriven_20260606.bit`, `YH_rv_cpu/scripts/build_pynq_z2_cpu25_rc128_bfnext_nozbkb_timingdriven_coremark.bat` |

## Parser Command

Use this command pattern for new rows:

```powershell
python YH_rv_cpu\scripts\parse_vivado_reports.py `
  --name <experiment_name> `
  --util <impl_utilization.rpt> `
  --timing <impl_timing_summary.rpt> `
  --coremark <CoreMark/MHz> `
  --dmips <DMIPS/MHz> `
  --tech "<short technical point>"
```

## Next Optimization Candidates

| ID | Candidate | Expected Benefit | Risk | Gate |
|---|---|---|---|---|
| O01 | Add CPU30/CPU33 MMCM options and test current RTL | Determine real clock headroom | Current 25 MHz WNS is only +0.291 ns, so likely fails without structural changes | Record full implementation WNS/WHS before promotion |
| O02 | Pipeline or register redirect-cache PC skip decision | Reduce DCache/front-end/PC path pressure | May cost one front-end cycle on some redirects | CoreMark/MHz must remain >4.5 and timing must close |
| O03 | Revisit regular redirect-cache lookup timing | Keep most redirect-cache benefit with shorter PC path | Could reduce CoreMark if lookup becomes late | Compare against cpu25_baseline and 6872 reference |
| O04 | Try RC128 at CPU25 only | CoreMark improves to 4.627215 and timing closes | Board evidence still needs PROGRAM_OK/UART/video if selected | Reproduced through `build_pynq_z2_cpu25_rc128_coremark.bat`; implementation is `7124 LUT / WNS +1.881 / WHS +0.100` |
| O06 | Restore branch-fold next-cache on CPU25 RC128 | CoreMark improves to 4.741458 while timing still closes | LUT rises versus RC128 but remains below 8000; board evidence pending | Superseded by no-ZBKB trim: `7374 LUT / WNS +0.282 / WHS +0.062` |
| O07 | Disable unused ZBKB hardware in BFNext | Saves 131 LUT versus BFNext with the same CoreMark/Dhrystone xsim results | Timing margin drops from +1.138 ns to +0.282 ns but still closes | Low-LUT candidate: `7374 LUT / 4.741458 CoreMark/MHz / WNS +0.282 / WHS +0.062` |
| O08 | Re-enable timing-driven synthesis for BFNext/no-ZBKB | Improves setup margin by +1.066 ns versus O07 while keeping LUT below 8000 | Costs +99 LUT versus O07 and WHS margin is +0.041 ns | Current timing-robust candidate: `7473 LUT / 4.741458 CoreMark/MHz / WNS +1.348 / WHS +0.041` |
| O05 | Power/resource trim around CPU25 | Improve low-power narrative | May lose already small CoreMark margin | Keep CoreMark/MHz >4.5 |
