<#
.SYNOPSIS
    Always-on voice keyword listener that shuts down Windows when you say a keyword.

.DESCRIPTION
    Uses the built-in offline Windows Speech Recognizer (System.Speech / SAPI).
    No internet, no external dependencies, no model downloads. Listens continuously
    for a spoken keyword (default: "agrivated"). When heard with enough confidence it
    starts a short cancellable countdown, then shuts the PC down.

    Say the cancel word (default: "cancel") during the countdown to abort.

.PARAMETER Keyword
    The word or phrase that triggers shutdown. Default: "agrivated".
    A two-word phrase (e.g. "computer shutdown") is recommended to avoid false triggers.

.PARAMETER CancelWord
    The word that aborts the countdown. Default: "cancel".

.PARAMETER Confidence
    Minimum recognition confidence (0.0 - 1.0) required to accept the keyword.
    Higher = fewer false positives but you may need to speak more clearly. Default: 0.85.

.PARAMETER CountdownSeconds
    Seconds to wait (cancellable) before shutting down. Default: 5.

.PARAMETER Test
    Dry run. Detects the keyword and runs the countdown but does NOT shut down.
    Use this to confirm your mic and keyword work safely.

.PARAMETER Force
    Force applications to close during shutdown (adds /f to shutdown).

.EXAMPLE
    .\voice-shutdown.ps1
    Listens for "agrivated".

.EXAMPLE
    .\voice-shutdown.ps1 -Keyword "computer shutdown" -Test
    Safe test run with a two-word phrase; never actually shuts down.
#>

[CmdletBinding()]
param(
    [string]$Keyword = "agrivated",
    [string]$CancelWord = "cancel",
    [ValidateRange(0.0, 1.0)]
    [double]$Confidence = 0.85,
    [ValidateRange(0, 3600)]
    [int]$CountdownSeconds = 5,
    [switch]$Test,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ---- Logging -------------------------------------------------------------
$LogFile = Join-Path $PSScriptRoot "voice-shutdown.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$stamp] [$Level] $Message"
    Write-Host $line
    try { Add-Content -Path $LogFile -Value $line -Encoding utf8 } catch { }
}

# ---- Load speech engine --------------------------------------------------
try {
    Add-Type -AssemblyName System.Speech
} catch {
    Write-Log "Failed to load System.Speech. This requires Windows Desktop with the Speech feature." "ERROR"
    exit 1
}

$recognizers = [System.Speech.Recognition.SpeechRecognitionEngine]::InstalledRecognizers()
if (-not $recognizers -or $recognizers.Count -eq 0) {
    Write-Log "No speech recognizers installed. Enable Windows Speech Recognition (Settings > Time & Language > Speech)." "ERROR"
    exit 1
}

Write-Log "Starting voice-shutdown. Keyword='$Keyword' Cancel='$CancelWord' Confidence=$Confidence Countdown=${CountdownSeconds}s Test=$($Test.IsPresent)"

$engine = New-Object System.Speech.Recognition.SpeechRecognitionEngine

# ---- Build a constrained grammar (keyword + cancel word) -----------------
$choices = New-Object System.Speech.Recognition.Choices
$choices.Add($Keyword)
$choices.Add($CancelWord)
$gb = New-Object System.Speech.Recognition.GrammarBuilder
$gb.Append($choices)
$grammar = New-Object System.Speech.Recognition.Grammar $gb
$engine.LoadGrammar($grammar)

# ---- Set audio input to default microphone -------------------------------
try {
    $engine.SetInputToDefaultAudioDevice()
} catch {
    Write-Log "No microphone found or access denied. Plug in a mic and allow microphone access in Windows Privacy settings." "ERROR"
    exit 1
}

# ---- Shared state --------------------------------------------------------
$script:CancelRequested = $false

function Invoke-Shutdown {
    Write-Log "Keyword confirmed. Beginning ${CountdownSeconds}s countdown. Say '$CancelWord' to abort." "WARN"
    $script:CancelRequested = $false

    for ($i = $CountdownSeconds; $i -gt 0; $i--) {
        if ($script:CancelRequested) {
            Write-Log "Shutdown ABORTED by voice command." "WARN"
            [System.Console]::Beep(400, 300)
            return
        }
        Write-Log "Shutting down in $i..." "WARN"
        [System.Console]::Beep(900, 150)
        Start-Sleep -Seconds 1
    }

    if ($script:CancelRequested) {
        Write-Log "Shutdown ABORTED by voice command." "WARN"
        return
    }

    if ($Test) {
        Write-Log "TEST MODE: shutdown skipped. (Real run would power off now.)" "WARN"
        [System.Console]::Beep(1200, 400)
        return
    }

    Write-Log "Executing shutdown now." "WARN"
    $args = @("/s", "/t", "0")
    if ($Force) { $args += "/f" }
    Start-Process -FilePath "shutdown.exe" -ArgumentList $args -WindowStyle Hidden
}

# ---- Recognition event handler -------------------------------------------
$onRecognized = {
    param($sender, $e)
    $text = $e.Result.Text
    $conf = [math]::Round($e.Result.Confidence, 3)

    if ($text -ieq $CancelWord) {
        Write-Log "Heard cancel word '$text' (confidence $conf)."
        $script:CancelRequested = $true
        return
    }

    if ($text -ieq $Keyword) {
        if ($e.Result.Confidence -ge $Confidence) {
            Write-Log "Keyword '$text' recognized (confidence $conf >= $Confidence)."
            Invoke-Shutdown
        } else {
            Write-Log "Keyword '$text' heard but confidence $conf < $Confidence. Ignored."
        }
    }
}

Register-ObjectEvent -InputObject $engine -EventName SpeechRecognized -Action $onRecognized | Out-Null

# ---- Start continuous recognition ----------------------------------------
$engine.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
Write-Log "Listening... (press Ctrl+C to quit)"

try {
    while ($true) { Start-Sleep -Milliseconds 500 }
} finally {
    Write-Log "Stopping listener."
    try { $engine.RecognizeAsyncStop() } catch { }
    try { $engine.Dispose() } catch { }
}
