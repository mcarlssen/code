^!f:: ;Ctrl+Alt+f hotkey...


#IfWinActive, ahk_class CabinetWClass
^n::
InputBox, FolderName, Create New Folder, What is the name of the project?,
FileCreateDir, %FolderName%
FileCreateDir, %FolderName%\AUDIO\Final Files
FileCreateDir, %FolderName%\AUDIO\Review Files
FileCreateDir, %FolderName%\Documents
FileCreateDir, %FolderName%\Social Media
FileCreateDir, %FolderName%\Character Review Files
;FileAppend, WELCOME BACK TO THE PODCAST.`n, %FolderName%\%FolderName%_new-doc.txt

return