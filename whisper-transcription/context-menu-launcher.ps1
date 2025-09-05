# Context Menu Launcher for Whisper Transcription
# This script is called when a user right-clicks on an audio file and selects "Whisper Transcribe"

param(
    [Parameter(Mandatory=$true)]
    [string]$filePath
)

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Change to the script directory to ensure relative paths work correctly
Set-Location $scriptDir

# Launch the main transcription script with the file path
& "$scriptDir\Whisper-Voicemail-Transcription.ps1" -filePath $filePath

# Keep the window open briefly so the user can see the results
Write-Host "`nPress any key to close..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
