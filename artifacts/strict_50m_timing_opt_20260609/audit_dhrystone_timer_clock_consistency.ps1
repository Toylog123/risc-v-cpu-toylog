param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
)

$ErrorActionPreference = "Stop"

function Require-Text([string]$Name, [string]$Text, [string]$Pattern) {
  if ($Text -notmatch $Pattern) {
    Write-Output "check_failed=$Name"
    Write-Output "missing_pattern=$Pattern"
    $script:ok = $false
    return
  }
  Write-Output "check_passed=$Name"
}

$buildPath = Join-Path $RepoRoot "YH_rv_cpu/scripts/build_dhrystone.bat"
$runPath = Join-Path $RepoRoot "YH_rv_cpu/scripts/run_dhrystone_fpga.bat"
$strict50RunPath = Join-Path $RepoRoot "YH_rv_cpu/scripts/run_strict50_dhrystone_impl220.bat"

$build = Get-Content -Raw -LiteralPath $buildPath
$run = Get-Content -Raw -LiteralPath $runPath
$strict50Run = Get-Content -Raw -LiteralPath $strict50RunPath

$ok = $true
Require-Text "build_accepts_timer_hz_arg" $build "set\s+DHRYSTONE_TIMER_HZ=%~4"
Require-Text "build_defaults_timer_hz" $build "if\s+`"%DHRYSTONE_TIMER_HZ%`"==`"`"\s+set\s+DHRYSTONE_TIMER_HZ=100000000L"
Require-Text "build_uses_timer_hz_for_main" $build "-DYH_DHRYSTONE_TIMER_HZ=%DHRYSTONE_TIMER_HZ%"
Require-Text "run_passes_clock_hz_to_build" $run "build_dhrystone\.bat`"?\s+%OUTPUT_NAME%\s+%DHRYSTONE_RUNS%\s+%TARGET%\s+%CLOCK_HZ%"
Require-Text "strict50_runner_uses_timer50" $strict50Run "set\s+DHRYSTONE_CLOCK_HZ=50000000L"
Require-Text "strict50_runner_uses_noautoinc" $strict50Run "rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_mac_noautoinc_idbr"
Require-Text "strict50_runner_calls_fpga_runner" $strict50Run "run_dhrystone_fpga\.bat`"?\s+%DHRYSTONE_TARGET%\s+%DHRYSTONE_RUNS%\s+%DHRYSTONE_CLOCK_HZ%"

if ($ok) {
  Write-Output "dhrystone_timer_clock_consistency=PASS"
  exit 0
}

Write-Output "dhrystone_timer_clock_consistency=FAIL"
exit 1
