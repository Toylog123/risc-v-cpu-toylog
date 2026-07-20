import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

function runtimeArtifactToolEntry() {
  const home = process.env.HOME || process.env.USERPROFILE;
  if (!home) throw new Error("HOME or USERPROFILE is required");
  return path.join(
    home,
    ".cache",
    "codex-runtimes",
    "codex-primary-runtime",
    "dependencies",
    "node",
    "node_modules",
    "@oai",
    "artifact-tool",
    "dist",
    "artifact_tool.mjs",
  );
}

const { Presentation, PresentationFile } = await import(
  pathToFileURL(process.env.ARTIFACT_TOOL_ENTRY || runtimeArtifactToolEntry()).href,
);

const ROOT = process.cwd();
const OUT = path.join(
  ROOT,
  "01-项目管理",
  "03-提交材料",
  "分赛区",
  "PPT",
  "CICC1003618_分赛区决赛_PPT.pptx",
);
const PREVIEW_DIR = path.join(
  ROOT,
  "_tmp",
  "regional_strict50_ppt_preview",
);

const W = 1280;
const H = 720;
const C = {
  bg: "#f7f9fc",
  ink: "#101828",
  muted: "#475467",
  faint: "#e4e7ec",
  line: "#cbd5e1",
  blue: "#0b5fff",
  cyan: "#0e7490",
  green: "#0f766e",
  amber: "#b45309",
  red: "#b42318",
  white: "#ffffff",
  black: "#111827",
};

function box(slide, left, top, width, height, fill = C.white, line = C.line, radius = 8) {
  return slide.shapes.add({
    geometry: "roundRect",
    position: { left, top, width, height },
    fill,
    line: { style: "solid", fill: line, width: 1 },
    borderRadius: radius,
  });
}

function text(slide, value, left, top, width, height, opts = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position: { left, top, width, height },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = value;
  shape.text.style = {
    fontSize: opts.size ?? 20,
    bold: opts.bold ?? false,
    color: opts.color ?? C.ink,
    alignment: opts.align ?? "left",
  };
  return shape;
}

function rule(slide, left, top, width, color = C.line, weight = 1.5) {
  slide.shapes.add({
    geometry: "line",
    position: { left, top, width, height: 0 },
    fill: "none",
    line: { style: "solid", fill: color, width: weight },
  });
}

function arrow(slide, x1, y1, x2, y2, color = C.line) {
  slide.shapes.add({
    geometry: "line",
    position: { left: x1, top: y1, width: x2 - x1, height: y2 - y1 },
    fill: "none",
    line: { style: "solid", fill: color, width: 2 },
    head: { type: "triangle", width: "sm", length: "sm" },
  });
}

function footer(slide, page) {
  rule(slide, 64, 656, 1152, C.faint, 1);
  text(slide, "CICC1003618 | strict50 impl220 | post-route timing-closed engineering candidate", 64, 666, 850, 26, {
    size: 13,
    color: "#667085",
  });
  text(slide, String(page).padStart(2, "0"), 1164, 664, 52, 30, {
    size: 15,
    bold: true,
    color: "#667085",
    align: "right",
  });
}

function title(slide, t, sub, page) {
  text(slide, "七星微企业命题 | 分赛区决赛", 64, 34, 380, 26, {
    size: 14,
    bold: true,
    color: C.cyan,
  });
  text(slide, t, 64, 78, 900, 58, { size: 38, bold: true, color: C.ink });
  if (sub) text(slide, sub, 66, 136, 980, 34, { size: 18, color: C.muted });
  footer(slide, page);
}

function metric(slide, label, value, left, top, width, accent = C.blue) {
  box(slide, left, top, width, 120, C.white, "#d0d5dd", 8);
  text(slide, value, left + 18, top + 24, width - 36, 40, {
    size: 31,
    bold: true,
    color: accent,
    align: "center",
  });
  text(slide, label, left + 14, top + 72, width - 28, 28, {
    size: 15,
    color: C.muted,
    align: "center",
  });
}

function chip(slide, label, left, top, width, fill, color) {
  box(slide, left, top, width, 34, fill, fill, 17);
  text(slide, label, left + 8, top + 7, width - 16, 20, {
    size: 13,
    bold: true,
    color,
    align: "center",
  });
}

function bulletList(slide, items, left, top, width, size = 18, color = C.muted) {
  text(slide, items.map((item) => `- ${item}`).join("\n"), left, top, width, items.length * (size + 10), {
    size,
    color,
  });
}

