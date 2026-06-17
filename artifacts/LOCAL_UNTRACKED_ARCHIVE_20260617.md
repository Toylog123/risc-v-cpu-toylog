# Local Untracked Archive Notes - 2026-06-17

This note records the remaining untracked local files after freezing the current
CPU25 and strict-50MHz evidence packages.

These files are intentionally not part of the current accepted baseline commit.
They are kept on disk as local historical archive material, but hidden from
routine `git status` through the local `.git/info/exclude` file.

## Keep Locally, Do Not Promote As Baseline

| Path or pattern | Reason |
|---|---|
| `artifacts/fpga_valid_20260518/` | Large historical May 2026 optimization log set. Useful for archaeology, but not a current reproducible freeze package. |
| `artifacts/coremark5_dmips3_20260507/repro_20260608/` | Reproduction logs for the older CoreMark5/DMIPS3 50MHz line. This is not the current strict exact-ROM accepted baseline. |
| `artifacts/coremark5_dmips3_50m_reconfirm_20260608/` | Historical 50MHz reconfirm package. Kept as reference only because current strict CoreMark-ROM timing closure is still not accepted. |
| `artifacts/region_baseline_6872_20260602/TIMING_OPT_20260603.md` and 20260603/20260604 report files | Intermediate 6872 timing optimization archaeology. The cleaned baseline documents now supersede these records. |
| `artifacts/freeze_timingclosed_cpu25_20260605/*cpu30*` | CPU30 BFNext/no-ZBKB timing-fail exploration. Useful negative evidence, but not part of the accepted CPU25 baseline. |
| `artifacts/freeze_timingclosed_cpu25_20260605/experiments/repro_cpu25_rc128_bfnext_nozbkb_no*` | Small rejected/diagnostic variants around the selected CPU25 family. |
| `artifacts/strict_50m_timing_opt_20260609/fast*`, `impl*`, `sim*`, `synth*` untracked directories | Local matrix of strict 50MHz exploration runs. Only explicitly frozen candidates should be committed. |
| `YH_rv_cpu/scripts/*coremark5_dmips3*`, `YH_rv_cpu/scripts/*cpu30*`, `YH_rv_cpu/scripts/*nobrldspec*`, `YH_rv_cpu/scripts/*noreglookup*` | Historical or rejected experiment wrappers. Do not use for the accepted baseline without a fresh evidence package. |
| `YH_rv_cpu/tb/YH_rv_cpu_coremark_rv32_zmmul_bitmanip*.v`, `YH_rv_cpu/tb/YH_rv_cpu_dhrystone_rv32_zmmul_xthead*.v` | Older micro-variant testbench wrappers. Current baseline testbenches are already tracked. |
| `tight_setup_hold_pins.txt` | Local timing debug scratch output. |

## Local Tracked Host Tweak

`YH_rv_cpu/scripts/resolve_python.bat` is a tracked local modification on this
host. It was intentionally not committed because earlier handoff notes marked it
as unrelated. To keep routine `git status` clean while preserving the local file,
it is marked with:

```powershell
git update-index --skip-worktree -- YH_rv_cpu/scripts/resolve_python.bat
```

To inspect or resolve it later:

```powershell
git update-index --no-skip-worktree -- YH_rv_cpu/scripts/resolve_python.bat
git diff -- YH_rv_cpu/scripts/resolve_python.bat
```

## Re-enable Visibility

The archive hiding rules are local only. To inspect these files again, remove
the `2026-06-17 local historical archive cleanup` block from:

```text
D:/BaiduSyncdisk/02_icdc_workspace/.git/info/exclude
```
