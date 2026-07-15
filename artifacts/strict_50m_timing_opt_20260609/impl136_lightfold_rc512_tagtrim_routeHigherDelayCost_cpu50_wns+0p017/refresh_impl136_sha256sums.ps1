param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

$artifactDir = $PSScriptRoot
$shaPath = Join-Path $artifactDir 'SHA256SUMS.txt'

function Normalize-RelPath {
    param([string]$Path)
    return $Path.Trim().Replace('\', '/')
}

function Get-Key {
    param([string]$Path)
    return (Normalize-RelPath $Path).ToLowerInvariant()
}

function Get-HashLine {
    param([string]$RelPath)
    $normalized = Normalize-RelPath $RelPath
    $fullPath = Join-Path $artifactDir $normalized
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Listed SHA256SUMS path is missing: $normalized"
    }
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $fullPath).Hash.ToLowerInvariant()
    return "$hash  $normalized"
}

if (-not (Test-Path -LiteralPath $shaPath)) {
    throw "Missing SHA256SUMS.txt at $shaPath"
}

$entries = New-Object System.Collections.Generic.List[string]
$seen = @{}

foreach ($line in Get-Content -LiteralPath $shaPath) {
    if ($line -match '^[0-9a-fA-F]{64}\s+(.+)$') {
        $rel = Normalize-RelPath $matches[1]
        $key = Get-Key $rel
        if (-not $seen.ContainsKey($key)) {
            $entries.Add($rel) | Out-Null
            $seen[$key] = $true
        }
    }
}

$optional = New-Object System.Collections.Generic.List[string]
foreach ($rel in @(
    'refresh_impl136_sha256sums.ps1',
    'uart_impl136.status.txt',
    'uart_impl136_raw.log'
)) {
    $optional.Add($rel) | Out-Null
}

foreach ($video in Get-ChildItem -LiteralPath $artifactDir -ErrorAction SilentlyContinue | Where-Object {
    (-not $_.PSIsContainer) -and
    ($_.BaseName -eq 'board_video_impl136') -and
    (@('.mp4', '.mov', '.mkv', '.avi', '.webm') -contains $_.Extension.ToLowerInvariant())
} | Sort-Object Name) {
    $optional.Add($video.Name) | Out-Null
}

$added = 0
foreach ($rel in $optional) {
    $fullPath = Join-Path $artifactDir $rel
    $key = Get-Key $rel
    if ((Test-Path -LiteralPath $fullPath) -and (-not $seen.ContainsKey($key))) {
        $entries.Add((Normalize-RelPath $rel)) | Out-Null
        $seen[$key] = $true
        $added++
    }
}

$newLines = New-Object System.Collections.Generic.List[string]
foreach ($rel in $entries) {
    $newLines.Add((Get-HashLine $rel)) | Out-Null
}

$currentLines = @(Get-Content -LiteralPath $shaPath)
$same = ($currentLines.Count -eq $newLines.Count)
if ($same) {
    for ($i = 0; $i -lt $newLines.Count; $i++) {
        if ($currentLines[$i] -ne $newLines[$i]) {
            $same = $false
            break
        }
    }
}

if ($CheckOnly) {
    if ($same) {
        Write-Output "SHA256SUMS_REFRESH_CHECK_OK entries=$($newLines.Count)"
        exit 0
    }
    Write-Output "SHA256SUMS_REFRESH_NEEDED entries=$($newLines.Count) added=$added"
    exit 1
}

Set-Content -LiteralPath $shaPath -Encoding ASCII -Value $newLines
Write-Output "SHA256SUMS_REFRESH_OK entries=$($newLines.Count) added=$added"
