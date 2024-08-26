; version 1.0, released 8/26/2024

; AutoHotkey Script to toggle between two PowerShell commands
; Press Ctrl+Shift+1 to toggle between executing two PowerShell commands

; Initialize a toggle variable
toggle := 0

^+1:: ; Ctrl+Shift+1
    if (toggle := !toggle) {
        Run, powershell.exe -Command "Start-Process -NoNewWindow -FilePath 'Z:\mthorn\blink1-tool.exe' -ArgumentList '-m 2000 --red -q'"
    } else {
        Run, powershell.exe -Command "Start-Process -NoNewWindow -FilePath 'Z:\mthorn\blink1-tool.exe' -ArgumentList '-m 2000 --off -q'"
    }
return
