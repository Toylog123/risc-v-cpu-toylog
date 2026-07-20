# CURRENT_STATUS

> Updated: `2026-07-01`
> Branch: `codex/strict50-impl136-opt-20260625`
> Authoritative rule: only timing-closed exact-ROM implementation results may be reported as a baseline. Short simulations, quick synthesis rows, demo/default-ROM timing closure, and timing-failed implementation rows are audit history only.

## 2026-07-01 current optimization status

Current canonical best post-freeze candidate, now frozen as the strict 50 MHz
implementation-evidence candidate in
`artifacts/strict_50m_timing_opt_20260609/FREEZE_STRICT50_IMPL220_20260701.md`:

| Role | Candidate | LUT | FF | CoreMark/MHz | Clock | Timing | Status |
|---|---|---:|---:|---:|---:|---|---|
| Frozen strict 50 MHz implementation candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | 9965 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.056 ns / WHS +0.121 ns | valid strict routed pass; board evidence pending |

Newly audited results:

| Candidate | LUT | FF | CoreMark/MHz | Clock | Timing | Decision |
|---|---:|---:|---:|---:|---|---|
| `impl200_impl136_bhtidupd0_routeMoreGlobalIterations_postAggressive_cpu50` | 10039 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.032 ns / WHS +0.046 ns | valid strict routed pass; not promoted |
| `impl212_impl136_bhtid0_foldnext0_routeMoreGlobalIterations_postAggressive_cpu50` | 9022 | 6413 | 4.207986 inherited from `fast203` | 50 MHz | WNS +0.092 ns / WHS +0.077 ns | valid strict routed pass; best timing/area relaxed-gate candidate |
| `synth213_fast204_ntfold_loadfold_bhtid0_foldnext0_cpu50` | 10200 synth LUT | 6483 | 4.270739 from `fast204` | 50 MHz target | synth WNS -3.898 ns / WHS +0.132 ns | rejected; not-taken/load fold reconnects long DMem-to-IF/ID path |
| `impl214_impl200_placeAltSpread_routeMoreGlobalIterations_postAggressive_cpu50` | 10168 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.054 ns / WHS +0.026 ns | valid strict routed pass; not promoted because LUT increased |
| `impl215_impl200_routeAdvancedSkewModeling_postAggressive_cpu50` | 10039 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.008 ns / WHS +0.047 ns | valid strict routed pass; not promoted |
| `impl216_impl200_routeNoTimingRelaxation_postAggressive_cpu50` | 10039 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.115 ns / WHS +0.047 ns | valid strict routed pass; best high-score timing-margin candidate, but 39 LUT above preferred target |
| `impl217_impl200_placeExtraPost_routeNoTimingRelaxation_postAggressive_cpu50` | 10043 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.028 ns / WHS +0.047 ns | rejected/not promoted because LUT increased |
| `impl218_impl200_optExploreArea_routeNoTimingRelaxation_postAggressive_cpu50` | 9963 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.006 ns / WHS +0.109 ns | valid strict routed pass; first high-score candidate below `LUT < 10000` |
| `impl219_impl200_optExploreArea_routeMoreGlobalIterations_postAggressive_cpu50` | 9967 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.008 ns / WHS +0.109 ns | valid strict routed pass; current best high-score preferred-gate candidate |
| `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` | 9965 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.056 ns / WHS +0.121 ns | valid strict routed pass; current best high-score preferred-gate candidate |
| `impl221_impl200_optExploreArea_placeAltSpread_routeMoreGlobalIterations_postAggressive_cpu50` | 10084 | 6522 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS -0.071 ns / WHS +0.051 ns | rejected; fails setup timing and exceeds `LUT < 10000` |
| `impl222_impl200_optExploreArea_placeExtraPost_routeAdvancedSkewModeling_postAggressive_cpu50` | 9964 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.006 ns / WHS +0.074 ns | valid strict routed pass; not promoted because margin is much weaker than `impl220` for only 1 LUT saved |
| `impl223_impl200_optExploreArea_routeHigherDelayCost_postAggressive_cpu50` | 9968 | 6520 | 4.287521 inherited from `fast200`/`fast210` | 50 MHz | WNS +0.003 ns / WHS +0.067 ns | valid strict routed pass; not promoted because it adds LUT and leaves much weaker setup slack than `impl220` |
| `synth205_impl190_rc1024_cpu50` | 12277 synth LUT | 6732 | 4.292102 from `fast181` | 50 MHz target | synth WNS -0.375 ns / WHS +0.132 ns | rejected |
| `synth207_defaultfast_idbexmem0_reject_wns-11p942` | 7908 synth LUT | 3960 | 4.591157 from `fast207` | 50 MHz target | synth WNS -11.942 ns / WHS +0.132 ns | rejected; not comparable to impl136/impl190 |
| `synth224_defaultfast_foldnext0_cpu50` | 7577 synth LUT | 3879 | 4.569338 from `fast201` | 50 MHz target | synth WNS -11.786 ns / WHS +0.132 ns | rejected; high fast score still depends on same-cycle DCache/MEM-to-front-end fold decode path |

`ENABLE_BRANCH_BHT_ID_UPDATE` has been added as a controlled switch. It cuts
the `impl190` BHT CE hotspot for experiments. `impl218` and `impl219` show that
`opt_design -directive ExploreArea` can recover enough routed area from the
`impl200` score line to meet the preferred `LUT < 10000` target while preserving
strict 50 MHz timing closure. `impl220` improves that line further by combining
`ExploreArea` with `route_design -directive AdvancedSkewModeling`.

The current exposed hotspot remains the route-dominated
DCache/redirect-cache/front-end decode path:
`cache_tag_reg[95][0]/C -> id_ex_alu_op_r_reg[3]_bret__0/D`
in `impl220`, with 22 logic levels and about 79.8% route delay.

`impl212` remains the lower-LUT timing-margin fallback under the relaxed
`CoreMark/MHz >= 4.15` gate. It does not supersede the current high-score
`impl219` line for score.
`synth213` shows that simply re-enabling not-taken/load fold is not timing-safe:
the worst synthesis setup path is
`u_soc/u_dmem_ram/g_sync_ram.g_posedge_read.ram_mem_reg_2_3/CLKARDCLK ->
u_soc/u_cpu/if_id_instruction_r_reg[12]_bret__3/D` with 30 logic levels.
`impl216` remains useful as the high-score timing-margin reference above the
preferred area target. `impl218` is the slightly smaller high-score pass
(`9963 LUT`), while `impl220` is the current preferred high-score pass by setup
slack (`+0.056 ns`). The remaining top paths are still route-dominated, so
continued work should either improve timing margin on the `ExploreArea` line or
cut the remaining redirect/DCache route-dominated path in RTL.

`impl221` shows that stacking `AltSpreadLogic_high` on top of `ExploreArea` is
not useful on the current DCP: it increases LUT, fails setup timing, and moves
the worst path into shared-ROM/front-end address logic.
`impl222` shows that `ExtraPostPlacementOpt` can still close strict 50 MHz
with one fewer LUT than `impl220`, but it leaves only `+0.006 ns` setup margin
and therefore does not supersede the current best.
`impl223` confirms that `HigherDelayCost` is not a better route directive for
the current `ExploreArea` DCP: it closes timing, but setup margin drops to
`+0.003 ns` and LUT rises to `9968`.
`synth224` confirms that the higher `fast201`/default-fast score line is still
not a viable strict 50 MHz source until the same-cycle DCache/load-use/fold
decode fan-in is retimed or decoupled.

## 2026-06-30 post-freeze strict 50 MHz sweep update

The post-freeze implementation-only sweep from
`synth186_impl136_foldexmem0_cpu50` has now covered `impl186` through `impl199`.
No implementation directive variant after `impl190` improved the best measured
setup margin.

Current canonical best post-freeze optimization candidate:

| Role | Candidate | LUT | FF | CoreMark/MHz | Clock | Timing | Status |
|---|---|---:|---:|---:|---:|---|---|
| Current best post-freeze timing candidate | `impl190_impl136_foldexmem0_routeMoreGlobalIterations_postAggressive_cpu50` | 9933 | 6224 | 4.287448 inherited from `fast186` | 50 MHz | WNS +0.050 ns / WHS +0.087 ns | valid strict routed pass; not frozen yet |

Corroborating tie:

| Role | Candidate | LUT | FF | CoreMark/MHz | Clock | Timing | Status |
|---|---|---:|---:|---:|---:|---|---|
| Timing-equivalent rerun | `impl193_impl136_foldexmem0_preAggressive_routeMoreGlobalIterations_postAggressive_cpu50` | 9933 | 6224 | 4.287448 inherited from `fast186` | 50 MHz | WNS +0.050 ns / WHS +0.087 ns | valid tie; pre-route `AggressiveExplore` did not improve over `impl190` |

Latest sweep summary:

| Candidate | Technique | LUT | FF | Clock | Timing | Decision |
|---|---|---:|---:|---:|---|---|
| `impl192_impl136_foldexmem0_placeExtraPost_routeMoreGlobalIterations_postAggressive_cpu50` | place `ExtraPostPlacementOpt`, route `MoreGlobalIterations` | 9926 | 6224 | 50 MHz | WNS +0.004 ns / WHS +0.095 ns | valid pass; not promoted |
| `impl193_impl136_foldexmem0_preAggressive_routeMoreGlobalIterations_postAggressive_cpu50` | pre `AggressiveExplore`, route `MoreGlobalIterations` | 9933 | 6224 | 50 MHz | WNS +0.050 ns / WHS +0.087 ns | valid tie with `impl190` |
| `impl194_impl136_foldexmem0_placeSSISpread_routeMoreGlobalIterations_postAggressive_cpu50` | place `SSI_SpreadLogic_high`, route `MoreGlobalIterations` | 9926 | 6224 | 50 MHz | WNS +0.004 ns / WHS +0.095 ns | valid pass; not promoted |
| `impl195_impl136_foldexmem0_routeAdvancedSkewModeling_postAggressive_retry_cpu50` | route `AdvancedSkewModeling` | 9923 | 6224 | 50 MHz | WNS +0.044 ns / WHS +0.067 ns | valid pass; not promoted |
| `impl196_impl136_foldexmem0_preAggressive_routeAdvancedSkewModeling_postAggressive_cpu50` | pre `AggressiveExplore`, route `AdvancedSkewModeling` | 9923 | 6224 | 50 MHz | WNS +0.044 ns / WHS +0.067 ns | valid pass; same as `impl195` |
| `impl197_impl136_foldexmem0_preAggressive_routeNoTimingRelaxation_postAggressive_cpu50` | pre `AggressiveExplore`, route `NoTimingRelaxation` | 9924 | 6224 | 50 MHz | WNS +0.003 ns / WHS +0.139 ns | valid pass; not promoted |
| `impl198_impl136_foldexmem0_placeAltSpread_routeMoreGlobalIterations_postAggressive_cpu50` | place `AltSpreadLogic_high`, route `MoreGlobalIterations` | 9849 | 6224 | 50 MHz | WNS +0.009 ns / WHS +0.095 ns | valid lower-LUT pass; timing margin too small |
| `impl199_impl136_foldexmem0_placeAltSpread_routeAdvancedSkewModeling_postAggressive_cpu50` | place `AltSpreadLogic_high`, route `AdvancedSkewModeling` | 9852 | 6224 | 50 MHz | WNS +0.014 ns / WHS +0.079 ns | valid lower-LUT pass; timing margin too small |

