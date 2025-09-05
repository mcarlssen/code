# Whisper Transcription - Installation Guide

This guide explains how to install Whisper Transcription as a system application with context menu integration.

## What This Installation Does

- **Installs to Program Files**: Moves all files to `C:\Program Files\WhisperTranscription`
- **Data Storage**: Stores models and settings in `C:\ProgramData\WhisperTranscription`
- **Context Menu Integration**: Adds "Whisper Transcribe" to right-click menu for audio files
- **System-wide Access**: Works from any location, not just the original folder
- **Professional Installation**: Proper Windows application structure

## Installation Methods

### Method 1: Easy Installation (Recommended)

1. **Download** all the Whisper Transcription files to a folder
2. **Right-click** on `INSTALL.bat` → "Run as administrator"
3. **Follow** the on-screen prompts
4. **Run** the context menu installer when prompted

### Method 2: Manual Installation

1. **Right-click PowerShell** → "Run as administrator"
2. **Navigate** to your whisper-transcription folder
3. **Run**: `.\install-whisper-transcription.ps1`
4. **Run**: `.\install-system-context-menu.ps1` (from the installation directory)

## Installation Locations

After installation, files will be organized as follows:

```
C:\Program Files\WhisperTranscription\
├── Whisper-Voicemail-Transcription.ps1
├── system-context-launcher.ps1
├── install-system-context-menu.ps1
├── uninstall-whisper-transcription.ps1
├── ffmpeg.exe
├── whisper.cpp_win_x64_vX.X.X\
└── [other script files]

C:\ProgramData\WhisperTranscription\
├── models\
│   ├── ggml-model-whisper-*.bin
│   └── [other model files]
└── settings.ini
```

## Post-Installation Setup

### 1. Install Context Menu

After the main installation, you need to add the context menu:

```powershell
# Run as Administrator
.\install-system-context-menu.ps1
```

### 2. First-Time Setup

The first time you run the application (either from context menu or directly), it will:

- **Download and install** ffmpeg (if not present)
- **Download and install** 7-Zip (if not present)  
- **Download and install** Whisper.cpp (if not present)
- **Prompt you to select** a transcription model
- **Download models** if none are available

### 3. Test the Installation

1. **Right-click** on any audio file (.wav, .mp3, .m4a, .aac, .flac, .ogg, .wma)
2. **Select** "Whisper Transcribe" from the context menu
3. **Wait** for transcription to complete
4. **Check** that the result is copied to your clipboard

## Supported Audio Formats

The context menu will appear for these file types:
- **.wav** - WAV audio files
- **.mp3** - MP3 audio files  
- **.m4a** - M4A audio files
- **.aac** - AAC audio files
- **.flac** - FLAC audio files
- **.ogg** - OGG audio files
- **.wma** - WMA audio files

## Usage

### Context Menu Usage
1. **Right-click** any supported audio file
2. **Select** "Whisper Transcribe"
3. **Wait** for processing (file is converted and transcribed)
4. **Result** is automatically copied to clipboard

### Direct Usage
You can also run the application directly:

```powershell
# From the installation directory
.\Whisper-Voicemail-Transcription.ps1

# Or with a specific file
.\Whisper-Voicemail-Transcription.ps1 -filePath "C:\path\to\audio\file.wav"
```

### Command Line Options
- `/update` - Update Whisper.cpp to latest version
- `/model` - Select or download a new transcription model
- `-filePath <path>` - Transcribe a specific file

## Uninstallation

To remove Whisper Transcription from your system:

1. **Right-click PowerShell** → "Run as administrator"
2. **Navigate** to: `C:\Program Files\WhisperTranscription`
3. **Run**: `.\uninstall-whisper-transcription.ps1`
4. **Choose** whether to keep your models and settings

## Troubleshooting

### Context Menu Not Appearing
- Ensure you ran the context menu installer as Administrator
- Try restarting Windows Explorer
- Check that the installation completed successfully

### Transcription Fails
- Verify that Whisper.cpp is properly installed
- Check that you have a default model selected
- Ensure ffmpeg is available in the installation directory
- Check that the audio file is not corrupted

### Permission Errors
- All installation scripts must be run as Administrator
- Check Windows Defender or antivirus software isn't blocking the scripts
- Ensure you have write access to Program Files and ProgramData

### File Not Found Errors
- Verify the installation completed successfully
- Check that all files are in the correct installation directories
- Re-run the installation if files are missing

## Advanced Configuration

### Custom Model Location
Models are stored in `C:\ProgramData\WhisperTranscription\models\`. You can:
- Add custom models to this directory
- Use the `/model` option to select different models
- Download additional models using the built-in downloader

### Settings File
Settings are stored in `C:\ProgramData\WhisperTranscription\settings.ini`. This file contains:
- Selected transcription model
- Other user preferences

## System Requirements

- **Windows 10/11** (64-bit recommended)
- **PowerShell 5.1** or later
- **Administrator privileges** for installation
- **Internet connection** for downloading dependencies and models
- **~2GB free space** for models and dependencies

## Notes

- The installation creates a proper Windows application structure
- Models and settings are preserved during updates
- The context menu works system-wide, not just in specific folders
- All temporary files are automatically cleaned up after transcription
- The application can be used from any location once installed
