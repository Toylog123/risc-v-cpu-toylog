from __future__ import annotations

import hashlib
import os
import shutil
import zipfile
from pathlib import Path


ROOT = Path.cwd().resolve()
REGION = ROOT / "01-项目管理" / "03-提交材料" / "分赛区"
SRC_ROOT = ROOT / "YH_rv_cpu"
ART = ROOT / "artifacts" / "strict_50m_timing_opt_20260609"
FIXED_ZIP_DATE = (2026, 7, 20, 0, 0, 0)


def inside(path: Path, base: Path) -> bool:
    path = path.resolve()
    base = base.resolve()
    return path == base or base in path.parents


def require_inside(path: Path, base: Path = REGION) -> Path:
    resolved = path.resolve()
    if not inside(resolved, base.resolve()):
        raise RuntimeError(f"refusing to touch path outside {base}: {resolved}")
    return resolved


def safe_rmtree(path: Path) -> None:
    resolved = require_inside(path)
    if resolved.exists():
        shutil.rmtree(resolved)


def safe_unlink(path: Path) -> None:
    resolved = require_inside(path)
    if resolved.exists():
        if resolved.is_dir():
            raise RuntimeError(f"safe_unlink got directory: {resolved}")
        resolved.unlink()


def copytree_clean(src: Path, dst: Path) -> None:
    if not src.exists():
        raise FileNotFoundError(src)
    dst = require_inside(dst)
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(
        src,
        dst,
        ignore=shutil.ignore_patterns(
            ".git",
            ".Xil",
            "xsim.dir",
            "__pycache__",
            "*.tmp",
            "*.bak",
            "*.jou",
            "*.str",
            "*.wdb",
            "*冲突文件*",
        ),
    )