Decision: keep `impl190` as the canonical current best post-freeze candidate.
The next useful work is RTL-level reduction of the route-dominated
DCache/redirect-cache/front-end timing paths. Repeating the same implementation
directive family is unlikely to improve beyond `WNS +0.050 ns`.

## 2026-06-25 post-freeze strict 50 MHz optimization update

After freezing `impl136`, a clean optimization worktree was created from
`freeze-best-strict50-impl136-20260625` and used for implementation sweeps that
preserve the strict exact-CoreMark-ROM benchmark gate.

The current best post-freeze optimization candidate is:

| Role | Candidate | LUT | FF | CoreMark/MHz | Clock | Timing | Status |
|---|---|---:|---:|---:|---:|---|---|
| Current best post-freeze timing candidate | `impl190_impl136_foldexmem0_routeMoreGlobalIterations_postAggressive_cpu50` | 9933 | 6224 | 4.287448 inherited from `fast186` | 50 MHz | WNS +0.050 ns / WHS +0.087 ns | valid strict routed pass; not frozen yet |

Evidence archive:
`artifacts/strict_50m_timing_opt_20260609/impl190_impl136_foldexmem0_routeMoreGlobalIterations_postAggressive_cpu50`.

Sweep summary:

| Candidate | Technique | LUT | FF | Clock | Timing | Decision |
|---|---|---:|---:|---:|---|---|
| `fast186_impl136_foldexmem0_iter10` | Disable `FOLD_EXMEM_LOAD_USE_SPEC`; exact fast gate | n/a | n/a | xsim | CoreMark/MHz 4.287448, CRC 0xfcaf | accepted for synth/impl; score matches frozen `impl136` |
| `synth186_impl136_foldexmem0_cpu50` | Synthesize `fast186` candidate | 9842 | 6223 | 50 MHz target | synth WNS -0.222 ns / WHS +0.132 ns | accepted as source DCP |
| `impl186_impl136_foldexmem0_routeHigherDelayCost_cpu50` | route `HigherDelayCost`, post-route `Explore` | 9929 | 6224 | 50 MHz | WNS +0.003 ns / WHS +0.053 ns | valid pass; not promoted |
| `impl188_impl136_foldexmem0_routeNoTimingRelaxation_postAggressive_cpu50` | route `NoTimingRelaxation`, post-route `AggressiveExplore` | 9924 | 6224 | 50 MHz | WNS +0.003 ns / WHS +0.139 ns | valid pass; better hold, not promoted |
| `impl189_impl136_foldexmem0_routeAdvancedSkewModeling_postAggressive_cpu50` | route `AdvancedSkewModeling`, post-route `AggressiveExplore` | 9923 | 6224 | 50 MHz | WNS +0.044 ns / WHS +0.067 ns | valid pass; superseded by `impl190` |
| `impl190_impl136_foldexmem0_routeMoreGlobalIterations_postAggressive_cpu50` | route `MoreGlobalIterations`, post-route `AggressiveExplore` | 9933 | 6224 | 50 MHz | WNS +0.050 ns / WHS +0.087 ns | current best post-freeze timing candidate |
| `impl191_impl136_foldexmem0_placeExtraNet_routeMoreGlobalIterations_postAggressive_cpu50` | place `ExtraNetDelay_high`, route `MoreGlobalIterations`, post-route `AggressiveExplore` | n/a | n/a | 50 MHz target | aborted before final route; early placement estimate WNS -3.063 ns / TNS -3086.220 ns | rejected/aborted; do not cite as timing evidence |

Important distinction: the official frozen candidate remains `impl136` until a
new freeze is explicitly made. `impl190` is currently the best measured
post-freeze optimization candidate because it keeps the same strict CoreMark/MHz
and improves setup timing margin from `+0.017 ns` to `+0.050 ns`, at the cost of
38 routed LUT versus `impl136`.
## 2026-06-25 frozen best strict 50 MHz candidate

The current best strict 50 MHz exact-CoreMark-ROM routed candidate is frozen as:

| Role | Candidate | LUT | FF | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
|---|---|---:|---:|---:|---:|---:|---|---|
| Frozen best strict routed CoreMark candidate | `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017` | 9895 | 6230 | 4.287448 | 1.178213 matched xsim | 50 MHz | WNS +0.017 ns / WHS +0.155 ns | frozen best strict routed candidate; bitstream pending |

Freeze manifest:
`artifacts/strict_50m_timing_opt_20260609/FREEZE_BEST_STRICT50_IMPL136_20260625.md`.

Fresh verification on 2026-06-25:

- `impl136` timing summary reports `All user specified timing constraints are met`.
- `impl136` timing summary reports WNS `+0.017 ns`, TNS `0.000 ns`, WHS `+0.155 ns`, THS `0.000 ns`.
- `impl136` CoreMark summary reports `coremark_per_mhz=4.287448`, `crcfinal=0xfcaf`, `acceptance_pass=yes`.
- `sim136` Dhrystone summary reports `dmips_per_mhz=1.178213`.

Important: `impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004`
remains a valid latest current-RTL pass, but it is not the best frozen candidate
because it is lower at `4.207950 CoreMark/MHz` and tighter at `WNS +0.004 ns`.
`impl179_impl173_routeNoTimingRelaxation_postExplore_cpu50` is incomplete and
has no final timing summary, so it is not candidate evidence.

## 2026-06-23 current-RTL strict 50 MHz routed pass

The current dirty RTL chain was rerun with the exact timing-friendly `impl161`
configuration after rejecting and rolling back the failed branch-fold restore
gate experiment. The new archived result is:

| Role | Candidate | LUT | FF | CoreMark/MHz | Clock | Timing | Status |
|---|---|---:|---:|---:|---:|---|---|
| Latest current-RTL routed PASS candidate | `impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004` | 10662 | 6245 | 4.207950 | 50 MHz | WNS +0.004 ns / WHS +0.088 ns | accepted current-RTL strict exact-ROM routed evidence; bitstream skipped |

Evidence archive:
`artifacts/strict_50m_timing_opt_20260609/impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004`.

Important distinction: `impl173` satisfies the current hard gates
(`50 MHz`, timing closed, `CoreMark/MHz >= 4.15`, `LUT < 15000`), but
`impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017`
remains the best historical strict routed CoreMark reference at
`4.287448 CoreMark/MHz`.

## 2026-06-23 current-RTL implementation-only follow-up

After `impl173`, implementation-only checks were run to see whether the latest
current-RTL pass could gain timing margin without RTL changes.

| Candidate | Source | Technique | LUT | FF | Clock | Timing | Decision |
|---|---|---|---:|---:|---:|---|---|
| `impl174_impl173_postAggressiveExplore_cpu50` | `impl173` routed DCP | Reopen routed DCP and run post-route `phys_opt_design -directive AggressiveExplore` | 10662 | 6245 | 50 MHz | WNS +0.004 ns / WHS +0.088 ns | valid no-op; unchanged from `impl173`; not promoted |
| `impl175_impl173_routeHigherDelayCost_postAggressive_cpu50` | `impl173` synth DCP | Rerun route `HigherDelayCost` plus post-route `AggressiveExplore` | 10662 | 6245 | 50 MHz | WNS +0.004 ns / WHS +0.088 ns | valid reproduction; unchanged from `impl173`; not promoted |
| `impl176_aborted_forcefanout64_nomatch` | `impl173` synth DCP | Try `FORCE_MAX_FANOUT=64` on candidate high-fanout redirect-cache names | n/a | n/a | 50 MHz target | no routed result | aborted; zero target nets matched, no valid effect |
| `impl177_aborted_force_repl_option_conflict` | `impl173` synth DCP | Try `phys_opt_design -directive Explore -force_replication_on_nets ...` | n/a | n/a | 50 MHz target | no routed result | aborted; Vivado rejects combining `-directive` with `-force_replication_on_nets` |
| `impl178_impl173_force_repl_nodirective_cpu50` | `impl173` synth DCP | Force replication on five matched high-fanout nets without a directive | n/a | n/a | 50 MHz target | pre-route worsened to WNS -1.075 ns / TNS -73.506 ns; route intermediate WHS -0.081 ns | rejected and killed; broad manual replication is harmful here |

Decision: `impl173` remains the latest current-RTL strict 50 MHz routed pass.
`impl174` and `impl175` reproduce the same timing but do not improve it.
`impl176` through `impl178` should not be repeated as candidate flows. In
particular, manual forced replication created 29 extra instances in `impl178`
and worsened both setup and hold behavior before route could complete.

## 2026-06-22 impl136 route-only sweep update

Six route/phys-opt-only sweeps were run from the archived `impl136` strict exact-ROM synth DCP to check whether implementation directives alone could improve the current best 50 MHz routed margin.

| Candidate | Source DCP | Directives | LUT | FF | Clock | Timing | Decision |
|---|---|---|---:|---:|---:|---|---|
| `impl165_impl136_routeHigherDelayCost_postAggressive_cpu50` | `impl136/.../dcp/cpu50_synth.dcp` | `place Explore / phys_opt Explore / route HigherDelayCost / post_route_phys_opt AggressiveExplore` | 9895 | 6230 | 50 MHz | WNS +0.017 ns / WHS +0.155 ns | valid, but identical timing to `impl136`; not promoted |
| `impl166_impl136_routeNoTimingRelaxation_postExplore_cpu50` | `impl136/.../dcp/cpu50_synth.dcp` | `place Explore / phys_opt Explore / route NoTimingRelaxation / post_route_phys_opt Explore` | 9888 | 6230 | 50 MHz | WNS +0.014 ns / WHS +0.125 ns | valid, but slightly worse than `impl136`; not promoted |
| `impl167_impl136_routeAdvancedSkewModeling_postExplore_cpu50` | `impl136/.../dcp/cpu50_synth.dcp` | `place Explore / phys_opt Explore / route AdvancedSkewModeling / post_route_phys_opt Explore` | 9893 | 6230 | 50 MHz | WNS +0.013 ns / WHS +0.177 ns | valid, but setup margin is below `impl136`; not promoted |
| `impl168_impl136_routeMoreGlobalIterations_postExplore_cpu50` | `impl136/.../dcp/cpu50_synth.dcp` | `place Explore / phys_opt Explore / route MoreGlobalIterations / post_route_phys_opt Explore` | 9895 | 6230 | 50 MHz | WNS +0.001 ns / WHS +0.119 ns | valid, but setup margin is below `impl136`; not promoted |
| `impl169_impl136_routeAdvancedSkewModeling_postAggressive_cpu50` | `impl136/.../dcp/cpu50_synth.dcp` | `place Explore / phys_opt Explore / route AdvancedSkewModeling / post_route_phys_opt AggressiveExplore` | 9893 | 6230 | 50 MHz | WNS +0.013 ns / WHS +0.177 ns | valid, but setup margin is below `impl136`; not promoted |
| `impl170_impl136_routeMoreGlobalIterations_postAggressive_cpu50` | `impl136/.../dcp/cpu50_synth.dcp` | `place Explore / phys_opt Explore / route MoreGlobalIterations / post_route_phys_opt AggressiveExplore` | 9895 | 6230 | 50 MHz | WNS +0.001 ns / WHS +0.119 ns | valid, but setup margin is below `impl136`; not promoted |

