# 🎙️ Voice Shutdown

Say a word, and your Windows PC turns off.

**Voice Shutdown** is a tiny, always-on listener for Windows. It waits silently in the
background until it hears your chosen keyword (default: **"very amazing"**), then immediately
powers off your computer.

It uses the **built-in offline Windows Speech Recognizer** — so there's:

- ✅ **No internet required at runtime** — nothing is sent anywhere, all recognition is local.
- ✅ **No dependencies** — no Python, no models, no third-party installers.
- ✅ **Just PowerShell + Windows' native `System.Speech` engine.**

---

## Install in one command

On the Windows machine you want to install on, open **Win+R** (or a PowerShell window) and
paste:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/DoubleAAGuy/voice-shutdown/main/install.ps1 | iex"
```

That downloads the latest copy, installs it to `%LOCALAPPDATA%\VoiceShutdown`, registers it
to start silently at every logon, and starts it right away. Installation is always something
**you** run on **your** machine — nothing installs itself when a USB device is plugged in.

To use a different keyword or threshold, pass parameters:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/DoubleAAGuy/voice-shutdown/main/install.ps1))) -Keyword 'shut it down' -Confidence 0.9"
```

Or download the repo and double-click **`install.bat`**.

> ⚠️ **There is no countdown or cancel** — the moment the keyword is recognized, the shutdown fires.

---

## Try it safely first

`-Test` does everything *except* actually shut down, so you can confirm your mic and keyword
work without losing work:

```powershell
powershell -ExecutionPolicy Bypass -File .\voice-shutdown.ps1 -Test
```

Say **"very amazing"**. You'll hear a beep instead of a shutdown.

---

## Run it silently in the background

Double-click **`run-hidden.vbs`** to start the listener with no visible window.

## Start automatically at every login

`install-startup.ps1` copies the app into `%LOCALAPPDATA%\VoiceShutdown` and registers a
per-user Scheduled Task that launches the listener whenever you log in. It runs through
`wscript` + `run-hidden.vbs`, so **no console window ever appears** — not even a brief flash
at boot.

```powershell
powershell -ExecutionPolicy Bypass -File .\install-startup.ps1
```

To stop it from auto-starting **and** remove the installed files:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall-startup.ps1
```

---

## Options

Pass these to `voice-shutdown.ps1` (`install.ps1` and `install-startup.ps1` also accept
`-Keyword` / `-Confidence`, plus `-NoStart` to skip launching it immediately):

| Option | Default | Description |
| --- | --- | --- |
| `-Keyword` | `"very amazing"` | Word/phrase that triggers shutdown. |
| `-Confidence` | `0.85` | Minimum recognition confidence (0.0–1.0). Higher = fewer false triggers. |
| `-Test` | off | Dry run — never actually shuts down. |
| `-Force` | off | Force apps to close (`shutdown /f`). |

**Examples**

```powershell
# Use a safer two-word phrase so a random word in conversation won't trigger it
.\voice-shutdown.ps1 -Keyword "shut it down"

# Stricter confidence
.\voice-shutdown.ps1 -Confidence 0.9
```

---

## Tips to avoid accidental shutdowns

- Use a distinctive phrase to reduce accidental triggers during normal conversation.
- Keep **`-Confidence`** at `0.85` or higher.
- Remember the **`-Test`** flag while you dial in the settings — shutdown is instant with no cancel.

---

## Requirements

- Windows 10 / 11
- A microphone
- Windows Speech feature enabled (it is by default). If recognition fails, go to
  **Settings → Time & Language → Speech** and make sure a recognizer is installed,
  and allow microphone access under **Settings → Privacy & security → Microphone**.

---

## How it works

The script loads .NET's `System.Speech.Recognition.SpeechRecognitionEngine`, builds a small
**constrained grammar** containing only your keyword, points it at your default microphone,
and listens continuously. When the keyword is recognized above the confidence threshold, it
immediately calls `shutdown /s /t 0`.

All activity is written to `voice-shutdown.log` next to the script.

---

## License

[MIT](LICENSE) © 2026 Asher Aldis
