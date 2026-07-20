# 分赛区答辩 PPT 草稿清单 2026-07-02

本文档记录当前 strict50 分赛区答辩 PPT 草稿。该 PPT 只作为当前 `impl220`
post-route timing-closed 工程候选的答辩材料草稿，不表示板级证据已经完成。

## 文件身份

| 项目 | 值 |
|---|---|
| PPTX | `CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx` |
| SHA256 | `54054BB497E8BBE410F426AFEA7525616FAB51CA3DC21647FF6E2D8DE5D50C10` |
| Slide count | 10 |
| Candidate | `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50` |
| Current metric line | 9965 LUT / 4.287521 CoreMark/MHz / 50 MHz / WNS +0.056 ns / WHS +0.121 ns |
| Evidence level | post-route implementation timing-closed; board evidence pending |

## QA 结果

| 检查 | 结果 |
|---|---|
| PPTX export | passed |
| Slide preview render | passed, 10 PNG previews generated in scratch workspace |
| Montage visual inspection | passed, no obvious overlap or unreadable slide |
| `slides_test.py` overflow check | passed, `Test passed. No overflow detected.` |
| Boundary wording scan | passed, DMIPS/board-proven/EEMBC terms remain in pending or prohibition context |

`slides_test.py` was run on an English temporary copy of the PPTX because the
tool hit a JSON escaping error on the original Chinese user-path. The checked
file content is the same PPTX bytes copied from this artifact.

## Slide Map

| Slide | Purpose |
|---:|---|
| 1 | Current strict50 candidate headline metrics |
| 2 | Contest requirement-to-evidence mapping |
| 3 | Five-stage CPU architecture overview |
| 4 | Why strict sync-BRAM matters |
| 5 | Timing hotspot explanation |
| 6 | Hardware and implementation optimization points |
| 7 | Current reportable impl220 result |
| 8 | Why higher fast-score rows are rejected |
| 9 | Compliance and defense boundaries |
| 10 | Board/application demo evidence plan |

## Boundaries

- Do not describe this PPT as board-proven evidence.
- Do not report a current `impl220` DMIPS/MHz value from this PPT.
- Do not describe the CoreMark result as official EEMBC 10-second compliance.
- Do not replace the current `impl220` metric line with old `4961 LUT`,
  `5918 LUT`, `6872 LUT`, or `fast201` / `synth224` timing-failed records.
