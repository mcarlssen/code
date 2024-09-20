function Install-WhisperCpp {
    # Define the GitHub releases API URL for retrieving the latest release info
    $apiUrl = "https://api.github.com/repos/regstuff/whisper.cpp_windows/releases/latest"

    # Fetch the latest release info using GitHub API
    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell script" }

    # Find the asset that matches the naming convention 'whisper.cpp_win_x64_vX.X.X.zip'
    $asset = $releaseInfo.assets | Where-Object { $_.name -match "whisper\.cpp_win_x64_v\d+\.\d+\.\d+\.zip" }

    if ($asset -ne $null) {
        # Define the download URL for the zip file
        $zipFileUrl = $asset.browser_download_url

        # Define the destination path (where the script is being run from)
        $zipFileName = Split-Path -Leaf $zipFileUrl
        $subfolderName = [System.IO.Path]::GetFileNameWithoutExtension($zipFileName)
        $subfolderPath = Join-Path -Path $PSScriptRoot -ChildPath $subfolderName

        # Create the subfolder if it doesn't exist
        if (-not (Test-Path -Path $subfolderPath)) {
            New-Item -Path $subfolderPath -ItemType Directory | Out-Null
        }

        # Download the zip file to the temp folder
        $zipFilePath = Join-Path -Path $env:TEMP -ChildPath $zipFileName
        Write-Host "Downloading the latest whisper.cpp release from $zipFileUrl..."
        Invoke-WebRequest -Uri $zipFileUrl -OutFile $zipFilePath

        # Extract the contents to the subfolder
        Write-Host "Extracting the contents to $subfolderPath..."

        # Extract the contents of the zip file to the subfolder
        Start-Process -FilePath 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x -y `"$zipFilePath`" -o`"$subfolderPath`"" -Wait

        Write-Host "Download and extraction completed."
    } else {
        Write-Host "No valid whisper.cpp zip file found in the latest release." -ForegroundColor Red
    }
}
