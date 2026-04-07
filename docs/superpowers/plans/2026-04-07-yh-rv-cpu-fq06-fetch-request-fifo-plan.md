# YH_rv_cpu FQ-06 Fetch-Request FIFO Decouple Plan

**Goal:** Execute one controlled higher-intrusion fetch-path round with strict
diagnostic-first gating.

## Task 1: Define invariants before RTL changes

- [ ] Define request FIFO state machine and outstanding-request invariant.
- [ ] Define redirect/drop-accounting rules for `IMEM_OUTPUT_REG=0/1`.
- [ ] Define fail-fast assertions/diagnostic checks.

## Task 2: Implement minimal structural slice

**Primary file:** `YH_rv_cpu/rtl/YH_rv_cpu.v`

- [ ] Add minimal request FIFO structures (no extra policy knobs).
- [ ] Keep IF/ID payload path unchanged in first cut.
- [ ] Keep changes bounded to fetch request path + accounting coupling points.

## Task 3: Diagnostics and quick-screen gate

- [ ] `scripts\run_fetch_redirect_reuse_diag.bat`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=0`
- [ ] `scripts\run_fetch_redirect_reuse_diag.bat require_queue_preserve require_drop_accounting imem_output_reg=1`
- [ ] `scripts\run_memwait_overlap_diag.bat`
- [ ] `scripts\run_coremark_smoke.bat rv32`
- [ ] `scripts\run_coremark_score.bat rv32 10 2000 100000000UL 20000000`

## Task 4: Expand only on gain

- [ ] If short score improves, run full matrix (`rv32`, `rv64`, strict `>=10s`, `impl50`, `fpga` probe).
- [ ] If no gain or any guardrail fails, revert RTL in same round and record reject.
