<#

# AUDIO FILE TRANSCRIPTION UTILITY

Transcribes a provided audio file. Utilizes ffmpeg to conform the provided audio file, then transcribes using Whisper.cpp faster than realtime. 

The transcription output is automatically copied to the user's clipboard for easy pasting into a ticket or other text field.

The Whisper.cpp engine uses the "Basic" model by default, but other models can be used by downloading and placing the file in the .\models directory, and updating
$whisperModel with the appropriate model name.

## USAGE
Launch script from a powershell command prompt like so:
$> .\Whisper-Voicemail-Transcription.ps1

If ffmpeg and/or 7-Zip are not installed, they will be downloaded and installed.

If you have not selected a default model, you will be prompted to do so; if you have not yet downloaded any transcription models, you will be prompted to
select one to download from a list of available models. 

When prompted, enter the full (absolute) path to the audio file you wish to transcribe. On Windows 11, this is easily done by right-clicking on the file and selecting "Copy as path". 
Then press Enter to transcribe the file. When finished, the script will copy the transcription to your clipboard.

Run the script with the /update switch to update the Whisper.cpp engine to the latest version.
Run it with /model to select or download a new default model.

## NOTES

Whisper.cpp for windows binary
[https://github.com/regstuff/whisper.cpp_windows]

Whisper GGML models sourced from: 
[https://ggml.ggerganov.com/]

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
param ( [Parameter()]$action )

# Path to the settings file
$settingsFilePath = Join-Path -Path $PSScriptRoot -ChildPath "settings.ini"
$modelsDirectory = Join-Path -Path $PSScriptRoot -ChildPath "models"
$global:whisperFolder = Get-ChildItem -Path $scriptDirectory -Directory | Where-Object { $_.Name -match "whisper.cpp_win_x64_v(\d+\.\d+\.\d+)" }

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
    $output = & cmd /c $command
    return $output
}

# Main function, which loops if the user wants to transcribe more than one file in a session
function Transcribe {
    $selectedWhisperModel = Get-Setting -filePath $settingsFilePath -key "selectedWhisperModel"
    Write-Host "Using model: $selectedWhisperModel" -foregroundcolor magenta

    while ($true) {
        # Prompt for the absolute path of the input WAV file
        $inputFile = $(Write-Host "Please enter the absolute path of the input WAV file: " -foregroundcolor yellow -nonewline; Read-Host) 

        # Strip any quotes from the input file path
        $inputFile = $inputFile.Trim('"')

        # Define the converted file path
        $convertedFile = [System.IO.Path]::ChangeExtension($inputFile, "converted.wav")

        # Convert the input file using ffmpeg
        $ffmpegCommand = "ffmpeg -i `"$inputFile`" -y -loglevel error -stats -ar 16000 -ac 1 -b:a 96K -acodec pcm_s16le `"$convertedFile`""
        Write-Host "Converting file with ffmpeg..." -foregroundcolor Magenta
        Run-Command $ffmpegCommand

        # Process the converted file using the external tool
        $processingCommand = "$whisperFolder\main.exe -m models\$selectedWhisperModel -t 4 -nt -f `"$convertedFile`""
        Write-Host "Processing converted file..." -foregroundcolor Magenta
        $output = Run-Command $processingCommand

        if ($output) {
            # Copy the transcription to the clipboard
            $output | Set-Clipboard
            Write-Host "Transcription has been copied to the clipboard." -foregroundcolor Yellow
            Write-Host $output -foregroundcolor Red
        } else {
            Write-Host "No transcription found in the output."
        }

        # Prompt to transcribe another file or exit
        $choice = Read-Host "Press 1 to transcribe another file, or any other key to exit"
        if ($choice -ne "1") {
            break
        }
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
    $ffmpegPath = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg.exe"
 
    if (Test-Path -Path $ffmpegPath) {
       # Write-Host "ffmpeg is already installed."
    } else {
        Write-Host "ffmpeg is not installed or not in the system PATH." -backgroundcolor red
        Install-FFmpeg
        return
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
	if ($whisperFolder -and (Test-Path -Path $whisperFolder)) {
		$WhisperCppPath = Join-Path -Path $whisperFolder -ChildPath "main.exe"
		#Write-Host "7-Zip installed, proceeding..."
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
        Write-Host "Usage: whisper.ps1 [/update | /model ]"    
    }
    Default {
        #Clear-Host
        Check-Initialization
		Check-7Zip
        Check-FFmpeg
		Check-WhisperCPP
        Transcribe
    }
}
