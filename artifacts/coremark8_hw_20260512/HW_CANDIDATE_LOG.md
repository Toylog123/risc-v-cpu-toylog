# Hardware Candidate Log

Date: 2026-05-14

All candidates in this log follow `HARDWARE_ONLY_BENCHMARK.md`.

| ID | RTL change | Directed evidence | CoreMark fixed image | Dhrystone fixed image | Decision |
|---|---|---|---|---|---|
| H01 | Remove ineffective PC sequence experiment from `YH_rv_cpu.v` | Fixed CoreMark image still reproduces baseline | `9.056273 CoreMark/MHz`, `1139273 cycles` in `fixedhex_clean_cm10.summary.txt` | Not applicable | Keep cleanup |
| H02 | Add ID-branch forwarding for SLL/SRL/SRA results from ID/EX | `run_id_branch_shift_forward_diag.bat` red before fix, pass after fix | `9.056273 CoreMark/MHz`, `1139272 cycles` in `fixedhex_shift_forward_cm10.summary.txt` | `1.366181 DMIPS/MHz`, `47399 cycles` in `dhrystone_fixedhex_shift_forward_zbc_xthead_idbr.summary.txt` | Keep as hardware coverage improvement, not score driver |
| H03 | Add ID-branch forwarding for effective XThead `th.mveqz/th.mvnez` results from ID/EX | Extended shift/XThead diagnostic red before fix, pass after fix | `9.056273 CoreMark/MHz`, `1139272 cycles` in `fixedhex_shift_xthead_forward_cm10.summary.txt` | `1.366181 DMIPS/MHz`, `47399 cycles` in `dhrystone_fixedhex_shift_xthead_forward_zbc_xthead_idbr.summary.txt` | Keep as hardware coverage improvement, not score driver |
| H04 | Formalize CRC16/CRC32 `CUSTOM-0` hardware ISA accelerator evidence | `run_custom_crc_diag.bat` pass, `crc16=00003ea2`, `crc32=00007d6e` | ISA-accelerated rebuild result `6.209618 CoreMark/MHz`, `1644639 cycles` in `custom_crc_after_hwcleanup_cm10.summary.txt` | Not applicable | Keep as formal hardware ISA acceleration evidence |

## Next Candidates

| ID | Hypothesis | Evidence Needed |
|---|---|---|
| H05 | Extend ID-branch forwarding to low-cost `bext/czero` paths where enabled | Directed red/green tests, CoreMark/DMIPS A/B |
| H06 | Evaluate a very small loop/backward branch predictor for Dhrystone control flow | Branch profile before/after, DMIPS fixed image A/B |
| H07 | Run FPGA resource/timing check on H02-H04 hardware set | LUT/FF/BRAM/DSP/WNS summary |
