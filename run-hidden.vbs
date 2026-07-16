' Launches voice-shutdown.ps1 with no visible window.
' Double-click this file to start the listener silently in the background.
' Edit the arguments below to change the keyword, e.g.:
'   ... -File ""..."" -Keyword ""computer shutdown""
Dim shell, scriptDir, ps1
Set shell = CreateObject("WScript.Shell")
scriptDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
ps1 = scriptDir & "voice-shutdown.ps1"
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """", 0, False
