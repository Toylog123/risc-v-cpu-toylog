param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
)

$ErrorActionPreference = "Stop"

function Read-Text([string]$Path) {
  if (!(Test-Path -LiteralPath $Path)) {
    throw "Missing required file: $Path"
  }
  return Get-Content -Raw -LiteralPath $Path
}

function Check-Text([string]$Name, [string]$Text, [string]$Pattern) {
  if ($Text -notmatch $Pattern) {
    return "$Name missing pattern: $Pattern"
  }
  return $null
}

$repoAbs = (Resolve-Path -LiteralPath $RepoRoot).Path
$artifactRoot = Join-Path $repoAbs "artifacts\strict_50m_timing_opt_20260609"
$evidenceDir = Join-Path $artifactRoot "sim220_dhrystone_impl220_strict50_match"
$summaryPath = Join-Path $evidenceDir "dhrystone_impl220_strict50_noautoinc_timer50_runs1000.summary.txt"
$logPath = Join-Path $evidenceDir "dhrystone_impl220_strict50_noautoinc_timer50_runs1000.log"
$stdoutPath = Join-Path $evidenceDir "run_strict50_dhrystone_impl220_timer50_runs1000.stdout.log"
$runnerPath = Join-Path $repoAbs "YH_rv_cpu\scripts\run_strict50_dhrystone_impl220.bat"
$timerAuditPath = Join-Path $artifactRoot "audit_dhrystone_timer_clock_consistency.ps1"

$summary = Read-Text $summaryPath
$log = Read-Text $logPath
$stdout = Read-Text $stdoutPath
$runner = Read-Text $runnerPath

$failures = @()

$failures += Check-Text "summary" $summary "clock_hz=50000000"
$failures += Check-Text "summary" $summary "runs=1000"
$failures += Check-Text "summary" $summary "dhrystones_per_second=219240"
$failures += Check-Text "summary" $summary "dmips_per_mhz=2\.495618"
$failures += Check-Text "summary" $summary "benchmark=Dhrystone 2\.2"
$failures += Check-Text "summary" $summary "measurement_mode=host-parsed-from-uart-log"
$failures += Check-Text "summary" $summary "competition_report_line=DMIPS/MHz \(host-parsed\): 2\.495618 / Dhrystones/s 219240 / runs 1000"

$failures += Check-Text "xsim log" $log "DHRYSTONE_RUNS=1000"
$failures += Check-Text "xsim log" $log "Dhrystones per Second:\s+219240"
$failures += Check-Text "xsim log" $log "PASS: dhrystone completed"

$failures += Check-Text "stdout" $stdout "strict50_dhrystone_candidate=impl220"
$failures += Check-Text "stdout" $stdout "strict50_dhrystone_clock_hz=50000000L"
$failures += Check-Text "stdout" $stdout "Dhrystone timer Hz: 50000000L"
$failures += Check-Text "stdout" $stdout "rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_mac_noautoinc_idbr"
$failures += Check-Text "stdout" $stdout "ENABLE_XTHEAD_MEMPAIR_EXTENSION=0"
$failures += Check-Text "stdout" $stdout "ENABLE_XTHEAD_BASE_UPDATE_EXTENSION=0"
$failures += Check-Text "stdout" $stdout "ENABLE_BRANCH_BHT_ID_UPDATE=0"
$failures += Check-Text "stdout" $stdout "DCACHE_EN=1"
$failures += Check-Text "stdout" $stdout "DCACHE_SIZE_BYTES=512"
$failures += Check-Text "stdout" $stdout "REDIRECT_CACHE_ENTRIES=512"

$failures += Check-Text "runner" $runner "set DHRYSTONE_CLOCK_HZ=50000000L"
$failures += Check-Text "runner" $runner "set YH_DHRYSTONE_FPGA_ENABLE_XTHEAD_MEMPAIR_EXTENSION=0"
$failures += Check-Text "runner" $runner "set YH_DHRYSTONE_FPGA_ENABLE_XTHEAD_BASE_UPDATE_EXTENSION=0"
$failures += Check-Text "runner" $runner "set YH_DHRYSTONE_FPGA_ENABLE_BRANCH_BHT_ID_UPDATE=0"

& powershell -NoProfile -ExecutionPolicy Bypass -File $timerAuditPath -RepoRoot $repoAbs | ForEach-Object {
  Write-Output $_
  if ($_ -match "dhrystone_timer_clock_consistency=FAIL") {
    $failures += "timer clock consistency audit failed"
  }
}

$failures = @($failures | Where-Object { $_ })

Write-Output "repo_root=$repoAbs"
Write-Output "dhrystone_summary=$summaryPath"
Write-Output "dhrystone_log=$logPath"
Write-Output "dhrystone_stdout=$stdoutPath"
Write-Output "strict50_dhrystone_runner=$runnerPath"

if ($failures.Count -gt 0) {
  Write-Output "strict50_dhrystone_audit_status=FAIL"
  Write-Output "failure_count=$($failures.Count)"
  foreach ($failure in $failures) {
    Write-Output "failure=$failure"
  }
  exit 1
}

Write-Output "strict50_dhrystone_audit_status=PASS"
