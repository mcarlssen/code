# thank you AnjanaMadu
# https://gist.github.com/AnjanaMadu/5f9689e9572492a50089f4a74b9b8de5#file-install-ffmpeg-ps1

function Move-FFmpeg {
    # Look for ffmpeg folders in multiple possible locations
    $searchPaths = @(
        "C:\ProgramData\WhisperTranscription",
        "C:\",
        "C:\Program Files\WhisperTranscription"
    )
    
    $ffmpegExecutable = $null
    $ffmpegFolder = $null
    
    foreach ($searchPath in $searchPaths) {
        if (Test-Path -Path $searchPath) {
            $allDirs = Get-ChildItem -Path $searchPath -Directory -ErrorAction SilentlyContinue
            
            # Look for any folder containing "ffmpeg"
            $ffmpegFolders = $allDirs | Where-Object { $_.Name -like "*ffmpeg*" }
            
            foreach ($folder in $ffmpegFolders) {
                $possibleExecutable = Join-Path -Path $folder.FullName -ChildPath "bin\ffmpeg.exe"
                if (Test-Path -Path $possibleExecutable) {
                    $ffmpegExecutable = $possibleExecutable
                    $ffmpegFolder = $folder
                    break
                }
            }
            if ($ffmpegExecutable) { break }
        }
    }
    
    if ($ffmpegExecutable) {
        $destinationPath = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "ffmpeg.exe"
        
        # Ensure destination directory exists
        $destDir = Split-Path -Path $destinationPath -Parent
        if (-not (Test-Path -Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        
        try {
            Copy-Item -Path $ffmpegExecutable -Destination $destinationPath -Force
            
            # Clean up the source folder
            if ($ffmpegFolder) {
                Remove-Item -Path $ffmpegFolder.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Host "Error copying ffmpeg: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No ffmpeg executable found in any search location." -ForegroundColor Red
    }
}

function Install-FFmpeg {
   $filePath = Join-Path -Path "C:\ProgramData\WhisperTranscription" -ChildPath "ffmpeg.7z"

    # Check if the file exists
    if (Test-Path -Path $filePath) {
        Write-Host "ffmpeg install file has already been downloaded. Extracting..."
    } else {
        Write-Host "Downloading ffmpeg..."
        Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z" -OutFile $filePath
    }

	Write-Host "Extracting ffmpeg..."
	# Run the 7z extraction command
	Start-Process -FilePath 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x -y `"$filePath`" -o`"C:\ProgramData\WhisperTranscription`" " -Wait 
	# Call the function
	Move-FFmpeg
	Write-Host "ffmpeg is installed." -foregroundcolor magenta
}

