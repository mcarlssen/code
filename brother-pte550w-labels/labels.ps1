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

## 0.1.0 first edition 11/25/24.

#>

#Classes required for label printing
Add-Type -AssemblyName System.Drawing

Function PrintLabelBatch {
    Param(
        $PrintQueue,
        [string[]]$IDs
    )

    $PrintDocument = New-Object System.Drawing.Printing.PrintDocument
    $PrinterName = [System.Drawing.Printing.PrinterSettings]::InstalledPrinters | Where-Object {$_ -match $PrintQueue} | Select-Object -First 1

    if ($PrinterName -eq $null) {
        Write-Host "Printer not found. Please check the printer name and try again."
        return
    }

    $PrintDocument.PrinterSettings.PrinterName = $PrinterName
    $PrintDocument.DefaultPageSettings.PaperSize = $PrintDocument.PrinterSettings.PaperSizes | Where-Object { $_.PaperName -eq '0.47"' }
    $PrintDocument.DefaultPageSettings.Landscape = $true

    # Loop through each ID in the list
    foreach ($ID in $IDs) {
        $PrintDocument.DocumentName = "Label - SuperMAX"
        $PrintDocument.add_PrintPage({
            # Create font and colors for text and background
            $TextFont = [System.Drawing.Font]::new('Letter Gothic Std Bold', 18, [System.Drawing.FontStyle]::Regular)
            $BrushFG = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,0,0,0))

            # Get the page width in pixels
            $PageWidth = [Math]::floor(($_.PageSettings.PrintableArea.Width / 100) * $_.PageSettings.PrinterResolution.X)

            # Measure the string before drawing it on the document
            $StringSize = $_.Graphics.MeasureString($ID, $TextFont)
            Write-Host "String width:", $StringSize.Width
            Write-Host "Page width:", $PageWidth

            # Draw the string on the document
            $_.Graphics.DrawString($ID, $TextFont, $BrushFG, 0, 5)    
        })

        # Print the document
        $PrintDocument.Print()
    }

    Write-Host "All labels have been sent to the printer."
}

# List of IDs to print
$LabelList = @("GAN000-2A0466","GAN000-2A0467","GAN000-2A0468","GAN000-2A0061","GAN000-2A0388","GAN000-2A0369","GAN000-2A0387","GAN000-2A0368") # Add up to 30 IDs here

# Call the function with your printer name and list of IDs
PrintLabelBatch -PrintQueue "Brother PT-E550W" -IDs $LabelList
