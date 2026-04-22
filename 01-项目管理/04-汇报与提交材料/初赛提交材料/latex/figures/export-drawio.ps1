param(
    [switch]$Transparent
)

$candidates = @(
    'C:\Program Files\draw.io\draw.io.exe',
    'C:\Program Files\Diagrams.net\draw.io.exe'
)

$drawio = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $drawio) {
    throw 'draw.io.exe not found. Install draw.io/diagrams.net first.'
}

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jobs = @(
    @{ Input = '01-system-architecture.drawio'; Output = '01-system-architecture-ai.png' },
    @{ Input = '02-pipeline-control.drawio'; Output = '02-pipeline-control-ai.png' },
    @{ Input = '03-validation-closure.drawio'; Output = '03-validation-closure-ai.png' },
    @{ Input = '04-fpga-prototype-flow.drawio'; Output = '04-fpga-prototype-flow-ai.png' }
)

foreach ($job in $jobs) {
    $inputPath = Join-Path $dir $job.Input
    $outputPath = Join-Path $dir $job.Output
    $args = @('-x', '-f', 'png')
    if ($Transparent) {
        $args += '--transparent'
    }
    $args += @('-o', $outputPath, $inputPath)

    & $drawio @args | Out-Null
    if (-not (Test-Path $outputPath)) {
        throw "Export failed for $($job.Input)"
    }

    Write-Host "Exported $($job.Output)"
}
