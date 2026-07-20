param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path,
  [string]$OutDir = (Join-Path $PSScriptRoot "CICC_YH_RVCPU_Strict50_Submission_DRAFT_20260702"),
  [switch]$Build
)

$ErrorActionPreference = "Stop"

function Rel([string]$Path) {
  return $Path.Replace("\", "/")
}

function Add-Entry([System.Collections.Generic.List[object]]$Entries, [string]$Source, [string]$Dest, [string]$Kind, [string]$Status = "ready") {
  $srcAbs = Join-Path $RepoRoot $Source
  $exists = Test-Path -LiteralPath $srcAbs
  $Entries.Add([pscustomobject]@{
    source = Rel $Source
    dest = Rel $Dest
    kind = $Kind
    exists = $exists
    status = if ($exists) { $Status } else { "missing" }
  }) | Out-Null
  if ($Build -and $exists) {
    $dstAbs = Join-Path $OutDir $Dest
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dstAbs) | Out-Null
    Copy-Item -LiteralPath $srcAbs -Destination $dstAbs -Force
  }
}

function Add-TreeFiles([System.Collections.Generic.List[object]]$Entries, [string]$SourceRoot, [string]$DestRoot, [string[]]$IncludeGlobs) {
  $srcRootAbs = Join-Path $RepoRoot $SourceRoot
  foreach ($glob in $IncludeGlobs) {
    Get-ChildItem -LiteralPath $srcRootAbs -Recurse -File -Filter $glob | ForEach-Object {
      $relUnder = $_.FullName.Substring($srcRootAbs.Length).TrimStart("\", "/")
      if ((Rel (Join-Path $SourceRoot $relUnder)) -eq "YH_rv_cpu/scripts/resolve_python.bat") {
        return
      }
      Add-Entry $Entries (Join-Path $SourceRoot $relUnder) (Join-Path $DestRoot $relUnder) "file"
    }
  }
}

$entries = [System.Collections.Generic.List[object]]::new()

$artifactRoot = "artifacts/strict_50m_timing_opt_20260609"
$impl220 = "$artifactRoot/impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50"
$fast210 = "$artifactRoot/fast210_impl136cfg_bhtid0_current_iter10"

# Report and defense materials.
$docs = @(
  "README.md",
  "REGION_DELIVERY_INDEX_20260702.md",
  "REGION_REQUIREMENT_MATRIX_20260702.md",
  "REGION_METRIC_EVIDENCE_TRACE_IMPL220_20260702.md",
  "REGION_STRICT_VERIFICATION_GATE_CHECKLIST_20260706.md",
  "REGION_TECH_REPORT_DRAFT_STRICT50_20260702.md",
  "REGION_REPORT_STRICT50_SECTION_20260701.md",
  "REGION_REPORT_OUTLINE_STRICT50_20260702.md",
  "REGION_ARCHITECTURE_DIAGRAMS_STRICT50_20260703.md",
  "REGION_WORK_INTRO_AND_PPT_MASTER_STRICT50_20260706.md",
  "REGION_FINAL_PACKAGE_MANIFEST_20260702.md",
  "REGION_DEFENSE_QA_STRICT50_20260702.md",
  "REGION_DEFENSE_SPEAKER_SCRIPT_STRICT50_20260702.md",
  "REGION_SUBMISSION_WORKPLAN_20260702.md",
  "REGION_PPT_STORYBOARD_STRICT50_20260702.md",
  "REGION_PPT_DRAFT_MANIFEST_20260702.md",
  "REGION_STRICT50_UPDATE_20260701.md",
  "FREEZE_STRICT50_IMPL220_20260701.md",
  "STRICT50_BOARD_DEMO_RUNBOOK_20260702.md",
  "STRICT50_BOARD_EVIDENCE_TEMPLATE_20260701.md",
  "STRICT50_BOARD_EVIDENCE_AUDIT_20260702.md",
  "audit_strict50_board_evidence.ps1",
  "STRICT50_APP_DEMO_EVIDENCE_20260702.md",
  "audit_strict50_demo_evidence.ps1",
  "STRICT50_DHRYSTONE_EVIDENCE_20260702.md",
  "audit_dhrystone_timer_clock_consistency.ps1",
  "audit_strict50_dhrystone_evidence.ps1",
  "verify_strict50_impl220_metrics.ps1"
)
foreach ($doc in $docs) {
  Add-Entry $entries "$artifactRoot/$doc" "02_reports/$doc" "file"
}
Add-Entry $entries "$artifactRoot/CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx" "03_presentation/CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx" "file"
Add-Entry $entries "$artifactRoot/CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx.inspect.ndjson" "03_presentation/CICC_STRICT50_REGION_DEFENSE_DRAFT_20260702.pptx.inspect.ndjson" "file"

# Implementation evidence. Deliberately exclude DCP files.
$implFiles = @(
  "README.md",
  "SHA256SUMS.txt",
  "reports_cpu50/impl_timing_summary.rpt",
  "reports_cpu50/impl_utilization.rpt",
  "reports_cpu50/impl_route_status.rpt",
  "reports_cpu50/impl_methodology.rpt",
  "reports_cpu50/impl_timing_setup_top20.rpt",
  "reports_cpu50/impl_timing_hold_top20.rpt",
  "logs/vivado_pynq_z2_impl.log",
  "logs/vivado_pynq_z2_impl.jou",
  "logs/run_impl220.ps1",
  "logs/build_stdout.log"
)
foreach ($file in $implFiles) {
  Add-Entry $entries "$impl220/$file" "04_evidence_impl220/$file" "file"
}
Add-Entry $entries "$fast210/coremark50_fast_gate_iter10.summary.txt" "04_evidence_impl220/coremark/coremark50_fast_gate_iter10.summary.txt" "file"
Add-Entry $entries "$fast210/coremark50_fast_gate_iter10.log" "04_evidence_impl220/coremark/coremark50_fast_gate_iter10.log" "file"
Add-Entry $entries "$artifactRoot/strict50_perf_demo_20260702/README.md" "04_evidence_impl220/app_demo/README.md" "file"
Add-Entry $entries "$artifactRoot/strict50_perf_demo_20260702/SHA256SUMS.txt" "04_evidence_impl220/app_demo/SHA256SUMS.txt" "file"
Add-Entry $entries "$artifactRoot/strict50_perf_demo_20260702/YH_rv_cpu_strict50_perf_demo_xsim_20260702.log" "04_evidence_impl220/app_demo/YH_rv_cpu_strict50_perf_demo_xsim_20260702.log" "file"
Add-Entry $entries "$artifactRoot/sim220_dhrystone_impl220_strict50_match/README.md" "04_evidence_impl220/dhrystone/README.md" "file"
Add-Entry $entries "$artifactRoot/sim220_dhrystone_impl220_strict50_match/SHA256SUMS.txt" "04_evidence_impl220/dhrystone/SHA256SUMS.txt" "file"
Add-Entry $entries "$artifactRoot/sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt" "04_evidence_impl220/dhrystone/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt" "file"
Add-Entry $entries "$artifactRoot/sim220_dhrystone_impl220_strict50_match/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.log" "04_evidence_impl220/dhrystone/dhrystone_impl220_strict50_noautoinc_timer50_runs1000.log" "file"
Add-Entry $entries "$artifactRoot/sim220_dhrystone_impl220_strict50_match/run_strict50_dhrystone_impl220_timer50_runs1000.stdout.log" "04_evidence_impl220/dhrystone/run_strict50_dhrystone_impl220_timer50_runs1000.stdout.log" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/README.md" "05_board_evidence/bitstream/README.md" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/bitstream_manifest.md" "05_board_evidence/bitstream/bitstream_manifest.md" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/SHA256SUMS.txt" "05_board_evidence/bitstream/SHA256SUMS.txt" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit" "05_board_evidence/bitstream/YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/write_bitstream_from_impl220.tcl" "05_board_evidence/bitstream/write_bitstream_from_impl220.tcl" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/vivado_write_bitstream_from_impl220.log" "05_board_evidence/bitstream/vivado_write_bitstream_from_impl220.log" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/vivado_write_bitstream_from_impl220.jou" "05_board_evidence/bitstream/vivado_write_bitstream_from_impl220.jou" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/write_bitstream_stdout.log" "05_board_evidence/bitstream/write_bitstream_stdout.log" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/bitstream_from_dcp_drc.rpt" "05_board_evidence/bitstream/bitstream_from_dcp_drc.rpt" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/bitstream_from_dcp_timing_summary.rpt" "05_board_evidence/bitstream/bitstream_from_dcp_timing_summary.rpt" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/bitstream_from_dcp_utilization.rpt" "05_board_evidence/bitstream/bitstream_from_dcp_utilization.rpt" "file"
Add-Entry $entries "$artifactRoot/board_impl220_bitstream_20260702/bitstream_from_dcp_route_status.rpt" "05_board_evidence/bitstream/bitstream_from_dcp_route_status.rpt" "file"

# Minimal source package. Keep source focused; do not copy generated artifacts.
Add-TreeFiles $entries "YH_rv_cpu/rtl" "01_source/YH_rv_cpu/rtl" @("*.v", "*.vh")
Add-TreeFiles $entries "YH_rv_cpu/tb" "01_source/YH_rv_cpu/tb" @("*.v")
Add-TreeFiles $entries "YH_rv_cpu/scripts" "01_source/YH_rv_cpu/scripts" @("*.ps1", "*.tcl", "*.py", "*.bat")
Add-Entry $entries "YH_rv_cpu/sw/src/perf_demo.c" "01_source/YH_rv_cpu/sw/src/perf_demo.c" "file"
Add-Entry $entries "YH_rv_cpu/sw/src/crt0.S" "01_source/YH_rv_cpu/sw/src/crt0.S" "file"
Add-Entry $entries "YH_rv_cpu/sw/linker/YH_rv_cpu_coremark.ld" "01_source/YH_rv_cpu/sw/linker/YH_rv_cpu_coremark.ld" "file"
Add-Entry $entries "YH_rv_cpu/README.md" "01_source/YH_rv_cpu/README.md" "file"

$missing = @($entries | Where-Object { -not $_.exists })
$dcp = @($entries | Where-Object { $_.source -match "\.dcp$|(^|/)dcp/" })
$forbidden = @($entries | Where-Object {
  $_.source -match "01-.*/03-.*|core_list_join|core_matrix|core_state|core_util|core_main|resolve_python"
})

$status = if ($missing.Count -eq 0 -and $dcp.Count -eq 0 -and $forbidden.Count -eq 0) { "PASS" } else { "FAIL" }

if ($Build) {
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
}
$manifestPath = if ($Build) {
  Join-Path $OutDir "PACKAGE_MANIFEST.tsv"
} else {
  Join-Path $PSScriptRoot "CICC_STRICT50_PACKAGE_DRYRUN_20260702.tsv"
}

$entries |
  Sort-Object dest |
  ForEach-Object { "{0}`t{1}`t{2}`t{3}" -f $_.status, $_.kind, $_.source, $_.dest } |
  Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Output "package_status=$status"
Write-Output "build=$([bool]$Build)"
Write-Output "manifest=$manifestPath"
Write-Output "entry_count=$($entries.Count)"
Write-Output "missing_count=$($missing.Count)"
Write-Output "dcp_entry_count=$($dcp.Count)"
Write-Output "forbidden_entry_count=$($forbidden.Count)"

if ($missing.Count -gt 0) {
  $missing | ForEach-Object { Write-Output "missing=$($_.source)" }
}
if ($dcp.Count -gt 0) {
  $dcp | ForEach-Object { Write-Output "dcp_entry=$($_.source)" }
}
if ($forbidden.Count -gt 0) {
  $forbidden | ForEach-Object { Write-Output "forbidden_entry=$($_.source)" }
}

if ($status -ne "PASS") {
  exit 1
}