Conclusion: `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017` remains the best historical strict routed CoreMark candidate. All six route-only sweeps met timing with zero routing errors, but none improved the `impl136` setup margin. Meaningful margin improvement likely requires RTL path staging/decoupling of the remaining DCache/redirect-cache/front-end path.

## 2026-06-19 strict 50 MHz evidence split

Current strict evidence must be read in layers:

| Role | Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
|---|---|---:|---:|---:|---:|---|---|
| Best historical strict routed CoreMark candidate | `impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017` | 9895 | 4.287448 | 1.178213 matched xsim | 50 MHz | WNS +0.017 ns / WHS +0.155 ns | valid archived exact-ROM routed evidence; bitstream still pending |
| Latest current-RTL routed PASS candidate | `impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004` | 10662 | 4.207950 | DMIPS not rerun; use earlier current-chain matched evidence until refreshed | 50 MHz | WNS +0.004 ns / WHS +0.088 ns | valid archived exact-ROM routed evidence; very tight setup margin; bitstream skipped |
| Latest current-RTL rejected route | `impl164_rejected_wns-0p291` | 10664 | 4.207196 | not rerun | 50 MHz | WNS -0.291 ns / WHS +0.028 ns | rejected; 101 setup failing endpoints |

Important:

- Do not replace the better historical `impl136` evidence with `impl161` when reporting "best known strict routed CoreMark". `impl136` remains the higher CoreMark/MHz timing-closed reference.
- Use `impl173` only as the latest timing-closed point on the current dirty RTL experiment chain. Its evidence is `artifacts/strict_50m_timing_opt_20260609/impl173_current_impl161cfg_exact_foldblock_iter10_routeHigherDelayCost_cpu50_wns+0p004`.
- Use `impl164_rejected_wns-0p291` only as rejected evidence. Its archive is `artifacts/strict_50m_timing_opt_20260609/impl164_rejected_wns-0p291`.
- The live `project/reports` directory is a scratch area and may contain stale or overwritten reports. Cite archived artifact paths for any baseline claim.
- The CoreMark summaries are short reproducible full-workload gates and record `strict_eembc_10s_compliant=no`. They are acceptable for engineering comparison, but not public EEMBC 10-second compliance evidence.

Next optimization should use archived DCPs for quick implementation sweeps before making more RTL changes. For performance-oriented work, start from `impl136` because it is the higher-score timing-closed reference. For the current dirty RTL chain, start from `impl161` and do route/phys-opt-only sweeps; do not promote `impl164`.

## 2026-06-17 optimization and handoff update

Current reportable baseline is unchanged: `impl136` remains the CoreMark-best
strict exact-ROM 50 MHz routed candidate under 10000 LUT. This update adds one
rejected optimization batch and a handoff document:

- `artifacts/strict_50m_timing_opt_20260609/HANDOFF_20260617.md`
- `artifacts/strict_50m_timing_opt_20260609/fast137_lightfold_rc512_tagtrim_xor1_iter10/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/fast140_lightfold_rc256_tagtrim_ntfold_fexmem0_iter10/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/synth140_lightfold_rc256_ntfold_fexmem0_reject_wns-4p466/README.md`
- `artifacts/strict_50m_timing_opt_20260609/synth140_lightfold_rc256_ntfold_fexmem0_reject_wns-4p466/SHA256SUMS.txt`

Latest strict exploration results:

| Experiment | CoreMark/MHz | LUT | Clock | Timing | Decision |
|---|---:|---:|---:|---|---|
| `fast137_lightfold_rc512_tagtrim_xor1_iter10` | 4.285487 | n/a | xsim | n/a | rejected; lower than `impl136`, no synth run |
| `fast140_lightfold_rc256_tagtrim_ntfold_fexmem0_iter10` | 4.315138 | n/a | xsim | n/a | promoted to synth audit |
| `synth140_lightfold_rc256_ntfold_fexmem0_reject_wns-4p466` | 4.315138 matched fast gate | 9035 synth Slice LUTs / 8115 LUT as Logic | 50 MHz | synth WNS -4.466 ns / WHS +0.132 ns | rejected; no implementation run |

Conclusion: not-taken fold remains the only nearby higher-CoreMark direction,
but the current same-cycle structure is still timing-prohibitive. Disabling
`ENABLE_FOLD_EXMEM_LOAD_USE_SPEC` did not rescue timing. Any future not-taken
fold work should retime or decouple the fold request/next-cache lookup so
DCache/MEM state cannot feed IF/ID instruction or PC selection in the same
cycle.

## 2026-06-14 strict 50 MHz exact-ROM route-directive update

Current strict 50 MHz candidates under the 10000 LUT limit:

| Role | LUT | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
|---|---:|---:|---:|---:|---|---|
| Current CoreMark-best strict exact-ROM routed candidate | 9895 post-route Slice LUTs / 8559 LUT as Logic | 4.287448 | 1.178213 matched xsim | 50 MHz | WNS +0.017 ns / WHS +0.155 ns | `impl136`; accepted routed DCP candidate; bitstream pending |
| Lower-LUT light-fold strict exact-ROM candidate | 8809 post-route Slice LUTs / 7857 LUT as Logic | 4.257776 | pending matched xsim | 50 MHz | WNS +0.022 ns / WHS +0.055 ns | `impl130`; valid routed DCP candidate; bitstream pending |
| Current bitstream-backed strict exact-ROM candidate | 9694 post-route Slice LUTs / 8454 LUT as Logic | 4.216239 | 2.506614 matched xsim | 50 MHz | WNS +0.022 ns / WHS +0.041 ns | `impl104`; accepted implementation+bitstream candidate; not board-proven |
| Area/timing strict exact-ROM candidate | 9105 post-route Slice LUTs / 7865 LUT as Logic | 4.207986 | 2.506614 matched xsim | 50 MHz | WNS +0.152 ns / WHS +0.106 ns | `impl115`; valid implementation candidate; bitstream pending |
| Strict 50 MHz exact-CoreMark-ROM timing-margin fallback | 6451 post-route Slice LUTs / 6059 LUT as Logic | 4.151598 | 2.484735 matched xsim | 50 MHz | WNS +0.341 ns / WHS +0.075 ns | valid lower-score fallback; not board-proven |

New evidence added in this update:

- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/README.md`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/fast134/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/logs/vivado_impl_from_synth.log`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_timing_setup_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_timing_hold_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/reports/cpu50/impl_route_status.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50_wns+0p017/dcp/cpu50_impl.dcp`
- `artifacts/strict_50m_timing_opt_20260609/sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/README.md`
- `artifacts/strict_50m_timing_opt_20260609/sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim_runs1000.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim_runs1000.log`
- `artifacts/strict_50m_timing_opt_20260609/sim136_dhrystone_impl136_lightfold_rc512_tagtrim_match/dhrystone_impl136_lightfold_rc512_tagtrim.dump`
- `artifacts/strict_50m_timing_opt_20260609/impl135_lightfold_rc512_tagtrim_placeExtraNet_routeNoRelax_cpu50_reject_wns-0p123/README.md`
- `artifacts/strict_50m_timing_opt_20260609/impl135_lightfold_rc512_tagtrim_placeExtraNet_routeNoRelax_cpu50_reject_wns-0p123/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/README.md`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/fast130_exact/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/fast130_exact/coremark50_fast_gate_iter10.log`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/logs/vivado_pynq_z2_synth.log`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/logs/vivado_impl_from_synth.log`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/reports/cpu50/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/reports/cpu50/impl_timing_setup_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/reports/cpu50/impl_timing_hold_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/reports/cpu50/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl130_lightfold_cpu50_wns+0p022/dcp/cpu50_impl.dcp`
- `artifacts/strict_50m_timing_opt_20260609/synth132_lightfold_rc512_ntfold_cpu50_reject_lut11226_wns-5p071/README.md`
- `artifacts/strict_50m_timing_opt_20260609/synth132_lightfold_rc512_ntfold_cpu50_reject_lut11226_wns-5p071/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/synth131_lightfold_rc512_cpu50_reject_lut10432/README.md`
- `artifacts/strict_50m_timing_opt_20260609/synth131_lightfold_rc512_cpu50_reject_lut10432/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/synth133_lightfold_rc256_ntfold_cpu50_reject_wns-3p084/README.md`
- `artifacts/strict_50m_timing_opt_20260609/synth133_lightfold_rc256_ntfold_cpu50_reject_wns-3p084/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/README.md`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/fast120_exact/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/fast120_exact/coremark50_fast_gate_iter10.log`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/logs/vivado_pynq_z2_impl.log`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/reports/cpu50/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/reports/cpu50/impl_timing_setup_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/reports/cpu50/impl_timing_hold_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/reports/cpu50/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl115_bhtdirect_cpu50_wns+0p152/dcp/cpu50_impl.dcp`
- `artifacts/strict_50m_timing_opt_20260609/sim115_dhrystone_impl115_bhtdirect_match/README.md`
- `artifacts/strict_50m_timing_opt_20260609/sim115_dhrystone_impl115_bhtdirect_match/dhrystone_impl115_bhtdirect_runs1000.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/sim115_dhrystone_impl115_bhtdirect_match/dhrystone_impl115_bhtdirect_runs1000.log`
- `artifacts/strict_50m_timing_opt_20260609/sim115_dhrystone_impl115_bhtdirect_match/dhrystone_impl115_bhtdirect.dump`
- `artifacts/strict_50m_timing_opt_20260609/impl122_highfold_direct_cpu50_abort/README.md`

Strict evidence checks:

