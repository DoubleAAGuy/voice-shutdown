<#
.SYNOPSIS
    One-command web installer for Voice Shutdown.
.DESCRIPTION
    Downloads the latest copy of this repo from GitHub, installs it to
    %LOCALAPPDATA%\VoiceShutdown, and registers it to start silently at every logon.
    Run this on the machine you want to install on.

    Quick install (paste into Win+R or a PowerShell window):

        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/DoubleAAGuy/voice-shutdown/main/install.ps1 | iex"

.PARAMETER Keyword
    Word or phrase that triggers shutdown. Default: "cool".
.PARAMETER Confidence
    Minimum recognition confidence 0.0-1.0. Default: 0.85.
.PARAMETER NoStart
    Register the task but do not start it immediately.
.EXAMPLE
    .\install.ps1
    Installs and starts the listener, watching for "cool".
.EXAMPLE
    .\install.ps1 -Keyword "shut it down" -Confidence 0.9
    Installs with a safer two-word phrase and a stricter threshold.
#>
[CmdletBinding()]
param(
    [string]$Keyword = "cool",
    [ValidateRange(0.0, 1.0)]
    [double]$Confidence = 0.85,
    [switch]$NoStart
)

$ErrorActionPreference = "Stop"
$Repo = "DoubleAAGuy/voice-shutdown"
$Branch = "main"
$InstallDir = Join-Path $env:LOCALAPPDATA "VoiceShutdown"
$ZipUrl = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"

Write-Host "Downloading Voice Shutdown from GitHub..."
$tmp = Join-Path $env:TEMP ("voice-shutdown-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    $zip = Join-Path $tmp "src.zip"
    Invoke-WebRequest -Uri $ZipUrl -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $tmp -Force

    $src = Get-ChildItem -Path $tmp -Directory |
        Where-Object { $_.Name -like "voice-shutdown-*" } |
        Select-Object -First 1
    if (-not $src) { throw "Could not find the extracted source folder." }

    if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -Path (Join-Path $src.FullName "*") -Destination $InstallDir -Recurse -Force
    Write-Host "Installed files to $InstallDir"
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

$installer = Join-Path $InstallDir "install-startup.ps1"
if (-not (Test-Path $installer)) { throw "Install incomplete: $installer is missing." }

$psArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $installer,
    "-Keyword", $Keyword, "-Confidence", $Confidence)
if ($NoStart) { $psArgs += "-NoStart" }

& powershell.exe @psArgs
exit $LASTEXITCODE
