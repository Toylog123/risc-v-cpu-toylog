param(
    [string]$ArtifactDir = $PSScriptRoot,
    [switch]$RequireBoardEvidence
)

$ErrorActionPreference = 'Stop'

$statusName = if ($RequireBoardEvidence) {
    'verify_impl136_evidence_board_required.status.txt'
} else {
    'verify_impl136_evidence.status.txt'
}
$statusPath = Join-Path $ArtifactDir $statusName
$strictSummary = Join-Path (Split-Path -Parent $ArtifactDir) 'strict10s_impl136_20260709\iter2150_cpu50timer\coremark50_fast_gate_iter2150_cpu50timer.summary.txt'

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [string]$Name,
        [bool]$Pass,
        [string]$Detail
    )
    $checks.Add([pscustomobject]@{
        Name = $Name
        Pass = $Pass
        Detail = $Detail
    }) | Out-Null
}

function Read-Text {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    return Get-Content -LiteralPath $Path -Raw
}

function Has-AllMarkers {
    param(
        [string]$Text,
        [string[]]$Markers
    )
    if ($null -eq $Text) {
        return $false
    }
    foreach ($marker in $Markers) {
        if ($Text.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0) {
            return $false
        }
    }
    return $true
}

function Resolve-EvidencePath {
    param([string]$Path)
    if (-not $Path) {
        return $null
    }
    $trimmed = $Path.Trim()
    if ([System.IO.Path]::IsPathRooted($trimmed)) {
        return $trimmed
    }
    return Join-Path $ArtifactDir $trimmed
}

function Normalize-ShaPath {
    param([string]$Path)
    if (-not $Path) {
        return ''
    }
    return $Path.Trim().Replace('\', '/').ToLowerInvariant()
}

function Get-ArtifactRelativePath {
    param([string]$Path)
    if (-not $Path) {
        return $null
    }
    $root = [System.IO.Path]::GetFullPath($ArtifactDir)
    if (-not $root.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $root = $root + [System.IO.Path]::DirectorySeparatorChar
    }
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length)
    }
    return $null
}

$uartMarkers = @(
    '2K performance run parameters for coremark.',
    'CoreMark Size    : 666',
    'Iterations       : 10',
    'seedcrc          : 0xe9f5',
    '[0]crcfinal      : 0xfcaf',
    'Correct operation validated. See README.md for run and reporting rules.'
)

$shaPath = Join-Path $ArtifactDir 'SHA256SUMS.txt'
$shaFailures = New-Object System.Collections.Generic.List[string]
$shaRelPaths = @{}
if (Test-Path -LiteralPath $shaPath) {
    foreach ($line in Get-Content -LiteralPath $shaPath) {
        if ($line -match '^([0-9a-f]{64})  (.+)$') {
            $want = $matches[1]
            $rel = $matches[2]
            $shaRelPaths[(Normalize-ShaPath $rel)] = $true
            $path = Join-Path $ArtifactDir $rel
            if (-not (Test-Path -LiteralPath $path)) {
                $shaFailures.Add("missing:$rel") | Out-Null
                continue
            }
            $got = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
            if ($got -ne $want) {
                $shaFailures.Add("mismatch:$rel") | Out-Null
            }
        }
    }
    Add-Check 'sha256sums' ($shaFailures.Count -eq 0) ($(if ($shaFailures.Count -eq 0) { 'ok' } else { $shaFailures -join ';' }))
} else {
    Add-Check 'sha256sums' $false 'missing SHA256SUMS.txt'
}

function Test-ShaCoverage {
    param([string]$PathOrRel)
    $rel = Get-ArtifactRelativePath $PathOrRel
    if (-not $rel) {
        $rel = $PathOrRel
    }
    $key = Normalize-ShaPath $rel
    return $shaRelPaths.ContainsKey($key)
}

function Add-BoardShaCoverageCheck {
    param(
        [string]$Name,
        [string]$PathOrRel,
        [bool]$Required
    )
    if ($RequireBoardEvidence) {
        $covered = $Required -and (Test-ShaCoverage $PathOrRel)
        Add-Check $Name $covered "SHA256SUMS entry required for $PathOrRel"
    } else {
        Add-Check "${Name}_boundary" $true 'board evidence SHA coverage pending; not required for offline verifier'
    }
}

$bitPath = Join-Path $ArtifactDir 'impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit'
if (Test-Path -LiteralPath $bitPath) {
    $bit = Get-Item -LiteralPath $bitPath
    $bitHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $bitPath).Hash.ToLower()
    Add-Check 'bitstream_present' (($bit.Length -eq 4045694) -and ($bitHash -eq 'ba83976a59f8596faf6f2bd9eb015188fbf96bed59c427effd4403f347d3c4d3')) "length=$($bit.Length) sha256=$bitHash"
} else {
    Add-Check 'bitstream_present' $false 'missing bitstream'
}

