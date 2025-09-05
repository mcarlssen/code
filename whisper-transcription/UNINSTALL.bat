@echo off
echo Whisper Transcription Uninstaller
echo =================================
echo.
echo This will remove Whisper Transcription from your system.
echo You will need administrator privileges.
echo.
echo WARNING: This will remove the application and optionally your models and settings.
echo.
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp0uninstall-whisper-transcription.ps1"

if %errorlevel% equ 0 (
    echo.
    echo Uninstallation completed successfully!
    echo.
    pause
) else (
    echo.
    echo Uninstallation failed. Please check the error messages above.
    echo.
    pause
)
