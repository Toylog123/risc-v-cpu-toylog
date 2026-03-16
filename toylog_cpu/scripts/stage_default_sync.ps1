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
    'toylog_cpu',
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
