@echo off
REM Double-click to install Voice Shutdown (downloads from GitHub, installs to
REM %LOCALAPPDATA%\VoiceShutdown, and starts it automatically at every logon).
REM Extra arguments are passed through, e.g.  install.bat -Keyword "shut it down"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
echo.
pause
