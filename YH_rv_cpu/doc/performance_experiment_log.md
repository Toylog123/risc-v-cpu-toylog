# Performance Experiment Log

## Frozen Baseline (2026-04-07)

Use this baseline before starting any competition-facing optimization work.

### CoreMark

| Item | Value |
|------|------|
| Command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Raw log | `build/sw/YH_rv_cpu_coremark_rv32_score.log` |
| Summary | `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt` |
| Result | `CoreMark/MHz = 0.912472` |
| Validation mode | `short_runtime_only` |

### riscv-tests

| Item | Value |
|------|------|
| RV32 baseline | `scripts\riscv_tests_rv32_baseline.txt` |
| RV32 fresh result | `33/33` |
| RV64 baseline | `scripts\riscv_tests_rv64_baseline.txt` |
| RV64 fresh result | `21/21` |

### FPGA impl50

| Item | Value |
|------|------|
| Command | `scripts\build_vivado_project.bat impl50` |
| Bitstream | `project/YH_rv_cpu_nexys_a7_100_20p000.bit` |
| Timing report | `project/reports/clk_20p000ns/impl_timing_summary.rpt` |
| Utilization report | `project/reports/clk_20p000ns/impl_utilization.rpt` |
| WNS | `+5.599ns` |
| WHS | `+0.025ns` |
| Slice LUTs | `2556` |
| Slice Registers | `2170` |
| BRAM | `4` |

## Experiment Rules

- Change only one optimization dimension at a time.
- Re-run `CoreMark score`, `riscv-tests rv32`, `riscv-tests rv64`, and `impl50` after every retained optimization.
- Do not replace this baseline with speculative or stale results.

## 2026-04-03 Retained Optimizations

### O1 - Tighten synchronous load hazard stall

| Item | Value |
|------|------|
| Change | `stall_decode` now stalls only on `load_use_hazard` |
| Files | `rtl/YH_rv_cpu_hazard_unit.v` |
| Before | `CoreMark/MHz = 0.888486` |
| After | `CoreMark/MHz = 0.912472` |
| Delta | `+0.023986` (`+2.70%`) |
| Formal command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Raw log | `build/sw/YH_rv_cpu_coremark_rv32_score.log` |
| Summary | `build/sw/YH_rv_cpu_coremark_rv32_score.summary.txt` |
| Validation | `validation_mode=short_runtime_only`, `competition_reportable=yes` |
| RV32 regression | `scripts\run_riscv_tests_subset.bat rv32` -> `33/33` |
| RV64 regression | `scripts\run_riscv_tests_subset.bat rv64` -> `21/21` |
| Keep? | `yes` |

Notes:

- The printed `Errors detected` line in this score run comes from the CoreMark
  `>=10s` runtime floor, not from CRC mismatch.
- The per-benchmark CRCs remain correct: `crclist=0xe714`,
  `crcmatrix=0x1fd7`, `crcstate=0x8e3a`.

## 2026-04-04 Formal CoreMark Validation Closure

This entry does not introduce a new retained optimization. It closes the formal
CoreMark validation gap on top of the already-retained baseline.

| Item | Value |
|------|------|
| Short command | `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000` |
| Short result | `CoreMark/MHz = 0.912472` |
| Short completion cycles | `11014885` |
| Short validation | `competition_reportable=yes`, `strict_eembc_10s_compliant=no` |
| Strict command | `scripts\run_coremark_score.bat rv32 1000 2000 100000000UL 1500000000 build\sw\YH_rv_cpu_coremark_rv32_strict.summary.txt` |
| Strict result | `CoreMark/MHz = 0.912465` |
| Strict completion cycles | `1095991523` |
| Strict runtime | `10.959325s` (`Total ticks = 1095932534`) |
| Strict validation | `validation_clean=yes`, `strict_eembc_10s_compliant=yes` |

Notes:

- The strict run confirms that the retained optimized baseline scales to a
  valid `>=10s` CoreMark result without changing workload semantics.
- The short run remains useful as a fast reproducible comparison path during
  future optimization work.

### O3 - FPGA path `DMEM_OUTPUT_REG: 1 -> 0`

