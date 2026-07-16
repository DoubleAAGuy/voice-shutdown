' Launches voice-shutdown.ps1 with NO visible window and no console flash.
' Double-click this file to start the listener silently in the background,
' or let the scheduled task (install-startup) run it at logon.
'
' Optional arguments:  run-hidden.vbs [keyword] [confidence]
'   e.g.  wscript run-hidden.vbs "computer agrivated" 0.9
Dim shell, scriptDir, ps1, cmd
Set shell = CreateObject("WScript.Shell")
scriptDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
ps1 = scriptDir & "voice-shutdown.ps1"

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """"
If WScript.Arguments.Count >= 1 Then
    cmd = cmd & " -Keyword """ & WScript.Arguments(0) & """"
End If
If WScript.Arguments.Count >= 2 Then
    cmd = cmd & " -Confidence " & WScript.Arguments(1)
End If

' Second parameter 0 = hidden window; True/False = don't wait.
shell.Run cmd, 0, False
