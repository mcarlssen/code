# Whisper Transcription Installation Script
# This script installs the Whisper Transcription tool to a proper system location

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This installation script requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Define installation paths
$installDir = "C:\Program Files\WhisperTranscription"
$programDataDir = "C:\ProgramData\WhisperTranscription"

Write-Host "Whisper Transcription Installation" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Get the source directory (where this script is located)
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if source directory contains required files
$requiredFiles = @(
    "Whisper-Voicemail-Transcription.ps1",
    "context-menu-launcher.ps1"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path (Join-Path -Path $sourceDir -ChildPath $file))) {
        Write-Host "Error: Required file not found: $file" -ForegroundColor Red
        Write-Host "Please ensure all files are in the same directory as this installation script." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Source directory: $sourceDir" -ForegroundColor Cyan
Write-Host "Installation directory: $installDir" -ForegroundColor Cyan
Write-Host "Data directory: $programDataDir" -ForegroundColor Cyan
Write-Host ""

# Create installation directories
try {
    Write-Host "Creating installation directories..." -ForegroundColor Yellow
    
    if (-not (Test-Path $installDir)) {
        New-Item -Path $installDir -ItemType Directory -Force | Out-Null
        Write-Host "Created: $installDir" -ForegroundColor Green
    } else {
        Write-Host "Directory already exists: $installDir" -ForegroundColor Yellow
    }
    
    if (-not (Test-Path $programDataDir)) {
        New-Item -Path $programDataDir -ItemType Directory -Force | Out-Null
        Write-Host "Created: $programDataDir" -ForegroundColor Green
    } else {
        Write-Host "Directory already exists: $programDataDir" -ForegroundColor Yellow
    }
    
    # Create models subdirectory in ProgramData
    $modelsDir = Join-Path -Path $programDataDir -ChildPath "models"
    if (-not (Test-Path $modelsDir)) {
        New-Item -Path $modelsDir -ItemType Directory -Force | Out-Null
        Write-Host "Created: $modelsDir" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Error creating directories: $_" -ForegroundColor Red
    exit 1
}

# Copy files to installation directory
Write-Host ""
Write-Host "Copying application files..." -ForegroundColor Yellow

$filesToCopy = @(
    "Whisper-Voicemail-Transcription.ps1",
    "context-menu-launcher.ps1",
    "Update-Whisper.ps1",
    "HF-Model-DL.ps1",
    "Manage-Models.ps1",
    "install-ffmpeg.ps1",
    "install-7zip.ps1",
    "install-whisper.ps1",
    "whisper.bat"
)

foreach ($file in $filesToCopy) {
    $sourceFile = Join-Path -Path $sourceDir -ChildPath $file
    $destFile = Join-Path -Path $installDir -ChildPath $file
    
    if (Test-Path $sourceFile) {
        try {
            Copy-Item -Path $sourceFile -Destination $destFile -Force
            Write-Host "Copied: $file" -ForegroundColor Green
        } catch {
            Write-Host "Error copying $file : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Warning: $file not found in source directory" -ForegroundColor Yellow
    }
}

# Copy existing models and settings if they exist
Write-Host ""
Write-Host "Copying existing data..." -ForegroundColor Yellow

# Copy models directory
$sourceModelsDir = Join-Path -Path $sourceDir -ChildPath "models"
$destModelsDir = Join-Path -Path $programDataDir -ChildPath "models"

if (Test-Path $sourceModelsDir) {
    try {
        Copy-Item -Path "$sourceModelsDir\*" -Destination $destModelsDir -Recurse -Force
        Write-Host "Copied existing models" -ForegroundColor Green
    } catch {
        Write-Host "Error copying models: $_" -ForegroundColor Red
    }
}

# Copy settings file
$sourceSettingsFile = Join-Path -Path $sourceDir -ChildPath "settings.ini"
$destSettingsFile = Join-Path -Path $programDataDir -ChildPath "settings.ini"

if (Test-Path $sourceSettingsFile) {
    try {
        Copy-Item -Path $sourceSettingsFile -Destination $destSettingsFile -Force
        Write-Host "Copied existing settings" -ForegroundColor Green
    } catch {
        Write-Host "Error copying settings: $_" -ForegroundColor Red
    }
}

# Copy ffmpeg.exe if it exists
$sourceFFmpeg = Join-Path -Path $sourceDir -ChildPath "ffmpeg.exe"
$destFFmpeg = Join-Path -Path $installDir -ChildPath "ffmpeg.exe"

if (Test-Path $sourceFFmpeg) {
    try {
        Copy-Item -Path $sourceFFmpeg -Destination $destFFmpeg -Force
        Write-Host "Copied ffmpeg.exe" -ForegroundColor Green
    } catch {
        Write-Host "Error copying ffmpeg.exe: $_" -ForegroundColor Red
    }
}

# Copy whisper.cpp folder if it exists
$whisperFolders = Get-ChildItem -Path $sourceDir -Directory | Where-Object { $_.Name -match "whisper.cpp_win_x64_v(\d+\.\d+\.\d+)" }
foreach ($folder in $whisperFolders) {
    $destFolder = Join-Path -Path $installDir -ChildPath $folder.Name
    try {
        Copy-Item -Path $folder.FullName -Destination $destFolder -Recurse -Force
        Write-Host "Copied whisper.cpp folder: $($folder.Name)" -ForegroundColor Green
    } catch {
        Write-Host "Error copying whisper.cpp folder: $_" -ForegroundColor Red
    }
}

# Create updated launcher script that references the installed location
Write-Host ""
Write-Host "Creating system launcher..." -ForegroundColor Yellow

$systemLauncherContent = @"
# System Context Menu Launcher for Whisper Transcription
# This script is called when a user right-clicks on an audio file and selects "Whisper Transcribe"

param(
    [Parameter(Mandatory=`$true)]
    [string]`$filePath
)

# Define the installation paths
`$installDir = "$installDir"
`$programDataDir = "$programDataDir"

# Change to the installation directory
Set-Location `$installDir

# Launch the main transcription script with the file path
& "`$installDir\Whisper-Voicemail-Transcription.ps1" -filePath `$filePath

# Keep the window open briefly so the user can see the results
Write-Host "`nPress any key to close..." -ForegroundColor Yellow
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

$systemLauncherPath = Join-Path -Path $installDir -ChildPath "system-context-launcher.ps1"
$systemLauncherContent | Set-Content -Path $systemLauncherPath -Encoding UTF8
Write-Host "Created system launcher: $systemLauncherPath" -ForegroundColor Green

# Install context menu directly
Write-Host ""
Write-Host "Installing context menu..." -ForegroundColor Yellow

$launcherPath = Join-Path -Path $installDir -ChildPath "system-context-launcher.ps1"

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
        
        # Set the command to launch PowerShell with the system launcher script
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

Write-Host "Context menu installation completed!" -ForegroundColor Green

# Create uninstaller script
Write-Host ""
Write-Host "Creating uninstaller..." -ForegroundColor Yellow

$uninstallerContent = @"
# Whisper Transcription Uninstaller
# This script removes the Whisper Transcription tool from the system

# Check if running as administrator
`$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not `$isAdmin) {
    Write-Host "This uninstaller requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Define installation paths
`$installDir = "$installDir"
`$programDataDir = "$programDataDir"

Write-Host "Whisper Transcription Uninstaller" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Red
Write-Host ""

# Remove context menu entries
Write-Host "Removing context menu entries..." -ForegroundColor Yellow

`$audioExtensions = @(".wav", ".mp3", ".m4a", ".aac", ".flac", ".ogg", ".wma")

foreach (`$extension in `$audioExtensions) {
    `$registryPath = "Registry::HKEY_CLASSES_ROOT\`$extension\shell\WhisperTranscribe"
    
    try {
        if (Test-Path `$registryPath) {
            Remove-Item -Path `$registryPath -Recurse -Force
            Write-Host "Removed context menu for `$extension files" -ForegroundColor Green
        } else {
            Write-Host "Context menu for `$extension files not found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to remove context menu for `$extension : `$_" -ForegroundColor Red
    }
}

# Remove from general audio file type
`$audioFileType = "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\audio\shell\WhisperTranscribe"

try {
    if (Test-Path `$audioFileType) {
        Remove-Item -Path `$audioFileType -Recurse -Force
        Write-Host "Removed context menu for general audio files" -ForegroundColor Green
    } else {
        Write-Host "Context menu for general audio files not found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Failed to remove context menu for general audio files: `$_" -ForegroundColor Red
}

# Remove installation directories
Write-Host ""
Write-Host "Removing installation files..." -ForegroundColor Yellow

if (Test-Path `$installDir) {
    try {
        Remove-Item -Path `$installDir -Recurse -Force
        Write-Host "Removed installation directory: `$installDir" -ForegroundColor Green
    } catch {
        Write-Host "Error removing installation directory: `$_" -ForegroundColor Red
    }
} else {
    Write-Host "Installation directory not found: `$installDir" -ForegroundColor Yellow
}

# Ask user if they want to keep their data
Write-Host ""
`$keepData = Read-Host "Do you want to keep your models and settings? (y/n)"

if (`$keepData -ne "y") {
    if (Test-Path `$programDataDir) {
        try {
            Remove-Item -Path `$programDataDir -Recurse -Force
            Write-Host "Removed data directory: `$programDataDir" -ForegroundColor Green
        } catch {
            Write-Host "Error removing data directory: `$_" -ForegroundColor Red
        }
    } else {
        Write-Host "Data directory not found: `$programDataDir" -ForegroundColor Yellow
    }
} else {
    Write-Host "Data directory preserved: `$programDataDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "Uninstallation completed!" -ForegroundColor Green
Write-Host "You may need to restart Explorer or log out/in to see the changes." -ForegroundColor Yellow
"@

$uninstallerPath = Join-Path -Path $installDir -ChildPath "uninstall-whisper-transcription.ps1"
$uninstallerContent | Set-Content -Path $uninstallerPath -Encoding UTF8
Write-Host "Created uninstaller: $uninstallerPath" -ForegroundColor Green

# Update the main script to use the new paths
Write-Host ""
Write-Host "Updating main script for system installation..." -ForegroundColor Yellow

$mainScriptPath = Join-Path -Path $installDir -ChildPath "Whisper-Voicemail-Transcription.ps1"
$mainScriptContent = Get-Content -Path $mainScriptPath -Raw

# Update the paths in the main script
$mainScriptContent = $mainScriptContent -replace '\$settingsFilePath = Join-Path -Path \$PSScriptRoot -ChildPath "settings\.ini"', '$settingsFilePath = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "settings.ini"'
$mainScriptContent = $mainScriptContent -replace '\$modelsDirectory = Join-Path -Path \$PSScriptRoot -ChildPath "models"', '$modelsDirectory = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "models"'

$mainScriptContent | Set-Content -Path $mainScriptPath -Encoding UTF8
Write-Host "Updated main script paths" -ForegroundColor Green

Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "What's been installed:" -ForegroundColor Yellow
Write-Host "[X] Whisper Transcription application" -ForegroundColor Green
Write-Host "[X] Context menu integration (right-click 'Whisper Transcribe')" -ForegroundColor Green
Write-Host "[X] System launcher and configuration" -ForegroundColor Green
Write-Host ""
Write-Host "You can now:" -ForegroundColor Yellow
Write-Host "[X] Right-click any audio file and select 'Whisper Transcribe'" -ForegroundColor Cyan
Write-Host "[X] Run the application directly from: $installDir" -ForegroundColor Cyan
Write-Host "[X] Uninstall using: $uninstallerPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation location: $installDir" -ForegroundColor Cyan
Write-Host "Data location: $programDataDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "You may need to restart Explorer or log out/in to see the context menu changes." -ForegroundColor Yellow
