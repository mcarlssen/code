<#

# AUDIO FILE TRANSCRIPTION UTILITY

Transcribes a provided audio file. Utilizes ffmpeg to conform the provided audio file, then transcribes using Whisper.cpp faster than realtime. 

The transcription output is automatically copied to the user's clipboard for easy pasting into a ticket or other text field.

The Whisper.cpp engine uses the "Basic" model by default, but other models can be used by downloading and placing the file in the .\models directory, and updating
$whisperModel with the appropriate model name.

## USAGE

### Context Menu (Recommended)
After installation, you can transcribe audio files directly from Windows Explorer:
1. Right-click on any audio file (.wav, .mp3, .m4a, .aac, .flac, .ogg, .wma)
2. Select "Show more options" (Windows 11) or look for "Whisper Transcribe" in the context menu
3. Click "Whisper Transcribe"
4. The transcription will appear in a new window and be copied to your clipboard

### Command Line
Launch script from a powershell command prompt like so:
$> .\Whisper-Voicemail-Transcription.ps1

If ffmpeg and/or 7-Zip are not installed, they will be downloaded and installed.

If you have not selected a default model, you will be prompted to do so; if you have not yet downloaded any transcription models, you will be prompted to
select one to download from a list of available models. 

When prompted, enter the full (absolute) path to the audio file you wish to transcribe. On Windows 11, this is easily done by right-clicking on the file and selecting "Copy as path". 
Then press Enter to transcribe the file. When finished, the script will copy the transcription to your clipboard.

### Command Line Options
Run the script with the /update switch to update the Whisper.cpp engine to the latest version.
Run it with /model to select or download a new default model.
Run it with -filePath "path\to\file.wav" to transcribe a specific file directly.

## NOTES

