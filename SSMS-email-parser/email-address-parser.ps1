<#

# SQL SERVER REPORT SUBSCRIPTION EMAIL RECIPIENT FORMATTER

Converts a list of contacts into a properly-formatted list of email addresses that SSRS will accept as report subscribers.

SSRS requires email addresses to be semicolon-delimited, without contact names.

This list is often sent to us in a non-standardized format - proper names are included, email addresses may or may not be enclosed in brackets, 
or delimited with semicolons or other characters already. Cleaning this up is tedious and can take time, and can be error-prone.

## USAGE
From a powershell prompt, run the script as so:
$> .\email-address-parser.ps1

When prompted, copy the provided email list into the terminal, and press Enter twice to submit. The script will process the input, sanitize the
email addresses, and output the resulting email list to the console - as well as load it into the clipboard.

## NOTES

# changelog

## 0.1.1 made script more friendly to run from a batch file. Added prompt after emails have been parsed to loop back through main input cycle (for repeat tasks).
## 0.1.0 first edition 5/17/24.

#>

#Clear-Host

# Function to extract email addresses from input dataset
function Get-EmailAddresses {
    param (
        [string[]]$contactList
    )
    $emailAddresses = @()
    foreach ($contact in $contactList) {
        # Trim each contact line to remove any leading/trailing whitespace or newlines
        $contact = $contact.Trim()

        if ($contact -match '<(.+?)>') {
            $emailAddresses += $matches[1]
        } elseif ($contact -match '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})') {
            $emailAddresses += $matches[1]
        }
    }
    return $emailAddresses -join '; '
}

# Function to capture user input until Ctrl+Enter is pressed
function Get-InputWithCtrlEnter {
    $data = @()
    Write-Host "Enter the contact list (press Ctrl+Enter to finish):" -ForegroundColor yellow
    
    $currentLine = ""
    while ($true) {
        $keyInfo = [System.Console]::ReadKey($true)
        
        if ($keyInfo.Key -eq "Enter" -and $keyInfo.Modifiers -eq "Control") {
            # Add the final line if there's any input
            if ($currentLine -ne "") {
                $data += $currentLine
            }
            break # Exit on Ctrl+Enter
        } elseif ($keyInfo.Key -eq "Enter") {
            Write-Host ""  # Print a new line
            if ($currentLine -ne "") {
                $data += $currentLine  # Add the full line of input to the data array
                $currentLine = ""      # Reset current line
            }
        } else {
            $char = $keyInfo.KeyChar
            Write-Host -NoNewline $char  # Display the character without a new line
            $currentLine += $char        # Append the character to the current line
        }
    }

    return $data
}

# Main loop
while ($true) {
    # Prompt the user to enter the dataset
    $data = Get-InputWithCtrlEnter

    if ($data.Count -eq 0) {
        Write-Host "No input provided. Please try again." -ForegroundColor Red
        continue # Restart the loop if no data is entered
    }

    # Remove any empty lines in the data
    $data = $data | Where-Object { $_ -match '\S' }

    # Get the email addresses
    $emailAddresses = Get-EmailAddresses -contactList $data

    if ($emailAddresses -eq "") {
        Write-Host "No valid email addresses found." -ForegroundColor Red
    } else {
        # Output the email addresses
        Write-Host "`n`nParsed email list:" -ForegroundColor DarkMagenta
        Write-Host $emailAddresses -ForegroundColor Gray
        $emailAddresses | Set-Clipboard
        Write-Host "`nThe email list has been copied to the clipboard." -ForegroundColor yellow
    }

    # Prompt to enter more data or exit
    $choice = Read-Host "Press 1 to enter more, or any other key to exit"
    if ($choice -ne "1") {
        break
    } 
}
