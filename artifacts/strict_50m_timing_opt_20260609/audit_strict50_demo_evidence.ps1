param(
  [string]$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

function Read-Text($Path) {
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

function Check-Absent([string]$Name, [string]$Text, [string]$Pattern) {
  if ($Text -match $Pattern) {
    return "$Name contains forbidden pattern: $Pattern"
  }
  return $null
}

function Check-Param([string]$Text, [string]$Param, [string]$Expected) {
  $escaped = [regex]::Escape($Param)
  $pattern = "\.$escaped\s*\(\s*$Expected\s*\)"
  if ($Text -notmatch $pattern) {
    return "$Param expected $Expected in strict50 demo testbench"
  }
  return $null
}

$repoAbs = (Resolve-Path -LiteralPath $RepoRoot).Path
$demoSourcePath = Join-Path $repoAbs "YH_rv_cpu\sw\src\perf_demo.c"
$strictTbPath = Join-Path $repoAbs "YH_rv_cpu\tb\YH_rv_cpu_strict50_perf_demo_tb.v"
$runnerPath = Join-Path $repoAbs "YH_rv_cpu\scripts\run_strict50_perf_demo.bat"
$synthLogPath = Join-Path $repoAbs "artifacts\strict_50m_timing_opt_20260609\synth200_impl136_bhtidupd0_cpu50\logs\vivado_pynq_z2_synth.log"

$failures = @()

$demoSource = Read-Text $demoSourcePath
$synthLog = Read-Text $synthLogPath

$failures += Check-Text "perf_demo.c" $demoSource "strict50"
$failures += Check-Text "perf_demo.c" $demoSource "impl220"
$failures += Check-Text "perf_demo.c" $demoSource "50MHz"
$failures += Check-Absent "perf_demo.c" $demoSource "freeze-timingclosed-cpu25|cpu25|25MHz"

if (!(Test-Path -LiteralPath $strictTbPath)) {
  $failures += "Missing strict50 demo testbench: $strictTbPath"
} else {
  $tb = Read-Text $strictTbPath
  $expectedParams = [ordered]@{
    "IMEM_OUTPUT_REG" = "0"
    "ROM_BYTES" = "65536"
    "RAM_BYTES" = "65536"
    "ENABLE_M_EXTENSION" = "0"
    "ENABLE_ZMMUL_EXTENSION" = "1"
    "ENABLE_BITMANIP_EXTENSION" = "1"
    "ENABLE_ZBC_EXTENSION" = "1"
    "ENABLE_ZICOND_EXTENSION" = "1"
    "ENABLE_ZBKB_EXTENSION" = "0"
    "ENABLE_XTHEAD_EXTENSION" = "1"
    "ENABLE_XTHEAD_CRC_EXTENSION" = "0"
    "ENABLE_XTHEAD_MUL_EXTENSION" = "1"
    "ENABLE_XTHEAD_COND_MOVE" = "1"
    "ENABLE_XTHEAD_ADDSL_EXTENSION" = "0"
    "ENABLE_XTHEAD_MEMPAIR_EXTENSION" = "0"
    "ENABLE_XTHEAD_BASE_UPDATE_EXTENSION" = "0"
    "ENABLE_ID_BRANCH_EX_FORWARD" = "0"
    "ENABLE_ID_BRANCH_EXMEM_LOAD_FORWARD" = "0"
    "ENABLE_EX_REDIRECT_EXMEM_LOAD_FORWARD" = "0"
    "ENABLE_ID_BRANCH_FOLD" = "1"
    "ENABLE_ID_BRANCH_FOLD_LIGHT_DECODE" = "1"
    "ENABLE_ID_BRANCH_NOT_TAKEN_FOLD" = "0"
    "ENABLE_ID_BRANCH_FOLD_NEXT_CACHE" = "1"
    "ENABLE_EX_REDIRECT_FOLD" = "1"
    "ENABLE_ID_BRANCH_NT_NEXT_CACHE" = "1"
    "ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD" = "0"
    "ENABLE_ID_ALU_PAIR_FOLD" = "0"
    "ENABLE_ID_ALU_DEP_FOLD" = "0"
    "ENABLE_REDIRECT_TARGET_CACHE" = "1"
    "ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP" = "1"
    "ENABLE_REDIRECT_CACHE_REGULAR_SIMPLE_LOOKUP" = "1"
    "ENABLE_REDIRECT_CACHE_EX_SIMPLE_BLOCK" = "1"
    "ENABLE_REDIRECT_CACHE_UPDATE_ON_REDIRECT" = "0"
    "ENABLE_FETCH_REDIRECT_REUSE" = "0"
    "ENABLE_FETCH_LIVE_BYPASS" = "1"
    "ENABLE_FETCH_REDIRECT_SAME_CYCLE_REQ" = "1"
    "ENABLE_REDIRECT_CACHE_HIT_EXTRA_IMEM_REQ" = "0"
    "ENABLE_REDIRECT_CACHE_PC_SKIP" = "1"
    "ENABLE_IF_ID_PAYLOAD_SIMPLE_CE" = "1"
    "REDIRECT_CACHE_ENTRIES" = "512"
    "REDIRECT_CACHE_XOR_INDEX" = "0"
    "ENABLE_DYNAMIC_BRANCH_PREDICT" = "1"
    "BRANCH_BHT_ENTRIES" = "64"
    "BRANCH_STATIC_PREDICT_MODE" = "1"
    "BRANCH_BHT_STRONG_ONLY" = "1"
    "BRANCH_BHT_DIRECT_UPDATE" = "1"
    "ENABLE_BRANCH_BHT_ID_UPDATE" = "0"
    "DMEM_NEGEDGE_READ" = "0"
    "DMEM_READ_PREISSUE" = "0"
    "DCACHE_EN" = "1"
    "DCACHE_SIZE_BYTES" = "512"
    "ENABLE_DCACHE_LOAD_USE_SPEC" = "0"
    "ENABLE_CONTROL_REDIRECT_DCACHE_LOAD_USE_SPEC" = "0"
    "ENABLE_BRANCH_REDIRECT_DCACHE_LOAD_USE_SPEC" = "0"
    "ENABLE_JALR_REDIRECT_DCACHE_LOAD_USE_SPEC" = "0"
    "ENABLE_FRONTEND_DCACHE_LOAD_USE_SPEC" = "0"
    "ENABLE_FOLD_DCACHE_LOAD_USE_SPEC" = "0"
    "ENABLE_FOLD_EXMEM_LOAD_USE_SPEC" = "0"
    "ENABLE_EXMEM_LOAD_MUL_FORWARD" = "0"
    "ENABLE_DCACHE_NEXT_PREFETCH" = "0"
    "ENABLE_DCACHE_WORD_ONLY" = "0"
    "ICACHE_EN" = "0"
  }

  foreach ($key in $expectedParams.Keys) {
    $failures += Check-Param $tb $key $expectedParams[$key]
  }
}

if (!(Test-Path -LiteralPath $runnerPath)) {
  $failures += "Missing strict50 demo runner: $runnerPath"
} else {
  $runner = Read-Text $runnerPath
  $failures += Check-Text "run_strict50_perf_demo.bat" $runner "YH_rv_cpu_strict50_perf_demo_tb"
  $failures += Check-Text "run_strict50_perf_demo.bat" $runner "strict50_perf_demo"
}

$failures += Check-Text "synth200 log" $synthLog "REDIRECT_CACHE_ENTRIES = 512"
$failures += Check-Text "synth200 log" $synthLog "ENABLE_DCACHE_LOAD_USE_SPEC = 0"
$failures += Check-Text "synth200 log" $synthLog "ENABLE_ZICOND_EXTENSION = 1"

$failures = @($failures | Where-Object { $_ })

Write-Output "repo_root=$repoAbs"
Write-Output "demo_source=$demoSourcePath"
Write-Output "strict50_demo_testbench=$strictTbPath"
Write-Output "strict50_demo_runner=$runnerPath"
Write-Output "synth_anchor_log=$synthLogPath"

if ($failures.Count -gt 0) {
  Write-Output "strict50_demo_audit_status=FAIL"
  Write-Output "failure_count=$($failures.Count)"
  foreach ($failure in $failures) {
    Write-Output "failure=$failure"
  }
  exit 1
}

Write-Output "strict50_demo_audit_status=PASS"
