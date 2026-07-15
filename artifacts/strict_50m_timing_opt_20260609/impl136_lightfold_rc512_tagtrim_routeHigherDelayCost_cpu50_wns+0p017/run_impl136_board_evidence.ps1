param(
    [string]$PortName = '',

    [int]$UartTimeoutSeconds = 45,

    [string]$VivadoExe = 'vivado',

    [switch]$SkipProgram,

    [switch]$SkipUart
)

$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$statusPath = Join-Path $scriptDir 'board_evidence_run_impl136.status.txt'
$probeStatus = Join-Path $scriptDir 'hw_probe_impl136.status.txt'
$programStatus = Join-Path $scriptDir 'program_impl136.status.txt'
$uartStatus = Join-Path $scriptDir 'uart_impl136.status.txt'

function Write-Status {
    param([string]$Message)
    Write-Output $Message
    Add-Content -LiteralPath $statusPath -Encoding ASCII -Value $Message
}

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Status "STEP_START=$Name"
    try {
        & $Action
        Write-Status "STEP_RESULT=$Name success"
        return $true
    } catch {
        Write-Status "STEP_RESULT=$Name failed"
        Write-Status "ERROR=$($_.Exception.Message)"
        return $false
    }
}

function Invoke-VivadoScript {
    param(
        [string]$Source,
        [string]$Log,
        [string]$Journal,
        [switch]$AllowFailure
    )

    $args = @(
        '-mode', 'batch',
        '-notrace',
        '-source', $Source,
        '-log', $Log,
        '-journal', $Journal
    )
    & $VivadoExe @args
    $exitCode = $LASTEXITCODE
    if (($exitCode -ne 0) -and (-not $AllowFailure)) {
        throw "Vivado exited with code $exitCode for $Source"
    }
    return $exitCode
}

function Resolve-PowerShellExe {
    $psExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $psExe) {
        $psExe = (Get-Command powershell -ErrorAction Stop).Source
    }
    return $psExe
}

function Invoke-Sha256SumsRefresh {
    $refreshScript = Join-Path $scriptDir 'refresh_impl136_sha256sums.ps1'
    if (-not (Test-Path -LiteralPath $refreshScript)) {
        throw "Missing SHA256SUMS refresh helper: $refreshScript"
    }

    Write-Status "SHA256SUMS_REFRESH_SCRIPT=$refreshScript"
    Write-Status 'SHA256SUMS_REFRESH_ATTEMPT=before_exit'
    $psExe = Resolve-PowerShellExe
    & $psExe -NoProfile -ExecutionPolicy Bypass -File $refreshScript
    if ($LASTEXITCODE -ne 0) {
        throw "SHA256SUMS refresh exited with code $LASTEXITCODE"
    }
}

function Complete-Run {
    param(
        [string]$Result,
        [int]$ExitCode
    )

    Write-Status "BOARD_EVIDENCE_RESULT=$Result"
    try {
        Invoke-Sha256SumsRefresh
    } catch {
        Write-Status 'SHA256SUMS_REFRESH_RESULT=failed'
        Write-Status "ERROR=$($_.Exception.Message)"
        exit 1
    }
    exit $ExitCode
}

Set-Content -LiteralPath $statusPath -Encoding ASCII -Value 'BOARD_EVIDENCE_RUN_START impl136'
Write-Status "SCRIPT_DIR=$scriptDir"
Write-Status "PORT_NAME=$PortName"
Write-Status "UART_TIMEOUT_SECONDS=$UartTimeoutSeconds"
Write-Status "SKIP_PROGRAM=$($SkipProgram.IsPresent)"
Write-Status "SKIP_UART=$($SkipUart.IsPresent)"

$ports = [System.IO.Ports.SerialPort]::GetPortNames()
Write-Status "SERIAL_PORTS=$($ports -join ',')"

$probeOk = Run-Step 'probe_hw_targets' {
    Invoke-VivadoScript `
        -Source (Join-Path $scriptDir 'probe_hw_targets_impl136.tcl') `
        -Log (Join-Path $scriptDir 'vivado_hw_probe_impl136.log') `
        -Journal (Join-Path $scriptDir 'vivado_hw_probe_impl136.jou') `
        -AllowFailure | Out-Null
}

$probeText = if (Test-Path -LiteralPath $probeStatus) {
    Get-Content -LiteralPath $probeStatus -Raw
} else {
    ''
}
Write-Status "PROBE_STATUS_PRESENT=$([bool]$probeText)"
if ($probeText) {
    foreach ($line in ($probeText -split "`r?`n")) {
        if ($line -match '^(HW_PROBE_RESULT|HW_DEVICE_TOTAL_COUNT|HW_TARGET_COUNT)=') {
            Write-Status $line
        }
    }
}

$programRan = $false
$programOk = $false
$programText = ''
if ($SkipProgram) {
    Write-Status 'PROGRAM_SKIPPED=explicit'
} elseif ($probeText -notmatch 'HW_PROBE_RESULT=devices_detected') {
    Write-Status 'PROGRAM_SKIPPED=no_detected_device'
} else {
    $programRan = $true
    $programOk = Run-Step 'program_impl136' {
        Invoke-VivadoScript `
            -Source (Join-Path $scriptDir 'program_impl136_if_single_xc7z020.tcl') `
            -Log (Join-Path $scriptDir 'vivado_program_impl136.log') `
            -Journal (Join-Path $scriptDir 'vivado_program_impl136.jou') | Out-Null
    }
    $programText = if (Test-Path -LiteralPath $programStatus) {
        Get-Content -LiteralPath $programStatus -Raw
    } else {
        ''
    }
    if ($programText) {
        foreach ($line in ($programText -split "`r?`n")) {
            if ($line -match '^(PROGRAM_RESULT|PROGRAM_OK)=') {
                Write-Status $line
            }
        }
    }
}

$programCurrentOk = $programRan -and ($programText -match 'PROGRAM_RESULT=program_ok')
$uartRan = $false
$uartText = ''
if ($SkipUart) {
    Write-Status 'UART_SKIPPED=explicit'
} elseif (-not $PortName) {
    Write-Status 'UART_SKIPPED=no_port_name'
} elseif ((-not $programCurrentOk) -and (-not $SkipProgram)) {
    Write-Status 'UART_SKIPPED=program_not_ok'
} else {
    $uartRan = $true
    Run-Step 'capture_uart' {
        $psExe = Resolve-PowerShellExe
        & $psExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir 'capture_impl136_uart.ps1') `
            -PortName $PortName `
            -TimeoutSeconds $UartTimeoutSeconds `
            -OutputDir $scriptDir
        if ($LASTEXITCODE -ne 0) {
            throw "UART capture exited with code $LASTEXITCODE"
        }
    } | Out-Null
}

$uartText = if ($uartRan -and (Test-Path -LiteralPath $uartStatus)) {
    Get-Content -LiteralPath $uartStatus -Raw
} else {
    ''
}
if ($uartText) {
    foreach ($line in ($uartText -split "`r?`n")) {
        if ($line -match '^(UART_RESULT|BYTES|RAW_LOG)=') {
            Write-Status $line
        }
    }
}

if ($programCurrentOk -and ($uartText -match 'UART_RESULT=markers_found')) {
    Complete-Run -Result 'program_and_uart_ok' -ExitCode 0
}

if ($SkipProgram -and ($uartText -match 'UART_RESULT=markers_found')) {
    Complete-Run -Result 'uart_ok_program_skipped' -ExitCode 1
}

Complete-Run -Result 'incomplete' -ExitCode 1
