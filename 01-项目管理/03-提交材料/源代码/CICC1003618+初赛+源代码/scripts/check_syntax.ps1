# CICC1003618 submission context:
# File role: scripts/check_syntax.ps1 is part of the reproducible build, simulation or reporting script.
# Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
# Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
# Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
# Verification note: functional changes require matching simulation logs or FPGA reports.
# Maintenance note: update documents, metrics and hashes when this file changes.

$ErrorActionPreference = "Stop"

# Syntax-only guard used before packaging the preliminary submission sources.
# The script maps the source tree to a short drive path because some Windows
# EDA tools still have fragile path-length handling when projects live under
# synchronized cloud folders or Chinese directory names.
# It invokes Icarus Verilog in parse/elaboration mode only; no simulation
# outputs are generated and no RTL files are rewritten.
# A non-zero process exit is propagated so batch wrappers and CI-style checks
# can fail fast on malformed Verilog or missing include paths.

$projectDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cmd = (
    'subst Z: "{0}" >nul && ' +
    'Z: && cd \ && ' +
    'iverilog -g2012 -tnull -I rtl -f scripts\iverilog_sources.f ' +
    '& set EC=%ERRORLEVEL% & subst Z: /d >nul & exit /b %EC%'
) -f $projectDir

cmd /c $cmd
exit $LASTEXITCODE
