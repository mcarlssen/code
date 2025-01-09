<#

# BROTHER PT-E550W BATCH LABEL PRINTING SCRIPT

Save yourself a lot of time and wasted label stock by batch-printing. Supports USB or wireless printing - script just relies on using an available Windows printer.

## USAGE
Launch script from a powershell command prompt like so:
$> .\labels.ps1

You will need to update two lines in the script for correct operation:

"$LabelList" - This is what the printer will output. The script expects the each label's text to be quote-enclosed and comma-separated.

At the bottom of the script, update the `-PrintQueue` parameter with the display name of the printer you'd like to use.

## NOTES

At this time, the labels are a fixed length. Dynamic-length labels are a planned feature for the future.

Other features such as font, text size, label size, etc are hardcoded and can be manually changed in the script. Some tweaking may be required to page length to compensate.

Script written by Magnus Carlssen. Released as public domain.
Please don't copy my code - not because it's good, but because it's terrible.
Please send bug reports or feature improvements to magnus@carlssen.co.uk.

https://carlssen.co.uk

# feature requests
- make print parameters easily adjustable (label size, text size, dynamic label length)

# changelog

## 0.2.0 added test mode, serial/customer number input 2025-01-09.
## 0.1.0 first edition 2024-11-25.

#>

Clear-Host

# Classes required for label printing
Add-Type -AssemblyName System.Drawing

Function GetLabelSettings {
    Param(
        [string]$PrintQueue
    )

    # Create a PrintDocument object to get the printer's paper size
    $PrintDocument = New-Object System.Drawing.Printing.PrintDocument
    $PrinterName = [System.Drawing.Printing.PrinterSettings]::InstalledPrinters | Where-Object { $_ -match $PrintQueue } | Select-Object -First 1

    if ($PrinterName -eq $null) {
        Write-Host "Printer not found. Please check the printer name and try again." -ForegroundColor Red
        return $null
    }

    # Assign the printer name to the PrintDocument
    $PrintDocument.PrinterSettings.PrinterName = $PrinterName

    # Get current paper size
    $PaperSize = $PrintDocument.DefaultPageSettings.PaperSize.PaperName
    if ($PaperSize -eq '0.47"') {
        $FontSize = 18
        $OffsetY = 5
    } elseif ($PaperSize -eq '0.35"') {
        $FontSize = 14
        $OffsetY = 3
    } else {
        Write-Host "Unsupported paper size: $PaperSize" -ForegroundColor Red
        return $null
    }

    # Return settings as a hash table
    return @{
        PaperSize = $PaperSize
        FontSize = $FontSize
        OffsetY  = $OffsetY
    }
}

Function PrintLabelBatch {
    Param(
        $PrintQueue,
        [string[]]$IDs,
        [switch]$TestMode
    )

    # Get label settings
    $Settings = GetLabelSettings -PrintQueue $PrintQueue
    if ($Settings -eq $null) {
        Write-Host "Failed to retrieve label settings. Exiting." -ForegroundColor Red
        return
    }

    # Extract settings for use
    $PaperSize = $Settings.PaperSize
    $FontSize = $Settings.FontSize
    $OffsetY = $Settings.OffsetY

    # Display settings
    Write-Host "`nPaper Size: $PaperSize" -ForegroundColor Cyan
    Write-Host "Font Size: $FontSize" -ForegroundColor Cyan
    Write-Host "Offset: 0,$OffsetY" -ForegroundColor Cyan

    # If in test mode, output details and return
    if ($TestMode) {
        Write-Host "`nTEST MODE: No labels will be printed." -ForegroundColor Yellow
        Write-Host "Labels to be printed:" -ForegroundColor Green
        $IDs | ForEach-Object { Write-Host $_ }
        return
    }

    # Proceed with printing
    $PrintDocument = New-Object System.Drawing.Printing.PrintDocument
    $PrintDocument.PrinterSettings.PrinterName = [System.Drawing.Printing.PrinterSettings]::InstalledPrinters | Where-Object { $_ -match $PrintQueue } | Select-Object -First 1

    foreach ($ID in $IDs) {
        $PrintDocument.DocumentName = "Label - SuperMAX"
        $PrintDocument.add_PrintPage({
            # Create font and draw the string
            $TextFont = [System.Drawing.Font]::new('Letter Gothic Std Bold', $FontSize, [System.Drawing.FontStyle]::Regular)
            $BrushFG = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,0,0,0))
            $_.Graphics.DrawString($ID, $TextFont, $BrushFG, 0, $OffsetY)
        })
        $PrintDocument.Print()
    }

    Write-Host "All labels have been sent to the printer." -ForegroundColor Green
}

Function GenerateLabelList {
    # Prompt for customer code
    $CustomerCode = Read-Host "What is the customer code?"

    # Prompt for serial numbers (multi-line input)
    Write-Host "Input serial numbers, one per line (press Enter twice to finish):" -ForegroundColor Cyan
    $Serials = @()
    while ($true) {
        $Input = Read-Host
        if ([string]::IsNullOrWhiteSpace($Input)) { break }
        $Serials += $Input
    }

    # Generate the label list
    $LabelList = $Serials | ForEach-Object { "$CustomerCode-$($_.Substring($_.Length - 6))" }
    return $LabelList
}

# Main routine
Write-Host "Welcome to the Brother PT-E550W Batch Label Printing Script" -ForegroundColor Cyan
$UseDynamicList = Read-Host "Do you want to generate a label list dynamically? (yes/no)"
if ($UseDynamicList -eq "yes") {
    $LabelList = GenerateLabelList
} else {
    # Hardcoded label list
    Write-Host "Printing hardcoded label list."
    $LabelList = @(
        "GRA006-0A0400", "GRA006-0A0373", "GRA006-0A0433", "GRA006-0A0377", "GRA006-0A0430", "GRA006-0A0378",
        "GRA006-0A0401", "GRA006-0A0408", "GRA006-0A0374", "GRA006-0A0403", "GRA006-0A0211", "GRA006-0A0314"
    )
}

# Retrieve label settings for confirmation
$Settings = GetLabelSettings -PrintQueue "Brother PT-E550W"
if ($Settings -eq $null) {
    Write-Host "Failed to retrieve label settings. Exiting." -ForegroundColor Red
    exit
}
$PaperSize = $Settings.PaperSize
$FontSize = $Settings.FontSize
$OffsetY = $Settings.OffsetY

# Test mode confirmation
$TestMode = Read-Host "Enable test mode? (yes/no)" -eq "yes"

# Confirm print job
Write-Host "`nLabels to print:" -ForegroundColor Green
$LabelList | ForEach-Object { Write-Host $_ }
Write-Host "`nPaper Size: $PaperSize" -ForegroundColor Cyan
Write-Host "Font Size: $FontSize" -ForegroundColor Cyan
Write-Host "Offset: 0,$OffsetY" -ForegroundColor Cyan
$Proceed = Read-Host "Proceed with printing? (yes/no)"
if ($Proceed -eq "yes") {
    PrintLabelBatch -PrintQueue "Brother PT-E550W" -IDs $LabelList -TestMode:$TestMode
} else {
    Write-Host "Print job canceled." -ForegroundColor Yellow
}