- Vivado synthesis log for `impl136` is inherited from the same strict exact-ROM `impl134` synthesis DCP and binds `ROM_INIT_HEX=.../coremark50_fast_gate_iter10.hex`.
- Vivado synthesis log for `impl136` is inherited from the same strict exact-ROM `impl134` synthesis DCP and binds `ROM_INIT_MEM32_HEX=.../coremark50_fast_gate_iter10.mem32.hex`.
- Vivado synthesis log for `impl136` records `ROM_BYTES=65536` and `RAM_BYTES=65536`.
- Vivado synthesis log for `impl136` confirms `$readmem ... coremark50_fast_gate_iter10.mem32.hex is read successfully`.
- Vivado final `report_timing_summary` for `impl136` shows `All user specified timing constraints are met`, `WNS +0.017 ns`, and `WHS +0.155 ns`.
- Matched fast-gate result for `impl136` reuses the same RTL/config evidence as `impl134`: `4.287448 CoreMark/MHz`, `crcfinal=0xfcaf`, `completion_cycles=2373958`, `acceptance_pass=yes`.
- Matched Dhrystone xsim result for `impl136`: `1.178213 DMIPS/MHz`, `207012 Dhrystones/s`, `completion_cycles=527080`, 1000 runs.
- `impl136` bitstream, PROGRAM_OK, UART capture, and board video evidence are still pending.
- `impl135` is rejected: it completed route with 0 routing errors but final timing failed at `WNS -0.123 ns / WHS +0.086 ns`.
- Vivado synthesis log for `impl130` binds `ROM_INIT_HEX=.../coremark50_fast_gate_iter10.hex`.
- Vivado synthesis log for `impl130` binds `ROM_INIT_MEM32_HEX=.../coremark50_fast_gate_iter10.mem32.hex`.
- Vivado synthesis log for `impl130` records `ROM_BYTES=65536` and `RAM_BYTES=65536`.
- Vivado synthesis log for `impl130` confirms `$readmem ... coremark50_fast_gate_iter10.mem32.hex is read successfully`.
- Vivado final `report_timing_summary` for `impl130` shows `All user specified timing constraints are met`, `WNS +0.022 ns`, and `WHS +0.055 ns`.
- Matched fast-gate result for `impl130`: `4.257776 CoreMark/MHz`, `crcfinal=0xfcaf`, `completion_cycles=2390364`, `acceptance_pass=yes`.
- `impl130` Dhrystone, bitstream, PROGRAM_OK, UART capture, and board video evidence are still pending.
- Do not promote the raw `synth131_lightfold_rc512_cpu50_reject_lut10432` result despite its `4.287448 CoreMark/MHz` score; that build is rejected under the current area rule at `10432 Slice LUTs`. The accepted RC512 path is now `impl136`, which adds strict ROM-window redirect-cache tag trimming and closes route under 10000 LUT.
- Do not promote `fast132_lightfold_rc512_ntfold_iter10` despite its `4.352646 CoreMark/MHz` score. The matching CPU50 synthesis is rejected at `11226 Slice LUTs` and `WNS -5.071 ns`.
- Do not promote `fast133_lightfold_rc256_ntfold_iter10` despite its `4.315138 CoreMark/MHz` score. The matching CPU50 synthesis stays under 10000 LUT at `9591 Slice LUTs`, but fails synthesis timing at `WNS -3.084 ns`.
- Do not promote `fast140_lightfold_rc256_tagtrim_ntfold_fexmem0_iter10` despite its `4.315138 CoreMark/MHz` score. The matching CPU50 synthesis stays under 10000 LUT at `9035 Slice LUTs`, but fails synthesis timing at `WNS -4.466 ns`.
- Vivado implementation log for `impl115` binds `ROM_INIT_HEX=.../coremark50_fast_gate_iter10.hex`.
- Vivado implementation log for `impl115` binds `ROM_INIT_MEM32_HEX=.../coremark50_fast_gate_iter10.mem32.hex`.
- Vivado implementation log for `impl115` records `ROM_BYTES=65536` and `RAM_BYTES=65536`.
- Vivado implementation log for `impl115` confirms `$readmem ... coremark50_fast_gate_iter10.mem32.hex is read successfully`.
- Vivado final `report_timing_summary` for `impl115` shows `All user specified timing constraints are met`, `WNS +0.152 ns`, and `WHS +0.106 ns`.
- Matched fast-gate result for `impl115`: `4.207986 CoreMark/MHz`, `crcfinal=0xfcaf`, `completion_cycles=2418360`, `acceptance_pass=yes`.
- Matched Dhrystone xsim result for `impl115`: `2.506614 DMIPS/MHz`, `440412 Dhrystones/s`, `completion_cycles=270147`, 1000 runs.
- No CoreMark algorithm source file was modified.
- The CoreMark evidence is a short reproducible full-workload fast gate, not a strict EEMBC 10-second run.
- DMIPS/MHz for `impl115` may be reported only as matched simulation evidence; do not describe it as board UART evidence.
- Bitstream, PROGRAM_OK, UART capture, and board video evidence are still pending.
- The earlier `fast115`/`fast121` high-fold direct-update fast-gate score
  (`4.703802` to `4.716581 CoreMark/MHz`) must not be paired with `impl115`.
  The high-fold implementation attempt was rejected: synth LUT is `11916`, synth
  WNS is `-11.416 ns`, and route stayed far negative before the run was stopped.

Key optimization:

- `impl136` keeps the `impl134` redirect-cache ROM-window tag trim and changes only route implementation effort to `route_design -directive HigherDelayCost`.
- Compared with `impl134`, post-route timing improves from `WNS +0.001 ns / WHS +0.119 ns` to `WNS +0.017 ns / WHS +0.155 ns`; LUT changes from `9892` to `9895`.
- Redirect-cache tag trimming passes `ROM_BASE` and `ROM_BYTES` into the CPU so strict CoreMark `ROM_BYTES=65536` can compare only `PC[15:11]` for RC512 instead of storing the full `PC[31:11]` tag.
- `impl130` adds `ENABLE_ID_BRANCH_FOLD_LIGHT_DECODE=1` and keeps taken branch fold enabled.
- In light-fold mode, the fold target path bypasses the full `u_fold_target_id_stage` decoder and decodes only a safe LUI/AUIPC/base ALU subset. Unsupported fold targets execute through the normal decode path.
- This removes the previous full-decoder fan-in from the branch-fold timing path. The remaining worst routed path is still MEM-address to front-end PC select through redirect-cache PC RAM, but it closes at 50 MHz.
- `synth133` confirms that enabling not-taken fold reintroduces a DCache/MEM-to-front-end path through `id_branch_not_taken_fold_candidate`; do not enable this feature in the current strict timing baseline.
- `synth140` confirms that disabling fold EX/MEM load-use forwarding is not sufficient to make not-taken fold timing-safe. The next viable version must structurally register or decouple not-taken fold from same-cycle IF/ID instruction and PC selection.
- `impl115` keeps the strict exact-ROM `impl104` fold-off family and adds `BRANCH_BHT_DIRECT_UPDATE=1`.
- With `BRANCH_BHT_STRONG_ONLY=1`, direct update writes `2'b11` for taken and `2'b00` for not-taken instead of saturating the old 2-bit counter value.
- This removes BHT counter read/add/sub logic from the update path. In the fold-off strict implementation, the main benefit is area/timing margin rather than CoreMark speed.
- Compared with `impl104`, post-route LUT drops from `9694` to `9105`; timing margin improves from `WNS +0.022 ns / WHS +0.041 ns` to `WNS +0.152 ns / WHS +0.106 ns`; matched CoreMark changes from `4.216239` to `4.207986`.

Next required gates:

- Treat `impl136` as the current CoreMark-best strict 50 MHz exact-ROM routed candidate under 10000 LUT.
- Keep `impl104` as the current bitstream-backed strict candidate until an `impl136` bitstream is generated.
- Generate an `impl136` bitstream only after final review of the current evidence; board UART/video evidence is still pending.
- If continuing optimization, preserve the light-fold/tag-trim structure and target the remaining route-dominated DCache/load-data/redirect-cache/front-end PC path.

## 2026-06-13 strict 50 MHz exact-ROM optimization update

This section is superseded by the 2026-06-14 `impl136` route-directive result.

## 2026-06-12 previous strict 50 MHz exact-ROM timing-closed candidate

Previous strict 50 MHz candidate before the 2026-06-13 `impl115` direct-update result:

| Role | LUT | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
|---|---:|---:|---:|---:|---|---|
| Current strict 50 MHz exact-CoreMark-ROM high-score candidate | 9694 post-route Slice LUTs / 8454 LUT as Logic | 4.216239 | 2.506614 matched xsim | 50 MHz | WNS +0.022 ns / WHS +0.041 ns | accepted implementation+bitstream candidate; not board-proven |
| Previous strict 50 MHz exact-CoreMark-ROM high-score candidate | 9884 post-route Slice LUTs / 8644 LUT as Logic | 4.209252 | 2.506614 matched xsim | 50 MHz | WNS +0.032 ns / WHS +0.033 ns | superseded by `impl104`; still valid evidence |
| Strict 50 MHz exact-CoreMark-ROM timing-margin fallback | 6451 post-route Slice LUTs / 6059 LUT as Logic | 4.151598 | 2.484735 matched xsim | 50 MHz | WNS +0.341 ns / WHS +0.075 ns | valid lower-score fallback; not board-proven |

Current evidence package:

- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/README.md`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/coremark50_fast_gate_iter10.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/coremark50_fast_gate_iter10.log`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/vivado_pynq_z2_impl.log`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl_timing_setup_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl_timing_hold_top20.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl_route_status.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl_methodology.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_impl.dcp`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl104.bit`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/bitstream_from_dcp_timing_summary.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/bitstream_from_dcp_utilization.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/bitstream_from_dcp_drc.rpt`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/vivado_write_bitstream_impl104.log`
- `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/SHA256SUMS.txt`
- `artifacts/strict_50m_timing_opt_20260609/sim104_dhrystone_impl104_rc512_dynbht64_strong1_static1_match/README.md`
- `artifacts/strict_50m_timing_opt_20260609/sim104_dhrystone_impl104_rc512_dynbht64_strong1_static1_match/dhrystone_impl104_rc512_dynbht64_strong1_static1_runs1000.summary.txt`
- `artifacts/strict_50m_timing_opt_20260609/sim104_dhrystone_impl104_rc512_dynbht64_strong1_static1_match/dhrystone_impl104_rc512_dynbht64_strong1_static1_runs1000.log`
- `artifacts/strict_50m_timing_opt_20260609/sim104_dhrystone_impl104_rc512_dynbht64_strong1_static1_match/dhrystone_impl104_rc512_dynbht64_strong1_static1.dump`
- `artifacts/strict_50m_timing_opt_20260609/sim104_dhrystone_impl104_rc512_dynbht64_strong1_static1_match/SHA256SUMS.txt`

Strict evidence checks:

- Vivado implementation log for `impl104` binds `ROM_INIT_HEX=.../coremark50_fast_gate_iter10.hex`.
- Vivado implementation log for `impl104` binds `ROM_INIT_MEM32_HEX=.../coremark50_fast_gate_iter10.mem32.hex`.
- Vivado implementation log for `impl104` records `ROM_BYTES=65536` and `RAM_BYTES=65536`.
- Vivado implementation log for `impl104` confirms `$readmem ... coremark50_fast_gate_iter10.mem32.hex is read successfully`.
- Vivado final `report_timing_summary` for `impl104` shows `WNS +0.022 ns / WHS +0.041 ns` with 0 setup/hold failing endpoints.
- Bitstream generation from the archived `impl104` routed checkpoint completed with DRC 0 errors and `Bitgen Completed Successfully`.
- Post-checkpoint timing for `impl104` remains `WNS +0.022 ns / WHS +0.041 ns`.
- Fast-gate result for `impl104`: `4.216239 CoreMark/MHz`, `crcfinal=0xfcaf`, `completion_cycles=2413734`, `acceptance_pass=yes`.
- Matched Dhrystone xsim result for `impl104`: `2.506614 DMIPS/MHz`, `440412 Dhrystones/s`, `completion_cycles=270147`, 1000 runs.
- The CoreMark evidence is a short reproducible full-workload fast gate, not a strict EEMBC 10-second run.
- DMIPS/MHz for `impl104` may be reported only as matched simulation evidence from `sim104_dhrystone_impl104_rc512_dynbht64_strong1_static1_match`; do not describe it as board UART evidence.
- No CoreMark algorithm source file was modified.

Key correction:

- `impl92_impl74_rc256_exactrom_cpu50_wns+0p115` and `impl93_impl92_rc512_exactrom_cpu50_wns+0p001` are no longer accepted as strict exact-ROM evidence. Their Vivado implementation logs bind `V:/project/YH_rv_cpu/build/sw/coremark50_fast_gate_iter10.mem32.hex` and report `CRITICAL WARNING: [Synth 8-4445] could not open $readmem data file ...`; treat them as historical timing experiments only.
- Fast-gate results such as `fast93_impl92_rc512_iter10` and `fast101_impl93_rc512_dynbht64_static1_iter10` are software/simulation exploration records and cannot repair an implementation log with a failed ROM read.
- `impl60_rcache_raw_lookup_cpu50_wns+0p301` remains demoted from strict reporting. Its implementation log binds `YH_rv_cpu_demo.hex` / `YH_rv_cpu_demo.mem32.hex`, with `ROM_BYTES=8192` and `RAM_BYTES=8192`.
- The valid implementation must match the fast-gate CoreMark ISA generics: `ZMMUL=1`, `BITMANIP=1`, `ZBC=1`, `ZICOND=1`, `XTHEAD=1`, `XTHEAD_MUL=1`, `XTHEAD_COND_MOVE=1`, with `ZBKB=0`, `XTHEAD_CRC=0`, `XTHEAD_MEMPAIR=0`, and `XTHEAD_BASE_UPDATE=0`.

Key optimization:

- `impl104` keeps the valid `impl101` strict exact-ROM family and adds `BRANCH_BHT_STRONG_ONLY=1`.
- This improves exact-ROM CoreMark/MHz from `4.209252` to `4.216239` and reduces post-route Slice LUTs from `9884` to `9694`.
- Timing margin changes from `WNS +0.032 ns / WHS +0.033 ns` to `WNS +0.022 ns / WHS +0.041 ns`; the setup margin is smaller but still positive at 50 MHz.
- `impl100` remains rejected: RC1024+BHT64 reached `4.212713 CoreMark/MHz` but failed exact-ROM implementation timing at `WNS -0.939 ns`.
- `impl102` remains rejected: RC512+BHT32 with valid exact-ROM read reached `4.210018 CoreMark/MHz` but failed timing at `WNS -0.132 ns`.
- `impl74` remains the strict readmem-success timing-margin fallback: `4.151598 CoreMark/MHz`, `WNS +0.341 ns`, generated bitstream.

Comparison to previous strict 50 MHz candidates:

| Candidate | LUT | CoreMark/MHz | Clock | WNS | WHS | Decision |
|---|---:|---:|---:|---:|---:|---|
| `impl60_rcache_raw_lookup_cpu50_wns+0p301` | 6255 | 4.151598 fast-gate only | 50 MHz | +0.301 ns | +0.104 ns | rejected for strict exact-ROM reporting; demo ROM / 8KiB ROM-RAM |
| `impl74_exblock_nodcache_luspec_exactrom_cpu50_wns+0p341` | 6451 Slice LUTs | 4.151598 | 50 MHz | +0.341 ns | +0.075 ns | strict readmem-success timing-margin fallback; bitstream exists |
| `impl92_impl74_rc256_exactrom_cpu50_wns+0p115` | 6802 Slice LUTs | 4.184162 fast-gate history | 50 MHz | +0.115 ns | +0.055 ns | rejected for strict reporting; implementation log has readmem open warning |
| `impl93_impl92_rc512_exactrom_cpu50_wns+0p001` | 8400 Slice LUTs | 4.205819 fast-gate history | 50 MHz | +0.001 ns | +0.056 ns | rejected for strict reporting; implementation log has readmem open warning |
| `impl100_rc1024_dynbht64_static1_exactrom_cpu50_wns-0p939` | 11933 Slice LUTs | 4.212713 | 50 MHz | -0.939 ns | +0.030 ns | rejected; exact-ROM timing failed |
| `impl101_rc512_dynbht64_static1_exactrom_cpu50_wns+0p032` | 9884 Slice LUTs | 4.209252 | 50 MHz | +0.032 ns | +0.033 ns | valid strict candidate; superseded by `impl104` |
| `impl102_rc512_dynbht32_static1_exactrom_cpu50_wns-0p132` | 9134 Slice LUTs | 4.210018 | 50 MHz | -0.132 ns | +0.119 ns | rejected; exact-ROM timing failed |
| `impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022` | 9694 Slice LUTs | 4.216239 | 50 MHz | +0.022 ns | +0.041 ns | previous recommended strict candidate; bitstream generated |

Next gates recorded before the 2026-06-13 `impl115` update:

- Run PROGRAM_OK and UART capture on PYNQ-Z2 using `artifacts/strict_50m_timing_opt_20260609/impl104_rc512_dynbht64_strong1_static1_exactrom_cpu50_wns+0p022/impl104.bit`.
- Capture board video evidence.
- Keep `impl74` ready as the strict readmem-success 50 MHz timing-margin fallback if the `impl104` +0.022 ns setup margin is considered too tight on board.
- Optional: rerun Dhrystone on board UART if final reporting requires board-level DMIPS evidence.

## 2026-06-09 authoritative baseline cleanup

Current accepted baseline for honest reporting:

| Role | LUT | CoreMark/MHz | DMIPS/MHz | Clock | Timing | Status |
|---|---:|---:|---:|---:|---|---|
| Board-facing fallback baseline | 6791 post-route | 4.501191 | 1.205669 | 25 MHz | WNS +0.291 ns / WHS +0.065 ns | accepted timing-closed baseline |
| Best recorded timing-closed successor candidate | 7473 post-route | 4.741458 | 1.205669 | 25 MHz | WNS +1.348 ns / WHS +0.041 ns | candidate; not board-proven |

Strict 50 MHz status at cleanup time, now superseded by the 2026-06-12 `impl104` result:

- At that time no accepted strict 50 MHz timing-closed CoreMark-ROM baseline existed in the evidence set.
- The exact 50 MHz CoreMark-ROM audit reached `11182 LUT / 5.162186 CoreMark/MHz short-run`, but failed implementation timing at `WNS -5.800 ns`; it is rejected for freeze.
- The historical `5918 LUT / 5.162186 CoreMark/MHz / WNS +0.358 ns` result was a demo/default-ROM timing result, not the exact CoreMark-ROM freeze build; it is not a baseline.
- The `6872 LUT / 5.023480 CoreMark/MHz` row remains an engineering reference only. Its full implementation audit failed at `7063 post-route LUT / WNS -10.360 ns`, so it is not timing-closed and not board-facing.

Allowed reporting names:

- Use `CPU25 timing-closed baseline` for `6791 LUT / 4.501191 CoreMark/MHz / 1.205669 DMIPS/MHz / 25 MHz / WNS +0.291 ns`.
- Use `CPU25 RC128 BFNext/no-ZBKB timing-closed candidate` for `7473 LUT / 4.741458 CoreMark/MHz / 1.205669 DMIPS/MHz / 25 MHz / WNS +1.348 ns`.
- Do not call any 50 MHz result a baseline until exact-ROM post-route timing closes and the evidence package records the exact ROM image, clock, utilization, timing, and benchmark summary.

Cleanup record:

- Authoritative cleanup file: `artifacts/region_baseline_6872_20260602/BASELINE_CLEANUP_20260609.md`.
- Historical results are retained as negative or exploratory evidence, but removed from the current-baseline claim path.

## 2026-06-08 strict 50 MHz CoreMark-ROM freeze audit

- Fresh audit result:
  - `artifacts/strict_50m_coremark_freeze_audit_20260608/README.md`.
  - CoreMark short-run remains `5.162186 CoreMark/MHz`, but the summary is not strict EEMBC 10-second compliant.
  - Exact PYNQ-Z2 50 MHz CoreMark-ROM implementation failed timing: `11182 post-route LUT / 3439 FF / 20 BRAM / 8 DSP / WNS -5.800 ns / WHS +0.061 ns`.
  - setup failures: `3967` endpoints, `TNS -18015.188 ns`.
  - worst setup path: `u_soc/g_shared_sync_rom.u_sync_rom/imem_rdata_r_reg_5/CLKBWRCLK -> u_soc/u_cpu/if_id_instruction_r_reg[8]/D`, `25.589 ns` data path delay, `32` logic levels.
- Decision:
  - do not freeze this exact 50 MHz CoreMark-ROM build.
  - do not use the earlier `5918 LUT / WNS +0.358 ns` demo-ROM implementation as strict CoreMark-ROM freeze evidence.
  - keep the earlier `5918` result only as historical/demo-ROM timing information.
- Historical freeze status at the 2026-06-08 audit date:
  - no version was accepted then as a strict 50 MHz timing-closed freeze baseline.
  - next candidate must be tested with the exact benchmark/application ROM image that will be reported.
  - implementation timing must be closed on that exact build before freezing.

## 2026-06-08 historical 50 MHz reconfirmation, now demoted

- Historical 50 MHz candidate was freshly reconfirmed on 2026-06-08:
  - source worktree: `D:\BaiduSyncdisk\02_icdc_workspace\.worktrees\coremark5-dmips3-20260506`.
  - branch/tag: `opt/coremark5-dmips3-20260506`, `freeze/coremark5-dmips3-20260507`.
  - commit: `9dc699a Reference freeze tag in artifact readme`.
- Reconfirmed metrics:
  - `5918 post-route LUT / 2382 FF / 4 BRAM / 15 DSP`.
  - `5.162186 CoreMark/MHz`.
  - `3.134092 DMIPS/MHz` from the frozen Dhrystone artifact.
  - PYNQ-Z2 CPU clock: `50 MHz`.
  - post-route timing: `WNS +0.358 ns`, `WHS +0.126 ns`; implementation reports zero setup/hold failing endpoints.
  - bitstream generation completed successfully.
- Fresh 2026-06-08 evidence package:
  - `artifacts/coremark5_dmips3_50m_reconfirm_20260608/README.md`.
  - `artifacts/coremark5_dmips3_50m_reconfirm_20260608/coremark5_recheck_resume_20260608.summary.txt`.
  - `artifacts/coremark5_dmips3_50m_reconfirm_20260608/impl_timing_summary.rpt`.
  - `artifacts/coremark5_dmips3_50m_reconfirm_20260608/impl_utilization.rpt`.
  - `artifacts/coremark5_dmips3_50m_reconfirm_20260608/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_reconfirm_20260608.bit`.
- 50 MHz application demo evidence:
  - demo source: `artifacts/coremark5_dmips3_50m_reconfirm_20260608/perf_demo_50m.c`.
  - workloads: CRC32, 8x8 matrix multiply, memory copy/fill, branch-heavy control flow, load-use pointer chasing.
  - xsim result: `PERF_DEMO PASS checksum=0xe727358b total_cycles=0x0002931c`.
  - completion: `185191 cycles`, `565 UART bytes`.
  - demo bitstream implementation: `WNS +0.143 ns`, `WHS +0.085 ns`.
  - demo bitstream: `artifacts/coremark5_dmips3_50m_reconfirm_20260608/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_perf_demo_20260608.bit`.
- Claim boundary:
  - CoreMark is a short reproducible full-workload run, not a strict 10-second EEMBC run.
  - Dhrystone/DMIPS is retained from the frozen 2026-05-07 artifact until the fresh Dhrystone rebuild loop is root-caused.
  - board PROGRAM_OK, UART capture, and video evidence are still pending; do not claim board-proven yet.
  - the 50 MHz application demo is simulation- and implementation-proven, but not yet board-captured.
- Correction after strict audit:
  - this historical package is not the current freeze baseline.
  - its `5918 LUT / WNS +0.358 ns` implementation evidence was for the earlier default/demo ROM build, not the exact 50 MHz CoreMark-ROM freeze audit.
  - the exact 50 MHz CoreMark-ROM implementation audit failed at `11182 LUT / WNS -5.800 ns`.
- Hard gates for later candidates:
  - FPGA clock must be `50 MHz` or higher for the main region-contest line.
  - `CoreMark/MHz >= 4.3`.
  - post-route timing must close.
  - no CoreMark core algorithm files may be modified.
- Current priority:
  - find and freeze a strict 50 MHz candidate that closes timing on the exact reported ROM image.
  - use CPU25 only as a fallback/timing-debug reference.
  - do not promote failing variants or demo-ROM-only timing results.

## 2026-06-05 frozen timing-closed CPU25 baseline

- Fallback timing-closed CPU25 baseline:
  - `6791 post-route LUT / 4.501191 CoreMark/MHz / 1.205669 DMIPS/MHz`.
  - PYNQ-Z2 CPU clock: `25 MHz` via new `USE_CLK_MMCM_25M` top-level generic.
  - implementation timing: `WNS +0.291 ns`, `WHS +0.065 ns`; Vivado reports all user timing constraints met.
  - bitstream: `project/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25.bit`.
- Freeze package:
  - `artifacts/freeze_timingclosed_cpu25_20260605/`.
  - intended freeze tag: `freeze-timingclosed-cpu25-20260605`.
- Configuration:
  - `DCache512 + RC64 + no branchfold next-cache + NT-load fold + no Zicond + no ID-branch EX-forward`.
  - timing guards: frontend DCache load-use speculation disabled, JALR/fold DCache load-use cuts enabled, EX operand frontend guard enabled.
- Evidence:
  - freeze package README: `artifacts/freeze_timingclosed_cpu25_20260605/README.md`.
  - next-step task list: `artifacts/freeze_timingclosed_cpu25_20260605/NEXT_STEPS.md`.
  - long-term optimization plan: `artifacts/freeze_timingclosed_cpu25_20260605/LONG_TERM_OPTIMIZATION_PLAN.md`.
  - detailed record: `artifacts/fpga_valid_20260518/TIMING_CLOSED_CPU25_20260605.md`.
  - implementation reports: `project/reports/pynq_z2_sysclk_8p000ns_cpu25/impl_timing_summary.rpt`, `project/reports/pynq_z2_sysclk_8p000ns_cpu25/impl_utilization.rpt`.
  - CoreMark summary: `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_exopfrontguard_foldldcut_jalrldcut_recheck_iter10_20260528.summary.txt`.
  - Dhrystone summary: `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_cpu25_timingclosed_frontguard_runs1000_20260528.summary.txt`.
- Next board evidence needed:
  - program this exact bitstream on PYNQ-Z2,
  - capture UART output and PROGRAM_OK evidence,
  - record a short video tying board output to the timing-closed bitstream.
- Performance demo program:
  - added automatic UART demo firmware `YH_rv_cpu/sw/src/perf_demo.c`.
  - build/run command: `cmd /c YH_rv_cpu\scripts\run_perf_demo.bat`.
  - xsim result: all five workloads pass and final line is `PERF_DEMO PASS checksum=0xe727358b total_cycles=0x00038add`.
  - PYNQ-Z2 demo bitstream: `artifacts/freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_perf_demo.bit`.
  - demo bitstream implementation: `6791 post-route LUT / WNS +0.291 ns / WHS +0.065 ns`.
  - evidence: `artifacts/freeze_timingclosed_cpu25_20260605/evidence/perf_demo_summary_20260605.txt` and `artifacts/freeze_timingclosed_cpu25_20260605/evidence/perf_demo_xsim_uart_20260605.log`.
  - board evidence still requires PROGRAM_OK, UART capture, and video after programming.
- Next execution batch:
  - collect board PROGRAM_OK/UART/video evidence for that demo bitstream,
  - add `BOARD_EVIDENCE.md` to the freeze package.
- Region-contest documentation update:
  - `artifacts/region_baseline_6872_20260602/REGION_SUBMISSION_STATUS_20260605.md` is superseded by the 2026-06-09 cleanup wording if present in the worktree.
  - `artifacts/region_baseline_6872_20260602/REGION_REPORT_DRAFT_CLEAN_20260609.md` provides the cleaned Chinese report/defense wording.
  - `artifacts/region_baseline_6872_20260602/BOARD_EVIDENCE_TEMPLATE.md` is ready for PROGRAM_OK/UART/video evidence.
  - Region wording now treats CPU25 as the accepted timing-closed baseline and demotes 6872 to timing-failed engineering reference.
- Long-term optimization focus:
  - RC128 CPU25 is now validated as a timing-closed optimization candidate: `7076 post-route LUT / 4.627215 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +0.514 ns / WHS +0.056 ns`.
  - the earlier RC128 Dhrystone block was traced to a Dhrystone ISA-target mismatch: the failed image emitted `th.lwib` while the CPU25 timing-cut hardware disables XThead base-update. Rebuilding Dhrystone with the existing no-auto-inc target passes 1000 runs.
  - RC128 simulation reproduction wrapper: `cmd /c YH_rv_cpu\scripts\run_cpu25_rc128_validated.bat`.
  - wrapper rerun on 2026-06-05 reproduced `4.627215 CoreMark/MHz` and `1.205669 DMIPS/MHz`; fresh summaries are under `artifacts/freeze_timingclosed_cpu25_20260605/experiments/repro_cpu25_rc128`.
  - RC128 PYNQ-Z2 implementation wrapper: `cmd /c YH_rv_cpu\scripts\build_pynq_z2_cpu25_rc128_coremark.bat impl`.
  - implementation rerun on 2026-06-05 closed timing at `7124 post-route LUT / WNS +1.881 ns / WHS +0.100 ns`; bitstream is `artifacts/freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_coremark_repro_20260605.bit`.
  - current recommended timing-robust follow-up is CPU25 RC128 BFNext/no-ZBKB timing-driven: `7473 post-route LUT / 4.741458 CoreMark/MHz / 1.205669 DMIPS/MHz / WNS +1.348 ns / WHS +0.041 ns`.
  - lower-LUT same-family alternative: `7374 post-route LUT / 4.741458 CoreMark/MHz / WNS +0.282 ns / WHS +0.062 ns`.
  - BFNext/no-ZBKB timing-driven bitstream is `artifacts/freeze_timingclosed_cpu25_20260605/YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu25_rc128_bfnext_nozbkb_timingdriven_20260606.bit`; board evidence is still pending.
  - first decide whether to replace the RC64 board-facing fallback with RC128 BFNext/no-ZBKB timing-driven,
  - then explore CPU30/CPU33 closure,
  - then structurally shorten regular redirect-cache/front-end/PC critical paths before trying to recover more CoreMark/MHz.

## 2026-06-02 historical region-contest reference selection, now demoted

- Historical region-contest engineering reference:
  - `6872 LUT / 5.023480 CoreMark/MHz / 1.275942 DMIPS/MHz`
  - configuration: `DCache512 + RC64 + no branchfold next-cache + NT-load fold + no Zicond + no ID-branch EX-forward`.
  - reason at the time: lowest recorded LUT point that kept CoreMark above 5 under quick-synth strict sync-BRAM evidence.
- Baseline package:
  - `artifacts/region_baseline_6872_20260602/`
  - use this directory as the handoff entry point for region-contest evidence, reproduction commands, and follow-up tasks.
- Evidence already available:
  - CoreMark full-workload short-run summary, CRC-clean acceptance: `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc64_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
  - Dhrystone/DMIPS summary: `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc64_nonext_nozicond_noexfwd_runs1000_20260528.summary.txt`
  - quick synthesis utilization/timing/hierarchy: `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_nonext_nozicond_noexfwd_noretiming_notiming_6872lut_20260601.rpt`
