# Hardware Candidate Log

Date: 2026-05-14

All candidates in this log follow `HARDWARE_ONLY_BENCHMARK.md`.

| ID | RTL change | Directed evidence | CoreMark fixed image | Dhrystone fixed image | Decision |
|---|---|---|---|---|---|
| H01 | Remove ineffective PC sequence experiment from `YH_rv_cpu.v` | Fixed CoreMark image still reproduces baseline | `9.056273 CoreMark/MHz`, `1139273 cycles` in `fixedhex_clean_cm10.summary.txt` | Not applicable | Keep cleanup |
| H02 | Add ID-branch forwarding for SLL/SRL/SRA results from ID/EX | `run_id_branch_shift_forward_diag.bat` red before fix, pass after fix | `9.056273 CoreMark/MHz`, `1139272 cycles` in `fixedhex_shift_forward_cm10.summary.txt` | `1.366181 DMIPS/MHz`, `47399 cycles` in `dhrystone_fixedhex_shift_forward_zbc_xthead_idbr.summary.txt` | Keep as hardware coverage improvement, not score driver |
| H03 | Add ID-branch forwarding for effective XThead `th.mveqz/th.mvnez` results from ID/EX | Extended shift/XThead diagnostic red before fix, pass after fix | `9.056273 CoreMark/MHz`, `1139272 cycles` in `fixedhex_shift_xthead_forward_cm10.summary.txt` | `1.366181 DMIPS/MHz`, `47399 cycles` in `dhrystone_fixedhex_shift_xthead_forward_zbc_xthead_idbr.summary.txt` | Keep as hardware coverage improvement, not score driver |
| H04 | Formalize CRC16/CRC32 `CUSTOM-0` hardware ISA accelerator evidence | `run_custom_crc_diag.bat` pass, `crc16=00003ea2`, `crc32=00007d6e` | ISA-accelerated rebuild result `6.209618 CoreMark/MHz`, `1644639 cycles` in `custom_crc_after_hwcleanup_cm10.summary.txt` | Not applicable | Keep as formal hardware ISA acceleration evidence |
| H05 | Add ID-branch forwarding for low-cost `bext/bexti` results from ID/EX | Extended shift/XThead/BEXT diagnostic red before fix, pass after fix | `9.056273 CoreMark/MHz`, `1139272 cycles` in `fixedhex_bext_forward_cm10.summary.txt` | Not rerun yet | Keep as hardware coverage improvement, not score driver |
| H06 | Add ID-branch forwarding for low-cost `czero.eqz/czero.nez` results from ID/EX | Extended shift/XThead/BEXT/Zicond diagnostic red before fix, pass after fix; `run_id_branch_fast_diag.bat`, `run_id_jal_fast_diag.bat`, `run_load_use_fast_diag.bat` pass | `9.056273 CoreMark/MHz`, `1139272 cycles` in `fixedhex_czero_forward_cm10.summary.txt` | `10.163426 DMIPS/MHz`, `43475 completion cycles` in `dhrystone_fixedhex_czero_forward_zbc_zicond_xthead_idbr.summary.txt`; short benchmark log, keep as candidate evidence until a longer benchmark image is generated | Keep as hardware coverage improvement; score unchanged on fixed CoreMark image |

## Next Candidates

| ID | Hypothesis | Evidence Needed |
|---|---|---|
| H07 | Evaluate a very small loop/backward branch predictor for Dhrystone control flow | Branch profile before/after, DMIPS fixed image A/B |
| H08 | Run FPGA resource/timing check on H02-H05 hardware set | LUT/FF/BRAM/DSP/WNS summary |
