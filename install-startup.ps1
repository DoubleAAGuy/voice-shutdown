<#
.SYNOPSIS
    Registers voice-shutdown to start automatically and silently every time you log in.
.DESCRIPTION
    Creates a Scheduled Task (per-user) that runs voice-shutdown.ps1 hidden at logon.
    Re-run to update. Use uninstall-startup.ps1 to remove.
.PARAMETER Keyword
    Keyword to listen for. Default: "agrivated".
.PARAMETER Confidence
    Minimum confidence 0.0-1.0. Default: 0.85.
#>
[CmdletBinding()]
param(
    [string]$Keyword = "agrivated",
    [double]$Confidence = 0.85
)

$ErrorActionPreference = "Stop"
$TaskName = "VoiceShutdownListener"
$ScriptPath = Join-Path $PSScriptRoot "voice-shutdown.ps1"
$VbsPath = Join-Path $PSScriptRoot "run-hidden.vbs"

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Cannot find voice-shutdown.ps1 next to this installer."
    exit 1
}
if (-not (Test-Path $VbsPath)) {
    Write-Error "Cannot find run-hidden.vbs next to this installer."
    exit 1
}

# Launch through wscript + the .vbs so NO console window (not even a flash)
# appears at logon. wscript starts the PowerShell process fully hidden.
$wsArgs = "`"$VbsPath`" `"$Keyword`" $Confidence"

$action    = New-ScheduledTaskAction -Execute "wscript.exe" -Argument $wsArgs
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "Installed scheduled task '$TaskName'."
Write-Host "It will listen for '$Keyword' automatically at every logon."
Write-Host "Starting it now..."
Start-ScheduledTask -TaskName $TaskName
Write-Host "Done. To remove: run uninstall-startup.ps1"
