@echo off
title TradingGems Launcher
color 0B

echo ================================================
echo    TradingGems Bot Launcher
echo ================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-TradingGems.ps1"