| Item | Value |
|------|------|
| Change | Remove the extra synchronous DMEM output register on the FPGA path |
| Files | `fpga/vivado/src/YH_rv_cpu_fpga_top.v`, `tb/YH_rv_cpu_coremark_fpga_tb.v` |
| FPGA probe command | `scripts\run_coremark_fpga.bat rv32 1 400 100000000UL 20000000 build\sw\fpga_probe_dmem0.summary.txt 1` |
| FPGA probe result | `timeout` at `20,000,000` cycles |
| impl50 WNS | `+6.113ns` |
| impl50 WHS | `+0.042ns` |
| impl50 LUT / FF / BRAM | `2555 / 2170 / 4` |
| Keep? | `yes, as intermediate step to O4` |

### O4 - FPGA path `IMEM_OUTPUT_REG: 1 -> 0` on top of O3

| Item | Value |
|------|------|
| Change | Remove the extra synchronous IMEM output register on the FPGA path |
| Files | `fpga/vivado/src/YH_rv_cpu_fpga_top.v`, `tb/YH_rv_cpu_coremark_fpga_tb.v` |
| FPGA probe command | `scripts\run_coremark_fpga.bat rv32 1 400 100000000UL 20000000 build\sw\fpga_probe_i0d0.summary.txt 1` |
| FPGA probe result | `PASS`, `completion_cycles=156442`, `CoreMark/MHz=7.728811` |
| FPGA probe validation | `validation_clean=yes`, reduced workload so `competition_reportable=no` |
| impl50 WNS | `+5.822ns` |
| impl50 WHS | `+0.057ns` |
| impl50 LUT / FF / BRAM | `2555 / 2170 / 4` |
| Keep? | `yes` |

Final retained FPGA-default state:

- `IMEM_OUTPUT_REG=0`
- `DMEM_OUTPUT_REG=0`
- Bitstream target remains `project/YH_rv_cpu_nexys_a7_100_20p000.bit`

### O6 - Evaluate fetch-side prefetch during decode stall

| Item | Value |
|------|------|
| Change | Investigate whether `imem_req` / fetch queue can keep advancing when `stall_decode=1` |
| Files reviewed | `rtl/YH_rv_cpu.v`, `rtl/YH_rv_cpu_hazard_unit.v` |
| Result | `not retained` |
| Reason | Current fetch PC (`pc_r`) is frozen when `stall_decode=1`, so simply relaxing the `!stall_decode` gate would re-request the same PC instead of safely prefetching future instructions |
| Risk | A real fetch-side gain would require a deeper decoupling of fetch PC advance, IF/ID hold, and redirect/drop accounting rather than a one-line gate removal |

Notes:

- The retained `+2.70%` gain comes from O1, not from fetch-side speculation.
- Keep O6 closed unless a dedicated fetch queue refactor is planned and regression budget is available.

### O7 - Evaluate a 1-entry request-side fetch cursor

| Item | Value |
|------|------|
| Change | Add a directed fetch diagnostic and trial a 1-entry request-side cursor so synchronous fetch can keep requesting while decode is stalled |
| Diagnostic assets | `tb/YH_rv_cpu_fetch_prefetch_tb.v`, `scripts/run_fetch_prefetch_diag.bat` |
| Experimental RTL | `rtl/YH_rv_cpu.v` (trial branch only, reverted before keep decision) |
| Directed red/green command | `scripts\run_fetch_prefetch_diag.bat -testplusarg require_prefetch` |
| Directed result on trial RTL | `PASS`, `83 cycles`, `stall_cycles=6`, `opportunities=6`, `prefetch_seen=1` |
| Baseline diagnostic command | `scripts\run_fetch_prefetch_diag.bat` |
| Baseline diagnostic result | `PASS`, `prefetch_seen=0`, confirms the frozen baseline still does not prefetch during `stall_decode` |
| CoreMark smoke on trial RTL | `620530 cycles` |
| CoreMark score on trial RTL | `11014885 cycles`, `CoreMark/MHz = 0.912472` |
| Score delta vs frozen baseline | `0` |
| RV32 regression on trial RTL | `33/33` |
| RV64 regression on trial RTL | `21/21` |
| impl50 / FPGA-like probe | `not re-run` because the official short-score delta was `0` and the RTL was reverted before retain consideration |
| Keep? | `no` |