function table(slide, rows, left, top, width, height, columnWidths) {
  const rowH = height / rows.length;
  const colW = columnWidths || Array(rows[0].length).fill(width / rows[0].length);
  let y = top;
  rows.forEach((row, r) => {
    let x = left;
    row.forEach((cell, c) => {
      const fill = r === 0 ? "#0f172a" : r % 2 === 0 ? "#f8fafc" : C.white;
      const color = r === 0 ? C.white : C.ink;
      box(slide, x, y, colW[c], rowH, fill, "#d0d5dd", 2);
      text(slide, cell, x + 10, y + 9, colW[c] - 20, rowH - 14, {
        size: r === 0 ? 15 : 14,
        bold: r === 0 || c === 0,
        color,
      });
      x += colW[c];
    });
    y += rowH;
  });
}

const p = Presentation.create({ slideSize: { width: W, height: H } });

// 1
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  text(s, "面向 PYNQ-Z2 的 strict 50 MHz RV32 五级流水 RISC-V CPU", 64, 70, 980, 118, {
    size: 51,
    bold: true,
    color: C.ink,
  });
  text(s, "第十届全国大学生集成电路创新创业大赛 | 七星微企业命题 | 队伍编号 CICC1003618", 68, 204, 940, 36, {
    size: 20,
    color: C.muted,
  });
  chip(s, "post-route timing-closed", 68, 260, 230, "#e0f2fe", "#075985");
  chip(s, "board evidence pending", 316, 260, 210, "#fef3c7", "#92400e");
  chip(s, "CoreMark core unchanged", 544, 260, 230, "#dcfce7", "#166534");
  metric(s, "Slice LUT", "9965", 68, 350, 170, C.blue);
  metric(s, "CoreMark/MHz", "4.287521", 262, 350, 220, C.blue);
  metric(s, "CPU clock", "50 MHz", 506, 350, 180, C.green);
  metric(s, "WNS / WHS", "+0.056 / +0.121", 710, 350, 260, C.green);
  text(s, "当前材料只声明 impl220 的实现级闭合证据；PROGRAM_OK、UART raw log 和同版视频补齐前，不写 board-proven。", 68, 548, 1080, 44, {
    size: 22,
    bold: true,
    color: C.red,
  });
  footer(s, 1);
}

// 2
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "分赛区材料统一到最新 impl220 口径", "按照分赛区要求，技术文档、PPT、源码和技术数据采用同一证据边界。", 2);
  table(
    s,
    [
      ["要求项", "当前材料口径", "证据状态"],
      ["CPU 设计", "自研 RV32 五级流水，IF/ID/EX/MEM/WB", "RTL 和 testbench 已归档"],
      ["性能指标", "4.287521 CoreMark/MHz；2.495618 DMIPS/MHz xsim", "summary 文件可复核"],
      ["FPGA 实现", "PYNQ-Z2 / xc7z020，50 MHz post-route closed", "Vivado reports 可复核"],
      ["技术数据", "源码包、timing/utilization、bitstream/SHA256、xsim 日志", "随材料包提交"],
      ["演示视频", "同一 bitstream 的 PROGRAM_OK/UART/video 待补", "不得用旧视频冒充当前结果"],
    ],
    70,
    210,
    1140,
    360,
    [210, 620, 310],
  );
}

// 3
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "架构围绕五级流水和同步 BRAM 收敛", "设计不是单周期演示，而是具备真实流水控制、访存和外设输出路径。", 3);
  const stages = ["IF\n取指/PC", "ID\n译码/冒险", "EX\nALU/分支", "MEM\nDCache/BRAM", "WB\n回写"];
  stages.forEach((stage, i) => {
    const x = 74 + i * 226;
    box(s, x, 235, 160, 110, i === 3 ? "#ecfeff" : C.white, i === 3 ? "#06b6d4" : C.line, 8);
    text(s, stage, x + 14, 255, 132, 64, { size: 22, bold: true, color: i === 3 ? C.cyan : C.ink, align: "center" });
    if (i < stages.length - 1) arrow(s, x + 166, 290, x + 218, 290, C.muted);
  });
  box(s, 120, 410, 1040, 86, "#f8fafc", C.line, 8);
  text(s, "前端优化：BHT / redirect-cache / fold / next-cache", 148, 430, 460, 30, { size: 20, bold: true, color: C.blue });
  text(s, "数据与控制：forwarding / load-use / stall / flush", 648, 430, 470, 30, { size: 20, bold: true, color: C.green });
  text(s, "strict sync-BRAM 口径让指令和数据存储延迟进入 RTL 与 timing，而不是只追求零延迟仿真分数。", 148, 468, 940, 28, { size: 17, color: C.muted });
}

