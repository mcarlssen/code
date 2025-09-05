# Remove Context Menu for Whisper Transcription
# This script removes the "Whisper Transcribe" option from the right-click context menu

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges to modify the registry." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Define the registry paths using proper PowerShell registry provider syntax
$audioExtensions = @(".wav", ".mp3", ".m4a", ".aac", ".flac", ".ogg", ".wma")

foreach ($extension in $audioExtensions) {
    $registryPath = "Registry::HKEY_CLASSES_ROOT\$extension\shell\WhisperTranscribe"
    
    try {
        if (Test-Path $registryPath) {
            Remove-Item -Path $registryPath -Recurse -Force
            Write-Host "Removed context menu for $extension files" -ForegroundColor Green
        } else {
            Write-Host "Context menu for $extension files not found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to remove context menu for $extension : $_" -ForegroundColor Red
    }
}

# Remove from general audio file type
$audioFileType = "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\audio\shell\WhisperTranscribe"

try {
    if (Test-Path $audioFileType) {
        Remove-Item -Path $audioFileType -Recurse -Force
        Write-Host "Removed context menu for general audio files" -ForegroundColor Green
    } else {
        Write-Host "Context menu for general audio files not found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Failed to remove context menu for general audio files: $_" -ForegroundColor Red
}

Write-Host "`nContext menu removal completed!" -ForegroundColor Green
Write-Host "You may need to restart Explorer or log out/in to see the changes." -ForegroundColor Yellow