Notes:

- The directed diagnostic proved that the request cursor can create `stall_decode`-time fetch requests, but that behavior did not improve the formal short CoreMark score.
- Review after the trial identified unresolved interactions around redirect reuse and `IMEM_OUTPUT_REG`/drop accounting, so the RTL was reverted instead of being carried into synthesis or FPGA probe work.
- Keep the diagnostic assets in-tree; they are now the preferred starting point for any future fetch/request/queue experiment.

## 2026-04-07 Diagnostic and Profiling Follow-up

This round added profiling coverage and two directed diagnostics that mirror the current sync-fetch redirect/mem-wait behavior. It also switched the sim scripts to isolated per-run runtime directories so parallel workers no longer collide on `xsim.dir`.

### CoreMark profile snapshot

| Item | Value |
|------|------|
| Command | `scripts\run_coremark_profile.bat rv32` |
| Result | `PASS` |
| Raw log | `build/sw/YH_rv_cpu_coremark_rv32_profile.log` |
| Total cycles | `12516421` |
| `stall_decode_cycles` | `207474` |
| `mem_wait_cycles` | `553215` |
| `ex_fetch_redirect_valid_cycles` | `1504970` |
| `fetch_queue_empty_cycles` | `1504970` |

Notes:

- This is a profiling-only path, not a score submission path.
- The profile shows both `mem_wait` and redirect activity are still material contributors in the current RV32 CoreMark workload. That is an inference from the counters, not a direct functional assertion.

### Redirect reuse diagnostic

| Item | Value |
|------|------|
| Command | `scripts\run_fetch_redirect_reuse_diag.bat` |
| Result | `PASS` |
| Runtime isolation | `prepare_xsim_runtime.bat fetch_redirect_reuse_diag` |
| Directed result | `21 cycles`, `stall_cycles=2`, `redirects=2`, `overlaps=1`, `require_pipe_hit=0` |
| Strict red/green entry | `scripts\run_fetch_redirect_reuse_diag.bat require_pipe_hit` |
| Strict result | `FAIL` as expected, because `fetch_redirect_pipe_hit` is still hardwired low in RTL |

### Redirect accounting diagnostic

This diagnostic is meant to validate redirect/flush/drop accounting under both
`IMEM_OUTPUT_REG=0` and `IMEM_OUTPUT_REG=1`.

| Item | Value |
|------|------|
| Command | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` and `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` |
| `IMEM_OUTPUT_REG=0` strict result | `PASS` (`21 cycles`, `redirects=1`, `overlaps=1`, `require_queue_preserve=1`, `require_drop_accounting=1`) |
| `IMEM_OUTPUT_REG=1` strict result | `PASS` (`21 cycles`, `redirects=1`, `overlaps=1`, `require_queue_preserve=1`, `require_drop_accounting=1`) |
| Notes | `run_fetch_redirect_reuse_diag.bat` now strips `imem_output_reg` from runtime plusargs and maps it to compile-time `xelab -generic_top IMEM_OUTPUT_REG=<0|1>`, so both strict variants are real compile-time runs. |

### Memwait overlap diagnostic

| Item | Value |
|------|------|
| Command | `scripts\run_memwait_overlap_diag.bat` |
| Result | `PASS` |
| Runtime isolation | `prepare_xsim_runtime.bat memwait_overlap_diag` |
| Directed result | `21 cycles`, `mem_wait_cycles=1`, `opportunities=1`, `overlap_requests=0`, `require_overlap=0` |
| Strict red/green entry | `scripts\run_memwait_overlap_diag.bat require_overlap` |
| Strict result | `FAIL` as expected, because the current baseline does not yet issue an actual overlap-time request |

### Runtime isolation fix

All `xsim`-based scripts that matter here now run under unique runtime directories created by `scripts\prepare_xsim_runtime.bat`. The practical effect is that the new profile and diagnostics can run beside other workers without fighting over a shared `YH_rv_cpu\xsim.dir`.

## 2026-04-07 Timer IRQ Closure and Vivado Payload Freeze

This round closed the remaining local regression in `timer_irq_smoke` and removed the last unstable default from the `impl50` build flow.

| Item | Value |
|------|------|
| Root cause | `rtl/YH_rv_cpu_soc.v` forced `timer_irq_en_r <= 1'b1` on `TIMER_CTRL_ADDR` byte writes, so handler-side `sw zero` could not disable the timer interrupt |
| Functional fix | Restore `timer_irq_en_r <= timer_ctrl_next[0]` |
| Quality fix | Explicitly declare `csr_mcause_trap_write` in `rtl/YH_rv_cpu.v` so synthesis no longer relies on an implicit net |
| Build-flow fix | `scripts\build_vivado_project.bat` now defaults `impl50` to the frozen `build\sw\YH_rv_cpu_demo.{hex,mem32.hex}` image and only falls back to staged `current.*` payloads if the demo artifacts are unavailable |
| timer_irq smoke | `PASS`, `PC=000000e4`, `136 cycles` |
| CoreMark short | unchanged, `11014885 cycles`, `0.912472 CoreMark/MHz` |
| RV32 regression | unchanged, `33/33` |
| RV64 regression | unchanged, `21/21` |
| impl50 | `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`, `WNS = +5.599ns`, `WHS = +0.025ns` |
| FPGA-like probe | unchanged, `156442 cycles`, `7.728811 CoreMark/MHz` |

