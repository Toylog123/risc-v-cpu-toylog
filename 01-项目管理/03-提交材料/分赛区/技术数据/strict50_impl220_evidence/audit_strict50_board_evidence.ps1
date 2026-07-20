param(
  [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path),
  [switch]$RequireComplete
)

$ErrorActionPreference = "Stop"

function Rel([string]$Path) {
  $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $Path).Path
  if ($full.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($resolvedRoot.Length).TrimStart("\", "/").Replace("\", "/")
  }
  return $full.Replace("\", "/")
}

function Get-FilesSafe([string[]]$Dirs, [string[]]$Filters) {
  $out = @()
  foreach ($dir in $Dirs) {
    if (!(Test-Path -LiteralPath $dir)) {
      continue
    }
    foreach ($filter in $Filters) {
      $out += Get-ChildItem -LiteralPath $dir -Recurse -File -Filter $filter -ErrorAction SilentlyContinue
    }
  }
  return @($out | Sort-Object FullName -Unique)
}

function Find-TextEvidence([System.IO.FileInfo[]]$Files, [string]$Pattern) {
  $hits = @()
  foreach ($file in $Files) {
    try {
      $text = Get-Content -Raw -LiteralPath $file.FullName -ErrorAction Stop
    } catch {
      continue
    }
    if ($text -match $Pattern) {
      $hits += $file
    }
  }
  return @($hits | Sort-Object FullName -Unique)
}

function Find-ProgramOkEvidence([System.IO.FileInfo[]]$Files) {
  $hits = @()
  $positivePattern = "(?mi)^\s*(PROGRAM_OK|program_status\s*=\s*PROGRAM_OK|.*program_hw_devices.*(succeed|success|done|completed)|.*Programmed device.*|.*End of startup status:\s*HIGH.*)\s*$"
  $negativePattern = "(?mi)\b(not|no|without|pending|missing)\b.*\b(PROGRAM_OK|program_hw_devices|Programmed device|End of startup status)|\b(PROGRAM_OK|program_hw_devices|Programmed device|End of startup status)\b.*\b(not|no|without|pending|missing)\b"
  foreach ($file in $Files) {
    try {
      $text = Get-Content -Raw -LiteralPath $file.FullName -ErrorAction Stop
    } catch {
      continue
    }
    if (($text -match $positivePattern) -and ($text -notmatch $negativePattern)) {
      $hits += $file
    }
  }
  return @($hits | Sort-Object FullName -Unique)
}

$candidate = "impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50"
$rootAbs = (Resolve-Path -LiteralPath $Root).Path
$candidateRoot = Join-Path $rootAbs $candidate
$boardDirs = @(
  Get-ChildItem -LiteralPath $rootAbs -Directory -Filter "board_impl220*" -ErrorAction SilentlyContinue
)

$bitSearchDirs = @($candidateRoot) + @($boardDirs | ForEach-Object { $_.FullName })
$boardSearchDirs = @($boardDirs | ForEach-Object { $_.FullName })

$bitstreams = @(
  Get-FilesSafe $bitSearchDirs @("*.bit") |
    Where-Object { $_.FullName -match "impl220|strict50|cpu50|$([regex]::Escape($candidate))" }
)
$ltxFiles = @(
  Get-FilesSafe $bitSearchDirs @("*.ltx") |
    Where-Object { $_.FullName -match "impl220|strict50|cpu50|$([regex]::Escape($candidate))" }
)

$boardTextFiles = Get-FilesSafe $boardSearchDirs @("*.log", "*.txt", "*.md")
$programTextFiles = Get-FilesSafe $boardSearchDirs @("program*.log", "program*.txt", "program*.md", "*program_hw*.log", "*program_hw*.txt", "*program_hw*.md", "*hardware*.log", "*hardware*.txt", "*hardware*.md")
$programOk = Find-ProgramOkEvidence $programTextFiles
$uartLogs = @(
  Get-FilesSafe $boardSearchDirs @("uart*.log", "*uart*.txt", "*uart*.md") |
    Where-Object { $_.Name -match "uart" }
)
$videos = Get-FilesSafe $boardSearchDirs @("*.mp4", "*.mov", "*.mkv", "*.avi")
$videoManifests = Get-FilesSafe $boardSearchDirs @("video_manifest.md")

$shaFiles = Get-FilesSafe $boardSearchDirs @("SHA256SUMS.txt", "bitstream_manifest.md", "*sha256*.txt", "*sha256*.md")
$shaEvidence = Find-TextEvidence $shaFiles "(\.bit|Bitstream SHA256|SHA256)"

$formalDmipsPaths = @(
  (Join-Path $rootAbs "STRICT50_DHRYSTONE_EVIDENCE_20260702.md")
  (Join-Path $rootAbs "sim220_dhrystone_impl220_strict50_match\README.md")
  (Join-Path $rootAbs "sim220_dhrystone_impl220_strict50_match\dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt")
  (Join-Path $rootAbs "sim220_dhrystone_impl220_strict50_match\dhrystone_impl220_strict50_noautoinc_timer50_runs1000.log")
  Join-Path $rootAbs "sim220_dhrystone_impl220_strict50_match\run_strict50_dhrystone_impl220_timer50_runs1000.stdout.log"
)
$formalDmipsFiles = @(
  foreach ($path in $formalDmipsPaths) {
    if (Test-Path -LiteralPath $path) {
      Get-Item -LiteralPath $path
    }
  }
)
$impl220Dmips = Find-TextEvidence $formalDmipsFiles "(impl220|strict50).*(DMIPS|Dhrystone|dhrystone)|(DMIPS|Dhrystone|dhrystone).*(impl220|strict50)|dmips_per_mhz=2\.495618|Dhrystones per Second:\s+219240"

$boardChecks = [ordered]@{
  bitstream = ($bitstreams.Count -gt 0)
  program_ok = ($programOk.Count -gt 0)
  uart_raw_log = ($uartLogs.Count -gt 0)
  board_video = (($videos.Count -gt 0) -or ($videoManifests.Count -gt 0))
  bitstream_sha256 = ($shaEvidence.Count -gt 0)
}

$submissionChecks = [ordered]@{}
foreach ($key in $boardChecks.Keys) {
  $submissionChecks[$key] = $boardChecks[$key]
}
$submissionChecks["impl220_dmips"] = ($impl220Dmips.Count -gt 0)

$boardMissing = @()
foreach ($key in $boardChecks.Keys) {
  if (-not $boardChecks[$key]) {
    $boardMissing += $key
  }
}

$submissionMissing = @()
foreach ($key in $submissionChecks.Keys) {
  if (-not $submissionChecks[$key]) {
    $submissionMissing += $key
  }
}

$boardComplete = ($boardMissing.Count -eq 0)
$submissionComplete = ($submissionMissing.Count -eq 0)

Write-Output "candidate=$candidate"
Write-Output "artifact_root=$rootAbs"
Write-Output "board_dir_count=$($boardDirs.Count)"
Write-Output "bitstream_count=$($bitstreams.Count)"
Write-Output "ltx_count=$($ltxFiles.Count)"
Write-Output "program_ok_count=$($programOk.Count)"
Write-Output "uart_log_count=$($uartLogs.Count)"
Write-Output "video_count=$($videos.Count)"
Write-Output "video_manifest_count=$($videoManifests.Count)"
Write-Output "bitstream_sha256_count=$($shaEvidence.Count)"
Write-Output "impl220_dmips_count=$($impl220Dmips.Count)"
Write-Output "board_evidence_complete=$boardComplete"
Write-Output "submission_evidence_complete=$submissionComplete"

if ($boardMissing.Count -gt 0) {
  Write-Output "board_missing_count=$($boardMissing.Count)"
  foreach ($item in $boardMissing) {
    Write-Output "board_missing=$item"
  }
} else {
  Write-Output "board_missing_count=0"
}

if ($submissionMissing.Count -gt 0) {
  Write-Output "submission_missing_count=$($submissionMissing.Count)"
  foreach ($item in $submissionMissing) {
    Write-Output "submission_missing=$item"
  }
} else {
  Write-Output "submission_missing_count=0"
}

foreach ($file in $bitstreams) {
  $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName
  Write-Output "bitstream=$(Rel $file.FullName)"
  Write-Output "bitstream_sha256=$($hash.Hash)"
}
foreach ($file in $ltxFiles) {
  Write-Output "ltx=$(Rel $file.FullName)"
}
foreach ($file in $programOk) {
  Write-Output "program_ok=$(Rel $file.FullName)"
}
foreach ($file in $uartLogs) {
  Write-Output "uart_log=$(Rel $file.FullName)"
}
foreach ($file in $videos) {
  Write-Output "video=$(Rel $file.FullName)"
}
foreach ($file in $videoManifests) {
  Write-Output "video_manifest=$(Rel $file.FullName)"
}
foreach ($file in $shaEvidence) {
  Write-Output "sha256_evidence=$(Rel $file.FullName)"
}
foreach ($file in $impl220Dmips) {
  Write-Output "impl220_dmips_evidence=$(Rel $file.FullName)"
}

if ($RequireComplete -and -not $submissionComplete) {
  exit 1
}
