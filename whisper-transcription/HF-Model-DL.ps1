# Updated to use direct model URLs from HuggingFace repository
# Function to get available models with direct download URLs
function Get-RemoteFiles {
    # Define available models with direct download URLs from https://huggingface.co/ggerganov/whisper.cpp/tree/main
    $files = @(
        @{
            Name = "ggml-tiny.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin"
            Size = "77.7 MB"
        },
        @{
            Name = "ggml-tiny.en.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin"
            Size = "77.7 MB"
        },
        @{
            Name = "ggml-base.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
            Size = "148 MB"
        },
        @{
            Name = "ggml-base.en.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
            Size = "148 MB"
        },
        @{
            Name = "ggml-small.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
            Size = "488 MB"
        },
        @{
            Name = "ggml-small.en.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"
            Size = "488 MB"
        },
        @{
            Name = "ggml-medium.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
            Size = "1.53 GB"
        },
        @{
            Name = "ggml-medium.en.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin"
            Size = "1.53 GB"
        },
        @{
            Name = "ggml-large-v2.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v2.bin"
            Size = "3.09 GB"
        },
        @{
            Name = "ggml-large-v3.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin"
            Size = "3.1 GB"
        },
        @{
            Name = "ggml-large-v3-turbo.bin"
            DownloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
            Size = "1.62 GB"
        }
    )

    return $files
}

# Function to list and select files from a remote web folder
function Select-RemoteFile {
    # Retrieve the list of files in the remote folder
    $files = Get-RemoteFiles

    if ($files.Count -eq 0) {
        Write-Host "No matching files found in the remote folder." -foregroundcolor red
        return $null
    }


    # Display the files in an ordered list with sizes
    Write-Host "Models available:" -foregroundcolor yellow
    for ($i = 0; $i -lt $files.Count; $i++) {
        $size = if ($files[$i].Size) { " ($($files[$i].Size))" } else { "" }
        Write-Host "$($i + 1). $($files[$i].name)$size"
    }

    # Ask user to select a model
    $selection = $(Write-Host "Choose a new model to download: " -ForegroundColor yellow -NoNewLine; Read-Host) 
    
    # Validate user input
    while($true) {
        if ($selection -match '^\d+$' -and [int]$selection -gt 0 -and [int]$selection -le $files.Count) {
            $selectedFile = $files[[int]$selection - 1]
            return $selectedFile
        } else {
            $selection = $(Write-Host "Invalid selection. " -backgroundcolor red -nonewline) + $(Write-Host " Please try again or press 'n' to exit: " -foregroundColor yellow -NoNewLine; Read-Host) 
            if ($selection -eq "n") {
                exit
            }
        }
    }
}

# Function to download the selected file
function Download-File {
    param (
        [string]$fileUrl,
        [string]$destinationPath
    )

    # Check if the file already exists
    if (Test-Path -Path $destinationPath) {
        $selection = $(Write-Host "Model already exists. " -foregroundcolor red -nonewline) + $(Write-Host "Do you want to overwrite it? (y/n) " -ForegroundColor yellow -NoNewLine; Read-Host) 

        if ($selection -ne "y") {
            Write-Host "Download aborted. " -nonewline -foregroundcolor red
            return
        }
    }

    # Download the selected file
    Write-Host "Downloading $fileName to $destinationPath..." -foregroundcolor magenta
    Invoke-WebRequest -Uri $fileUrl -OutFile $destinationPath
    Write-Host "Download completed." -foregroundcolor yellow
}

# Main script logic
# Ensure the models directory exists in ProgramData
$modelsDirectory = "C:\ProgramData\WhisperTranscription\models"
if (-not (Test-Path -Path $modelsDirectory)) {
    New-Item -Path $modelsDirectory -ItemType Directory -Force
}

function Download-Model {
    :download
    while ($true) {
        # Call the function to select a file
        $selectedFile = Select-RemoteFile -remoteUri $remoteUri

        if ($selectedFile) {
            # Extract the file name from the selected file
            $fileName = $selectedFile.Name

            # Define the destination path
            $destinationPath = Join-Path -Path $modelsDirectory -ChildPath $fileName

            # Call the function to download the file
            Download-File -fileUrl $selectedFile.DownloadUrl -destinationPath $destinationPath
        }

        # Prompt to transcribe another file or exit
        $choice = $(Write-Host "Do you want to download a different model? (y/n) " -foregroundcolor yellow -NoNewLine; Read-Host) 
        if ($choice -ne "y") {
            break
        }
        #$selectedWhisperModel = $fileName
        #return $selectedWhisperModel
    }
}