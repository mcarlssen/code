<#

# UTILITY TO PARSE PLAINTEXT LOGS TO FIND A GIVEN SUBSTRING

When a mobile device is lost or misplaced, customers need to know the Guard1 last-logged-in user on that device. This is stored in a server-side log file:

`C:\ProgramData\TimeKeeping Systems\Guard1 Tracking\<X.xx>\Logs\G1TServer\Active.log` -OR-
`C:\ProgramData\TimeKeeping Systems\Guard1 Tracking\<X.xx>\Logs\G1TServer\Arc.YYYY-MM-DD.log`

Each log file contains 24 hours of activity. We can parse these logs by MAC address to locate the device in question, and from these entries determine the most recent last-seen date and user logged-in at the time.

## USAGE
Copy Last-Logged-In-Mobile-User.ps1 to the ~\Logs\G1TServer folder on the target server. Right-click on the script and select "Run in Powershell", or open a powershell prompt and run the script as so:
$> .\Last-Logged-In-Mobile-User.ps1

When prompted, type or paste a MAC address (or any desired string) and hit Enter. The script will parse all log files in the current folder and display a "MAC address not found" or "MAC address found in file" message, with the file path, for all *.log files in that folder, in descending order.

By observing the *last 'MAC address found' entry*, you can easily locate the most recent log containing entries for that mobile device.

Open that log file in Notepad and search for the MAC address string. Locate the *last entry* (most easily done by placing the cursor at the top of the file and choosing "Up" direction and "Wrap around" in the Search dialog"). This entry, in the format as seen above, is the last-seen time and user for that mobile device.

## NOTES

# changelog

## 0.2.0 adds option to choose between 5 search modes: LineByLine, SelectString, StreamReader, Parallel, FindStr.
		 also now supports the -macAddress and -mode switches.
## 0.1.1 adds timer to output duration of search query
## 0.1.0 first edition 5/22/24.

#>

param (
    [string]$macAddress = $(Read-Host "Please enter the MAC address to search for"),
    [ValidateSet("LineByLine", "SelectString", "StreamReader", "Parallel", "FindStr")]
    [string]$mode = $(Read-Host "Please enter mode (LineByLine, SelectString, StreamReader, Parallel, FindStr)")
)

$currentDir = Get-Location
$logFiles = Get-ChildItem -Path $currentDir -Filter *.log

# Start the timer
$startTime = Get-Date

# Function to search using Line-by-Line reading
function Search-LineByLine {
    foreach ($file in $logFiles) {
        $filePath = $file.FullName
        $found = $false
        
        Get-Content -Path $filePath -ReadCount 0 | ForEach-Object {
            if ($_ -match $macAddress) {
                Write-Host "MAC address found in file: $filePath"
                $found = $true
                return
            }
        }

        if (-not $found) {
            Write-Host "MAC address not found in file: $filePath"
        }
    }
}

# Function to search using Select-String
function Search-SelectString {
    foreach ($file in $logFiles) {
        $matches = Select-String -Path $file.FullName -Pattern $macAddress -List
        
        if ($matches) {
            Write-Host "MAC address found in file: $($file.FullName)"
        } else {
            Write-Host "MAC address not found in file: $($file.FullName)"
        }
    }
}

# Function to search using .NET StreamReader
function Search-StreamReader {
    foreach ($file in $logFiles) {
        $filePath = $file.FullName
        $found = $false
        $reader = [System.IO.StreamReader]::new($filePath)
        
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line -match $macAddress) {
                Write-Host "MAC address found in file: $filePath"
                $found = $true
                break
            }
        }
        $reader.Close()
        
        if (-not $found) {
            Write-Host "MAC address not found in file: $filePath"
        }
    }
}

# Function to search using PowerShell 7 parallel processing
function Search-Parallel {
    $logFiles | ForEach-Object -Parallel {
        $macAddress = $using:macAddress
        $filePath = $_.FullName
        $found = $false
        $reader = [System.IO.StreamReader]::new($filePath)
        
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line -match $macAddress) {
                Write-Host "MAC address found in file: $filePath"
                $found = $true
                break
            }
        }
        $reader.Close()
        
        if (-not $found) {
            Write-Host "MAC address not found in file: $filePath"
        }
    }
}

# Function to search using external FindStr
function Search-FindStr {
    foreach ($file in $logFiles) {
        $filePath = $file.FullName
        $result = cmd.exe /c "findstr /M /C:$macAddress $filePath"
        
        if ($result) {
            Write-Host "MAC address found in file: $filePath"
        } else {
            Write-Host "MAC address not found in file: $filePath"
        }
    }
}

# Select the mode and execute
switch ($mode) {
    "LineByLine" {
        Write-Host "Running Line-by-Line file reading..."
        Search-LineByLine
    }
    "SelectString" {
        Write-Host "Running Select-String optimization..."
        Search-SelectString
    }
    "StreamReader" {
        Write-Host "Running .NET StreamReader optimization..."
        Search-StreamReader
    }
    "Parallel" {
        Write-Host "Running Parallel processing optimization (PowerShell 7 required)..."
        Search-Parallel
    }
    "FindStr" {
        Write-Host "Running external FindStr optimization..."
        Search-FindStr
    }
    default {
        Write-Host "Invalid mode. Please enter a valid mode: LineByLine, SelectString, StreamReader, Parallel, FindStr"
        exit
    }
}

# Stop the timer
$endTime = Get-Date
$timeTaken = $endTime - $startTime
Write-Host "`nTime taken for search: $($timeTaken.TotalSeconds) seconds"

Read-Host -Prompt "Press any key to quit"