$bitgenLog = Read-Text (Join-Path $ArtifactDir 'vivado_write_bitstream_impl136.log')
Add-Check 'bitgen_log_markers' (Has-AllMarkers $bitgenLog @('DRC finished with 0 Errors', 'Bitgen Completed Successfully', 'write_bitstream completed successfully')) 'required Vivado bitgen markers'

$timingText = Read-Text (Join-Path $ArtifactDir 'bitstream_from_dcp_timing_summary.rpt')
Add-Check 'bitstream_timing' (Has-AllMarkers $timingText @('All user specified timing constraints are met.', '      0.017        0.000                      0                25948        0.155')) 'WNS=0.017 WHS=0.155 timing met'

$strictText = Read-Text $strictSummary
Add-Check 'strict10s_summary_present' ($null -ne $strictText) $strictSummary
Add-Check 'strict10s_summary_values' (Has-AllMarkers $strictText @('clock_hz=50000000', 'iterations=2150', 'total_seconds=10.029656', 'coremark_per_mhz=4.287286', 'crcfinal=0xea58', 'validation_clean=yes', 'strict_eembc_10s_compliant=yes', 'acceptance_pass=yes')) 'strict 10-second xsim values'

$boardRunnerText = Read-Text (Join-Path $ArtifactDir 'run_impl136_board_evidence.ps1')
Add-Check 'board_runner_refresh_hook' (Has-AllMarkers $boardRunnerText @('refresh_impl136_sha256sums.ps1', 'function Complete-Run', 'Invoke-Sha256SumsRefresh', 'SHA256SUMS_REFRESH_ATTEMPT=before_exit')) 'runner refreshes SHA256SUMS after final board result'

$shaRefreshText = Read-Text (Join-Path $ArtifactDir 'refresh_impl136_sha256sums.ps1')
Add-Check 'sha_refresh_helper_contract' (Has-AllMarkers $shaRefreshText @('[switch]$CheckOnly', 'SHA256SUMS_REFRESH_CHECK_OK', 'SHA256SUMS_REFRESH_NEEDED', 'SHA256SUMS_REFRESH_OK', 'uart_impl136.status.txt', 'uart_impl136_raw.log', 'board_video_impl136', '.mp4', '.mov', '.mkv', '.avi', '.webm', 'Set-Content -LiteralPath $shaPath -Encoding ASCII -Value $newLines')) 'refresh helper check-only mode and optional board artifacts are covered'

$programHelperText = Read-Text (Join-Path $ArtifactDir 'program_impl136_if_single_xc7z020.tcl')
Add-Check 'program_helper_single_xc7z020_guard' (Has-AllMarkers $programHelperText @('set xc7z020_devices {}', 'XC7Z020_DEVICE_COUNT=', '!= 1', 'PROGRAM_RESULT=refused_expected_single_xc7z020', 'program_hw_devices $dev', 'PROGRAM_RESULT=program_ok', 'impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit')) 'program helper keeps single-xc7z020 guard and expected bitstream'

$uartCaptureText = Read-Text (Join-Path $ArtifactDir 'capture_impl136_uart.ps1')
Add-Check 'uart_capture_marker_contract' (Has-AllMarkers $uartCaptureText ($uartMarkers + @('uart_impl136_raw.log', 'uart_impl136.status.txt', 'UART_RESULT=markers_found', 'UART_RESULT=markers_missing'))) 'UART capture script uses the verifier CoreMark markers and writes raw/status logs'

$readmeText = Read-Text (Join-Path $ArtifactDir 'README.md')
$boardTemplateText = Read-Text (Join-Path $ArtifactDir 'BOARD_EVIDENCE_TEMPLATE.md')
$docBoundaryOk =
    (Has-AllMarkers $readmeText @('not board-proven', 'PROGRAM_OK, UART evidence, and board video are still missing', 'This mode must fail until PROGRAM_OK, UART marker/raw-log evidence, and board', 'do not describe it', 'board UART evidence')) -and
    (Has-AllMarkers $boardTemplateText @('board-proven until every required item is filled', 'not strict 10-second board evidence', 'xsim-only', 'PROGRAM_OK device=...', 'UART_RESULT=markers_found', 'board_video_impl136.[mp4|mov|mkv|avi|webm]', 'must also be listed in', 'SHA256SUMS.txt'))
Add-Check 'documentation_boundary_contract' $docBoundaryOk 'README/template preserve board-evidence and xsim-only claim boundaries'

$boardRunText = Read-Text (Join-Path $ArtifactDir 'board_evidence_run_impl136.status.txt')
$boardComplete = Has-AllMarkers $boardRunText @('BOARD_EVIDENCE_RESULT=program_and_uart_ok')
if ($RequireBoardEvidence) {
    Add-Check 'board_evidence' $boardComplete 'PROGRAM_OK and UART markers required'
} else {
    $detail = if ($boardComplete) { 'board evidence complete' } else { 'board evidence pending; not required for offline verifier' }
    Add-Check 'board_evidence_boundary' $true $detail
}

