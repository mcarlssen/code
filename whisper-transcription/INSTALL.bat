@echo off
echo Whisper Transcription Installation
echo ==================================
echo.
echo This will install Whisper Transcription to your system.
echo You will need administrator privileges.
echo.
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp0install-whisper-transcription.ps1"

if %errorlevel% equ 0 (
    echo.
    echo Installation completed successfully!
    echo.
    echo Next steps:
    echo 1. The context menu installer has been created in the installation directory
    echo 2. Run it to add the "Whisper Transcribe" option to your right-click menu
    echo.
    pause
) else (
    echo.
    echo Installation failed. Please check the error messages above.
    echo.
    pause
)
