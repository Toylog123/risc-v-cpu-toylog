param(
    [Parameter(Mandatory = $true)]
    [string]$PortName,

    [int]$BaudRate = 115200,

    [int]$TimeoutSeconds = 30,

    [string]$OutputDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$rawLog = Join-Path $OutputDir 'uart_impl136_raw.log'
$statusLog = Join-Path $OutputDir 'uart_impl136.status.txt'

$markers = @(
    '2K performance run parameters for coremark.',
    'CoreMark Size    : 666',
    'Iterations       : 10',
    'seedcrc          : 0xe9f5',
    '[0]crcfinal      : 0xfcaf',
    'Correct operation validated. See README.md for run and reporting rules.'
)

$serial = [System.IO.Ports.SerialPort]::new($PortName, $BaudRate, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
$serial.ReadTimeout = 500
$serial.NewLine = "`n"

$buffer = New-Object System.Text.StringBuilder
$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

"UART_CAPTURE_START impl136" | Set-Content -LiteralPath $statusLog -Encoding ASCII
"PORT=$PortName BAUD=$BaudRate TIMEOUT_SECONDS=$TimeoutSeconds" | Add-Content -LiteralPath $statusLog -Encoding ASCII

try {
    $serial.Open()
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            $chunk = $serial.ReadExisting()
            if ($chunk.Length -gt 0) {
                [void]$buffer.Append($chunk)
            }
        } catch [TimeoutException] {
        }
        Start-Sleep -Milliseconds 100
    }
} finally {
    if ($serial.IsOpen) {
        $serial.Close()
    }
}

$text = $buffer.ToString()
$text | Set-Content -LiteralPath $rawLog -Encoding ASCII

$missing = @()
foreach ($marker in $markers) {
    if ($text -notlike "*$marker*") {
        $missing += $marker
    }
}

"RAW_LOG=$rawLog" | Add-Content -LiteralPath $statusLog -Encoding ASCII
"BYTES=$($text.Length)" | Add-Content -LiteralPath $statusLog -Encoding ASCII
if ($missing.Count -eq 0) {
    "UART_RESULT=markers_found" | Add-Content -LiteralPath $statusLog -Encoding ASCII
    exit 0
}

"UART_RESULT=markers_missing" | Add-Content -LiteralPath $statusLog -Encoding ASCII
foreach ($marker in $missing) {
    "MISSING_MARKER=$marker" | Add-Content -LiteralPath $statusLog -Encoding ASCII
}
exit 1