$programStatusText = Read-Text (Join-Path $ArtifactDir 'program_impl136.status.txt')
if ($programStatusText -like '*PROGRAM_RESULT=program_ok*') {
    Add-Check 'program_status_boundary' $true 'program_ok present'
} else {
    Add-Check 'program_status_boundary' (-not $RequireBoardEvidence) 'no PROGRAM_OK evidence present'
}

$uartStatusText = Read-Text (Join-Path $ArtifactDir 'uart_impl136.status.txt')
$uartStatusOk = Has-AllMarkers $uartStatusText @('UART_RESULT=markers_found')
if ($RequireBoardEvidence) {
    Add-Check 'uart_status' $uartStatusOk 'UART_RESULT=markers_found required'
} else {
    $detail = if ($uartStatusOk) { 'UART markers found' } else { 'UART status pending; not required for offline verifier' }
    Add-Check 'uart_status_boundary' $true $detail
}

$rawLogPath = Join-Path $ArtifactDir 'uart_impl136_raw.log'
if ($uartStatusText -match '(?m)^RAW_LOG=(.+)$') {
    $rawLogPath = Resolve-EvidencePath $matches[1]
}
$uartRawText = Read-Text $rawLogPath
$uartRawOk = (Test-Path -LiteralPath $rawLogPath) -and (Has-AllMarkers $uartRawText $uartMarkers)
if ($RequireBoardEvidence) {
    Add-Check 'uart_raw_log' $uartRawOk "path=$rawLogPath required markers"
} else {
    $detail = if ($uartRawOk) { "UART raw log present path=$rawLogPath" } else { 'UART raw log pending; not required for offline verifier' }
    Add-Check 'uart_raw_log_boundary' $true $detail
}

$videoExtensions = @('.mp4', '.mov', '.mkv', '.avi', '.webm')
$boardVideo = @(Get-ChildItem -LiteralPath $ArtifactDir -ErrorAction SilentlyContinue | Where-Object {
    (-not $_.PSIsContainer) -and
    ($_.BaseName -eq 'board_video_impl136') -and
    ($videoExtensions -contains $_.Extension.ToLowerInvariant()) -and
    ($_.Length -gt 0)
} | Select-Object -First 1)
$boardVideoOk = ($boardVideo.Count -gt 0)
if ($RequireBoardEvidence) {
    $detail = if ($boardVideoOk) { "path=$($boardVideo[0].FullName)" } else { 'missing board_video_impl136.[mp4|mov|mkv|avi|webm]' }
    Add-Check 'board_video' $boardVideoOk $detail
} else {
    $detail = if ($boardVideoOk) { "board video present path=$($boardVideo[0].FullName)" } else { 'board video pending; not required for offline verifier' }
    Add-Check 'board_video_boundary' $true $detail
}

Add-BoardShaCoverageCheck 'program_status_sha256sum' (Join-Path $ArtifactDir 'program_impl136.status.txt') $true
Add-BoardShaCoverageCheck 'board_runner_status_sha256sum' (Join-Path $ArtifactDir 'board_evidence_run_impl136.status.txt') $true
Add-BoardShaCoverageCheck 'uart_status_sha256sum' (Join-Path $ArtifactDir 'uart_impl136.status.txt') $uartStatusOk
Add-BoardShaCoverageCheck 'uart_raw_log_sha256sum' $rawLogPath $uartRawOk
$boardVideoPath = if ($boardVideoOk) { $boardVideo[0].FullName } else { Join-Path $ArtifactDir 'board_video_impl136.mp4' }
Add-BoardShaCoverageCheck 'board_video_sha256sum' $boardVideoPath $boardVideoOk

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('VERIFY_IMPL136_EVIDENCE_START') | Out-Null
$lines.Add("ARTIFACT_DIR=$ArtifactDir") | Out-Null
$lines.Add("REQUIRE_BOARD_EVIDENCE=$($RequireBoardEvidence.IsPresent)") | Out-Null
foreach ($check in $checks) {
    $state = if ($check.Pass) { 'PASS' } else { 'FAIL' }
    $lines.Add("CHECK $state $($check.Name) $($check.Detail)") | Out-Null
}

$failed = @($checks | Where-Object { -not $_.Pass })
if ($failed.Count -eq 0) {
    $lines.Add('VERIFY_RESULT=pass') | Out-Null
    Set-Content -LiteralPath $statusPath -Encoding ASCII -Value $lines
    $lines | ForEach-Object { Write-Output $_ }
    exit 0
}

$lines.Add('VERIFY_RESULT=fail') | Out-Null
Set-Content -LiteralPath $statusPath -Encoding ASCII -Value $lines
$lines | ForEach-Object { Write-Output $_ }
exit 1
