<#
.SYNOPSIS
    Removes the Voice Shutdown auto-start task and the installed files.
#>
$ErrorActionPreference = "SilentlyContinue"
$TaskName = "VoiceShutdownListener"
$InstallDir = Join-Path $env:LOCALAPPDATA "VoiceShutdown"

Stop-ScheduledTask -TaskName $TaskName
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed scheduled task '$TaskName'."
} else {
    Write-Host "Task '$TaskName' was not installed."
}

# Stop the hidden listener if it is still running, then remove the files.
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
    Where-Object { $_.CommandLine -like "*$InstallDir*voice-shutdown.ps1*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
    Write-Host "Removed $InstallDir."
}

Write-Host "Voice Shutdown has been uninstalled."
