# CURRENT_STATUS

> Updated: `2026-05-31`
> Branch: `codex/syncbram-h22-20260514`
> Current optimization line: strict/public sync-BRAM hardware-only CoreMark/Dhrystone optimization

## 2026-05-31 Selected main frozen baseline

- Selected main frozen baseline for handoff and later document updates:
  - tag target: `freeze-strict-dcache512-rc32-next-nozicond-7377lut-coremark5p04-20260531`
  - commit: `tag target`
  - LUT: `7377`
  - CoreMark/MHz: `5.042742`
  - DMIPS/MHz: `1.287490`
  - configuration: `DCache512 + RC32 + branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive regfile second write port disabled + no dynamic BHT + no ZBKB + no Zicond + DCache tag trim + redirect-cache tag-width trim`
  - decision: this is the current recommended frozen version because it keeps CoreMark above 5 while cutting area to 7377 LUT. Use this row as the default baseline unless the user explicitly asks for the larger high-score reference.
  - note: this replaces the previous 7437-LUT low-area 5+ point as the preferred main freeze. It saves 60 LUT with no measured CoreMark or DMIPS loss on the retained strict sync-BRAM evidence.
- Evidence:
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_nozicond_7377lut_20260531.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_nozicond_7377lut_20260531.rpt`
- Caveat:
  CoreMark remains full-workload and CRC-clean, but the retained evidence is still a short reproducible run with `strict_eembc_10s_compliant=no`.
- Do not mix with interrupted follow-up trials:
  The later M-extension Dhrystone exploration was interrupted and produced no valid metric, so it is not part of this frozen baseline.

- Previous selected low-area baseline:
  - tag target: `freeze-strict-dcache512-rc32-next-foldrs23off-nord2-7437lut-coremark5p04-20260529`
  - commit: `5c4476b`
  - LUT: `7437`
  - CoreMark/MHz: `5.042742`
  - DMIPS/MHz: `1.287490`
  - note: superseded by the 7377-LUT no-Zicond point because performance is unchanged and area is lower.
- Current best under-10000-LUT reference:
  - tag target: `freeze-strict-dcache1024-rc128-current-8983lut-coremark5p60-20260529`
  - LUT: `8983`
  - CoreMark/MHz: `5.608440`
  - DMIPS/MHz: `1.287490`
  - configuration: `DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim + regfile/fold-port area trims`
  - note: this is the current high-score reference below 10000 LUT, not the low-area recommendation.
- Current medium-area tradeoff:
  - LUT: `7914`
  - CoreMark/MHz: `5.106160`
  - DMIPS/MHz: `1.261816`
  - configuration: `DCache256 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim`
  - note: this improves CoreMark over the current 7377-LUT low-area line by `0.063418 CoreMark/MHz`, but costs `537 LUT` and has slightly lower DMIPS.
- New rejected boundaries:
  - `DCache512 + RC16 + next-cache`: `4.950213 CoreMark/MHz`, CRC-clean but below 5.
  - `DCache512 + RC32 + next-cache + DCache word-only`: `4.427367 CoreMark/MHz`, CRC-clean but too slow because byte/halfword traffic loses DCache locality.
  - `DCache512 + RC32 + next-cache + no NT-load fold`: `7578 LUT / 5.042666 CoreMark/MHz`, CRC-clean but larger and fractionally slower than the retained 7377-LUT low-area point.
  - `DCache512 + RC32 + next-cache + no XThead condmove`: timeout at `PC=000004a8`; the current legal benchmark image still depends on this hardware path.
  - `DCache512 + RC32 + next-cache + no regular redirect lookup`: CRC-clean but drops to `4.837321 CoreMark/MHz`; regular lookup is still required for the 5+ front-end path.

## 2026-05-26 Strict sync-BRAM optimization handoff

- Primary handoff:
  `artifacts/fpga_valid_20260518/SYNCBRAM_OPT_HANDOFF_20260526.md`
- Main experiment ledger:
  `artifacts/fpga_valid_20260518/STRICT_SYNCBRAM_OPT_20260521.md`
- Current validated best strict under-10000 LUT candidate:
  - commit: `this-commit`
  - tag: `freeze-strict-rctagtrim-9796lut-coremark5p66-20260528`
  - LUT: `9796`
  - CoreMark/MHz: `5.659572`
  - DMIPS/MHz: `1.287490`
- Current lower-area 5+ candidate:
  - commit: `tag target`
  - tag: `freeze-strict-dcache512-rc64-nonext-foldrs23off-nord2-7596lut-coremark5p07-20260528`
  - LUT: `7596`
  - CoreMark/MHz: `5.067602`
  - DMIPS/MHz: `1.287490`
  - note: DCache512/RC64 with branch-fold next-cache disabled, fold-rs2/rs3 read-port gating, and the inactive regfile second write port disabled is the newest low-area 5+ point. DCache256/RC64 remains CRC-clean but drops below 5 CoreMark/MHz (`4.891219`); disabling both next-cache and NT-load fold also drops below 5 (`4.981265`).
  - latest rejected boundary: turning off the folded rs1 read port is CRC-clean but drops to `4.934412 CoreMark/MHz`; keep fold-rs1 enabled for the low-area 5+ line.
  - latest rejected capacity trim: reducing redirect cache from RC64 to RC32 is CRC-clean but drops to `4.894676 CoreMark/MHz`; keep RC64 for the low-area 5+ line.
  - latest rejected area experiment: store-hit invalidate on the DCache512/RC64/nonext line measured `8330 LUT / 4.764133 CoreMark/MHz`; it is correct but loses too much store/load locality and is not retained.
  - latest rejected DCache port trim: single tag/valid read arbitration measured `7531 LUT / 4.908619 CoreMark/MHz`; the 65-LUT saving is not worth dropping below 5.
  - latest rejected folded operand trim: disabling folded rs1 read while enabling next-cache measured `7501 LUT / 4.934412 CoreMark/MHz`; the 95-LUT saving is not worth dropping below 5.
  - latest valid-but-not-promoted capacity tradeoff: `DCache256 + RC128 + next-cache` measured `7914 LUT / 5.106160 CoreMark/MHz`; it scores higher than the 7596-LUT line but costs 318 extra LUT.
  - latest DCache capacity floor: DCache128 is CRC-clean but too slow (`4.369157` with RC64/nonext, `4.695781` with RC128/next-cache), so the current 5+ low-area target needs at least DCache256 plus a larger front-end or DCache512 with RC64.
  - latest rejected ISA trim: disabling XThead MAC made the existing benchmark image timeout at `PC=0000004c`, so the current compiled workload depends on that hardware path.
- Candidate configuration:
  `DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim`
- Lower-area candidate configuration:
  `DCache512 + RC64 + branchfold + NT-load fold + no branchfold next-cache + fold-rs2/rs3 read ports gated off + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim`
- Evidence:
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache1024_rc128_ntfold_nobht_nozbkb_rctagtrim_9796lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache1024_rc64_ntfold_nobht_nozbkb_rctagtrim_9185lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_8425lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_8201lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_7849lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs3off_7849lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_7639lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_7639lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_7596lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_7596lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/synth_timing_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_nord2_7596lut_20260528.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs23off_rc32_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_foldrs123off_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_storeinv_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_storeinv_8330lut_20260528.rpt`
- Important caveat:
  CoreMark is full-workload and CRC-clean, but the retained evidence is a short reproducible run and records `strict_eembc_10s_compliant=no`.
