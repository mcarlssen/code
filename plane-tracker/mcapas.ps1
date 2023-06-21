<#

# MAGNUS CARLSSEN AIRCRAFT PROXIMITY ALERT SYSTEM (MCAPAS)

Pulls live data from the ADS-B Exchange API based on user-provided lat/long coordinates (and a radius distance)
to provide visual warning about any aircraft about to enter audible airspace. Users are warned when aircraft
enter a 3x, 2x, 1.5x, and finally the target audible zone.

-radius uses Nautical Miles as this is the unit that ADB-S prefers.

I configured this script to use a blink(1) LED device; however, if you don't have one, you can still use the script.
Just add '--noblink' to the command line.

**You will need to get your own RapidAPI key to use on line 53.** (https://rapidapi.com/adsbx/api/adsbexchange-com1)

## USAGE
From a powershell prompt, run the script as so:
$> .\mcapas.ps1 -lat xx.xxxxx -lon xx.xxxxx -dist x [--noblink]

## NOTES

Script written by Magnus Carlssen. Released as public domain.
Please don't copy my code - not because it's good, but because it's terrible.
Please send bug reports or feature improvements to magnus@carlssen.co.uk.

https://carlssen.co.uk

# changelog

## 0.1.0 first edition 6/21/23.

#>

Param
    (
         [Parameter(Mandatory=$false, Position=0)]
          $lat,
         [Parameter(Mandatory=$false, Position=1)]
          $lon,
		 [Parameter(Mandatory=$false, Position=2)]
          $dist,
		 [Parameter(Mandatory=$false, Position=3)]
          $noblink
    )
	
# tidy up a little
Clear-Host

####Base Settings####
$radius=($dist*4)
$response=@{}
$headers=@{}
$headers.Add("X-RapidAPI-Key", "<INSERT-YOUR-API-KEY-HERE>")
$headers.Add("X-RapidAPI-Host", "adsbexchange-com1.p.rapidapi.com")
$uri = "https://adsbexchange-com1.p.rapidapi.com/v2/lat/$lat/lon/$lon/dist/$radius/"


if ($lat -eq $null -or $lon -eq $null -or $dist -eq $null) {
	Write-Host "**ERROR**: Parameters missing. Please re-run script and provide latitude and longitude as -lat and -lon, and range to search in nautical miles as -dist." -ForegroundColor Red
	Exit
} else {
	Write-Host "MAGNUS CARLSSEN AIRCRAFT PROXIMITY ALERT SYSTEM (MCAPAS)" -ForegroundColor DarkYellow
	Write-Host "SEARCHING COORDINATES:"$lat", "$lon"`nDanger range: "$dist" nautical miles`n" -ForegroundColor DarkGray
}

function Get-Aircraft {
		$alt=$dist*6076 #nautical mile in feet

		$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

		$aircraft=$response.ac
		$ranges=@()
		if ($aircraft.alt_baro.Count -eq $null) {
			Write-Host "No aircraft within audible range."
		} else {
			Write-Host "`nAircraft in area:"$aircraft.alt_baro.Count
			foreach ($plane in $aircraft) {
				if ($plane.alt_baro -lt $alt -And $plane.alt_baro -ne "ground" ) { 

					Add-Type -AssemblyName System.Device
					$planeCoord = New-Object System.Device.Location.GeoCoordinate $plane.lat, $plane.lon
					$scanCoord = New-Object System.Device.Location.GeoCoordinate $lat, $lon
					$distance = $planeCoord.GetDistanceTo( $scanCoord ) / 1852 # converts meters to nautical miles
					$ranges += $distance
					Write-Host $plane.flight" - altitude"$plane.alt_baro"ft, "$distance" nautical miles from coordinates."
				}
			}
			
			$dangerClose = ($ranges | Measure-Object -Minimum).Minimum
			#if ($noblink -eq $null) { Write-Host "noblink=null" } else { Write-Host "noblink set!" }
			if ($dangerClose -lt $dist) {
				Write-Host "Aircraft within audible range." -ForegroundColor Red
				if ($noblink -eq $null) { Start-Process -NoNewWindow -FilePath "C:\blink1-tool.exe" -ArgumentList "-m 2000 --red -q" }
			} elseif ($dangerClose -lt $dist*1.5) {
				Write-Host "Aircraft within 1.5x radius." -ForegroundColor DarkYellow
				if (!$noblink) { Start-Process -NoNewWindow -FilePath "C:\blink1-tool.exe" -ArgumentList "-m 2000 --rgb=eb9234 -q" }
			} elseif ($dangerClose -lt $dist*2) {
				Write-Host "Aircraft within 2x radius." -ForegroundColor Yellow
				if (!$noblink)  {Start-Process -NoNewWindow -FilePath "C:\blink1-tool.exe" -ArgumentList "-m 2000 --yellow -q" }
			} elseif ($dangerClose -lt $dist*3) {
				Write-Host "Aircraft within 3x radius." -ForegroundColor Blue
				if (!$noblink) { Start-Process -NoNewWindow -FilePath "C:\blink1-tool.exe" -ArgumentList "-m 2000 --blue -q" }
				} else {
				$inaudible = [math]::Round($dangerClose-$dist,2)
				Write-Host "Closest aircraft is"$inaudible"nm outside audible danger radius."
				if (!$noblink) { Start-Process -NoNewWindow -FilePath "C:\blink1-tool.exe" -ArgumentList "-m 2000 --white -q" }
			}
		}
	}

function Get-Scan {
	$up = $true
	$finish = $false
	$timeout = 10
	Write-Host "Scanning for aircraft. " -NoNewline
	do {
		for ($i=0;$i -le 10;$i++){
			$str = ""
			$x=9-$i
			for($z=0;$z -le $i;$z++){$str+="."}
			Write-host "`rScanning for UFOs..." -NoNewline
			Get-Aircraft
			Start-Sleep -Seconds $timeout
		}
		if ($timeout -le 0){$finish = $true}
		$timeout-=1
	} until ($finish)
	$str = ""
	for ($i=0;$i -le 10;$i++){$str+=" "}
	Write-Host "`rScan Complete.$str"
}

Get-Scan