// 4
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "主要时序风险来自 MEM/DCache 到前端控制的长路径", "高分探索通常会试图同周期利用访存和 redirect 信息，但这会把 PC 选择路径拉长。", 4);
  box(s, 92, 230, 220, 105, "#ecfeff", "#0891b2", 8);
  text(s, "MEM / DCache\nload-use state", 112, 258, 180, 46, { size: 21, bold: true, color: C.cyan, align: "center" });
  box(s, 420, 230, 220, 105, "#fff7ed", "#fb923c", 8);
  text(s, "redirect-cache\nBHT update", 440, 258, 180, 46, { size: 21, bold: true, color: C.amber, align: "center" });
  box(s, 748, 230, 220, 105, "#eff6ff", "#60a5fa", 8);
  text(s, "PC select\nIF/ID control", 768, 258, 180, 46, { size: 21, bold: true, color: C.blue, align: "center" });
  arrow(s, 314, 282, 416, 282, C.red);
  arrow(s, 642, 282, 744, 282, C.red);
  text(s, "同周期组合扇入增加", 336, 246, 270, 28, { size: 18, bold: true, color: C.red, align: "center" });
  box(s, 92, 430, 876, 82, "#fff1f2", "#fecdd3", 8);
  text(s, "结论：当前候选必须以 post-route timing report 为准。fast-only、高分但 timing-failed、demo-ROM 或旧 board-proven 记录都不能替代 impl220。", 122, 454, 812, 34, { size: 20, bold: true, color: C.red });
}

// 5
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "优化集中在硬件路径和实现流程，不改 benchmark", "当前结果来自 RTL 参数、控制路径收敛和 Vivado implementation directive。", 5);
  const items = [
    ["BHT ID-update 可配置", "ENABLE_BRANCH_BHT_ID_UPDATE 将 BHT CE 热点变成可审计开关。", C.blue],
    ["fold/next-cache 取舍", "高分同周期路径未闭合时序，主候选保留 timing-safe 配置。", C.amber],
    ["DCache/load-use 扇入削减", "减少 MEM 状态对 PC 和 IF/ID 选择的直接组合影响。", C.green],
    ["ExploreArea + AdvancedSkewModeling", "在保持性能线的同时收敛到 9965 LUT 和正 slack。", C.cyan],
  ];
  items.forEach(([head, body, color], i) => {
    const x = 76 + (i % 2) * 570;
    const y = 220 + Math.floor(i / 2) * 175;
    box(s, x, y, 520, 130, C.white, "#d0d5dd", 8);
    text(s, head, x + 24, y + 22, 460, 30, { size: 24, bold: true, color });
    text(s, body, x + 24, y + 64, 460, 44, { size: 18, color: C.muted });
  });
}

// 6
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "impl220 是当前可报告的 strict 50 MHz 主结果", "所有主指标均绑定到归档 summary 或 Vivado post-route reports。", 6);
  metric(s, "Slice LUT", "9965", 78, 210, 170, C.blue);
  metric(s, "Slice FF", "6520", 270, 210, 170, C.blue);
  metric(s, "BRAM / DSP", "32 / 8", 462, 210, 170, C.blue);
  metric(s, "CoreMark/MHz", "4.287521", 654, 210, 230, C.green);
  metric(s, "DMIPS/MHz xsim", "2.495618", 906, 210, 230, C.green);
  table(
    s,
    [
      ["候选", "CPU 时钟", "post-route WNS", "post-route WHS", "证据等级"],
      ["impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50", "50 MHz", "+0.056 ns", "+0.121 ns", "implementation closed; board pending"],
    ],
    78,
    400,
    1060,
    104,
    [410, 120, 150, 150, 230],
  );
  text(s, "一句话口径：9965 LUT / 4.287521 CoreMark/MHz / 50 MHz / WNS +0.056 ns / WHS +0.121 ns。", 80, 546, 1030, 34, { size: 23, bold: true, color: C.ink });
}

// 7
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "证据链把每个数字绑定到原始文件", "技术数据包中保留可复核 summary、Vivado reports、bitstream/SHA256 和脚本。", 7);
  const chain = [
    ["RTL/config", "YH_rv_cpu/rtl"],
    ["CoreMark", "fast210 summary"],
    ["Vivado reports", "impl220 reports_cpu50"],
    ["Dhrystone", "sim220 timer50"],
    ["Bitstream", "board_impl220_bitstream"],
  ];
  chain.forEach(([h, b], i) => {
    const x = 70 + i * 224;
    box(s, x, 235, 178, 118, C.white, "#d0d5dd", 8);
    text(s, h, x + 14, 260, 150, 30, { size: 22, bold: true, color: C.blue, align: "center" });
    text(s, b, x + 12, 300, 154, 32, { size: 14, color: C.muted, align: "center" });
    if (i < chain.length - 1) arrow(s, x + 184, 294, x + 216, 294, C.muted);
  });
  box(s, 118, 430, 1040, 92, "#f0fdf4", "#bbf7d0", 8);
  text(s, "自动复核命令", 148, 452, 220, 26, { size: 22, bold: true, color: C.green });
  text(s, "powershell -ExecutionPolicy Bypass -File artifacts/strict_50m_timing_opt_20260609/verify_strict50_impl220_metrics.ps1", 148, 486, 940, 26, { size: 18, color: C.black });
}

