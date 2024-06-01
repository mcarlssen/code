# thank you AnjanaMadu
# https://gist.github.com/AnjanaMadu/5f9689e9572492a50089f4a74b9b8de5#file-install-ffmpeg-ps1

function Install-FFmpeg {
    <#
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (!$isAdmin) {
        Write-Host "Please run this script as administrator."
        exit
    } #>

   $filePath = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg.7z"

    # Check if the file exists
    if (Test-Path -Path $filePath) {
        Write-Host "The download file already exists, skipping download..."
    } else {
        Write-Host "Downloading ffmpeg..."
        Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z" -OutFile "ffmpeg.7z"
    }
    
    Write-Host "Extracting ffmpeg..."
    Start-Process -FilePath 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x -y ffmpeg.7z -oc:\ " 
    
    function Move-FFmpeg {
        # Define the source and destination paths
        $sourcePath = "C:\ffmpeg-7.0.1-essentials_build\bin\"
        $ffmpegExecutable = Join-Path -Path $sourcePath -ChildPath "ffmpeg.exe"
        $destinationPath = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg.exe"
        $folderToDelete = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg-release-essentials"
    
        # Check if the source file exists
        if (Test-Path -Path $sourcePath) {
            try {
                # Move the ffmpeg.exe file to the whisper\ directory
                Move-Item -Path $($sourcePath + "\ffmpeg.exe") -Destination $destinationPath -Force
                # Delete the ffmpeg-release-essentials folder and all its contents
                Remove-Item -Path $sourcePath -Recurse -Force
            } catch {
                Write-Host "An error occurred: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "The source file does not exist: $sourcePath" -ForegroundColor Red
        }
    }
    
    # Call the function
    Move-FFmpeg

    Write-Host "ffmpeg is installed." -foregroundcolor magenta
}
