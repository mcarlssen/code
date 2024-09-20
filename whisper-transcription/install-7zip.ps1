function Install-7Zip {
    # Check if the script is running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not $isAdmin) {
        Write-Host "Not running as admin, please manually acknowledge 7-Zip installation, then restart this script." -ForegroundColor Red
    }
	
	# thank you dansmith65 and SomeCallMeTom
	# https://gist.github.com/dansmith65/7dd950f183af5f5deaf9650f2ad3226c
	$dlurl = 'https://7-zip.org/' + (Invoke-WebRequest -UseBasicParsing -Uri 'https://7-zip.org/' | Select-Object -ExpandProperty Links | Where-Object {($_.outerHTML -match 'Download')-and ($_.href -like "a/*") -and ($_.href -like "*-x64.exe")} | Select-Object -First 1 | Select-Object -ExpandProperty href)
	# modified to work without IE
	# above code from: https://perplexity.nl/windows-powershell/installing-or-updating-7-zip-using-powershell/
	$installerPath = Join-Path $env:TEMP (Split-Path $dlurl -Leaf)
	Invoke-WebRequest $dlurl -OutFile $installerPath
	Start-Process -FilePath $installerPath -Args "/S" -Verb RunAs -Wait
	Remove-Item $installerPath
}
