# thank you AnjanaMadu
# https://gist.github.com/AnjanaMadu/5f9689e9572492a50089f4a74b9b8de5#file-install-ffmpeg-ps1

function Move-FFmpeg {
    # Define the base directory where ffmpeg folders are located
    $baseDirectory = "C:\"
    $regexPattern = "ffmpeg-(\d+\.\d+\.\d+)-essentials_build"

    # Get all directories in the base directory that match the pattern
    $ffmpegFolders = Get-ChildItem -Path $baseDirectory -Directory | Where-Object { $_.Name -match $regexPattern }

    # Sort the folders by version number and select the highest version
    $latestFFmpegFolder = $ffmpegFolders | Sort-Object {
        # Extract the version number and split it into an array for comparison
        [version]($_.Name -replace 'ffmpeg-([0-9\.]+)-essentials_build', '$1')
    } | Select-Object -Last 1

    # Check if a folder was found
    if ($latestFFmpegFolder) {
        $sourcePath = Join-Path -Path $latestFFmpegFolder.FullName -ChildPath "bin"
        $ffmpegExecutable = Join-Path -Path $sourcePath -ChildPath "ffmpeg.exe"
        $destinationPath = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg.exe"
        $folderToDelete = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg-release-essentials"
      
        # Check if the source file exists
        if (Test-Path -Path $ffmpegExecutable) {
            try {
                # Move the ffmpeg.exe file to the destination
                Move-Item -Path $ffmpegExecutable -Destination $destinationPath -Force
                # Optionally delete the ffmpeg folder after moving the file
                Remove-Item -Path $latestFFmpegFolder.FullName -Recurse -Force
            } catch {
                Write-Host "An error occurred: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "The ffmpeg executable does not exist at the source path: $ffmpegExecutable" -ForegroundColor Red
        }
    } else {
        Write-Host "No matching ffmpeg folder found." -ForegroundColor Red
    }
}

function Install-FFmpeg {
   $filePath = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg.7z"

    # Check if the file exists
    if (Test-Path -Path $filePath) {
        Write-Host "ffmpeg install file has already been downloaded. Extracting..."
    } else {
        Write-Host "Downloading ffmpeg..."
        Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z" -OutFile "ffmpeg.7z"
    }

	Write-Host "Extracting ffmpeg..."
	# Run the 7z extraction command
	Start-Process -FilePath 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x -y ffmpeg.7z -oc:\ " 
	# Call the function
	Move-FFmpeg
	Write-Host "ffmpeg is installed." -foregroundcolor magenta
}

