# Function to read the settings file
function Get-Setting {
    param (
        [string]$filePath,
        [string]$key
    )
    if (Test-Path -Path $filePath) {
        $settings = Get-Content -Path $filePath | ConvertFrom-StringData
        return $settings[$key]
    }
    return $null
}

# Function to write the settings file
function Set-Setting {
    param (
        [string]$filePath,
        [string]$key,
        [string]$value
    )
    $settings = @{}
    if (Test-Path -Path $filePath) {
        $settings = Get-Content -Path $filePath | ConvertFrom-StringData
    }
    $settings[$key] = $value
    $settingsContent = $settings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
    $settingsContent | Set-Content -Path $filePath
}

# Function to select a model
function Select-Model {
    param (
        [string]$modelsDirectory
    )
    # Ensure the models directory exists
    if (-not (Test-Path -Path $modelsDirectory)) {
        New-Item -Path $modelsDirectory -ItemType Directory -Force
    }
    
    # Get the list of existing models
    $existingModels = Get-ChildItem -Path $modelsDirectory -Filter "ggml-model-whisper-*.bin"

    if ($existingModels.Count -eq 0) {
        $(Write-Host "No existing models found." -backgroundcolor red -nonewline) + $(Write-Host " Checking for downloadable models..." -foregroundcolor magenta)
        Remove-Item settings.ini -Force
        Download-Model
    } else {
        Write-Host "Select a new default model: " -ForegroundColor yellow
    }
    #this is repeated because if you have a default model set, but the file doesn't exist, it doesn't become available to select after downloading if the models aren't re-scanned first
    $existingModels = Get-ChildItem -Path $modelsDirectory -Filter "ggml-model-whisper-*.bin"

    # Display the existing models
    for ($i = 0; $i -lt $existingModels.Count; $i++) {
        Write-Host "$($i + 1). $($existingModels[$i].Name)"
    }
    Write-Host "$($existingModels.Count + 1). Download a new model"

    # Get user input to select a model
    $selection = $(Write-Host "Enter your selection: " -ForegroundColor yellow -NoNewLine; Read-Host) 

    # Validate user input
    while($true) {
        if ($selection -match '^\d+$' -and [int]$selection -gt 0 -and [int]$selection -le $existingModels.Count) {
            $selectedWhisperModel = $existingModels[[int]$selection - 1].Name
            Write-Host "Default model saved." -foregroundcolor magenta
            break
        } elseif ($selection -eq "$($existingModels.Count + 1)") {
            # Download a new model
            Write-Host "Checking models..." -foregroundcolor magenta
            Download-Model
        } else {
            $selection = $(Write-Host "Invalid selection. " -backgroundcolor red -nonewline) + $(Write-Host " Please try again or press 'n' to exit: " -foregroundColor yellow -NoNewLine; Read-Host) 
            if ($selection -eq "n") {
                exit
            }
        }
    }
    return $selectedWhisperModel
    #Write-Host "Using model: $selectedWhisperModel"
}


