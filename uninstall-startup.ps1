<#
.SYNOPSIS
    Removes the voice-shutdown auto-start scheduled task.
#>
$ErrorActionPreference = "SilentlyContinue"
$TaskName = "VoiceShutdownListener"

Stop-ScheduledTask -TaskName $TaskName
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed scheduled task '$TaskName'."
} else {
    Write-Host "Task '$TaskName' was not installed."
}
