# Updates the Whisper.cpp binary
function Update-Whisper {
    Write-Host "Checking for updates..."

    # adapted with love from Splaxi https://gist.github.com/Splaxi/fe168eaa91eb8fb8d62eba21736dc88a
    $repo = "regstuff/whisper.cpp_windows"
    $filenamePattern = "whisper.cpp_win_x64_v*"
    #$pathExtract = $PSScriptRoot # alternately you can hardcode this; I like "C:\Whisper-Transcription\"

    $releasesUri = "https://api.github.com/repos/$repo/releases/latest"
    $downloadUri = ((Invoke-RestMethod -Method GET -Uri $releasesUri).assets | Where-Object name -like $filenamePattern ).browser_download_url
    $remoteFileName = [System.IO.Path]::GetFileNameWithoutExtension($downloadUri)
    $remoteVersion = Get-VersionNumber -inputString $remoteFileName

    $scriptDirectory = Get-Location
    if ($whisperFolder) {
        $localVersion = Get-VersionNumber -inputString $whisperFolder.Name
        # Compare version numbers
        if ($null -eq $remoteVersion -or $null -eq $localVersion) {
            Write-Host "Unable to determine version numbers."
        } elseif ([version]$remoteVersion -gt [version]$localVersion) {
            Write-Host "A new version is available ($localversion). Proceeding with update..."
            Download-Update
            Write-Host "Whisper.cpp binary updated to version $versionNumber"
        }
        elseif ([version]$remoteVersion -eq [version]$localVersion) {
            Write-Host "Local Whisper.cpp binary is up to date (version $remoteversion)." -foregroundcolor Yellow
        }
    } else {
        Write-Host "Whisper.cpp binary not found. Downloading latest..."
        Download-Update
    }
}

# function to download latest binary
function Download-Update {
    $pathZip = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $(Split-Path -Path $downloadUri -Leaf)
    Invoke-WebRequest -Uri $downloadUri -Out $pathZip
    # Extract the file name without the extension, so that the contents can be placed in a subfolder by that name
    $zipfileName = [System.IO.Path]::GetFileNameWithoutExtension($pathZip)
    # Define the path where the files will be extracted, creating a folder named after the zip file
    $pathExtract = Join-Path -Path "." -ChildPath $zipfileName
    # Create the extraction directory
    New-Item -Path $pathExtract -ItemType Directory -Force
    # Extract the downloaded zip file into the new directory
    Expand-Archive -Path $pathZip -DestinationPath $pathExtract -Force
    # Remove the downloaded zip file after extraction
    Remove-Item $pathZip -Force
}

# Function to extract version number from the github file name
function Get-VersionNumber {
    param ([string]$inputString)
    if ($inputString -match "v(\d+\.\d+\.\d+)") {
        return $matches[1]
    }
    return $null
}
