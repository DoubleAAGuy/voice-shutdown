@echo off
REM Double-click to install Voice Shutdown as an auto-start-at-login task.
REM Runs install-startup.ps1 sitting next to this file.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-startup.ps1" %*
echo.
pause
