<#

# UTILITY TO PARSE G1RT MOBILE ACTIVITY LOGS TO FIND A SUPERMAX LAST-LOGGED-IN-USER

When a mobile device is lost or misplaced, customers need to know the Guard1 last-logged-in user on that device. This is stored in a server-side log file:

`C:\ProgramData\TimeKeeping Systems\Guard1 Tracking\<X.xx>\Logs\G1TServer\Active.log` -OR-
`C:\ProgramData\TimeKeeping Systems\Guard1 Tracking\<X.xx>\Logs\G1TServer\Arc.YYYY-MM-DD.log`

Each log file contains 24 hours of activity, including mobile logs like this:

```2024-04-08 21:58:42.0317 -04:00|10024|INFO|G1tClient|10.0.0.76|G1TMobileApp/8.0.0.33 ANDROID/9-PM85 G1TAPI/14.0|POST /Tks.G1Track.Server/Sys/Trace|{"$type":"G1T.Dc.TraceData, G1T.Dc","Time":"2024-04-08T21:58:46.326598-04:00","Level":3,"Desc":"|Common.PlatformConnectivityService {-222619932}","Data":"|[3fad80968ba34933acbb3895d475f244]|[15]|PublishPlatformConnectivityMessage - OnCapabilitiesChanged  - Wifi (Rssi -66) - Internet - Validated - HasConnectivity: True, WifiIsConnected: True, MobileIsConnected: False|DeviceID:|64:CB:A3:F1:F4:CB [MAC]|User:|tlowery|cc42ff9f-5e98-4f78-a35f-7b1ca2323fa2|gadjjmcr\\tlowery"}

We can parse these logs by MAC address to locate the device in question, and from these entries determine the most recent last-seen date and user logged-in at the time.

## USAGE
Copy Last-Logged-In-Mobile-User.ps1 to the ~\Logs\G1TServer folder on the target server. Right-click on the script and select "Run in Powershell", or open a powershell prompt and run the script as so:
$> .\Last-Logged-In-Mobile-User.ps1

When prompted, type or paste a MAC address (or any desired string) and hit Enter. The script will parse all log files in the current folder and display a "MAC address not found" or "MAC address found in file" message, with the file path, for all *.log files in that folder, in descending order.

By observing the *last 'MAC address found' entry*, you can easily locate the most recent log containing entries for that mobile device.

Open that log file in Notepad and search for the MAC address string. Locate the *last entry* (most easily done by placing the cursor at the top of the file and choosing "Up" direction and "Wrap around" in the Search dialog"). This entry, in the format as seen above, is the last-seen time and user for that mobile device.

## NOTES

# changelog

## 0.1.1 adds timer to output duration of search query
## 0.1.0 first edition 5/22/24.

#>

# Prompt the user to enter the MAC address to search for
$macAddress = Read-Host "Please enter the MAC address to search for"

# Get the current directory
$currentDir = Get-Location

# Get all text log files in the current directory
$logFiles = Get-ChildItem -Path $currentDir -Filter *.log

# Function to search for the MAC address in a file
function Search-MacAddressInFile {
    param (
        [string]$filePath,
        [string]$macAddress
    )
    
    # Read the file content
    $fileContent = Get-Content -Path $filePath
    
    # Search for the MAC address
    $matches = Select-String -InputObject $fileContent -Pattern $macAddress
    
    return $matches
}

# Start the timer
$startTime = Get-Date

# Search for the MAC address in each log file
foreach ($file in $logFiles) {
    $matches = Search-MacAddressInFile -filePath $file.FullName -macAddress $macAddress
    
    # Output the results
    if ($matches) {
        Write-Host "MAC address found in file: $($file.FullName)"
      <#  foreach ($match in $matches) {
            Write-Host "Line $($match.LineNumber): $($match.Line)"
        } #>
    } else {
        Write-Host "MAC address not found in file: $($file.FullName)"
    }
}

# Stop the timer
$endTime = Get-Date

# Calculate the time taken and output it
$timeTaken = $endTime - $startTime
Write-Host "`nTime taken for search: $($timeTaken.TotalSeconds) seconds"

# Require user confirmation before exiting
Read-Host -Prompt "Press any key to quit"