- Evidence still required before calling it a board-facing submission version:
  - full implementation timing report at 50 MHz,
  - generated bitstream,
  - board programming/UART evidence,
  - optional strict 10-second CoreMark run if a stricter benchmark-valid report is needed.
- Cleanup rule:
  do not use this 6872-LUT row as the current baseline after the 2026-06-09 cleanup. It may only be cited as a timing-failed low-resource engineering reference.

## 2026-06-02 6872 baseline implementation audit

- Exact 6872 quick-synthesis baseline was run through PYNQ-Z2 Vivado implementation.
- Result:
  - post-route utilization: `7063 LUT`.
  - post-route timing: `WNS -10.360 ns`, `WHS +0.028 ns`.
  - bitstream generation completed, but this bitstream is diagnostic only because setup timing failed.
- Worst setup path:
  - source: `u_soc/u_cpu/ex_mem_mem_addr_r_reg[3]/C`.
  - destination: `u_soc/u_cpu/pc_r_reg[30]/D`.
  - data path delay: `30.328 ns`.
  - logic levels: `41`.
- Interpretation:
  the current board-facing blocker is the same-cycle MEM/DCache/load-use/redirect-cache/front-end control fan-in into PC selection. The next optimization should shorten this hardware path while keeping CoreMark core files unchanged.
