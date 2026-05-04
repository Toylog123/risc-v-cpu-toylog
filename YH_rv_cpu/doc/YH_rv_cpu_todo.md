# YH_rv_cpu Long-Running TODO

> Updated: `2026-04-30`

## P0 - Freeze Current Preliminary Submission

- [x] Promote the timing-safe formal path: `RV32I + Zmmul + Zba/Zbb/Zbs + Zbc + XThead memidx/condmov + IDBR cmp-cheapALU + JAL early redirect`.
- [x] Measure and recheck CoreMark: `5.162186 CoreMark/MHz`, `1937164` ticks, `1971888` completion cycles.
- [x] Measure conservative Dhrystone on the same RTL superset: `1.009846 DMIPS/MHz`, `177430 Dhrystones/s`, no hard `div/rem`.
- [x] Close PYNQ-Z2 implementation at `50.0 MHz`: `4634 LUT`, `2317 FF`, `4 BRAM`, `15 DSP`, `WNS=+0.608 ns`, `WHS=+0.121 ns`.
- [x] Program the connected PYNQ-Z2 through Vivado Hardware Manager: `PROGRAM_OK: xc7z020_1`.
- [x] Refresh LaTeX technical specification and performance/verification report for the `5.162186 / 4634 LUT` formal path.
- [x] Refresh PPT/PDF, FPGA connection diagram, bitstream copy, logs, and demonstration video candidate.
- [ ] Rebuild the source ZIP after this documentation sync.
- [ ] Rerun the final Attachment 1/2 submission audit and freeze the `2026-04-30` snapshot.

## P0 - Initial-Round Requirement Checklist

- [x] Attachment 1 content requirement has separate organized file under `../../01-项目管理/01-赛题要求/初赛要求/`.
- [x] Attachment 2 submission/format requirement has separate organized file under `../../01-项目管理/01-赛题要求/初赛要求/`.
- [x] Technical specification contains cover, quick preview, CPU architecture design, Verilog modeling guideline, verification plan/test report, FPGA adaptation guide, and AI tool statement.
- [x] Performance/verification report contains simulation and FPGA data, instruction coverage, branch prediction accuracy, DMIPS/MHz, resource utilization, and before/after performance comparison.
- [x] Source ZIP contains RTL, TestBench, scripts, RISC-V programs, FPGA files, minimal docs, and evidence summaries.
- [x] FPGA artifact folder contains bitstream, PYNQ-Z2 connection diagram, XDC, implementation/synthesis reports, logs, and hardware program log.
- [x] PPT has PPTX and exported PDF.
- [x] MP4 candidate is 1080p and about 5 minutes.
- [ ] Final upload still needs human platform action and optional manual video narration review.

## P1 - CoreMark Toward 6+

- [ ] Profile remaining CoreMark stalls after JAL early redirect. Current counters show EX redirect is already small (`BEQ=1864`, `JALR=26`, `JAL=0`), so the next gain likely needs load/use, memory, fetch, or software layout work.
- [ ] Add a low-cost measurement-only counter set for load-use bubbles, memory wait contribution, branch class mix, and hot basic-block entry counts.
- [ ] Explore compiler/code-layout variants using the current formal RTL only; promote only if CoreMark ticks improve and CRC stays valid.
- [ ] Explore selective IF/ID fetch buffering or tiny predecode changes that do not threaten the `5000 LUT` gate.
- [ ] Explore cheaper branch equality/compare logic reuse only if synthesis shows net LUT and timing remain within budget.
- [ ] Revisit XThead/autoincrement and compressed memory-index patterns only with targeted disassembly evidence from CoreMark hot loops.
- [ ] For every candidate above `5.162186`, run functional regression, CoreMark score, Vivado implementation, resource/timing audit, and material refresh before promotion.

## P2 - Cleanup And Maintainability

- [ ] Keep `.worktrees/doc` as minimal engineering status only; do not duplicate submission PDFs or project-management folders there.
- [ ] Keep temporary render/audit folders under `tmp/` disposable; remove them only after their evidence has been copied into checklist or reports.
- [ ] If final upload naming uses a different team-number prefix, rename only the top-level submission artifacts and update the checklist.
