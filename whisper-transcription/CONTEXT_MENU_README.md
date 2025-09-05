# Whisper Transcription Context Menu Installation

This document explains how to add a "Whisper Transcribe" option to your Windows right-click context menu for audio files.

## What This Adds

After installation, you'll be able to:
- Right-click on any audio file (.wav, .mp3, .m4a, .aac, .flac, .ogg, .wma)
- Select "Whisper Transcribe" from the context menu
- The file will be automatically transcribed and the result copied to your clipboard

## Installation Steps

### 1. Run as Administrator
The installation script requires administrator privileges to modify the Windows registry.

1. Right-click on PowerShell and select "Run as Administrator"
2. Navigate to your whisper-transcription folder
3. Run the installation script:

```powershell
.\install-context-menu.ps1
```

### 2. Restart Explorer (Optional)
You may need to restart Windows Explorer or log out/in to see the changes:
- Press `Ctrl+Shift+Esc` to open Task Manager
- Find "Windows Explorer" in the list
- Right-click and select "Restart"

### 3. Test the Context Menu
1. Right-click on any audio file
2. You should see "Whisper Transcribe" in the context menu
3. Click it to transcribe the file

## How It Works

1. **Context Menu Trigger**: When you right-click an audio file, Windows calls the launcher script
2. **File Path**: The launcher receives the file path as a parameter
3. **Transcription**: The main script processes the file and copies the result to your clipboard
4. **Cleanup**: Temporary files are automatically removed

## Files Created

- `context-menu-launcher.ps1` - Launches transcription from context menu
- `install-context-menu.ps1` - Adds registry entries for context menu
- `remove-context-menu.ps1` - Removes context menu entries

## Uninstallation

To remove the context menu option:

1. Run PowerShell as Administrator
2. Navigate to your whisper-transcription folder
3. Run:

```powershell
.\remove-context-menu.ps1
```

## Troubleshooting

### Context Menu Not Appearing
- Ensure you ran the installation script as Administrator
- Try restarting Windows Explorer
- Check that all script files are in the same directory

### Transcription Fails
- Verify that Whisper.cpp is properly installed
- Check that you have a default model selected
- Ensure ffmpeg is available in the script directory

### Permission Errors
- The installation script must be run as Administrator
- Check Windows Defender or antivirus software isn't blocking the scripts

## Supported Audio Formats

The context menu will appear for these file types:
- .wav, .mp3, .m4a, .aac, .flac, .ogg, .wma

## Notes

- The context menu works with the existing Whisper transcription setup
- Your model preferences and settings are preserved
- The script automatically cleans up temporary files
- The transcription result is copied to your clipboard for easy pasting
