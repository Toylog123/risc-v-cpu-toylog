param(
    [string]$Port = "",
    [int]$Baud = 115200,
    [int]$Seconds = 15,
    [string]$LogPath = "",
    [switch]$List
)

$ErrorActionPreference = "Stop"

function Show-Ports {
    Get-PnpDevice -Class Ports |
        Select-Object Status, FriendlyName, InstanceId |
        Format-Table -AutoSize
}

if ($List -or [string]::IsNullOrWhiteSpace($Port)) {
    Show-Ports
    if ([string]::IsNullOrWhiteSpace($Port)) {
        Write-Host ""
        Write-Host "Usage: powershell -ExecutionPolicy Bypass -File .\scripts\capture_uart.ps1 -Port COMx [-Seconds 20] [-LogPath log.txt]"
        exit 0
    }
}

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogPath = Join-Path (Get-Location) "uart_capture_${Port}_${stamp}.txt"
}

$logDir = Split-Path -Parent $LogPath
if (-not [string]::IsNullOrWhiteSpace($logDir) -and -not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$serial = New-Object System.IO.Ports.SerialPort $Port, $Baud, "None", 8, "One"
$serial.Handshake = "None"
$serial.ReadTimeout = 200
$serial.WriteTimeout = 500
$serial.DtrEnable = $true
$serial.RtsEnable = $true

$capture = New-Object System.Text.StringBuilder
$startedAt = Get-Date

try {
    $serial.Open()
    Start-Sleep -Milliseconds 200

    Write-Host "UART capture started: port=$Port baud=$Baud seconds=$Seconds"
    Write-Host "Terminal settings: 115200 8N1, no parity, no flow control"
    Write-Host "Press reset/release SW0 on the board now if you want to capture the boot banner."
    Write-Host "---- live uart ----"

    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        $chunk = $serial.ReadExisting()
        if ($chunk.Length -gt 0) {
            [void]$capture.Append($chunk)
            [Console]::Write($chunk)
        }
        Start-Sleep -Milliseconds 50
    }
}
finally {
    if ($serial.IsOpen) {
        $serial.Close()
    }
}

$text = $capture.ToString()
$header = @(
    "port=$Port",
    "baud=$Baud",
    "settings=8N1,no parity,no flow control",
    "started_at=$($startedAt.ToString('yyyy-MM-dd HH:mm:ss'))",
    "finished_at=$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))",
    "captured_chars=$($text.Length)",
    "--- capture ---"
) -join "`r`n"

Set-Content -LiteralPath $LogPath -Value ($header + "`r`n" + $text) -Encoding UTF8
Write-Host ""
Write-Host "---- capture summary ----"
Write-Host "captured_chars=$($text.Length)"
Write-Host "log=$LogPath"

if ($text.Length -eq 0) {
    Write-Host "No UART text captured. Check that the selected COM port is connected to the PL soft CPU UART TX pin."
    Write-Host "For PYNQ-Z2 submission bitstream, PL UART TX is Pmod B JB1/Y14 and needs an external 3.3 V USB-UART adapter."
}
