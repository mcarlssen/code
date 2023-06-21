^!f:: ;Ctrl+Alt+f hotkey...


#IfWinActive, ahk_class CabinetWClass
^n::
InputBox, FolderName, Create New Folder, What is the name of the project?,
FileCreateDir, %FolderName%
FileCreateDir, %FolderName%\_AUDIO\Characters
FileCreateDir, %FolderName%\_AUDIO\_RENDERS\_FINAL
FileCreateDir, %FolderName%\_AUDIO\_RENDERS\_R1
FileCreateDir, %FolderName%\_AUDIO\_RENDERS\_R2
FileCreateDir, %FolderName%\_DOCS
FileCreateDir, %FolderName%/_SOCIAL
FileCreateDir, %FolderName%/_VIDEO
;FileAppend, WELCOME BACK TO THE PODCAST.`n, %FolderName%\%FolderName%_new-doc.txt

return