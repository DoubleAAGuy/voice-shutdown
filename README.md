# 🎙️ Voice Shutdown

Say a word, and your Windows PC turns off.

**Voice Shutdown** is a tiny, always-on listener for Windows. It waits silently in the
background until it hears your chosen keyword (default: **"agrivated"**), then immediately
powers off your computer.

It uses the **built-in offline Windows Speech Recognizer** — so there's:

- ✅ **No internet required** — nothing is sent anywhere, all recognition is local.
- ✅ **No downloads or dependencies** — no Python, no models, no installers.
- ✅ **Just one PowerShell script** using Windows' native `System.Speech` engine.

---

## Quick start

1. **Download** this repo (green **Code** button → *Download ZIP*, then extract).
2. Open the folder, **right-click `voice-shutdown.ps1`** and pick *Run with PowerShell*
   — or run it from a terminal:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\voice-shutdown.ps1
   ```

3. Say **"agrivated"**. Your PC shuts down immediately.

> ⚠️ **There is no countdown or cancel** — the moment the keyword is recognized, the shutdown fires.
> **Try it safely first** with `-Test`, which does everything *except* actually shut down:
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\voice-shutdown.ps1 -Test
> ```

---

## Run it silently in the background

Double-click **`run-hidden.vbs`** to start the listener with no visible window.

## Start automatically at every login

Run once:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-startup.ps1
```

This registers a per-user Scheduled Task that launches the listener silently whenever you
log in. To stop it from auto-starting:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall-startup.ps1
```

---

## Options

Pass these to `voice-shutdown.ps1` (and `install-startup.ps1` supports `-Keyword` / `-Confidence`):

| Option | Default | Description |
| --- | --- | --- |
| `-Keyword` | `"agrivated"` | Word/phrase that triggers shutdown. |
| `-Confidence` | `0.85` | Minimum recognition confidence (0.0–1.0). Higher = fewer false triggers. |
| `-Test` | off | Dry run — never actually shuts down. |
| `-Force` | off | Force apps to close (`shutdown /f`). |

**Examples**

```powershell
# Use a safer two-word phrase so a random word in conversation won't trigger it
.\voice-shutdown.ps1 -Keyword "computer agrivated"

# Stricter confidence
.\voice-shutdown.ps1 -Confidence 0.9
```

---

## Tips to avoid accidental shutdowns

- Use a **two-word phrase** like `"computer agrivated"` or `"goodnight computer"`.
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
