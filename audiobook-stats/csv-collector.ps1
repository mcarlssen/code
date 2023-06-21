<#

# CSV File Concatenator

This script should be run AFTER executing `2ndopinionconverter.ps1`. It will create a NEW csv file called 
`Audiobook-Data.csv` which will contain the contents of all those report files, in one easy-to-manipulate file.

## USAGE

Run this script in a powershell prompt at the root level of all folders where CSV files containing `2nd-Opinion` reports
may be found (likely, from the same folder you ran `2ndopinionconverter`. The output file will be created in that root folder.

Note that this script doesn't handle commas or quotation marks in chapter titles. If this occurs, that row of data will be mangled.

# changelog

## 0.1.0 first edition 6/13/23.

## NOTES

Script written by Magnus Carlssen. Released as public domain.
Please don't copy my code - not because it's good, but because it's terrible.
Please send bug reports or feature improvements to magnus@carlssen.co.uk.

https://carlssen.co.uk

#>

Clear-Host 

$inputFile = "2nd-opinion_formatted.csv"
$outputFile = "Audiobook-Data.csv"

function Get-CSVFiles {
	$rundir = Get-Location
	$csvFiles = (Get-ChildItem -Path $rundir -Filter $inputFile -Recurse -ErrorAction SilentlyContinue -Force)
	
	 if ($rundir -eq $null) {
        Write-Host "**ERROR**: Cannot determine current folder, or access denied." -ForegroundColor Red
        Exit
    } elseif ($csvFiles -eq 0) {
		Write-Host "**ERROR**: No report files found in $raw." -ForegroundColor Red
	} else {
		Write-Host $csvFiles.Count"reports found:" -ForegroundColor DarkMagenta
		foreach ($filename in $csvFiles) {
			$last2parts = $filename.FullName.Split("\") | Select-Object -Last 2
			$last2parts = $last2parts -join "\"
			Write-Host "..\"$last2parts -foregroundColor DarkMagenta
		}
		
		try {
			$csvFiles | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $outputFile -NoTypeInformation -Append
			Write-Host "Successfully merged"$csvFiles.Count"reports.`nFile saved to"$rundir"\"$outputfile"."
		} catch {
			Write-Host "Error combining files." $_ -ForegroundColor Red
		}
	}
}

Write-Host "SEARCHING FOR '2nd-Opinion' CSV FILES..." -foregroundcolor DarkYellow
Get-CSVFiles
