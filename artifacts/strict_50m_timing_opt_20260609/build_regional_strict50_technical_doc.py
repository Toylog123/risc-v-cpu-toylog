from __future__ import annotations

import os
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path.cwd()
OUT_DIR = ROOT / "01-项目管理" / "03-提交材料" / "分赛区" / "技术文档"
MD_PATH = OUT_DIR / "CICC1003618_分赛区决赛_技术文档.md"
PDF_PATH = OUT_DIR / "CICC1003618_分赛区决赛_技术文档.pdf"

FONT_REGULAR_CANDIDATES = [
    Path(r"C:\Windows\Fonts\NotoSansSC-VF.ttf"),
    Path(r"C:\Windows\Fonts\msyh.ttc"),
    Path(r"C:\Windows\Fonts\Deng.ttf"),
    Path(r"C:\Windows\Fonts\simhei.ttf"),
]
FONT_BOLD_CANDIDATES = [
    Path(r"C:\Windows\Fonts\NotoSansSC-VF.ttf"),
    Path(r"C:\Windows\Fonts\msyhbd.ttc"),
    Path(r"C:\Windows\Fonts\Dengb.ttf"),
    Path(r"C:\Windows\Fonts\simhei.ttf"),
]


def pick_font(candidates: list[Path]) -> Path:
    for item in candidates:
        if item.exists():
            return item
    raise FileNotFoundError("No Chinese font found under C:\\Windows\\Fonts")


FONT_REG = pick_font(FONT_REGULAR_CANDIDATES)
FONT_BOLD = pick_font(FONT_BOLD_CANDIDATES)
pdfmetrics.registerFont(TTFont("NotoSC", str(FONT_REG)))
pdfmetrics.registerFont(TTFont("NotoSC-Bold", str(FONT_BOLD)))


