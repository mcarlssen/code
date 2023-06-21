<#

# Reaper Project File Edit Counter

This script creates a very basic report containing a count of all clip edits within any .RPP project files
it can find. It searches recursively at and below the folder it is run in, and generates a single output file
called `Reaper-Project-Edits-Count.txt`.

I use this when calculating efficiency stats for audiobooks, as it tells me roughly how many mistakes I made!

## USAGE

Run this script in a powershell prompt at the root level of all folders where you have Reaper project files you wish to scan.

# changelog

## 0.1.0 first edition 7/8/22.

## NOTES

Script written by Magnus Carlssen. Released as public domain.
Please don't copy my code - not because it's good, but because it's terrible.
Please send bug reports or feature improvements to magnus@carlssen.co.uk.

https://carlssen.co.uk

#>

function Get-ReaperFiles {
	$ProjectData = @()
	$ProjectFiles = (Get-ChildItem -Path $raw -Filter *.rpp -Recurse -ErrorAction SilentlyContinue -Force)
	$raw = Get-Location
	
	 if ($raw -eq $null) {
        Write-Host "**ERROR**: Cannot determine current folder, or access denied." -ForegroundColor Red
        Exit
    } elseif ($ProjectFiles -eq 0) {
		Write-Host "**ERROR**: No project files found in $raw." -ForegroundColor Red
	} else {
		Write-Host $ProjectFiles.Count"files found. Writing to"$raw"\Reaper-Project-Edits-Count.txt" -ForegroundColor Yellow
		foreach ($projectname in $ProjectFiles) {
			$editcount = (select-string -Path $projectname -Pattern "<ITEM").Count
			if ($editcount -gt 1) {
				$clipcount = $editcount-1
			} else {
				$clipcount = $editcount
			}
			$ProjectData += $projectname.Name,$editcount
			"$projectname, $editcount edits" | format-table | out-file $raw\Reaper-Project-Edits-Count.txt -append
		}
	}
}

Write-Host "Scanning for Reaper project files..." -ForegroundColor Yellow
Get-ReaperFiles
