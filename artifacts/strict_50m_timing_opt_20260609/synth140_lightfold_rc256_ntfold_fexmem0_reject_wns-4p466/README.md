# synth140 Light-Fold RC256 NT-Fold FEXMEM0 Rejection

Status: rejected. This experiment tested whether disabling fold EX/MEM load-use
forwarding would rescue the not-taken-fold timing path while preserving the
RC256 not-taken-fold CoreMark gain.

## Result

| Item | Value |
| --- | --- |
| Fast gate CoreMark/MHz | 4.315138 |
| Completion cycles | 2358385 |
| CRC final | 0xfcaf |
| Acceptance | yes |
| Synth Slice LUTs | 9035 |
| Synth LUT as Logic | 8115 |
| Synth Registers | 6310 |
| BRAM / DSP | 32 / 8 |
| Synth WNS/WHS | -4.466 ns / +0.132 ns |
| Decision | Rejected; no implementation run |

## Configuration Delta

Relative to the current light-fold/tag-trim family:

- `REDIRECT_CACHE_ENTRIES=256`
- `ENABLE_ID_BRANCH_NOT_TAKEN_FOLD=1`
- `ENABLE_FOLD_EXMEM_LOAD_USE_SPEC=0`
- `ENABLE_ID_BRANCH_FOLD_LIGHT_DECODE=1`

The score stays above the current `impl136` result, and synthesis area is below
10000 LUT. However, CPU50 synthesis timing is still far negative. Disabling
fold EX/MEM load-use forwarding does not cut the not-taken-fold critical path
enough for 50 MHz.

## Evidence Files

- `fast140/coremark50_fast_gate_iter10.summary.txt`
- `fast140/coremark50_fast_gate_iter10.log`
- `logs/vivado_pynq_z2_synth.log`
- `reports/cpu50/synth_timing_summary.rpt`
- `reports/cpu50/synth_utilization.rpt`
- `reports/cpu50/synth_utilization_hierarchical.rpt`
- `dcp/cpu50_synth.dcp`

## Validity Notes

- CoreMark algorithm source files were not modified.
- CoreMark evidence is a short reproducible full-workload fast gate, not a
  strict EEMBC 10-second run.
- This result must not be promoted as a candidate because synthesis timing
  failed at `WNS -4.466 ns`.