def copy_file(src: Path, dst: Path) -> None:
    if not src.exists():
        raise FileNotFoundError(src)
    dst = require_inside(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def write_text(path: Path, text: str) -> None:
    path = require_inside(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def zip_dir(source_dir: Path, zip_path: Path) -> int:
    source_dir = require_inside(source_dir)
    zip_path = require_inside(zip_path)
    if zip_path.exists():
        zip_path.unlink()
    count = 0
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for file in sorted(source_dir.rglob("*")):
            if file.is_file():
                arcname = file.relative_to(source_dir.parent).as_posix()
                info = zipfile.ZipInfo(arcname, date_time=FIXED_ZIP_DATE)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o644 << 16
                zf.writestr(info, file.read_bytes(), compresslevel=6)
                count += 1
    return count


def zip_paths(paths: list[Path], zip_path: Path, base: Path) -> int:
    zip_path = require_inside(zip_path)
    if zip_path.exists():
        zip_path.unlink()
    count = 0
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for item in paths:
            item = require_inside(item)
            if item.is_file():
                arcname = item.relative_to(base).as_posix()
                info = zipfile.ZipInfo(arcname, date_time=FIXED_ZIP_DATE)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o644 << 16
                zf.writestr(info, item.read_bytes(), compresslevel=6)
                count += 1
            elif item.is_dir():
                for file in sorted(item.rglob("*")):
                    if file.is_file():
                        arcname = file.relative_to(base).as_posix()
                        info = zipfile.ZipInfo(arcname, date_time=FIXED_ZIP_DATE)
                        info.compress_type = zipfile.ZIP_DEFLATED
                        info.external_attr = 0o644 << 16
                        zf.writestr(info, file.read_bytes(), compresslevel=6)
                        count += 1
    return count


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def clean_obsolete_submission_refs() -> None:
    for rel in [
        "技术文档/CICC1003618_分赛区决赛_技术文档_前置说明.pdf",
        "技术文档/CICC1003618_分赛区决赛_性能与验证报告_参考.pdf",
        "技术文档/CICC1003618_分赛区决赛_初赛技术说明书_参考.pdf",
        "PPT/CICC1003618_分赛区决赛_PPT_初赛版参考.pptx",
        "PPT/CICC1003618_分赛区决赛_PPT_初赛版参考.pdf",
        "PPT/CICC1003618_分赛区决赛_PPT_演讲备注版_初赛参考.pptx",
        "PPT/CICC1003618_分赛区决赛_PPT演讲备注_待更新.md",
        "PPT/CICC1003618_分赛区决赛_PPT逐页构思_待更新.md",
        "PPT/CICC1003618_分赛区决赛_PPT.pptx.inspect.ndjson",
        "技术数据/CICC1003618_分赛区决赛_性能与验证报告_技术数据参考.pdf",
        "FPGA原型系统/README_初赛证据参考.md",
    ]:
        safe_unlink(REGION / rel)
    for rel in [
        "技术数据/fpga_artifacts_pynq_z2",
        "FPGA原型系统/fpga_artifacts_pynq_z2",
    ]:
        safe_rmtree(REGION / rel)


def rebuild_source_package() -> tuple[Path, int]:
    src_parent = REGION / "源代码"
    pkg_dir = src_parent / "CICC1003618_分赛区决赛_源代码"
    zip_path = src_parent / "CICC1003618_分赛区决赛_源代码.zip"
    safe_rmtree(pkg_dir)
    pkg_dir.mkdir(parents=True, exist_ok=True)
    for name in ["rtl", "tb", "sw", "fpga", "scripts"]:
        copytree_clean(SRC_ROOT / name, pkg_dir / name)
    if (SRC_ROOT / "README.md").exists():
        copy_file(SRC_ROOT / "README.md", pkg_dir / "README.md")
    write_text(
        pkg_dir / "运行环境说明.md",
        "# 运行环境说明\n\n"
        "本源码包由主目录 `YH_rv_cpu/` 白名单目录重新生成，对应分赛区 strict50 `impl220` 口径。\n\n"
        "## 推荐工具链\n\n"
        "- Vivado 2025.2 或兼容版本，用于综合、实现、bitstream 和 Hardware Manager。\n"
        "- xsim，用于 CoreMark、Dhrystone 和 perf demo 仿真复核。\n"
        "- PowerShell，用于运行 `scripts/` 与 `artifacts/strict_50m_timing_opt_20260609/` 下的复核脚本。\n\n"
        "## 当前主证据\n\n"
        "- Candidate: `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`。\n"
        "- 指标验证脚本：`artifacts/strict_50m_timing_opt_20260609/verify_strict50_impl220_metrics.ps1`。\n"
        "- 当前为 post-route timing-closed engineering candidate；PROGRAM_OK、UART raw log 和视频仍待补。\n",
    )
    write_text(
        pkg_dir / "分赛区源码更新说明-2026-07-20.md",
        "# 分赛区源码更新说明\n\n"
        "更新时间：`2026-07-20`\n\n"
        "本目录由主工作区 `YH_rv_cpu/` 按分赛区 strict50 `impl220` 复核口径整理生成。\n\n"
        "## 本次整理原则\n\n"
        "- 保留 `rtl/`、`tb/`、`sw/`、`fpga/`、`scripts/` 和 `README.md`。\n"
        "- 不打包历史 `doc/` 目录；研发过程、指标证据和交接记录统一由分赛区技术文档、技术数据包和 `00-提交检查与清单/` 承担。\n"
        "- 补充 `run_strict50_dhrystone_impl220.bat`、`run_strict50_perf_demo.bat` 与 `YH_rv_cpu_strict50_perf_demo_tb.v`。\n"
        "- 不引入 `build/`、`xsim.dir/`、`.Xil/`、`_tmp/` 等本地生成产物。\n"
        "- 源码包与技术文档、PPT 和技术数据包统一到 `impl220`。\n\n"
        "## 证据边界\n\n"
        "当前源码支撑 `impl220` post-route timing-closed evidence；上板 PROGRAM_OK、UART raw log 和视频仍需补齐后才可称 board-proven。\n",
    )
    count = zip_dir(pkg_dir, zip_path)
    return zip_path, count


def rebuild_fpga_and_technical_data(source_zip: Path) -> tuple[Path, int]:
    fpga_dir = REGION / "FPGA原型系统"
    evidence_dir = REGION / "技术数据" / "strict50_impl220_evidence"
    safe_rmtree(evidence_dir)
    evidence_dir.mkdir(parents=True, exist_ok=True)

    strict_files = [
        "FREEZE_STRICT50_IMPL220_20260701.md",
        "REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md",
        "REGION_REQUIREMENT_MATRIX_20260702.md",
        "REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md",
        "REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md",
        "STRICT50_BOARD_EVIDENCE_AUDIT_20260702.md",
        "STRICT50_DHRYSTONE_EVIDENCE_20260702.md",
        "STRICT50_APP_DEMO_EVIDENCE_20260702.md",
        "verify_strict50_impl220_metrics.ps1",
        "audit_strict50_board_evidence.ps1",
        "audit_strict50_dhrystone_evidence.ps1",
        "audit_strict50_demo_evidence.ps1",
    ]
    for rel in strict_files:
        shutil.copy2(ART / rel, evidence_dir / rel)
    for rel in [
        "fast210_impl136cfg_bhtid0_current_iter10",
        "impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50",
        "board_impl220_bitstream_20260702",
        "sim220_dhrystone_impl220_strict50_match",
        "strict50_perf_demo_20260702",
    ]:
        src = ART / rel
        dst = evidence_dir / rel
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)

    bit_dst = fpga_dir / "strict50_impl220_bitstream"
    safe_rmtree(bit_dst)
    shutil.copytree(ART / "board_impl220_bitstream_20260702", bit_dst)
    write_text(
        fpga_dir / "README.md",
        "# FPGA 原型系统证据说明\n\n"
        "本目录当前只放置 strict50 `impl220` 的 bitstream 生成证据和 SHA256。\n\n"
        "## 当前状态\n\n"
        "- `strict50_impl220_bitstream/`：已归档 bitstream、bitstream 生成日志、timing/utilization 报告和 SHA256。\n"
        "- PROGRAM_OK、board UART raw log、board video：待补。\n"
        "- 旧初赛 PYNQ-Z2 上板证据不再放在分赛区当前主证据目录中；如需查阅，请回到 `../初赛/FPGA原型系统/`。\n\n"
        "## 边界\n\n"
        "bitstream 生成成功不等同于板级 PROGRAM_OK。补齐 PROGRAM_OK、UART raw log 和视频前，不应把 `impl220` 写成 board-proven。\n",
    )

    tech_dir = REGION / "技术数据"
    tech_source_zip = tech_dir / "CICC1003618_分赛区决赛_技术数据_源码包.zip"
    shutil.copy2(source_zip, tech_source_zip)
    write_text(
        tech_dir / "CICC1003618_分赛区决赛_技术数据说明.md",
        "# CICC1003618 分赛区决赛技术数据说明\n\n"
        "本目录用于集中保存分赛区决赛复核所需技术数据。当前技术数据统一到 strict50 `impl220` 口径。\n\n"
        "## 文件入口\n\n"
        "| 文件 | 用途 | 当前状态 |\n"
        "|---|---|---|\n"
        "| `CICC1003618_分赛区决赛_技术数据包.zip` | 统一技术数据包 | 已重新生成 |\n"
        "| `CICC1003618_分赛区决赛_技术数据_源码包.zip` | 从主目录 `YH_rv_cpu/` 白名单生成的源码包 | 已重新生成 |\n"
        "| `strict50_impl220_evidence/` | impl220 Vivado reports、CoreMark/Dhrystone/demo xsim、bitstream/SHA256、audit 脚本 | 已同步 |\n\n"
        "## 当前主指标\n\n"
        "- Candidate: `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`。\n"
        "- 资源：9965 LUT / 6520 FF / 32 BRAM Tile / 8 DSP。\n"
        "- 性能：4.287521 CoreMark/MHz；2.495618 DMIPS/MHz xsim。\n"
        "- 时序：50 MHz post-route WNS +0.056 ns / WHS +0.121 ns。\n\n"
        "## 复核建议\n\n"
        "1. 解压统一技术数据包，检查源码包和 `strict50_impl220_evidence/` 是否存在。\n"
        "2. 运行 `strict50_impl220_evidence/verify_strict50_impl220_metrics.ps1` 或主目录同名脚本复核指标。\n"
        "3. 注意当前 PROGRAM_OK、board UART raw log 和 board video 仍待补，不应把 impl220 写成 board-proven。\n",
    )
    unified_zip = tech_dir / "CICC1003618_分赛区决赛_技术数据包.zip"
    count = zip_paths(
        [
            tech_source_zip,
            tech_dir / "CICC1003618_分赛区决赛_技术数据说明.md",
            evidence_dir,
        ],
        unified_zip,
        tech_dir,
    )
    return unified_zip, count


def update_video_readme() -> None:
    video_dir = REGION / "功能演示视频"
    write_text(
        video_dir / "README.md",
        "# 功能演示视频说明\n\n"
        "分赛区要求七星微命题现场展示视频控制在 3 分钟内；若使用倍速视频，正常速度版本也需同时上传和保留。\n\n"
        "## 当前状态\n\n"
        "- 目录中现有 MP4 文件保留为历史/备份材料，上传前必须人工确认其 workload、bitstream 和口播是否与当前 `impl220` 口径一致。\n"
        "- 若视频不能绑定 `board_impl220_bitstream_20260702` 中的同一 bitstream，则不得作为 `impl220 board-proven` 证据使用。\n"
        "- 当前正式缺口仍是：PROGRAM_OK、board UART raw log、同版上板视频。\n\n"
        "## 推荐补录内容\n\n"
        "1. 展示 PYNQ-Z2、Vivado Hardware Manager PROGRAM_OK 或等效下载日志。\n"
        "2. 展示 UART 输出，CoreMark、Dhrystone 和 perf demo 输出分开说明。\n"
        "3. 现场展示版控制在 3 分钟内，另保留正常速度原始视频。\n",
    )
    write_text(
        video_dir / "CICC1003618_分赛区决赛_3分钟现场展示视频录制说明.md",
        "# CICC1003618 分赛区决赛 3 分钟现场展示视频说明\n\n"
        "本目录保留分赛区现场展示视频和正常速度备份视频。当前 MP4 文件尚未完成同版 `impl220` 绑定性人工确认。\n\n"
        "## 当前文件\n\n"
        "| 文件 | 用途 | 当前状态 |\n"
        "|---|---|---|\n"
        "| `CICC1003618_分赛区决赛_3分钟现场展示视频.mp4` | 现场展示版，需控制在 3 分钟内 | 历史/备份文件，待人工确认是否绑定 impl220 |\n"
        "| `CICC1003618_分赛区决赛_正常速度上板演示备份.mp4` | 正常速度备份文件 | 历史/备份文件，待人工确认是否绑定 impl220 |\n\n"
        "## 上传前必须确认\n\n"
        "1. 视频画面、口播和文件名不包含评分材料禁用身份标识。\n"
        "2. 视频中使用的 bitstream、workload、UART 输出和当前 `impl220` 技术文档口径一致。\n"
        "3. 如无法确认同版绑定，必须补录同一 bitstream 的 PROGRAM_OK、UART raw log、3 分钟展示视频和正常速度备份。\n",
    )
    write_text(
        video_dir / "CICC1003618_分赛区决赛_正常速度上板演示备份说明.md",
        "# CICC1003618 分赛区决赛正常速度上板演示备份说明\n\n"
        "本文件只记录正常速度备份视频的提交边界。当前备份视频不得自动视为 `impl220 board-proven` 证据。\n\n"
        "## 当前边界\n\n"
        "- 若备份视频不能人工确认绑定 `board_impl220_bitstream_20260702` 中同一 bitstream，则只能作为历史/应急备份材料。\n"
        "- 分赛区主材料当前只主张 `impl220` 为 post-route timing-closed engineering candidate。\n"
        "- 需要板级证明时，应补齐 PROGRAM_OK、board UART raw log、3 分钟展示视频和正常速度原始视频。\n\n"
        "## 人工复核项\n\n"
        "| 项目 | 完成标准 |\n"
        "|---|---|\n"
        "| 身份信息 | 画面和口播无评分材料禁用身份标识 |\n"
        "| 版本绑定 | bitstream、workload、运行结果与 `impl220` 一致 |\n"
        "| 视频留档 | 现场展示版小于 3 分钟，正常速度版同步保留 |\n",
    )


def update_root_readme() -> None:
    write_text(
        REGION / "README.md",
        "# CICC1003618 分赛区决赛提交材料\n\n"
        "本目录是分赛区决赛材料的当前权威入口，基于 `../初赛/` 材料和主目录最新 strict50 `impl220` 工程状态整理。上传和交接优先使用本目录，不再直接上传 `初赛/` 下的旧命名文件。\n\n"
        "## 当前可用材料\n\n"
        "| 类别 | 优先上传/使用文件 | 状态 |\n"
        "|---|---|---|\n"
        "| 技术文档 | `技术文档/CICC1003618_分赛区决赛_技术文档.pdf` | 已重生成，impl220 口径 |\n"
        "| 技术文档源稿 | `技术文档/CICC1003618_分赛区决赛_技术文档.md` | 已生成，便于后续修改 |\n"
        "| 答辩 PPT 主展示 | `PPT/CICC1003618_分赛区决赛_PPT.pdf` 或 `PPT/CICC1003618_分赛区决赛_PPT_纯图片版.pptx` | 已重生成，10 页 |\n"
        "| 答辩 PPT 源文件 | `PPT/CICC1003618_分赛区决赛_PPT.pptx` | 已重生成，源文件备用 |\n"
        "| 技术数据 | `技术数据/CICC1003618_分赛区决赛_技术数据包.zip` | 已重生成，含 impl220 证据 |\n"
        "| 源代码 | `源代码/CICC1003618_分赛区决赛_源代码.zip` | 已从主目录 `YH_rv_cpu/` 重生成 |\n"
        "| FPGA 原型系统 | `FPGA原型系统/strict50_impl220_bitstream/` | bitstream/SHA256 已归档；PROGRAM_OK/UART/video 待补 |\n"
        "| 演示视频 | `功能演示视频/` | 现有 MP4 需人工确认是否绑定 impl220；同版视频待补 |\n"
        "| 作品海报 | `作品海报/` | JPG/PNG 待人工制作；海报可包含团队/学校信息，评分材料不可包含 |\n\n"
        "## 当前主口径\n\n"
        "- Candidate: `impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50`。\n"
        "- 指标：9965 LUT / 6520 FF / 32 BRAM Tile / 8 DSP / 4.287521 CoreMark/MHz / 2.495618 DMIPS/MHz xsim / WNS +0.056 ns / WHS +0.121 ns。\n"
        "- 边界：当前是 post-route timing-closed engineering candidate；PROGRAM_OK、board UART raw log 和同版视频未补齐前，不称 board-proven。\n\n"
        "## 上传前检查\n\n"
        "1. 优先上传 PDF 或纯图片版 PPT 作为主展示文件，PPT 源文件作为备用。\n"
        "2. 上传后必须在线预览技术文档和答辩 PPT，检查能否打开、内容是否完整、排版是否错乱。\n"
        "3. 评分材料和比赛过程不得出现学校名称、LOGO、简称、指导老师信息或成员真实姓名；海报为活动例外材料。\n"
        "4. 若后续补齐 PROGRAM_OK/UART/video 或继续修改 RTL，需重新生成 PPT、技术文档、源码包、技术数据包和冻结哈希。\n\n"
        "## 管理记录\n\n"
        "- 要求对照：`00-提交检查与清单/01-要求对照/分赛区决赛提交要求对照-2026-07-20.md`\n"
        "- 冻结快照：`00-提交检查与清单/02-冻结快照/分赛区决赛材料冻结快照-2026-07-20.md`\n"
        "- 交接记录：`00-提交检查与清单/02-冻结快照/分赛区决赛交接记录-2026-07-20.md`\n"
        "- 证据索引：`00-提交检查与清单/03-证据索引/分赛区决赛证据索引-2026-07-20.md`\n"
        "- 敏感信息检查：`00-提交检查与清单/04-敏感信息检查/分赛区决赛敏感信息检查-2026-07-20.md`\n",
    )


def main() -> None:
    if not inside(REGION, ROOT):
        raise RuntimeError("REGION must be inside repository root")
    clean_obsolete_submission_refs()
    source_zip, source_count = rebuild_source_package()
    unified_zip, data_count = rebuild_fpga_and_technical_data(source_zip)
    update_video_readme()
    update_root_readme()
    print(f"source_zip={source_zip}")
    print(f"source_zip_entries={source_count}")
    print(f"technical_data_zip={unified_zip}")
    print(f"technical_data_entries={data_count}")
    print(f"source_zip_sha256={sha256(source_zip)}")
    print(f"technical_data_zip_sha256={sha256(unified_zip)}")


if __name__ == "__main__":
    main()
