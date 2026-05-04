# Regression Test Log

> Updated: `2026-04-30`

## Formal Candidate

Configuration: `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect`, full M division disabled, PYNQ-Z2 CPU clock `50.0 MHz`.

## Functional Regression

| Check | Command / evidence | Result |
|---|---|---|
| XThead memidx directed | `scripts/run_xthead_memidx_test.bat` | PASS, `cycles=12` |
| Zmmul directed | `scripts/run_zmmul_test.bat` | PASS, multiply path valid; `divu` traps as unsupported |
| Bitmanip directed | `scripts/run_bitmanip_test.bat` | PASS, `23/23` |
| Fast bitmanip subset directed | `scripts/run_bitmanip_fast_subset_test.bat` | PASS, fast ops accepted and `clmul` rejected when `Zbc=0` |
| SoC smoke | `scripts/run_soc_smoke.bat` | PASS, `PC=0000003c`, `cycles=150` |

## Performance Regression

| Check | Command / evidence | Result |
|---|---|---|
| CoreMark score | `scripts/run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 build\sw\YH_rv_cpu_coremark_idbr_cmp_jal_predict_score_20260430_rerun.summary.txt` | PASS, `5.162186 CoreMark/MHz`, CRC OK |
| Dhrystone conservative score | `scripts/run_dhrystone_score.bat 100000000UL 250000000 build\sw\YH_rv_cpu_dhrystone_idbr_cmp_jal_predict.summary.txt 10 rv32i_zmmul_zba_zbb_zbs` | PASS, `1.009846 DMIPS/MHz`, `177430 Dhrystones/s` |

CoreMark counters:

| Counter | Value |
|---|---:|
| ticks | `1937164` |
| iterations/s | `516.218555` |
| completion cycles | `1971888` |
| EX branch redirect cycles | `1900` |
| EX BEQ redirect cycles | `1864` |
| EX JAL redirect cycles | `0` |
| EX JALR redirect cycles | `26` |
| ID branch decode redirect cycles | `141100` |

## FPGA Closure

| Item | Result |
|---|---:|
| Target board | `PYNQ-Z2 / xc7z020clg400-1` |
| CPU clock | `50.0 MHz` |
| Slice LUTs | `4634 / 53200 = 8.71%` |
| Slice Registers | `2317 / 106400 = 2.18%` |
| Block RAM Tile | `4 / 140 = 2.86%` |
| DSPs | `15 / 220 = 6.82%` |
| Setup slack | `WNS=+0.608 ns` |
| Hold slack | `WHS=+0.121 ns` |
| Bitstream | `project/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit` |
| Hardware program | `PROGRAM_OK: xc7z020_1` |

## Promotion Decision

The `5.162186` candidate replaces the prior `5.155952` cmp-cheapALU path because it improves CoreMark, reduces LUT usage from `4665` to `4634`, and keeps positive setup/hold slack at `50.0 MHz`.

Source ZIP and final submission audit must be refreshed after this log update before the material snapshot is treated as frozen.
