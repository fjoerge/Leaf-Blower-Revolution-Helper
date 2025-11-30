@echo off
setlocal

REM directory of this .bat file (with trailing backslash)
set SCRIPT_DIR=%~dp0

REM if needed, switch to that directory (optional but nice)
cd /d "%SCRIPT_DIR%"

REM start PowerShell script from the same folder
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%TradingGems.v4.2.ps1"

echo.
echo Script beendet. Stats koennen jetzt markiert und kopiert werden.
pause
endlocal