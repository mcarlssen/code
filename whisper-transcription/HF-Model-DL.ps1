# this domain may cease to host files in future. Should update to use the HuggingFace repo eventually. https://huggingface.co/ggerganov
$remoteUri = 'https://ggml.ggerganov.com/'

# Function to parse the HTML content and extract filenames
function Get-RemoteFiles {
    # Retrieve the HTML content of the web page
    $response = Invoke-WebRequest -Uri $remoteUri

    # Parse the HTML to extract file links
    $fileLinks = $response.Links | Where-Object { $_.href -match "^ggml-model-whisper-.{4,5}\.bin$" }

    # Create a custom object to store the file name and download URL
    $files = @()
    foreach ($link in $fileLinks) {
        $file = New-Object PSObject -Property @{
            Name = [System.IO.Path]::GetFileName($link.href)
            DownloadUrl = [System.Uri]::new($response.BaseResponse.ResponseUri, $link.href).AbsoluteUri
        }
        $files += $file
    }

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


    # Display the files in an ordered list
    Write-Host "Models available:" -foregroundcolor yellow
    for ($i = 0; $i -lt $files.Count; $i++) {
        Write-Host "$($i + 1). $($files[$i].name)"
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
# Ensure the models directory exists
$modelsDirectory = Join-Path -Path "." -ChildPath "models"
if (-not (Test-Path -Path $modelsDirectory)) {
    New-Item -Path $modelsDirectory -ItemType Directory
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