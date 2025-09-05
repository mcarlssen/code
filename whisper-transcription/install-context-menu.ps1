# Install Context Menu for Whisper Transcription
# This script adds a "Whisper Transcribe" option to the right-click context menu for audio files

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges to modify the registry." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcherPath = Join-Path -Path $scriptDir -ChildPath "context-menu-launcher.ps1"

# Verify the launcher script exists
if (-not (Test-Path $launcherPath)) {
    Write-Host "Context menu launcher script not found at: $launcherPath" -ForegroundColor Red
    exit 1
}

# Define the registry paths using proper PowerShell registry provider syntax
$audioExtensions = @(".wav", ".mp3", ".m4a", ".aac", ".flac", ".ogg", ".wma")

foreach ($extension in $audioExtensions) {
    $registryPath = "Registry::HKEY_CLASSES_ROOT\$extension\shell\WhisperTranscribe"
    
    try {
        # Create the shell key
        New-Item -Path $registryPath -Force | Out-Null
        
        # Set the display name
        Set-ItemProperty -Path $registryPath -Name "(Default)" -Value "Whisper Transcribe"
        
        # Set the icon (optional - you can change this to a custom icon)
        Set-ItemProperty -Path $registryPath -Name "Icon" -Value "shell32.dll,169"
        
        # Create the command key
        $commandPath = "$registryPath\command"
        New-Item -Path $commandPath -Force | Out-Null
        
        # Set the command to launch PowerShell with the launcher script
        $command = "powershell.exe -ExecutionPolicy Bypass -File `"$launcherPath`" -filePath `"%1`""
        Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $command
        
        Write-Host "Added context menu for $extension files" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to add context menu for $extension : $_" -ForegroundColor Red
    }
}

# Also add to the general audio file type
$audioFileType = "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\audio\shell\WhisperTranscribe"

try {
    # Create the shell key
    New-Item -Path $audioFileType -Force | Out-Null
    
    # Set the display name
    Set-ItemProperty -Path $audioFileType -Name "(Default)" -Value "Whisper Transcribe"
    
    # Set the icon
    Set-ItemProperty -Path $audioFileType -Name "Icon" -Value "shell32.dll,169"
    
    # Create the command key
    $commandPath = "$audioFileType\command"
    New-Item -Path $commandPath -Force | Out-Null
    
    # Set the command
    $command = "powershell.exe -ExecutionPolicy Bypass -File `"$launcherPath`" -filePath `"%1`""
    Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $command
    
    Write-Host "Added context menu for general audio files" -ForegroundColor Green
}
catch {
    Write-Host "Failed to add context menu for general audio files: $_" -ForegroundColor Red
}

Write-Host "`nContext menu installation completed!" -ForegroundColor Green
Write-Host "You may need to restart Explorer or log out/in to see the changes." -ForegroundColor Yellow
Write-Host "Right-click on any audio file to see the 'Whisper Transcribe' option." -ForegroundColor Yellow