def esc(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def para(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(text), style)


SECTIONS: list[tuple[str, list[str]]] = [
    (
        "作品核心内容快速预览",
        [
            "本作品面向 PYNQ-Z2 / xc7z020 FPGA 平台实现一款自研 RV32 五级流水 RISC-V CPU。处理器采用 IF、ID、EX、MEM、WB 五级流水结构，并围绕数据前递、load-use 处理、分支重定向、BHT、redirect-cache、DCache/BRAM 访问控制等路径进行性能和时序优化。",
            "分赛区主版本统一为 impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50。该候选在 strict sync-BRAM 口径下完成 50 MHz post-route timing closure，资源为 9965 Slice LUT、6520 Slice FF、32 BRAM Tile、8 DSP，CoreMark/MHz 为 4.287521，同配置 Dhrystone xsim 为 2.495618 DMIPS/MHz，post-route WNS 为 +0.056 ns，WHS 为 +0.121 ns。",
            "本技术文档只声明已经有证据支撑的实现级结论。当前 impl220 的 bitstream 和 SHA256 已归档，但 PROGRAM_OK、board UART raw log 和同版本演示视频仍待补齐，因此本文不把 impl220 表述为 board-proven。旧初赛板级证据保留为历史参考，不能替代当前 strict50 主候选。",
        ],
    ),
    (
        "设计目标与约束",
        [
            "项目目标是在 FPGA 原型系统约束下实现可复核的 RISC-V 处理器，而不是只完成理想存储模型下的仿真演示。分赛区材料采用 strict sync-BRAM 口径，即 FPGA Block RAM 的同步读延迟进入 RTL、仿真模型和 Vivado timing 约束。",
            "功能目标包括 RV32 基础整数指令路径、五级流水、寄存器堆、ALU、访存、分支跳转、SoC 集成 ROM/BRAM/UART/timer，以及 CoreMark、Dhrystone 和应用 demo 的运行链路。性能目标是在 PYNQ-Z2 上达到 50 MHz post-route timing closure，并给出 CoreMark/MHz、DMIPS/MHz xsim、资源占用和时序报告。",
            "合规约束包括不修改 CoreMark 核心算法文件，不把 timing-failed 的高分探索配置作为当前候选，不用旧初赛 board-proven 材料替代当前 impl220 的板级证据。",
        ],
    ),
    (
        "处理器微结构",
        [
            "处理器采用 IF、ID、EX、MEM、WB 五级流水组织。IF 阶段负责 PC 选择和取指；ID 阶段完成指令译码、寄存器读、立即数生成和冒险检测；EX 阶段执行 ALU、比较、分支解析和目标地址计算；MEM 阶段连接 DCache/BRAM 访问路径；WB 阶段完成寄存器堆回写。",
            "流水线控制包含 forwarding、load-use 检测、stall、flush 和 redirect。普通 RAW 数据相关通过 EX/MEM/WB 前递减少等待；load-use 场景在访存返回前不能直接使用数据，因此由 hazard 逻辑暂停或重放。分支和跳转通过 EX 阶段真实结果纠正前端取指路径。",
            "前端优化包括 BHT、redirect-cache、fold 和 next-cache 等可配置结构。这些结构可以减少控制流 workload 的前端损失，但如果与 MEM/DCache/load-use 状态在同一周期强组合耦合，会形成跨流水级长路径。当前 impl220 的设计重点是在保留有效优化的同时切断不可闭合的同周期组合扇入。",
        ],
    ),
    (
        "strict sync-BRAM 设计口径",
        [
            "FPGA Block RAM 是同步读资源，真实硬件中地址、使能和数据返回存在时钟边界。如果把存储器建模为零延迟数组，仿真分数可能偏高，但该分数难以对应综合、布局布线和上板行为。",
            "本项目在分赛区材料中坚持 strict sync-BRAM 口径，将指令 ROM、数据 BRAM/DCache 访问和相关 load-use 控制纳入同步时序。这一选择使性能结果更保守，但能与 Vivado post-route timing report 对齐，也便于后续将 bitstream、PROGRAM_OK、UART raw log 和视频证据绑定到同一工程候选。",
        ],
    ),
    (
        "关键优化与创新点",
        [
            "第一，设计把 BHT ID-update 路径配置化。ENABLE_BRANCH_BHT_ID_UPDATE 使 BHT CE 热点从固定组合扇入变成可审计开关，从而可以在性能和时序之间做单变量比较。",
            "第二，设计对 redirect-cache、fold 和 next-cache 相关路径做 timing-safe 取舍。高分同周期路径虽然能提高 fast-gate 结果，但会重新引入 DCache/MEM 到前端 PC 选择的长组合路径；当前候选只保留能够完成 strict 50 MHz implementation closure 的组合。",
            "第三，设计削减 DCache/load-use 对前端控制的同周期扇入。该策略避免 MEM 阶段状态在同一周期直接放大到 PC 或 IF/ID 选择路径，降低跨级组合逻辑深度。",
            "第四，设计配合 Vivado implementation directive 完成实现收敛。当前候选采用 opt_design -directive ExploreArea 与 route_design -directive AdvancedSkewModeling，在保持 4.287521 CoreMark/MHz 工程性能线的同时，将资源收敛到 9965 LUT 并取得正 setup/hold slack。",
        ],
    ),
    (
        "研发过程与候选冻结",
        [
            "研发过程采用证据驱动的候选筛选方式。历史探索中存在更高 fast-gate CoreMark/MHz 的配置，例如 fast201 达到 4.569338 CoreMark/MHz，但对应 synth224 在 50 MHz synthesis 下 WNS 为 -11.786 ns，不能作为 FPGA 原型系统主结果。",
            "当前候选 impl220 是在 impl200/impl218/impl219/impl222/impl223 等相邻实现结果比较后冻结的 strict50 主版本。impl223 虽然也能 closing，但 setup slack 只有 +0.003 ns 且 LUT 更高；impl222 少 1 LUT 但 WNS 仅 +0.006 ns。impl220 在 9965 LUT 下取得 +0.056 ns WNS 和 +0.121 ns WHS，因此作为当前分赛区主口径。",
            "冻结记录、指标追踪和复核脚本均保存在 artifacts/strict_50m_timing_opt_20260609/ 下，分赛区材料包将其中的关键证据同步到技术数据目录。",
        ],
    ),
    (
        "验证与实验结果",
        [
            "当前主结果由三类证据共同支撑：一是 Vivado post-route timing/utilization reports，证明 50 MHz 实现闭合和资源占用；二是 CoreMark 与 Dhrystone xsim summary，证明 benchmark 在同配置下的工程性能；三是 bitstream/SHA256 与 board evidence audit，证明 bitstream 已生成且板级证据缺口被显式记录。",
            "CoreMark 结果为工程 short-gate，CRC 为 0xfcaf，acceptance_pass=yes，strict_eembc_10s_compliant=no。该结果用于分赛区工程汇报和同配置设计迭代，不表述为官方 EEMBC 10 秒认证结果。Dhrystone 结果为 2.495618 DMIPS/MHz，来自 impl220 同配置 timer50 xsim host-parsed 证据，不表述为板级 UART 结果。",
        ],
    ),
    (
        "应用演示与视频材料计划",
        [
            "除 CoreMark 和 Dhrystone 外，当前 strict50 线准备了应用演示程序 perf demo。该 demo 覆盖 CRC32、MATMUL8、MEMCPYFILL、BRANCH 和 LOADUSE 场景，用于展示处理器对整数运算、访存、控制流和 load-use 冒险处理的综合执行能力。xsim 日志记录 PERF_DEMO PASS checksum=0xe727358b。",
            "分赛区要求视频展示跑分、运行过程和运行结果，且现场展示视频控制在 3 分钟内；若使用倍速视频，正常速度版本也需同时上传和保留。当前材料目录保留旧视频作为历史参考，但 impl220 正式板级证据仍需基于同一 bitstream 重新采集 PROGRAM_OK、UART raw log 和视频。",
        ],
    ),
    (
        "原创性、可行性与风险边界",
        [
            "原创性方面，作品的 CPU RTL、流水线控制、参数化优化、Vivado 实现流程脚本和证据整理均来自本项目 YH_rv_cpu 线。当前优化集中在硬件 RTL、参数配置和实现流程，不通过修改 CoreMark 核心算法文件提高分数。",
            "可行性方面，impl220 已完成 PYNQ-Z2 / xc7z020 post-route timing closure，bitstream 已生成并记录 SHA256，说明该候选具备继续上板补证的工程基础。技术数据包中提供了 RTL、testbench、脚本、Vivado reports、benchmark summary 和 audit 脚本，便于复核。",
            "风险边界方面，当前尚未补齐 PROGRAM_OK、board UART raw log 和视频。材料中必须把 implementation evidence、xsim evidence 和 board evidence 分开叙述，避免把旧初赛板级材料或当前 xsim 证据写成 impl220 board-proven。",
        ],
    ),
    (
        "结论与后续工作",
        [
            "本文档给出的分赛区主结论是：impl220 证明该自研 RV32 五级流水 RISC-V CPU 在 strict sync-BRAM 和 PYNQ-Z2 post-route implementation 口径下可以闭合 50 MHz，并在不修改 CoreMark 核心算法的条件下达到 4.287521 CoreMark/MHz。",
            "后续工作不应更换材料口径，而应围绕同一 impl220 bitstream 补齐 PROGRAM_OK、UART raw log、上板演示视频和最终上传预览检查。只有这些板级证据完成后，才能把当前候选从 implementation-evidence candidate 提升为 board evidence complete。",
        ],
    ),
]

TABLES: list[tuple[str, list[list[str]], list[int]]] = [
    (
        "表 1 当前分赛区主指标",
        [
            ["指标", "数值", "证据"],
            ["Candidate", "impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50", "FREEZE_STRICT50_IMPL220_20260701.md"],
            ["Slice LUT", "9965", "impl_utilization.rpt"],
            ["Slice FF", "6520", "impl_utilization.rpt"],
            ["BRAM Tile / DSP", "32 / 8", "impl_utilization.rpt"],
            ["CPU clock", "50 MHz", "impl_timing_summary.rpt"],
            ["CoreMark/MHz", "4.287521", "fast210 summary"],
            ["DMIPS/MHz", "2.495618 xsim", "sim220 Dhrystone timer50 summary"],
            ["post-route WNS / WHS", "+0.056 ns / +0.121 ns", "impl_timing_summary.rpt"],
        ],
        [92, 188, 200],
    ),
    (
        "表 2 当前可报告项与不可越界项",
        [
            ["类别", "可以写入正式材料", "不可写入正式材料"],
            ["CoreMark", "工程 short-gate，CRC 0xfcaf，acceptance_pass=yes", "官方 EEMBC 10 秒认证结果"],
            ["Dhrystone", "2.495618 DMIPS/MHz，同配置 xsim", "板级 UART DMIPS"],
            ["FPGA", "50 MHz post-route timing closed，bitstream/SHA256 已归档", "impl220 已经 board-proven"],
            ["视频", "需提交 3 分钟内现场展示视频和正常速度备份", "用旧初赛视频冒充当前 impl220 证据"],
        ],
        [90, 215, 175],
    ),
    (
        "表 3 技术数据索引",
        [
            ["材料", "路径", "用途"],
            ["源码包", "分赛区/源代码/CICC1003618_分赛区决赛_源代码.zip", "复核 RTL、TB、脚本和软件 workload"],
            ["技术数据包", "分赛区/技术数据/CICC1003618_分赛区决赛_技术数据包.zip", "统一复核入口"],
            ["PPT PDF", "分赛区/PPT/CICC1003618_分赛区决赛_PPT.pdf", "现场主展示或在线预览"],
            ["纯图片 PPT", "分赛区/PPT/CICC1003618_分赛区决赛_PPT_纯图片版.pptx", "兼容性优先展示"],
            ["证据索引", "分赛区/00-提交检查与清单/03-证据索引/", "指标到原始文件追踪"],
        ],
        [88, 230, 160],
    ),
]


def markdown_text() -> str:
    lines: list[str] = []
    lines.append("# CICC1003618 分赛区决赛技术文档")
    lines.append("")
    lines.append("生成日期：2026-07-20")
    lines.append("")
    lines.append("本文档为分赛区决赛主提交技术文档，基于初赛材料和当前主目录最新 impl220 strict50 证据整理。")
    lines.append("")
    lines.append("## 目录")
    for idx, (heading, _) in enumerate(SECTIONS, 1):
        lines.append(f"{idx}. {heading}")
    lines.append("")
    for idx, (heading, paragraphs) in enumerate(SECTIONS, 1):
        lines.append(f"## {idx}. {heading}")
        lines.append("")
        for paragraph in paragraphs:
            lines.append(paragraph)
            lines.append("")
        if idx == 7:
            for title, rows, _ in TABLES[:2]:
                lines.append(f"### {title}")
                header = rows[0]
                lines.append("| " + " | ".join(header) + " |")
                lines.append("|" + "|".join(["---"] * len(header)) + "|")
                for row in rows[1:]:
                    lines.append("| " + " | ".join(row) + " |")
                lines.append("")
        if idx == 8:
            title, rows, _ = TABLES[2]
            lines.append(f"### {title}")
            header = rows[0]
            lines.append("| " + " | ".join(header) + " |")
            lines.append("|" + "|".join(["---"] * len(header)) + "|")
            for row in rows[1:]:
                lines.append("| " + " | ".join(row) + " |")
            lines.append("")
    return "\n".join(lines)


def draw_header_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("NotoSC", 8.5)
    canvas.setFillColor(colors.HexColor("#667085"))
    canvas.drawString(18 * mm, 287 * mm, "CICC1003618 分赛区决赛技术文档 | strict50 impl220")
    canvas.drawRightString(192 * mm, 287 * mm, f"第 {doc.page} 页")
    canvas.setStrokeColor(colors.HexColor("#E4E7EC"))
    canvas.line(18 * mm, 283.5 * mm, 192 * mm, 283.5 * mm)
    canvas.line(18 * mm, 15 * mm, 192 * mm, 15 * mm)
    canvas.restoreState()


def build_pdf():
    styles = getSampleStyleSheet()
    base = ParagraphStyle(
        "base",
        parent=styles["Normal"],
        fontName="NotoSC",
        fontSize=10.3,
        leading=16,
        textColor=colors.HexColor("#101828"),
        alignment=TA_LEFT,
        spaceAfter=6,
    )
    title_style = ParagraphStyle(
        "title",
        parent=base,
        fontName="NotoSC-Bold",
        fontSize=22,
        leading=30,
        alignment=TA_CENTER,
        spaceAfter=16,
    )
    subtitle_style = ParagraphStyle(
        "subtitle",
        parent=base,
        fontSize=12,
        leading=18,
        alignment=TA_CENTER,
        textColor=colors.HexColor("#475467"),
        spaceAfter=18,
    )
    h1 = ParagraphStyle(
        "h1",
        parent=base,
        fontName="NotoSC-Bold",
        fontSize=15,
        leading=22,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=12,
        spaceAfter=8,
    )
    h2 = ParagraphStyle(
        "h2",
        parent=base,
        fontName="NotoSC-Bold",
        fontSize=11,
        leading=16,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=8,
        spaceAfter=5,
    )
    small = ParagraphStyle(
        "small",
        parent=base,
        fontSize=8.4,
        leading=11.5,
    )

    doc = BaseDocTemplate(
        str(PDF_PATH),
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=22 * mm,
        bottomMargin=18 * mm,
        title="CICC1003618 分赛区决赛技术文档",
        author="CICC1003618",
    )
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="normal")
    doc.addPageTemplates([PageTemplate(id="main", frames=[frame], onPage=draw_header_footer)])

    story = []
    story.append(para("CICC1003618 分赛区决赛技术文档", title_style))
    story.append(para("strict50 impl220 技术方案、研发过程、验证证据与提交材料索引", subtitle_style))
    story.append(para("生成日期：2026-07-20。本文档为分赛区决赛主提交技术文档，基于初赛材料和主目录最新 impl220 strict50 证据整理。", base))
    story.append(Spacer(1, 6))
    story.append(para("目录", h1))
    for idx, (heading, _) in enumerate(SECTIONS, 1):
        story.append(para(f"{idx}. {heading}", base))
    story.append(PageBreak())

    for idx, (heading, paragraphs) in enumerate(SECTIONS, 1):
        story.append(para(f"{idx}. {heading}", h1))
        for paragraph in paragraphs:
            story.append(para(paragraph, base))
        if idx == 7:
            for table_title, rows, col_widths in TABLES[:2]:
                story.append(para(table_title, h2))
                story.append(make_table(rows, col_widths, small))
        if idx == 8:
            table_title, rows, col_widths = TABLES[2]
            story.append(para(table_title, h2))
            story.append(make_table(rows, col_widths, small))
        story.append(Spacer(1, 5))
    doc.build(story)


def make_table(rows: list[list[str]], widths: list[int], style: ParagraphStyle) -> Table:
    data = [[para(cell, style) for cell in row] for row in rows]
    table = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), "NotoSC"),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0F172A")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "NotoSC-Bold"),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#FFFFFF")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#D0D5DD")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    MD_PATH.write_text(markdown_text(), encoding="utf-8")
    build_pdf()
    print(f"markdown={MD_PATH}")
    print(f"pdf={PDF_PATH}")


if __name__ == "__main__":
    main()
