@echo off
REM libvips-image run script for Windows
REM Usage: run.bat vips_tool.py <args>
REM        run.bat vips_batch.py <args>

setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "SKILL_DIR=%SCRIPT_DIR%\.."

REM Set libvips PATH if installed locally
if exist "%LOCALAPPDATA%\vips\bin\libvips-42.dll" (
    set "PATH=%LOCALAPPDATA%\vips\bin;%PATH%"
)

REM Also check common install locations
if exist "C:\vips\bin\libvips-42.dll" (
    set "PATH=C:\vips\bin;%PATH%"
)

REM Check for project venv
if exist "%SKILL_DIR%\.venv\Scripts\python.exe" (
    set "PYTHON=%SKILL_DIR%\.venv\Scripts\python.exe"
    goto :run
)

REM Check for uv
where uv >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if exist "%SKILL_DIR%\pyproject.toml" (
        cd /d "%SKILL_DIR%"
        uv run python "%SCRIPT_DIR%%*"
        exit /b %ERRORLEVEL%
    )
)

REM Try python commands
where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "PYTHON=python"
    goto :run
)

where python3 >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "PYTHON=python3"
    goto :run
)

where py >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "PYTHON=py"
    goto :run
)

echo Error: Python not found
exit /b 1

:run
"%PYTHON%" "%SCRIPT_DIR%%*"
exit /b %ERRORLEVEL%