Notes:

- The `impl50` resource/timing delta is a real post-fix result on the repaired SoC path, not a payload-staging artifact.
- This is now the fresh local frozen baseline to quote in README, handoff, regression, and FPGA flow materials.

## 2026-04-07 Memwait Overlap Trial (Rejected)

This round tried the minimal `mem_wait overlap` request gate described in
`docs/superpowers/specs/2026-04-07-yh-rv-cpu-memwait-overlap-design.md`.

| Item | Value |
|------|------|
| RTL change | Allow `imem_req` during `mem_wait` when no buffered fetch data is present |
| Directed strict | `scripts\run_memwait_overlap_diag.bat require_overlap` -> `PASS` (`overlap_requests=1`) |
| Directed default | `scripts\run_memwait_overlap_diag.bat` -> `PASS` |
| Redirect guardrail | `scripts\run_fetch_redirect_reuse_diag.bat` -> `PASS` |
| CoreMark short | `11014885 cycles`, `0.912472 CoreMark/MHz` (unchanged) |
| RV32 regression | `33/33` |
| RV64 regression | `21/21` |
| Keep? | `no` |

Notes:

- The strict directed diagnostic turned green, but the formal short CoreMark
  score did not improve.
- The RTL was reverted immediately; only the diagnostics and documentation
  remain in mainline.

## 2026-04-07 Redirect Pipe-Hit Recheck Trial (Rejected)

This round re-tested a minimal `fetch_redirect_pipe_hit` gate after the
redirect accounting diagnostic was fully closed.

| Item | Value |
|------|------|
| Trial RTL change | Temporarily drive `fetch_redirect_pipe_hit` from `(IMEM_SYNC != 0) && fetch_reuse_redirect_valid && fetch_pipe_valid && (fetch_rsp_pc == fetch_reuse_redirect_pc)` |
| Directed strict | `scripts\run_fetch_redirect_reuse_diag.bat require_pipe_hit` -> `PASS` (`pipe_hits=1`) |
| Redirect accounting strict (`IMEM_OUTPUT_REG=0`) | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0` -> `PASS` |
| Redirect accounting strict (`IMEM_OUTPUT_REG=1`) | `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1` -> `PASS` |
| CoreMark smoke | `620530 cycles` |
| CoreMark short | `11014885 cycles`, `0.912472 CoreMark/MHz` (unchanged) |
| Keep? | `no` |

Notes:

- The functional gate is feasible under current diagnostics, but score gain is
  `0`, so the trial does not pass retention criteria.
- The RTL was reverted in the same round and the frozen baseline remains
  unchanged.