// 8
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "更高 fast score 没有通过时序，不能作为当前候选", "报告采用可复现、可审计、post-route timing-closed 的结果。", 8);
  box(s, 104, 230, 470, 250, "#fff1f2", "#fecdd3", 8);
  text(s, "Rejected high-score path", 132, 260, 410, 34, { size: 26, bold: true, color: C.red });
  text(s, "fast201: 4.569338 CoreMark/MHz\n对应 synth224: WNS -11.786 ns\n结论：timing failed，只保留为探索记录", 132, 315, 390, 96, { size: 20, color: C.muted });
  box(s, 706, 230, 470, 250, "#ecfdf3", "#bbf7d0", 8);
  text(s, "Reportable current path", 734, 260, 410, 34, { size: 26, bold: true, color: C.green });
  text(s, "impl220: 4.287521 CoreMark/MHz\npost-route WNS +0.056 ns\n结论：当前 strict50 主候选", 734, 315, 390, 96, { size: 20, color: C.muted });
  text(s, "判断原则：性能分数必须与同一配置的 50 MHz timing closure 同时成立。", 154, 538, 920, 34, { size: 24, bold: true, color: C.ink, align: "center" });
}

// 9
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "答辩时主动说明合规边界", "把已完成证据和待补证据分开，是当前材料可信度的关键。", 9);
  box(s, 80, 214, 520, 330, "#f0fdf4", "#bbf7d0", 8);
  text(s, "可以声明", 112, 244, 450, 34, { size: 28, bold: true, color: C.green });
  bulletList(s, [
    "CoreMark 核心算法文件未修改",
    "impl220 完成 50 MHz post-route timing closure",
    "CoreMark short-gate CRC 0xfcaf、acceptance_pass=yes",
    "Dhrystone 2.495618 DMIPS/MHz 来自同配置 xsim",
    "bitstream 和 SHA256 已归档",
  ], 112, 298, 450, 19, C.ink);
  box(s, 680, 214, 520, 330, "#fffbeb", "#fde68a", 8);
  text(s, "不能越界", 712, 244, 450, 34, { size: 28, bold: true, color: C.amber });
  bulletList(s, [
    "不称官方 EEMBC 10 秒认证结果",
    "不称 DMIPS 为板级 UART 结果",
    "PROGRAM_OK、UART raw log、视频待补前不称 board-proven",
    "旧初赛板级证据不能替代当前 impl220",
  ], 712, 298, 450, 19, C.ink);
}

// 10
{
  const s = p.slides.add();
  s.background.fill = C.bg;
  title(s, "下一步围绕同一 bitstream 补齐板级闭环", "后续不是更换口径，而是把 PROGRAM_OK、UART 和视频绑定到已归档 impl220。", 10);
  const tasks = [
    ["1", "PROGRAM_OK", "Hardware Manager log 或截图识别同一 impl220 bitstream"],
    ["2", "UART raw log", "CoreMark、Dhrystone、perf demo 输出分开归档"],
    ["3", "演示视频", "板卡、下载上下文和 UART 输出同框；3 分钟内"],
    ["4", "最终提交审计", "技术文档、PPT、源码包、技术数据包哈希一致"],
  ];
  tasks.forEach(([n, h, b], i) => {
    const y = 210 + i * 88;
    box(s, 118, y, 1040, 66, C.white, "#d0d5dd", 8);
    box(s, 142, y + 13, 40, 40, "#e0f2fe", "#e0f2fe", 20);
    text(s, n, 142, y + 20, 40, 24, { size: 18, bold: true, color: C.blue, align: "center" });
    text(s, h, 210, y + 16, 240, 30, { size: 23, bold: true, color: C.ink });
    text(s, b, 470, y + 19, 620, 28, { size: 18, color: C.muted });
  });
  text(s, "完成定义：只有 bitstream、PROGRAM_OK、UART 和视频都齐全后，才能把 impl220 写成 board evidence complete。", 118, 580, 1040, 34, { size: 22, bold: true, color: C.red, align: "center" });
}

await fs.mkdir(path.dirname(OUT), { recursive: true });
await fs.mkdir(PREVIEW_DIR, { recursive: true });
for (const [index, slide] of p.slides.items.entries()) {
  const blob = await p.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(PREVIEW_DIR, `slide-${String(index + 1).padStart(2, "0")}.png`), new Uint8Array(await blob.arrayBuffer()));
}
const pptx = await PresentationFile.exportPptx(p);
await pptx.save(OUT);
console.log(`pptx=${OUT}`);
console.log(`preview_dir=${PREVIEW_DIR}`);