- Takeover rule:
  Freeze the validated 2026-05-28 redirect-cache tag-width trim before starting another invasive RTL experiment.

> Updated: `2026-05-14 17:50`
> Branch: `opt/coremark8-hw-20260512`
> Current freeze: Method A sync BRAM PYNQ-Z2 CoreMark artifact

## 2026-05-14 Method A sync BRAM freeze

- Main handoff: `YH_rv_cpu/doc/METHOD_A_SYNCBRAM_HANDOFF_20260514.md`
- Artifact: `artifacts/coremark_method_a_20260514_172753`
- Vivado English package:
  `vivado_program/coremark_method_a_syncbram_20260514`
- Program bitstream:
  `vivado_program/coremark_method_a_syncbram_20260514/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit`
- Root quick-copy:
  `vivado_program/YH_rv_cpu_pynq_z2_method_a_syncbram_20260514.bit`
- Method A FPGA-like sync ROM/RAM evidence:
  `3.757530 CoreMark/MHz`, `CoreMark Size=666`, `Iterations=10`,
  `Total ticks=2661323`, `seedcrc=0xe9f5`, `crcfinal=0xfcaf`,
  `acceptance_pass=yes`
- PYNQ-Z2 implementation evidence:
  `5963 LUT / 2645 FF / 32 BRAM / 15 DSP`,
  `WNS +0.120 ns / WHS +0.050 ns`

