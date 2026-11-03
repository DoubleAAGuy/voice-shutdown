<#
.SYNOPSIS
    Installs Voice Shutdown into %LOCALAPPDATA%\VoiceShutdown and registers it to
    start automatically, silently, at every logon.
.DESCRIPTION
    Copies the needed files to a stable per-user folder, then creates a Scheduled
    Task (per-user) that runs voice-shutdown.ps1 hidden at logon. Re-run to update.
    Use uninstall-startup.ps1 to remove.
.PARAMETER Keyword
    Keyword to listen for. Default: "very amazing".
.PARAMETER Confidence
    Minimum confidence 0.0-1.0. Default: 0.85.
.PARAMETER NoStart
    Register the task but do not start it immediately.
#>
[CmdletBinding()]
param(
    [string]$Keyword = "very amazing",
    [ValidateRange(0.0, 1.0)]
    [double]$Confidence = 0.85,
    [switch]$NoStart
)

$ErrorActionPreference = "Stop"
$TaskName = "VoiceShutdownListener"
$InstallDir = Join-Path $env:LOCALAPPDATA "VoiceShutdown"
$Here = $PSScriptRoot
$Required = @("voice-shutdown.ps1", "run-hidden.vbs")

foreach ($f in $Required) {
    if (-not (Test-Path (Join-Path $Here $f))) {
        Write-Error "Missing '$f' next to this installer ($Here)."
        exit 1
    }
}

# Copy into the stable install folder unless we are already running from it.
if ((Resolve-Path $Here).Path.TrimEnd('\') -ne $InstallDir.TrimEnd('\')) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    foreach ($f in @("voice-shutdown.ps1", "run-hidden.vbs", "uninstall-startup.ps1", "README.md")) {
        $src = Join-Path $Here $f
        if (Test-Path $src) { Copy-Item $src -Destination $InstallDir -Force }
    }
    Write-Host "Copied files to $InstallDir"
}

$VbsPath = Join-Path $InstallDir "run-hidden.vbs"

# Launch through wscript + the .vbs so NO console window (not even a flash)
# appears at logon. wscript starts the PowerShell process fully hidden.
$wsArgs = "`"$VbsPath`" `"$Keyword`" $Confidence"

$action    = New-ScheduledTaskAction -Execute "wscript.exe" -Argument $wsArgs
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "Installed scheduled task '$TaskName' -> $InstallDir"
Write-Host "It will listen for '$Keyword' automatically at every logon."
if (-not $NoStart) {
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "Started now."
}
Write-Host "To remove: run uninstall-startup.ps1"
