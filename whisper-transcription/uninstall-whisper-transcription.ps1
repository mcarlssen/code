# Whisper Transcription Uninstaller
# This script removes the Whisper Transcription tool from the system

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This uninstaller requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Define installation paths
$installDir = "C:\Program Files\WhisperTranscription"
$programDataDir = "C:\ProgramData\WhisperTranscription"

Write-Host "Whisper Transcription Uninstaller" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Red
Write-Host ""

# Check if Whisper Transcription is installed
if (-not (Test-Path $installDir)) {
    Write-Host "Whisper Transcription is not installed or already removed." -ForegroundColor Yellow
    Write-Host "Installation directory not found: $installDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found Whisper Transcription installation at: $installDir" -ForegroundColor Green
Write-Host ""

# Remove context menu entries
Write-Host "Removing context menu entries..." -ForegroundColor Yellow

$audioExtensions = @(".wav", ".mp3", ".m4a", ".aac", ".flac", ".ogg", ".wma")
$removedCount = 0

foreach ($extension in $audioExtensions) {
    $registryPath = "Registry::HKEY_CLASSES_ROOT\$extension\shell\WhisperTranscribe"
    
    try {
        if (Test-Path $registryPath) {
            Remove-Item -Path $registryPath -Recurse -Force
            Write-Host "Removed context menu for $extension files" -ForegroundColor Green
            $removedCount++
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
        $removedCount++
    } else {
        Write-Host "Context menu for general audio files not found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Failed to remove context menu for general audio files: $_" -ForegroundColor Red
}

if ($removedCount -gt 0) {
    Write-Host "Removed $removedCount context menu entries" -ForegroundColor Green
} else {
    Write-Host "No context menu entries found to remove" -ForegroundColor Yellow
}

# Remove installation directories
Write-Host ""
Write-Host "Removing installation files..." -ForegroundColor Yellow

if (Test-Path $installDir) {
    try {
        Remove-Item -Path $installDir -Recurse -Force
        Write-Host "Removed installation directory: $installDir" -ForegroundColor Green
    } catch {
        Write-Host "Error removing installation directory: $_" -ForegroundColor Red
        Write-Host "You may need to manually delete: $installDir" -ForegroundColor Yellow
    }
} else {
    Write-Host "Installation directory not found: $installDir" -ForegroundColor Yellow
}

# Ask user if they want to keep their data
Write-Host ""
if (Test-Path $programDataDir) {
    Write-Host "Found data directory: $programDataDir" -ForegroundColor Cyan
    Write-Host "This contains your models and settings." -ForegroundColor Cyan
    Write-Host ""
    
    do {
        $keepData = Read-Host "Do you want to keep your models and settings? (y/n)"
        $keepData = $keepData.ToLower()
    } while ($keepData -ne "y" -and $keepData -ne "n")
    
    if ($keepData -ne "y") {
        try {
            Remove-Item -Path $programDataDir -Recurse -Force
            Write-Host "Removed data directory: $programDataDir" -ForegroundColor Green
        } catch {
            Write-Host "Error removing data directory: $_" -ForegroundColor Red
            Write-Host "You may need to manually delete: $programDataDir" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Data directory preserved: $programDataDir" -ForegroundColor Green
        Write-Host "Your models and settings have been kept." -ForegroundColor Green
    }
} else {
    Write-Host "Data directory not found: $programDataDir" -ForegroundColor Yellow
}

# Check for any remaining files
Write-Host ""
Write-Host "Checking for any remaining files..." -ForegroundColor Yellow

$remainingFiles = @()
if (Test-Path $installDir) { $remainingFiles += $installDir }
if (Test-Path $programDataDir) { $remainingFiles += $programDataDir }

if ($remainingFiles.Count -gt 0) {
    Write-Host "Warning: Some files could not be removed:" -ForegroundColor Yellow
    foreach ($file in $remainingFiles) {
        Write-Host "  - $file" -ForegroundColor Yellow
    }
    Write-Host "You may need to manually delete these directories." -ForegroundColor Yellow
} else {
    Write-Host "All files removed successfully." -ForegroundColor Green
}

Write-Host ""
Write-Host "Uninstallation completed!" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "• Context menu entries removed" -ForegroundColor Green
Write-Host "• Application files removed" -ForegroundColor Green
if ($keepData -eq "y") {
    Write-Host "• User data preserved" -ForegroundColor Green
} else {
    Write-Host "• User data removed" -ForegroundColor Green
}
Write-Host ""
Write-Host "You may need to restart Explorer or log out/in to see the changes." -ForegroundColor Yellow
Write-Host "Thank you for using Whisper Transcription!" -ForegroundColor Cyan
