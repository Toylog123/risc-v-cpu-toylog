$ErrorActionPreference = "Stop"

$projectDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cmd = (
    'subst Z: "{0}" >nul && ' +
    'Z: && cd \ && ' +
    'iverilog -g2012 -tnull -I rtl -f scripts\iverilog_sources.f ' +
    '& set EC=%ERRORLEVEL% & subst Z: /d >nul & exit /b %EC%'
) -f $projectDir

cmd /c $cmd
exit $LASTEXITCODE
