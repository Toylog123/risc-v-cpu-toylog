param(
    [string]$Port = "COM7",
    [int]$Baud = 115200,
    [string]$LogPath = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogPath = Join-Path (Get-Location) "uart_live_${Port}_${stamp}.txt"
}

$logDir = Split-Path -Parent $LogPath
if (-not [string]::IsNullOrWhiteSpace($logDir) -and -not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$serial = New-Object System.IO.Ports.SerialPort $Port, $Baud, "None", 8, "One"
$serial.Handshake = "None"
$serial.ReadTimeout = 100
$serial.WriteTimeout = 500
$serial.DtrEnable = $true
$serial.RtsEnable = $true

$writer = [System.IO.StreamWriter]::new($LogPath, $false, [System.Text.Encoding]::UTF8)

try {
    $serial.Open()
    $serial.DiscardInBuffer()
    $serial.DiscardOutBuffer()

    Write-Host "YH_rv_cpu UART live monitor"
    Write-Host "Port: $Port"
    Write-Host "Baud: $Baud, 8N1, no flow control"
    Write-Host "Log:  $LogPath"
    Write-Host "Press Ctrl+C to stop."
    Write-Host "---- live uart ----"

    $writer.WriteLine("YH_rv_cpu UART live monitor")
    $writer.WriteLine("port=$Port")
    $writer.WriteLine("baud=$Baud")
    $writer.WriteLine("settings=8N1,no parity,no flow control")
    $writer.WriteLine("started_at=$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
    $writer.WriteLine("---- live uart ----")
    $writer.Flush()

    while ($true) {
        $chunk = $serial.ReadExisting()
        if ($chunk.Length -gt 0) {
            [Console]::Write($chunk)
            $writer.Write($chunk)
            $writer.Flush()
        }
        Start-Sleep -Milliseconds 20
    }
}
finally {
    if ($serial.IsOpen) {
        $serial.Close()
    }
    $writer.WriteLine()
    $writer.WriteLine("finished_at=$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
    $writer.Close()
}