- Archived evidence:
  - `artifacts/region_baseline_6872_20260602/reports/impl_utilization_6872baseline_7063lut_wns-10p360.rpt`
  - `artifacts/region_baseline_6872_20260602/reports/impl_timing_6872baseline_7063lut_wns-10p360.rpt`
  - `artifacts/region_baseline_6872_20260602/TEST_STATUS.md`
  - `artifacts/region_baseline_6872_20260602/HANDOFF_20260602.md`
- Do not describe this baseline as timing-closed or board-proven. After the 2026-06-09 cleanup, compare accepted-reporting work against the CPU25 timing-closed baseline, and cite the 6872 row only as timing-failed reference evidence.

## 2026-06-01 historical under-8000 LUT 5+ exploration

- Historical low-resource quick-synth candidate, not current baseline:
  - `7216 LUT / 5.042742 CoreMark/MHz / 1.287490 DMIPS/MHz`
  - tag target: `freeze-strict-dcache512-rc32-next-nozicond-noretiming-notiming-7216lut-coremark5p04-20260601`
  - reason at the time: lowest recorded LUT point that kept CoreMark above 5 in quick-synth exploration. This is not the current baseline because it lacks accepted exact-ROM timing-closed implementation evidence.
- New under-8000 performance/area tradeoff:
  - `7316 LUT / 5.067602 CoreMark/MHz / 1.287490 DMIPS/MHz`
  - configuration: `DCache512 + RC64 + branchfold + no branchfold next-cache + NT-load fold + no Zicond + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim`
  - synthesis option: quick synth utilization with retiming disabled and timing-driven override disabled.
  - decision at the time: balanced low-resource exploration point. Not current baseline.
- New lowest-LUT 5+ candidate:
  - `6872 LUT / 5.023480 CoreMark/MHz / 1.275942 DMIPS/MHz`
  - configuration: `DCache512 + RC64 + no branchfold next-cache + NT-load fold + no Zicond + no ID-branch EX-forward`.
  - synthesis option: quick synth utilization with retiming disabled and timing-driven override disabled.
  - decision at the time: lowest quick-synth LUT point above 5 CoreMark/MHz. It is now demoted to engineering reference because full implementation timing failed.
- Historical under-8000 performance/area candidate:
  - `7164 LUT / 5.208729 CoreMark/MHz / 1.275942 DMIPS/MHz`
  - configuration: `DCache512 + RC128 + no branchfold next-cache + NT-load fold + no Zicond + no ID-branch EX-forward`.
  - synthesis option: quick synth utilization with retiming disabled and timing-driven override disabled.
  - decision at the time: under-8000 strict sync-BRAM performance/area exploration point. Not current baseline; full implementation timing failed.
  - full implementation check: timing-driven implementation reports `7677 LUT / WNS -11.408 ns`; recorded as timing-fail evidence only. The worst path moved from sync instruction ROM to the execute/memory address and ID/EX control network, so the next board-facing work should reduce decode/control fan-in rather than only resizing caches.
- New under-8000 high-CoreMark candidate:
  - `7853 LUT / 5.281995 CoreMark/MHz / 1.275942 DMIPS/MHz`
  - configuration: `DCache512 + RC256 + no branchfold next-cache + NT-load fold + no Zicond + no ID-branch EX-forward`.
  - synthesis option: quick synth utilization with retiming disabled and timing-driven override disabled.
  - decision at the time: high-CoreMark quick-synth exploration point below 8000 LUT. Not current baseline.
- Higher-CoreMark under-8000 performance/area tradeoff:
  - `7676 LUT / 5.106160 CoreMark/MHz / 1.261816 DMIPS/MHz`
  - configuration: `DCache256 + RC128 + branchfold next-cache + NT-load fold + no Zicond + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim`
  - synthesis option: quick synth utilization with retiming disabled and timing-driven override disabled.
  - decision at the time: higher-CoreMark quick-synth exploration point below 8000 LUT. Not current baseline.
- Full implementation timing check for the balanced 7316-LUT line:
  - configuration: `DCache512 + RC64 + no branchfold next-cache + NT-load fold + no Zicond`, with timing-driven synthesis and retiming enabled.
  - post-route utilization: `7674 LUT / 3494 FF / 20 BRAM / 8 DSP`.
  - post-route timing: `WNS -11.425 ns`, `TNS -6709.239 ns`.
  - critical path begins at the sync instruction ROM/BRAM output and ends at `u_cpu/if_id_instruction_r_reg[31]/D`.
  - decision: recorded as a timing-fail implementation artifact only. Do not use this bitstream/report as board-facing 50 MHz evidence.
- Full implementation timing check for the 7216/7377 low-LUT line:
  - configuration: `DCache512 + RC32 + branchfold next-cache + NT-load fold + no Zicond`, with timing-driven synthesis and retiming enabled.
  - synthesis utilization in this implementation run: `7377 LUT / 3229 FF / 20 BRAM / 8 DSP`.
  - post-route utilization: `7532 LUT / 3230 FF / 20 BRAM / 8 DSP`.
  - post-route timing: `WNS -12.744 ns`, `TNS -11157.795 ns`.
  - critical path begins at the sync instruction ROM/BRAM output and ends at `u_cpu/if_id_pc_r_reg[14]/CE`.
  - decision: recorded as a timing-fail implementation artifact only. The next RTL work should reduce same-cycle fetch/decode/front-end control fan-in instead of changing only Vivado switches.
- Rejected/neutral checks from the same batch:
  - `DCache512 + RC32 + no Zicond + IMEM output register`: CRC-clean but `3.988680 CoreMark/MHz`, below the initial submission and 5+ targets. This confirms that a coarse extra fetch cycle can help timing structurally but costs too much benchmark throughput.
  - `DCache512 + RC32 + no Zicond + no ID branch fold`: CRC-clean but `4.880429 CoreMark/MHz`, below the 5+ target.
  - `DCache512 + RC32 + no Zicond + no ID-branch EX-forward`: CRC-clean but `4.994062 CoreMark/MHz`, just below the 5+ target.
  - `DCache256 + RC256 + no Zicond + no ID-branch EX-forward`: CRC-clean but `4.862945 CoreMark/MHz`, showing the retained 5+ no-EX-forward family still needs DCache512 for CoreMark locality.
  - `DCache512 + RC32 + no Zicond + redirect-cache XOR index`: CRC-clean but `4.998261 CoreMark/MHz`, below the 5+ target.
  - `DCache512 + RC32 + no Zicond + fetch redirect reuse`: CRC-clean and unchanged at `5.042742 CoreMark/MHz`; no promotion because it adds a hardware option without measured benefit.
  - `DCache256 + RC128 + no Zicond + no NT-load fold`: xsim generated-C compile failed before benchmark output; no metric recorded.
  - `DCache256 + RC128 + no Zicond + redirect-cache XOR index`: CRC-clean but `5.096227 CoreMark/MHz`, lower than the retained `5.106160` point.
  - `DCache256 + RC128 + no Zicond + fetch redirect reuse`: CRC-clean and unchanged at `5.106160 CoreMark/MHz`; no promotion without benefit.
  - `DCache256 + RC128 + no Zicond + DCache next-prefetch`: CRC-clean but `5.099317 CoreMark/MHz`, lower than the retained point.
  - `DCache512 + RC32 + no Zicond + DCache next-prefetch`: CRC-clean at `5.067158 CoreMark/MHz` and `1.287501 DMIPS/MHz`, but synthesis reports `8407 LUT`, above the 8000-LUT limit.
  - `DCache512 + RC32 + no Zicond + static predict mode 1`: CRC-clean and unchanged at `5.042742 CoreMark/MHz`; no measured benefit. The latest no-retiming/no-timing-driven synth reports `7232 LUT`, 16 LUT above the 7216-LUT mode-0 baseline.
  - `DCache256 + RC128 + no Zicond + no DCache load-use speculation`: CRC-clean but `4.898993 CoreMark/MHz`, below the 5+ target.
  - `DCache512 + RC32 + no Zicond + no Zbc`: timeout at `PC=00000478`; the current compiled workload depends on Zbc, so this ISA subset cannot be trimmed.
  - `DCache512 + RC32 + no Zicond + no XThead condmove`: timeout at `PC=000004a8`; the current compiled workload depends on the XThead conditional-move path.
