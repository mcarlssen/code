; version 2.0, released 9/18/2024
; Updates syntax for AHK 2.0
; Eliminates powershell dependency

; Press Ctrl+Shift+1 to toggle state of Blink(1) device
; Update 'exepath' with location of your blink1-tool.exe binary

ExePath := "Z:\\mthorn\\blink1-tool.exe"
toggle := 0  ; Initialize the toggle variable

^+1:: {
	global toggle
	global ExePath
    toggle := !toggle  ; Toggle the state
    color := toggle ? "red" : "off"  ; Determine the color based on the toggle
    args := "-m 2000 --" color " -q"
    ; Run the executable directly, hiding any window
    Run('"' exePath '" ' args, "", "Hide")
}