Whisper.cpp for windows binary
[https://github.com/regstuff/whisper.cpp_windows]

Whisper GGML models sourced from: 
[https://huggingface.co/ggerganov/whisper.cpp]

ffmpeg install script by AnjanaMadu
[https://gist.github.com/AnjanaMadu/5f9689e9572492a50089f4a74b9b8de5#file-install-ffmpeg-ps1]

version detector script by Splaxi
[https://gist.github.com/Splaxi/fe168eaa91eb8fb8d62eba21736dc88a]

Script written by Magnus Carlssen. Released as public domain.
Please don't copy my code - not because it's good, but because it's terrible.
Please send bug reports or feature improvements to magnus@carlssen.co.uk.

https://carlssen.co.uk

# feature requests
- make possible to execute from a network share
- revise install-ffmpeg.ps1 to not require 7zip
- use curl instead of invoke-webrequest

# changelog

## 0.3.0 context is everything 9/5/2025
    *Added context menu integration.*
    *Improved model sourcing and options selection.*

## 0.2.2 7-zipperoo 9/20/24
	*Added auto-install function for 7-Zip binary.*
	*Added auto-install function for Whisper.cpp binary.*

## 0.2.1 bugfix 9/18/24
	*Fixed broken error handling in model-download and ffmpeg-install functions.*
	*Added better console output to clarify user actions required to download or select new models.*

## 0.2.0 second edition 5/31/24
    *Significant refactor.*
    *Added Whisper.cpp update feature.*
    *Added GGML model download/switch feature.*
    *Added settings.ini to store default model selection.*

## 0.1.0 first edition 5/31/24.

#>

# Get any command-line arguments
param ( [Parameter()]$action, [Parameter()]$filePath )

# Path to the settings file
$settingsFilePath = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "settings.ini"
$modelsDirectory = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "models"
$global:whisperFolder = Get-ChildItem -Path "C:\ProgramData\WhisperTranscription" -Directory | Where-Object { $_.Name -match "whisper.cpp_win_x64_v(\d+\.\d+\.\d+)" }

# Updates the Whisper.cpp engine to the latest release (does not overwrite current files)
. ./Update-Whisper.ps1

# Downloads new GGML models from web source
. ./HF-Model-DL.ps1

# Sets or changes the default transcription model
. ./Manage-Models.ps1

# Downloads and installs FFmpeg if needed
. ./install-ffmpeg.ps1

# Downloads and installs 7-Zip if needed
. ./install-7zip.ps1

# Downloads and installs Whisper.cpp if needed
. ./install-whisper.ps1

# function to run a shell command and return the output
function Run-Command {
    param ([string]$command)
    # Redirect stderr to suppress debug output, keep stdout for transcription
    $output = & cmd /c "$command 2>nul"
    return $output
}

# Main function, which loops if the user wants to transcribe more than one file in a session
function Transcribe {
    $selectedWhisperModel = Get-Setting -filePath $settingsFilePath -key "selectedWhisperModel"
    Write-Host "Using model: $selectedWhisperModel" -foregroundcolor magenta

    # If filePath is provided (context menu usage), transcribe that file and exit
    if ($filePath) {
        Transcribe-SingleFile -inputFile $filePath -selectedWhisperModel $selectedWhisperModel
        return
    }

    while ($true) {
        # Prompt for the absolute path of the input WAV file
        $inputFile = $(Write-Host "Please enter the absolute path of the input WAV file: " -foregroundcolor yellow -nonewline; Read-Host) 

        # Strip any quotes from the input file path
        $inputFile = $inputFile.Trim('"')

        Transcribe-SingleFile -inputFile $inputFile -selectedWhisperModel $selectedWhisperModel

        # Prompt to transcribe another file or exit
        $choice = Read-Host "Press 1 to transcribe another file, or any other key to exit"
        if ($choice -ne "1") {
            break
        }
    }
}

# Function to transcribe a single file
function Transcribe-SingleFile {
    param (
        [string]$inputFile,
        [string]$selectedWhisperModel
    )
    
    # Validate input file exists
    if (-not (Test-Path -Path $inputFile)) {
        Write-Host "Error: Input file not found: $inputFile" -ForegroundColor Red
        return
    }
    
    # Get file extension and validate it's an audio file
    $fileExtension = [System.IO.Path]::GetExtension($inputFile).ToLower()
    $supportedFormats = @(".wav", ".mp3", ".m4a", ".aac", ".flac", ".ogg", ".wma", ".aiff")
    
    if ($fileExtension -notin $supportedFormats) {
        Write-Host "Error: Unsupported audio format: $fileExtension" -ForegroundColor Red
        Write-Host "Supported formats: $($supportedFormats -join ', ')" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Whisper Transcription" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "Processing: $(Split-Path -Leaf $inputFile)" -ForegroundColor Green
    
    # Define the converted file path
    $convertedFile = [System.IO.Path]::ChangeExtension($inputFile, "converted.wav")

    # Convert the input file using ffmpeg
    $ffmpegPath = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "ffmpeg.exe"
    $ffmpegCommand = "`"$ffmpegPath`" -i `"$inputFile`" -y -loglevel error -stats -ar 16000 -ac 1 -b:a 96K -acodec pcm_s16le `"$convertedFile`""
    Write-Host "Converting audio..." -foregroundcolor Magenta
    $ffmpegResult = Run-Command $ffmpegCommand
    
    # Check if ffmpeg conversion was successful
    if (-not (Test-Path $convertedFile)) {
        Write-Host "Error: FFmpeg conversion failed. Please check if the input file is a valid audio file." -ForegroundColor Red
        return
    }

    # Process the converted file using the external tool
    $processingCommand = "$whisperFolder\main.exe -m `"$modelsDirectory\$selectedWhisperModel`" -t 4 -nt -f `"$convertedFile`""
    Write-Host "Transcribing..." -foregroundcolor Magenta
    $output = Run-Command $processingCommand

    if ($output) {
        # Copy the transcription to the clipboard
        $output | Set-Clipboard
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host "                    TRANSCRIPTION RESULT" -ForegroundColor Cyan
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host $output -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host "Transcription has been copied to the clipboard." -ForegroundColor Yellow
    } else {
        Write-Host "No transcription found in the output." -ForegroundColor Red
    }

    # Clean up the converted file
    if (Test-Path $convertedFile) {
        Remove-Item $convertedFile -Force
        #Write-Host "Temporary files cleaned up." -ForegroundColor Green
    }
}

# Function to extract the transcription output from the whisper.cpp console stream
function Extract-Transcription {
    param (
        [string[]]$output
    )
    $startIndex = $output.IndexOf(" >>")
    $endIndex = $output.IndexOf("whisper_print_timings:")

    if ($startIndex -ge 0 -and $endIndex -ge 0) {
        $transcription = $output[$startIndex..($endIndex - 1)]
        $transcription = $transcription -join "`n"
        return $transcription
    }
    return ""
}

# Check for settings file and selected model
function Check-Initialization {
    $selectedWhisperModel = Get-Setting -filePath $settingsFilePath -key "selectedWhisperModel"
    $selectedModelPath = Join-Path -Path $modelsDirectory -ChildPath $selectedWhisperModel
    if (-not (Test-Path -Path $selectedModelPath)) {
        Write-Host "Selected model $selectedWhisperModel not found. Resetting selection." -foregroundcolor red
        $selectedWhisperModel = Select-Model -modelsDirectory $modelsDirectory
        Set-Setting -filePath $settingsFilePath -key "selectedWhisperModel" -value $selectedWhisperModel
    }

    if (-not $selectedWhisperModel) {
        Write-Host "A default transcription model has not been set. Select an existing model or download a new one:" -foregroundcolor Red
        $selectedWhisperModel = Select-Model -modelsDirectory $modelsDirectory
        if ($selectedWhisperModel) {
            Set-Setting -filePath $settingsFilePath -key "selectedWhisperModel" -value $selectedWhisperModel
        } else {
            Write-Host "No model selected. Exiting script."
            exit
        }
    }
}

function Check-FFmpeg {
    $ffmpegPath = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "ffmpeg.exe"
 
    if (Test-Path -Path $ffmpegPath) {
       # Write-Host "ffmpeg is already installed."
    } else {
        # Try to find ffmpeg in version-specific folders
        $ffmpegFolders = Get-ChildItem -Path "C:\ProgramData\WhisperTranscription" -Directory | Where-Object { $_.Name -match "ffmpeg-(\d+\.\d+\.\d+)-essentials_build" }
        if ($ffmpegFolders) {
            $latestFFmpegFolder = $ffmpegFolders | Sort-Object {
                [version]($_.Name -replace 'ffmpeg-([0-9\.]+)-essentials_build', '$1')
            } | Select-Object -Last 1
            
            $versionSpecificPath = Join-Path -Path $latestFFmpegFolder.FullName -ChildPath "bin\ffmpeg.exe"
            if (Test-Path -Path $versionSpecificPath) {
                Write-Host "Found ffmpeg in version folder, moving to standard location..." -ForegroundColor Yellow
                Copy-Item -Path $versionSpecificPath -Destination $ffmpegPath -Force
                Write-Host "ffmpeg is now available at standard location." -ForegroundColor Green
            } else {
                Write-Host "ffmpeg is not installed or not in the system PATH." -backgroundcolor red
                Install-FFmpeg
                return
            }
        } else {
            Write-Host "ffmpeg is not installed or not in the system PATH." -backgroundcolor red
            Install-FFmpeg
            return
        }
    }
}

function Check-7Zip {
	# Check if 7-Zip is installed by checking if the executable exists
	$7ZipPath = 'C:\Program Files\7-Zip\7z.exe'
 
    if (Test-Path -Path $7ZipPath) {
        #Write-Host "7-Zip installed, proceeding..."
    } else {
        Write-Host "7-Zip not found, installing..." -backgroundcolor red
        Install-7Zip
        return
    }
}

function Check-WhisperCPP {
	# Check if Whisper.cpp 'main.exe' binary is present
	$whisperExecutable = $null
	$searchPaths = @(
		"C:\ProgramData\WhisperTranscription",
		"C:\Program Files\WhisperTranscription"
	)
	
	foreach ($searchPath in $searchPaths) {
		if (Test-Path -Path $searchPath) {
			$allDirs = Get-ChildItem -Path $searchPath -Directory -ErrorAction SilentlyContinue
			
			# Look for any folder containing "whisper.cpp"
			$whisperFolders = $allDirs | Where-Object { $_.Name -like "*whisper.cpp*" }
			
			foreach ($folder in $whisperFolders) {
				$possibleExecutable = Join-Path -Path $folder.FullName -ChildPath "main.exe"
				if (Test-Path -Path $possibleExecutable) {
					$whisperExecutable = $possibleExecutable
					$global:whisperFolder = $folder.FullName
					break
				}
			}
			if ($whisperExecutable) { break }
		}
	}
	
	if ($whisperExecutable) {
		# Whisper.cpp found, no need to show message
	} else {
		Write-Host "Whisper.cpp binary not found, installing..." -backgroundcolor red
		Install-WhisperCpp
		return
	}
}

switch ($action) {
    "/update" {
        Update-Whisper
    }
    "/model" {
        if ($selectedWhisperModel) {
            Write-Host "The currently selected transcription model is $selectedWhisperModel" -ForegroundColor Yellow
        }
        Select-Model -modelsDirectory ($modelsDirectory)
    }
    "/?"{
        Write-Host "Usage: whisper.ps1 [/update | /model | -filePath <path>]"    
    }
    Default {
        # If filePath is provided (context menu usage), check dependencies and transcribe
        if ($filePath) {
            Check-Initialization
            Check-7Zip
            Check-FFmpeg
            Check-WhisperCPP
            
            $selectedWhisperModel = Get-Setting -filePath $settingsFilePath -key "selectedWhisperModel"
            if ($selectedWhisperModel) {
                Transcribe-SingleFile -inputFile $filePath -selectedWhisperModel $selectedWhisperModel
            } else {
                Write-Host "No transcription model selected. Please run the script normally first to set up a model." -ForegroundColor Red
            }
        } else {
            # Normal interactive mode
            #Clear-Host
            Check-Initialization
            Check-7Zip
            Check-FFmpeg
            Check-WhisperCPP
            Transcribe
        }
    }
}
