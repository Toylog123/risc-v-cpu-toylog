@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI

set XVLOG=
set XELAB=
set XSIM=
for %%T in (xvlog.bat xvlog) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XVLOG=%%T
        goto :xvlog_done
    )
)
:xvlog_done
for %%T in (xelab.bat xelab) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XELAB=%%T
        goto :xelab_done
    )
)
:xelab_done
for %%T in (xsim.bat xsim) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XSIM=%%T
        goto :xsim_done
    )
)
:xsim_done

if not defined XVLOG (
    echo Missing xvlog.
    exit /b 1
)
if not defined XELAB (
    echo Missing xelab.
    exit /b 1
)
if not defined XSIM (
    echo Missing xsim.
    exit /b 1
)

set RUN_DIR=%PROJECT_DIR%\build\tb\dcache_word_xsim
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"
pushd "%RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dcache_word_tb.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_dcache.v"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

call %XELAB% YH_rv_cpu_dcache_word_tb -s YH_rv_cpu_dcache_word_tb_snapshot
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

call %XSIM% YH_rv_cpu_dcache_word_tb_snapshot -runall
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

popd
endlocal