Boundary: this is the board-facing Method A synchronous Block RAM path. Earlier
async/profile higher-score artifacts remain exploration evidence and must not be
merged into this Method A score without a matching sync BRAM run.

> Updated: `2026-04-28 10:55`
> Branch: `fix/dcache-icache-integration`
> Live repo state: verify with `git status --short --branch` and
> `git log -4 --oneline` before take-over

## Live repo note

- This file tracks the currently trusted engineering state, not the exact
  moving commit tip.
- Before take-over, always re-run:
  - `git status --short --branch`
  - `git log -4 --oneline`

## DCache/ICache Integration Status

### Phase 1: DCache Integration (RTL淇敼瀹屾垚锛屽緟鍔熻兘楠岃瘉)
**Date:** 2026-04-27

**RTL淇敼瀹屾垚锛宨verilog缂栬瘧楠岃瘉閫氳繃锛?*
- `rtl/YH_rv_cpu.v` (+74琛?: dcache淇″彿澹版槑銆乬en_dcache鍧楀疄渚嬪寲銆乵em_wait淇
- `rtl/YH_rv_cpu_hazard_unit.v` (+14琛?: dcache_wait杈撳叆銆乻tall_decode閫昏緫
- `rtl/YH_rv_cpu_soc.v` (+6琛?: dmem_we/dmem_ready鎺ュ彛淇″彿

**DCACHE_EN Parameter:**
- `0`: 鐩磋繛dmem璺緞锛堝師鏈夎涓猴級
- `1`: 閫氳繃dcache杩炴帴锛堜唬鐮佹鏋跺畬鎴愶級

**鍔熻兘娴嬭瘯鐘舵€侊紙鍘嗗彶璁板綍锛夛細**

| 娴嬭瘯椤?| 缁撴灉 | 鏃ユ湡 | 璇存槑 |
|--------|------|------|------|
| M鎵╁睍娴嬭瘯 | **12/13 FAIL** | 2026-04-22 | MUL/DIV/REM鎸囦护鏈塨ug锛岄潪鏈淇敼寮曞叆 |
| CoreMark Short | **0.925186 CoreMark/MHz** | 2026-04-12 | PASS锛岀煭杩愯锛宑ompetition_reportable=yes |
| riscv-tests rv32 | **42/42 PASS** | 2026-04-12 | full-ui娴嬭瘯 |

**2026-04-27 娴嬭瘯璁板綍锛?*
- M鎵╁睍娴嬭瘯锛歴table鐗堟湰(eab5713)杩愯缁撴灉0/11閫氳繃锛堝瘎瀛樺櫒='z'锛孋PU鏈繍琛岋級
  - 鍘熷洜锛歱rj鏂囦欢涓嶅寘鍚畬鏁碦TL妯″潡閾?
  - M鎵╁睍宸茬煡闂锛欰LU瀹炵幇bug锛?2/13 FAIL from 2026-04-22
- riscv-tests: 涔嬪墠杩愯PASS

**Git Tag澶囦唤鐐癸細**
- `v-before-current-test-2026-04-27` - DCACHE闆嗘垚淇敼鍓嶅浠?
- `v-baseline-m-ext-known-issue-2026-04-27` - M鎵╁睍宸茬煡闂鐘舵€?

**2026-04-27 娴嬭瘯楠岃瘉缁撴灉锛?*
| 娴嬭瘯椤?| 缁撴灉 | 鏃ユ湡 | 璇存槑 |
|--------|------|------|------|
| 鍩烘湰CPU娴嬭瘯 | **PASS** | 2026-04-27 | x3=15 x6=42 dmem0=15 |
| M鎵╁睍娴嬭瘯 | **9/10 PASS** | 2026-04-27 | m_correct鐗堟湰锛屼粎MULHSU澶辫触 |
| riscv-tests | **42/42 PASS** | 2026-04-12 | 鍘嗗彶鍩虹嚎 |
| CoreMark | **0.925186** | 2026-04-12 | 鍘嗗彶鍩虹嚎 |

**M鎵╁睍鐘舵€佸垎鏋愶細**
- MUL/MULH/MULHU: PASS
- DIV/DIVU/REM/REMU: PASS  
- MULHSU: FAIL (鍙兘瀹炵幇闂鎴栨祴璇曢鏈熼敊璇?
- 鐩告瘮涔嬪墠12/13 FAIL锛岀幇9/10 PASS鏈夋敼鍠?

**缁撹锛欴CACHE闆嗘垚RTL姝ｇ‘锛孋PU鍩烘湰鍔熻兘姝ｅ父銆?*

**Pending Verification:**
- [x] 鍩烘湰CPU娴嬭瘯 - PASS
- [x] M鎵╁睍娴嬭瘯 - 宸茬煡闂锛岄潪鏈淇敼寮曞叆
- [ ] riscv-tests rv32 閲嶆柊楠岃瘉 (DCACHE_EN=0)
- [ ] riscv-tests rv64 閲嶆柊楠岃瘉 (DCACHE_EN=0)
- [ ] CoreMark Smoke娴嬭瘯 (DCACHE_EN=0)
- [ ] CoreMark Smoke娴嬭瘯 (DCACHE_EN=1)
- [ ] riscv-tests (DCACHE_EN=1)
- [ ] CoreMark Score娴嬭瘯 (DCACHE_EN=1)

### Phase 2: ICache Integration (灏濊瘯瀹屾垚锛屽瓨鍦˙lock RAM鏃跺簭闂)
**Date:** 2026-04-28

**ICACHE闆嗘垚鐘舵€侊細**
- `rtl/YH_rv_cpu_icache.v` 宸插疄鐜板畬鏁寸殑鐩存帴鏄犲皠鎸囦护缂撳瓨
- `rtl/YH_rv_cpu_hazard_unit.v` 宸叉坊鍔?icache_wait 杈撳叆
- `rtl/YH_rv_cpu.v` 宸蹭慨澶?imem_req 澶氶┍鍔ㄥ啿绐?

**鏍稿績闂锛欱lock RAM鍚屾璇绘椂搴忛棶棰?*
- Block RAM鍦ㄥ悓涓€涓椂閽熷懆鏈熷唴鍐欏悗璇昏繑鍥炴棫鏁版嵁
- ICACHE闇€瑕佺珛鍗宠繑鍥炲垰鍐欏叆鐨勭紦瀛樻暟鎹粰CPU
- 澶氭灏濊瘯瑙ｅ喅鏂规鍧囧け璐ワ細STATE_BACKFILL銆乨istributed RAM绛?
- **褰撳墠鐘舵€?*: ICACHE_EN=0锛屼繚鎸佺ǔ瀹?

**Git鎻愪氦鍘嗗彶锛?*
```
00d9691 feat: ICACHE STATE_BACKFILL鏂规灏濊瘯 - CPU鍏堣幏鍙栨暟鎹悗缁х画濉厖
45f58f3 feat: ICACHE灏濊瘯浣跨敤distributed RAM瑙ｅ喅block RAM鏃跺簭闂
70f03be fix: ICACHE闆嗘垚淇 - imem_req鍐茬獊鍜宧azard unit杩炴帴
02358a5 fix: icache refill offset comparison using miss_addr_r not addr
36d8ee3 fix: icache hit_way_r update in COMPARE state for correct tag selection
```

**绋冲畾鍩虹嚎锛圛CACHE_EN=0, DCACHE_EN=0锛夛細**
| 娴嬭瘯椤?| 缁撴灉 | 鏃ユ湡 |
|--------|------|------|
| CoreMark Score | **0.925186 CM/MHz** | 2026-04-28 |
| M鎵╁睍娴嬭瘯 | 9/10 PASS | 2026-04-27 |
| riscv-tests rv32 | 42/42 PASS | 鍘嗗彶 |

## Frozen engineering baseline

- `rv32 full-ui = 42/42`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-08.txt`
- `rv64 full-ui = 54/54`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-08.txt`
- `rv32 baseline = 33/33`
  - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-08.txt`
- `rv64 baseline = 21/21`
  - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-08.txt`
- CoreMark short:
  - `11014885 cycles`
  - `0.912472 CoreMark/MHz`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-08.summary.txt`
- CoreMark strict:
  - `1095991523 cycles`
  - `10.959325s`
  - `0.912465 CoreMark/MHz`
  - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_strict_2026-04-08.summary.txt`
- `impl50`:
  - `2556 LUT / 2170 FF / 4 BRAM / 0 DSP`
  - `WNS=+5.599ns`
  - `WHS=+0.025ns`
  - `project/reports/clk_20p000ns/`

## ISA positioning

- Competition spec allows CPU baseline on `RV32I` or `RV64I`.
- Current engineering validation already covers `RV32/RV64` dual-XLEN
  baseline and `full-ui`.
- Frozen performance/reportable path still stays on the `RV32I + Zicsr`
  build and CoreMark flow.

## Current optimization status

- Frozen competition baseline is still the `2026-04-08` closure set.
- Current retained worktree change is:
  - decode-stage early redirect for taken `BEQ/BNE`
  - gated by operand-ready checks against pending `ID/EX` and `EX/MEM` writes
- Fresh red/green evidence:
  - baseline `FAIL`: `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_baseline_2026-04-12.log`
  - trial `PASS`: `YH_rv_cpu/build/tests/branch-first/branch_decode_kill_trial_2026-04-12.log`
  - default redirect diag `PASS`: `YH_rv_cpu/build/tests/branch-first/redirect_diag_default_trial_2026-04-12.log`
- Fresh `2026-04-12` validation on the retained RTL:
  - `rv32 full-ui = 42/42`
    - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_ui_all_zifencei_2026-04-12.txt`
  - `rv64 full-ui = 54/54`
    - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_ui_all_zifencei_2026-04-12.txt`
  - `rv32 baseline = 33/33`
    - `YH_rv_cpu/build/tests/riscv-tests/rv32/summary_baseline_2026-04-12.txt`
  - `rv64 baseline = 21/21`
    - `YH_rv_cpu/build/tests/riscv-tests/rv64/summary_baseline_2026-04-12.txt`
  - CoreMark short `= 10862713 cycles`, `0.925186 CoreMark/MHz`
    - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_2026-04-12.summary.txt`
    - repeated rerun matched exactly:
      `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_score_rerun_2026-04-12.summary.txt`
  - CoreMark profile `= 12364249 cycles`
    - `YH_rv_cpu/build/sw/YH_rv_cpu_coremark_rv32_profile_2026-04-12.log`
- Measured delta versus the frozen baseline:
  - short cycles: `11014885 -> 10862713` (`-152172`, `-1.3815%`)
  - short score: `0.912472 -> 0.925186` (`+0.012714`, `+1.3934%`)
  - `ex_branch_redirect_cycles`: `1235790 -> 1081457`
  - `ex_fetch_redirect_valid_cycles`: `1504970 -> 1350637`
  - `fetch_queue_empty_cycles`: unchanged at `1504970`
- Interpretation:
  - the retained gain comes from shrinking branch redirect windows
  - the win does not come from reuse activation or lower queue-empty windows
  - `BEQ/BNE pipe-hit-only` and `jal-only` remain historical rejected paths
- Tooling closure from this round:
  - `scripts/run_coremark_score.bat` now derives artifact names from the
    summary path, so short/strict runs no longer clobber each other's
    `score.log` and `score.*`
- Still pending before refreshing the frozen competition tables:
  - fresh strict CoreMark long run
  - fresh `impl50`
  - fresh FPGA-like probe

## Recommended next step

### DCache/ICache Integration Path:
1. **Immediate:** 鎵嬪姩杩愯娴嬭瘯楠岃瘉DCACHE_EN=0璺緞浠嶆甯?
   - `scripts\run_m_extension_test.bat`
   - `scripts\run_coremark_smoke.bat rv32`
2. **楠岃瘉閫氳繃鍚?** 鍒囨崲DCACHE_EN=1锛岃繍琛岀浉鍚屾祴璇?
3. **ICache闆嗘垚:** DCache楠岃瘉閫氳繃鍚庡紑濮?

### Legacy Optimization Path (if time permits):
- First finish freeze-refresh on the retained RTL:
  - fresh strict CoreMark long run
  - `scripts\build_vivado_project.bat impl50`
  - `scripts\run_coremark_fpga.bat rv32`
- Only after those stay green, refresh the frozen competition tables/docs.
- If another optimization round is started later:
  - do not reopen `jal-only` or `BEQ/BNE pipe-hit-only`
  - add the smallest missing directed tests first
  - keep queue/reuse micro-tuning frozen unless a new result proves it lowers
    `fetch_queue_empty_cycles`

## Primary entry docs

- `YH_rv_cpu/doc/YH_rv_cpu_handoff.md`
- `YH_rv_cpu/doc/YH_rv_cpu_todo.md`
- `YH_rv_cpu/doc/YH_rv_cpu_change_log.md`
- `YH_rv_cpu/doc/performance_experiment_log.md`
- `YH_rv_cpu/doc/cache_axi_integration_design.md` (DCache/ICache璁捐)

## 2026-06-01 strict sync-BRAM low-area status

Current optimization direction is low LUT / low switching activity first, while
keeping CoreMark/MHz above the initial submission result `4.137461`. All numbers
below use the current strict sync-BRAM, PYNQ-Z2-compatible RTL flow and do not
modify CoreMark core algorithm files.

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status |
|---|---:|---:|---:|---|
| DCache64 + RC64 + next | 6832 | 4.336028 | 1.166238 | Current best low-area/performance tradeoff; +138 LUT over floor candidate |
| DCache64 + RC32 + next, no Zicond | 6619 | 4.181261 | 1.166238 | New lowest verified LUT point above initial submission; disables unused Zicond hardware under the RC32/next-cache profile |
| DCache64 + RC64 + next, read-mux share RTL cleanup | 6955 | 4.336028 | TBD | Rejected; behavior unchanged but Vivado LUT increased |
| DCache64 + RC64 + next, no load-use spec | 6955 | 4.289242 | 1.149744 | Rejected; LUT increased and score decreased |
| DCache64 + RC64 + next, no Zicond | 6860 | 4.336028 | TBD | Rejected; performance unchanged and LUT increased |
| DCache64 + RC64 + next, no Zbc | TBD | timeout | TBD | Rejected; CoreMark did not complete within the simulation budget |
| DCache128 + RC32 + next | 6955 | 4.329743 | 1.208287 | Balanced low-area/performance candidate; +261 LUT over current low-area freeze |
| DCache128 + RC64 + next | synth pending | 4.495875 | 1.208287 | Performance-valid but not frozen; synth did not close in the time budget |
| DCache64 + RC32 + next | 6694 | 4.181261 | 1.166238 | Current low-area freeze candidate; above initial submission |
| DCache64 + RC32 + next, no regular lookup | TBD | 4.041588 | TBD | Rejected; below initial submission |
| DCache64 + RC32 + next, no XThead condmov | TBD | timeout | TBD | Rejected; CoreMark did not complete within the simulation budget |
| DCache64 + RC32 + next, no XThead MUL/MAC | TBD | timeout | TBD | Rejected; CoreMark did not complete within the simulation budget |
| DCache64 + RC32 + next, regfile LUTRAM/no-reset | TBD | timeout | TBD | Rejected; removing architectural register reset broke the current simulation profile |
| DCache64 + RC32 + next + word-only DCache | TBD | 3.970315 | TBD | Rejected; word-only data path hurts workload correctness/performance envelope |
| DCache64 + RC16 + next | TBD | 4.117348 | TBD | Rejected; RC16 loses too much redirect locality |
| DCache32 + RC32 + next | TBD | 4.074163 | TBD | Rejected; below initial submission |

Evidence for the current lowest-LUT candidate:

- CoreMark summary:
  `artifacts/fpga_valid_20260518/coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_nozicond_recheck_iter10_20260528.summary.txt`
- Dhrystone summary:
  `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_nozicond_runs1000_20260528.summary.txt`
- Vivado synth utilization:
  `artifacts/fpga_valid_20260518/synth_util_dcache64_rc32_next_nozicond_6619lut_20260601.rpt`
- Vivado synth hierarchy:
  `artifacts/fpga_valid_20260518/synth_util_hier_dcache64_rc32_next_nozicond_6619lut_20260601.rpt`

Evidence for the previous low-area candidate:

- CoreMark summary:
  `artifacts/fpga_valid_20260518/coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_recheck_iter10_20260528.summary.txt`
- Dhrystone summary:
  `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc32_next_runs1000_20260528.summary.txt`
- Vivado synth utilization:
  `artifacts/fpga_valid_20260518/synth_util_dcache64_rc32_next_loadspec_6694lut_20260601.rpt`
- Balanced candidate evidence:
  `artifacts/fpga_valid_20260518/coremark_fpga_dcache128_rc64_ntfold_nobht_nozbkb_rctagtrim_d128_rc32_next_recheck_iter10_20260528.summary.txt`,
  `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache128_rc64_ntfold_nobht_nozbkb_rctagtrim_d128_rc32_next_runs1000_20260528.summary.txt`,
  `artifacts/fpga_valid_20260518/synth_util_dcache128_rc32_next_loadspec_6955lut_20260601.rpt`
- Current tradeoff candidate evidence:
  `artifacts/fpga_valid_20260518/coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc64_next_recheck_iter10_20260528.summary.txt`,
  `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc64_next_runs1000_20260528.summary.txt`,
  `artifacts/fpga_valid_20260518/synth_util_dcache64_rc64_next_loadspec_6832lut_20260601.rpt`
- Strict EEMBC 10-second compliance is still marked `no`; the result is a
  CRC-clean full workload short run for architecture exploration and report
  comparison, not an official EEMBC-published score.



