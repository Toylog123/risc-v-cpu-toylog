# YH_rv_cpu Handoff

> Updated: `2026-04-30`

## Snapshot

- Active worktree: `.worktrees/coremark-over-1p5`
- Active project: `.worktrees/coremark-over-1p5/YH_rv_cpu`
- Board: `Xilinx PYNQ-Z2 (xc7z020clg400-1)`
- Team number in submission materials: `CICC1003618`
- Formal freeze label: `pynq-z2-cpu50-coremark-5.162186-idbr-cmpcheap-jalpredict`

## Formal Result

- CoreMark/MHz: `5.162186`
- CoreMark ticks: `1937164`
- Completion cycles: `1971888`
- Dhrystone conservative binary: `1.009846 DMIPS/MHz`, `177430 Dhrystones/s`
- CPU configuration: `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect`, `M=0`
- FPGA utilization: `4634 LUT / 2317 FF / 4 BRAM / 15 DSP`
- Timing: `WNS=+0.608 ns`, `WHS=+0.121 ns`
- Hardware: connected PYNQ-Z2 programmed successfully, `PROGRAM_OK: xc7z020_1`

## Submission Material Roots

Use the main workspace submission directory, not `.worktrees`, for review/upload:

```text
../../01-项目管理/03-提交材料/
```

Expected folders:

- `技术说明书/`
- `性能与验证报告/`
- `PPT/`
- `源代码/`
- `FPGA原型系统/`
- `功能演示视频/`
- `官方模板/`

Current key files:

- `技术说明书/YH_rv_cpu初赛技术说明书-2026-04-30.pdf`
- `性能与验证报告/YH_rv_cpu初赛性能与验证报告-2026-04-30.pdf`
- `PPT/CICC1003618+初赛+作品PPT.pptx`
- `PPT/CICC1003618+初赛+作品PPT.pdf`
- `源代码/YH_rv_cpu初赛源码包-2026-04-30.zip`
- `FPGA原型系统/fpga_artifacts_pynq_z2/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_zmmul_zbc_xthead_idbr_cmpcheap_jalpredict.bit`
- `功能演示视频/CICC1003618+初赛+演示视频.mp4`
- `初赛提交材料清单与要求对照-2026-04-30.md`
- `初赛提交材料冻结检查-2026-04-30.md`

## Rebuild Rules

1. After editing LaTeX source, compile with XeLaTeX and copy `main.pdf` over the top-level submission PDF.
2. After editing worktree docs, rebuild the source ZIP so the submitted code package contains the latest status.
3. After replacing any performance number, rerun the final audit and update both checklist markdown files.
4. Do not promote an optimization unless it passes functional regression, CoreMark, PYNQ-Z2 implementation, timing/resource gates, and hardware or artifact refresh checks.

## Core Commands

```bat
scripts\run_xthead_memidx_test.bat
scripts\run_zmmul_test.bat
scripts\run_bitmanip_test.bat
scripts\run_bitmanip_fast_subset_test.bat
scripts\run_soc_smoke.bat

scripts\run_coremark_score.bat rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv 10 2000 100000000UL 30000000 build\sw\YH_rv_cpu_coremark_idbr_cmp_jal_predict_score_20260430_rerun.summary.txt
scripts\run_dhrystone_score.bat 100000000UL 250000000 build\sw\YH_rv_cpu_dhrystone_idbr_cmp_jal_predict.summary.txt 10 rv32i_zmmul_zba_zbb_zbs
```

For PYNQ-Z2 implementation, keep the CPU clock at `50.0 MHz`, enable `Zmmul/Zba/Zbb/Zbs/Zbc/XThead/IDBR cmp-cheapALU/JAL early redirect`, and keep full M division disabled.

## Next Work

1. Rebuild the source ZIP from this updated worktree.
2. Rerun final Attachment 1/2 audit and record frozen evidence.
3. Continue CoreMark optimization toward `6+` while respecting the hard `5000 LUT` ceiling.
4. If a new candidate beats `5.162186`, repeat the full evidence chain before refreshing submission materials.
