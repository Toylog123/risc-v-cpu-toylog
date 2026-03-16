$ErrorActionPreference = "Stop"

$projectDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cmd = (
    'subst Z: "{0}" >nul && ' +
    'Z: && cd \ && ' +
    'iverilog -g2012 -tnull -I rtl ' +
    'tb\toylog_cpu_tb.v ' +
    'rtl\toylog_cpu.v ' +
    'rtl\toylog_cpu_if_stage.v ' +
    'rtl\toylog_cpu_id_stage.v ' +
    'rtl\toylog_cpu_ex_stage.v ' +
    'rtl\toylog_cpu_mem_stage.v ' +
    'rtl\toylog_cpu_wb_stage.v ' +
    'rtl\toylog_cpu_hazard_unit.v ' +
    'rtl\toylog_cpu_decoder.v ' +
    'rtl\toylog_cpu_regfile.v ' +
    'rtl\toylog_cpu_alu.v ' +
    '& set EC=%ERRORLEVEL% & subst Z: /d >nul & exit /b %EC%'
) -f $projectDir

cmd /c $cmd
exit $LASTEXITCODE
