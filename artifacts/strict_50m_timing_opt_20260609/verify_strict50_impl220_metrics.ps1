param(
  [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$ErrorActionPreference = "Stop"

function Read-Text($Path) {
  if (!(Test-Path -LiteralPath $Path)) {
    throw "Missing required evidence file: $Path"
  }
  return Get-Content -Raw -LiteralPath $Path
}

function Get-FirstMatch($Text, $Pattern, $Name) {
  $m = [regex]::Match($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if (!$m.Success) {
    throw "Could not parse $Name with pattern: $Pattern"
  }
  return $m.Groups[1].Value
}

$candidate = "impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50"
$timingPath = Join-Path $Root "$candidate/reports_cpu50/impl_timing_summary.rpt"
$utilPath = Join-Path $Root "$candidate/reports_cpu50/impl_utilization.rpt"
$coremarkPath = Join-Path $Root "fast210_impl136cfg_bhtid0_current_iter10/coremark50_fast_gate_iter10.summary.txt"

$timing = Read-Text $timingPath
$util = Read-Text $utilPath
$coremark = Read-Text $coremarkPath

$timingClosed = $timing.Contains("All user specified timing constraints are met.")
$timingRow = [regex]::Match(
  $timing,
  "^\s*([+-]?\d+\.\d+)\s+([+-]?\d+\.\d+)\s+\d+\s+\d+\s+([+-]?\d+\.\d+)\s+",
  [System.Text.RegularExpressions.RegexOptions]::Multiline
)
if (!$timingRow.Success) {
  throw "Could not parse timing summary WNS/WHS row."
}
$wns = $timingRow.Groups[1].Value
$whs = $timingRow.Groups[3].Value

$lut = Get-FirstMatch $util "^\|\s*Slice LUTs\s*\|\s*(\d+)\s*\|" "Slice LUTs"
$ff = Get-FirstMatch $util "^\|\s*Slice Registers\s*\|\s*(\d+)\s*\|" "Slice Registers"
$bram = Get-FirstMatch $util "^\|\s*Block RAM Tile\s*\|\s*(\d+)\s*\|" "Block RAM Tile"
$dsp = Get-FirstMatch $util "^\|\s*DSPs\s*\|\s*(\d+)\s*\|" "DSPs"

$coremarkPerMhz = Get-FirstMatch $coremark "^coremark_per_mhz=([0-9.]+)" "coremark_per_mhz"
$crcFinal = Get-FirstMatch $coremark "^crcfinal=(0x[0-9a-fA-F]+)" "crcfinal"
$acceptancePass = Get-FirstMatch $coremark "^acceptance_pass=(\w+)" "acceptance_pass"
$strictEembc = Get-FirstMatch $coremark "^strict_eembc_10s_compliant=(\w+)" "strict_eembc_10s_compliant"
$validationMode = Get-FirstMatch $coremark "^validation_mode=([^\r\n]+)" "validation_mode"

$expected = [ordered]@{
  lut = "9965"
  ff = "6520"
  bram_tile = "32"
  dsp = "8"
  coremark_per_mhz = "4.287521"
  crcfinal = "0xfcaf"
  acceptance_pass = "yes"
  strict_eembc_10s_compliant = "no"
  wns_ns = "0.056"
  whs_ns = "0.121"
  timing_closed = "True"
}

$actual = [ordered]@{
  candidate = $candidate
  timing_report = $timingPath
  utilization_report = $utilPath
  coremark_summary = $coremarkPath
  lut = $lut
  ff = $ff
  bram_tile = $bram
  dsp = $dsp
  coremark_per_mhz = $coremarkPerMhz
  crcfinal = $crcFinal
  acceptance_pass = $acceptancePass
  strict_eembc_10s_compliant = $strictEembc
  validation_mode = $validationMode
  wns_ns = $wns
  whs_ns = $whs
  timing_closed = [string]$timingClosed
}

$failures = @()
foreach ($key in $expected.Keys) {
  if ([string]$actual[$key] -ne [string]$expected[$key]) {
    $failures += "$key expected=$($expected[$key]) actual=$($actual[$key])"
  }
}

$actual.GetEnumerator() | ForEach-Object {
  Write-Output "$($_.Key)=$($_.Value)"
}

if ($failures.Count -gt 0) {
  Write-Output "verification_status=FAIL"
  $failures | ForEach-Object { Write-Output "failure=$_" }
  exit 1
}

Write-Output "verification_status=PASS"