- New evidence:
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc32_next_nozicond_noretiming_notiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc32_next_nozicond_noretiming_notiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_nonext_nozicond_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_nonext_nozicond_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_nonext_nozicond_noretiming_notiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_nonext_nozicond_noretiming_notiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc64_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc64_nonext_nozicond_noexfwd_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_nonext_nozicond_noexfwd_noretiming_notiming_6872lut_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc64_nonext_nozicond_noexfwd_noretiming_notiming_6872lut_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_timing_dcache512_rc64_nonext_nozicond_noexfwd_noretiming_notiming_6872lut_20260601.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc128_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc128_nonext_nozicond_noexfwd_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc128_nonext_nozicond_noexfwd_noretiming_notiming_7164lut_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc128_nonext_nozicond_noexfwd_noretiming_notiming_7164lut_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_timing_dcache512_rc128_nonext_nozicond_noexfwd_noretiming_notiming_7164lut_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc128_nonext_nozicond_noexfwd_timingdriven_implrun_20260602.rpt`
  - `artifacts/fpga_valid_20260518/impl_util_dcache512_rc128_nonext_nozicond_noexfwd_timingdriven_timingfail_20260602.rpt`
  - `artifacts/fpga_valid_20260518/impl_timing_dcache512_rc128_nonext_nozicond_noexfwd_timingdriven_timingfail_20260602.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc256_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_rc256_nonext_nozicond_noexfwd_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc256_nonext_nozicond_noexfwd_noretiming_notiming_7853lut_20260602.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc256_nonext_nozicond_noexfwd_noretiming_notiming_7853lut_20260602.rpt`
  - `artifacts/fpga_valid_20260518/synth_timing_dcache512_rc256_nonext_nozicond_noexfwd_noretiming_notiming_7853lut_20260602.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_nonext_d256_rc256_nonext_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_nofold_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_noexfwd_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc64_nonext_nozicond_timingdriven_implrun_20260601.rpt`
  - `artifacts/fpga_valid_20260518/impl_util_dcache512_rc64_nonext_nozicond_timingdriven_timingfail_20260601.rpt`
  - `artifacts/fpga_valid_20260518/impl_timing_dcache512_rc64_nonext_nozicond_timingdriven_timingfail_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc32_next_nozicond_timingdriven_implrun_20260601.rpt`
  - `artifacts/fpga_valid_20260518/impl_util_dcache512_rc32_next_nozicond_timingdriven_timingfail_20260601.rpt`
  - `artifacts/fpga_valid_20260518/impl_timing_dcache512_rc32_next_nozicond_timingdriven_timingfail_20260601.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_imemout_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache256_rc128_next_nozicond_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache256_rc128_next_nozicond_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache256_rc128_next_nozicond_noretiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache256_rc128_next_nozicond_noretiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache256_rc128_next_nozicond_noretiming_notiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache256_rc128_next_nozicond_noretiming_notiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_xor1_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_fetchreuse_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_noreglookup_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_d256_rc128_next_nozicond_dnextpf_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_dnextpf_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_dnextpf_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc32_next_nozicond_dnextpf_20260601.rpt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_d512_rc32_next_nozicond_static1_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache256_rc64_ntfold_nobht_nozbkb_rctagtrim_nolspec_d256_rc128_next_nozicond_nolspec_recheck_iter10_20260528.summary.txt`

## 2026-05-31 historical selected quick-synth baseline, now demoted

- Historical selected quick-synth baseline for handoff at that time:
  - tag target: `freeze-strict-dcache512-rc32-next-nozicond-noretiming-notiming-7216lut-coremark5p04-20260601`
  - commit: `tag target`
  - LUT: `7216`
  - CoreMark/MHz: `5.042742`
  - DMIPS/MHz: `1.287490`
  - configuration: `DCache512 + RC32 + branchfold next-cache + NT-load fold + fold-rs2/rs3 read ports gated off + inactive regfile second write port disabled + no dynamic BHT + no ZBKB + no Zicond + DCache tag trim + redirect-cache tag-width trim`
  - decision at the time: selected because it kept CoreMark above 5 while cutting area to 7216 LUT. Do not use this row as the default baseline after the 2026-06-09 cleanup.
  - note: this replaces the previous 7377-LUT low-area 5+ point as the preferred main freeze. It saves 161 LUT with no measured CoreMark or DMIPS loss on the retained strict sync-BRAM evidence; only the quick synth options changed.
- Evidence:
  - `artifacts/fpga_valid_20260518/coremark_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_recheck_iter10_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache512_rc64_ntfold_nobht_nozbkb_rctagtrim_rc32_next_nozicond_runs1000_20260528.summary.txt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_nozicond_7377lut_20260531.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc32_ntfold_nobht_nozbkb_rctagtrim_foldrs23off_nord2_next_nozicond_7377lut_20260531.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_dcache512_rc32_next_nozicond_noretiming_notiming_20260601.rpt`
  - `artifacts/fpga_valid_20260518/synth_util_hier_dcache512_rc32_next_nozicond_noretiming_notiming_20260601.rpt`
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
  - note: superseded by the 7216-LUT no-Zicond/no-retiming/no-timing-driven point because performance is unchanged and area is lower.
- Historical best under-10000-LUT reference:
  - tag target: `freeze-strict-dcache1024-rc128-current-8983lut-coremark5p60-20260529`
  - LUT: `8983`
  - CoreMark/MHz: `5.608440`
  - DMIPS/MHz: `1.287490`
  - configuration: `DCache1024 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim + regfile/fold-port area trims`
  - note: historical high-score reference below 10000 LUT; not current baseline.
- Historical medium-area tradeoff:
  - LUT: `7676`
  - CoreMark/MHz: `5.106160`
  - DMIPS/MHz: `1.261816`
  - configuration: `DCache256 + RC128 + branchfold next-cache + NT-load fold + no dynamic BHT + no ZBKB + DCache tag trim + redirect-cache tag-width trim`
  - note: historical quick-synth tradeoff; not current baseline.
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
- Historical validated strict under-10000 LUT candidate, not current baseline:
  - commit: `this-commit`
  - tag: `freeze-strict-rctagtrim-9796lut-coremark5p66-20260528`
  - LUT: `9796`
  - CoreMark/MHz: `5.659572`
  - DMIPS/MHz: `1.287490`
- Historical lower-area 5+ candidate:
  - commit: `tag target`
  - tag: `freeze-strict-dcache512-rc64-nonext-foldrs23off-nord2-7596lut-coremark5p07-20260528`
  - LUT: `7596`
  - CoreMark/MHz: `5.067602`
  - DMIPS/MHz: `1.287490`
  - note: DCache512/RC64 with branch-fold next-cache disabled, fold-rs2/rs3 read-port gating, inactive regfile second write port disabled, and no Zicond now has a no-retiming/no-timing-driven quick synth at `7316 LUT / 5.067602 CoreMark/MHz / 1.287490 DMIPS/MHz`. DCache256/RC64 remains CRC-clean but drops below 5 CoreMark/MHz (`4.891219`); disabling both next-cache and NT-load fold also drops below 5 (`4.981265`).
  - latest rejected boundary: turning off the folded rs1 read port is CRC-clean but drops to `4.934412 CoreMark/MHz`; keep fold-rs1 enabled for the low-area 5+ line.
  - latest rejected capacity trim: reducing redirect cache from RC64 to RC32 is CRC-clean but drops to `4.894676 CoreMark/MHz`; keep RC64 for the low-area 5+ line.
  - latest rejected area experiment: store-hit invalidate on the DCache512/RC64/nonext line measured `8330 LUT / 4.764133 CoreMark/MHz`; it is correct but loses too much store/load locality and is not retained.
  - latest rejected DCache port trim: single tag/valid read arbitration measured `7531 LUT / 4.908619 CoreMark/MHz`; the 65-LUT saving is not worth dropping below 5.
  - latest rejected folded operand trim: disabling folded rs1 read while enabling next-cache measured `7501 LUT / 4.934412 CoreMark/MHz`; the 95-LUT saving is not worth dropping below 5.
  - latest valid capacity tradeoff: `DCache256 + RC128 + next-cache` measured `7676 LUT / 5.106160 CoreMark/MHz` in the latest no-retiming/no-timing-driven quick synth; it scores higher than the 7216-LUT line at a 460-LUT cost.
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
> Historical freeze: Method A sync BRAM PYNQ-Z2 CoreMark artifact, not the current 2026-06-09 accepted baseline

## 2026-05-14 historical Method A sync BRAM freeze

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

Boundary: this is a historical board-facing Method A synchronous Block RAM path. Earlier
async/profile higher-score artifacts remain exploration evidence and must not be
merged into this Method A score without a matching sync BRAM run. Do not use this
section as the current baseline after the 2026-06-09 cleanup.

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

Historical optimization direction was low LUT / low switching activity first,
while keeping CoreMark/MHz above the initial submission result `4.137461`. All
numbers below are retained as historical strict sync-BRAM exploration records and
must not be used as the current baseline after the 2026-06-09 cleanup.

| Candidate | LUT | CoreMark/MHz | DMIPS/MHz | Status |
|---|---:|---:|---:|---|
| DCache64 + RC64 + next | 6832 | 4.336028 | 1.166238 | Historical low-area/performance tradeoff; +138 LUT over floor candidate |
| DCache64 + RC32 + next, no Zicond, no NT-load fold | 6523 | 4.181209 | 1.166238 | New lowest verified LUT point above initial submission; trims Zicond and not-taken load fold while retaining next-cache branch fold |
| DCache64 + RC32 + next, no Zicond | 6619 | 4.181261 | 1.166238 | Previous lowest verified LUT point; disables unused Zicond hardware under the RC32/next-cache profile |
| DCache64 + RC64 + next, read-mux share RTL cleanup | 6955 | 4.336028 | TBD | Rejected; behavior unchanged but Vivado LUT increased |
| DCache64 + RC64 + next, no load-use spec | 6955 | 4.289242 | 1.149744 | Rejected; LUT increased and score decreased |
| DCache64 + RC64 + next, no Zicond | 6860 | 4.336028 | TBD | Rejected; performance unchanged and LUT increased |
| DCache64 + RC64 + next, no Zbc | TBD | timeout | TBD | Rejected; CoreMark did not complete within the simulation budget |
| DCache128 + RC32 + next | 6955 | 4.329743 | 1.208287 | Historical balanced low-area/performance candidate |
| DCache128 + RC64 + next | synth pending | 4.495875 | 1.208287 | Performance-valid but not frozen; synth did not close in the time budget |
| DCache64 + RC32 + next | 6694 | 4.181261 | 1.166238 | Historical low-area freeze candidate; above initial submission |
| DCache64 + RC32 + next, no regular lookup | TBD | 4.041588 | TBD | Rejected; below initial submission |
| DCache64 + RC32 + next, no XThead condmov | TBD | timeout | TBD | Rejected; CoreMark did not complete within the simulation budget |
| DCache64 + RC32 + next, no XThead MUL/MAC | TBD | timeout | TBD | Rejected; CoreMark did not complete within the simulation budget |
| DCache64 + RC32 + next, regfile LUTRAM/no-reset | TBD | timeout | TBD | Rejected; removing architectural register reset broke the current simulation profile |
| DCache64 + RC32 + next + word-only DCache | TBD | 3.970315 | TBD | Rejected; word-only data path hurts workload correctness/performance envelope |
| DCache64 + RC16 + next | TBD | 4.117348 | TBD | Rejected; RC16 loses too much redirect locality |
| DCache32 + RC32 + next | TBD | 4.074163 | TBD | Rejected; below initial submission |

Evidence for the historical lowest-LUT candidate:

- CoreMark summary:
  `artifacts/fpga_valid_20260518/coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_nontload_d64_rc32_next_nozicond_nontload_recheck_iter10_20260528.summary.txt`
- Dhrystone summary:
  `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_nontload_d64_rc32_next_nozicond_nontload_runs1000_20260528.summary.txt`
- Vivado synth utilization:
  `artifacts/fpga_valid_20260518/synth_util_dcache64_rc32_next_nozicond_nontload_6523lut_20260601.rpt`
- Vivado synth hierarchy:
  `artifacts/fpga_valid_20260518/synth_util_hier_dcache64_rc32_next_nozicond_nontload_6523lut_20260601.rpt`

Evidence for the previous no-Zicond low-LUT candidate:

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
- Historical tradeoff candidate evidence:
  `artifacts/fpga_valid_20260518/coremark_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc64_next_recheck_iter10_20260528.summary.txt`,
  `artifacts/fpga_valid_20260518/dhrystone_fpga_dcache64_rc64_ntfold_nobht_nozbkb_rctagtrim_d64_rc64_next_runs1000_20260528.summary.txt`,
  `artifacts/fpga_valid_20260518/synth_util_dcache64_rc64_next_loadspec_6832lut_20260601.rpt`
- Strict EEMBC 10-second compliance is still marked `no`; the result is a
  CRC-clean full workload short run for architecture exploration and report
  comparison, not an official EEMBC-published score.



