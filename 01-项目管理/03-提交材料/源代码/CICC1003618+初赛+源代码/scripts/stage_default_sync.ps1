# CICC1003618 submission context:
# File role: scripts/stage_default_sync.ps1 is part of the reproducible build, simulation or reporting script.
# Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
# Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
# Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
# Verification note: functional changes require matching simulation logs or FPGA reports.
# Maintenance note: update documents, metrics and hashes when this file changes.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardArgs
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$dryRun = $ForwardArgs -contains '--dry-run'

Set-Location $repoRoot

$projectMgmtDir = Split-Path -Leaf (Resolve-Path '01-*')
$toolchainDir = Split-Path -Leaf (Resolve-Path '04-*')

$syncPaths = @(
    'YH_rv_cpu',
    $toolchainDir,
    $projectMgmtDir
)

if ($dryRun) {
    Write-Host 'Default sync scope:'
    foreach ($path in $syncPaths) {
        Write-Host "  $path"
    }
    & git status --short -- @syncPaths
    exit $LASTEXITCODE
}

& git add -A -- @syncPaths
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Host "Default sync staging failed, exit code=$exitCode"
    exit $exitCode
}

Write-Host 'Staged with default sync scope:'
foreach ($path in $syncPaths) {
    Write-Host "  $path"
}

exit 0
