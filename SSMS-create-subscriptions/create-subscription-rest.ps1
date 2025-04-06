Clear-Host

# Force PowerShell to use TLS 1.2 for secure communication
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Class to track subscription results
class SubscriptionResult {
    [bool]$Success
    [int]$RowNumber
    [string]$ServerId
    [string]$ReportType
    [string]$ErrorMessage

    SubscriptionResult([bool]$success, [int]$rowNumber, [string]$serverId, [string]$reportType, [string]$errorMessage) {
        $this.Success = $success
        $this.RowNumber = $rowNumber
        $this.ServerId = $serverId
        $this.ReportType = $reportType
        $this.ErrorMessage = $errorMessage
    }
}

# Helper functions for colored output
function Write-InfoMessage {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-DiagnosticMessage {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor DarkMagenta
}

function Write-SuccessMessage {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-ErrorMessage {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

# Function to generate schedule XML based on parameters
function Get-ScheduleXML {
    param (
        [string]$ScheduleType,
        [string]$Time,
        [string]$DaysOfWeek,
        [string]$DayOfMonth,
        [string]$Interval
    )
    
    # Get local timezone offset
    $timezone = [System.TimeZoneInfo]::Local
    $utcOffset = $timezone.BaseUtcOffset
    $offsetStr = $utcOffset.ToString("hh\:mm")
    if ($utcOffset.TotalMinutes -ge 0) {
        $offsetStr = "+$offsetStr"
    } else {
        $offsetStr = "-$offsetStr"
    }
    
    # Default time if not specified
    if ([string]::IsNullOrWhiteSpace($Time)) {
        $timeFormatted = "08:00:00"
    } else {
        try {
            $timeObj = [DateTime]::Parse($Time)
            $timeFormatted = $timeObj.ToString("HH:mm:ss")
        } catch {
            Write-ErrorMessage "Invalid time format. Using default (08:00:00)."
            $timeFormatted = "08:00:00"
        }
    }
    
    # Get tomorrow's date for start date (to ensure future date)
    $startDate = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
    
    # Process based on schedule type
    switch ($ScheduleType) {
        "Daily" {
            # Parse interval
            $daysInterval = 1
            if (-not [string]::IsNullOrWhiteSpace($Interval) -and [int]::TryParse($Interval, [ref]$null)) {
                $daysInterval = [int]$Interval
                if ($daysInterval -lt 1) { $daysInterval = 1 }
            }
            
            return @"
<?xml version="1.0" encoding="utf-16"?>
<ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <StartDateTime>$($startDate)T$($timeFormatted)$offsetStr</StartDateTime>
    <DailyRecurrence>
        <DaysInterval>$daysInterval</DaysInterval>
    </DailyRecurrence>
</ScheduleDefinition>
"@
        }
        "Monthly" {
            # Parse day of month
            $dayOfMonthValue = 1
            if (-not [string]::IsNullOrWhiteSpace($DayOfMonth) -and [int]::TryParse($DayOfMonth, [ref]$null)) {
                $dayOfMonthValue = [int]$DayOfMonth
                if ($dayOfMonthValue -lt 1 -or $dayOfMonthValue -gt 31) { $dayOfMonthValue = 1 }
            }
            
            # Parse interval (months)
            $monthsInterval = 1
            if (-not [string]::IsNullOrWhiteSpace($Interval) -and [int]::TryParse($Interval, [ref]$null)) {
                $monthsInterval = [int]$Interval
                if ($monthsInterval -lt 1) { $monthsInterval = 1 }
            }
            
            return @"
<?xml version="1.0" encoding="utf-16"?>
<ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <StartDateTime>$($startDate)T$($timeFormatted)$offsetStr</StartDateTime>
    <MonthlyRecurrence>
        <DaysOfMonth>
            <Day>$dayOfMonthValue</Day>
        </DaysOfMonth>
        <MonthsInterval>$monthsInterval</MonthsInterval>
        <MonthsOfYear>
            <January>true</January>
            <February>true</February>
            <March>true</March>
            <April>true</April>
            <May>true</May>
            <June>true</June>
            <July>true</July>
            <August>true</August>
            <September>true</September>
            <October>true</October>
            <November>true</November>
            <December>true</December>
        </MonthsOfYear>
    </MonthlyRecurrence>
</ScheduleDefinition>
"@
        }
        "Weekly" {
            # Parse interval
            $weeksInterval = 1
            if (-not [string]::IsNullOrWhiteSpace($Interval) -and [int]::TryParse($Interval, [ref]$null)) {
                $weeksInterval = [int]$Interval
                if ($weeksInterval -lt 1) { $weeksInterval = 1 }
            }
            
            # Parse days of week
            $days = @{
                "Monday" = $false
                "Tuesday" = $false
                "Wednesday" = $false
                "Thursday" = $false
                "Friday" = $false
                "Saturday" = $false
                "Sunday" = $false
            }
            
            if (-not [string]::IsNullOrWhiteSpace($DaysOfWeek)) {
                $daysList = $DaysOfWeek -split ','
                foreach ($day in $daysList) {
                    $trimmedDay = $day.Trim()
                    if ($days.ContainsKey($trimmedDay)) {
                        $days[$trimmedDay] = $true
                    }
                }
            }
            
            # If no days selected, default to Monday
            if (-not ($days.Values -contains $true)) {
                $days["Monday"] = $true
            }
            
            $daysXml = ($days.GetEnumerator() | Where-Object { $_.Value } | ForEach-Object {
                "            <$($_.Key)>true</$($_.Key)>"
            }) -join "`n"
            
            return @"
<?xml version="1.0" encoding="utf-16"?>
<ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <StartDateTime>$($startDate)T$($timeFormatted)$offsetStr</StartDateTime>
    <WeeklyRecurrence>
        <WeeksInterval>$weeksInterval</WeeksInterval>
        <DaysOfWeek>
$daysXml
        </DaysOfWeek>
    </WeeklyRecurrence>
</ScheduleDefinition>
"@
        }
        default {
            # Default to daily
            return @"
<?xml version="1.0" encoding="utf-16"?>
<ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <StartDateTime>$($startDate)T$($timeFormatted)$offsetStr</StartDateTime>
    <DailyRecurrence>
        <DaysInterval>1</DaysInterval>
    </DailyRecurrence>
</ScheduleDefinition>
"@
        }
    }
}

# Function to validate Server ID format
function Test-ServerIdFormat {
    param (
        [string]$ServerId
    )
    $serverIdRegex = "^[a-zA-Z0-9]{6}_[0-9]{5}$"
    return $ServerId -match $serverIdRegex
}

# Function to get Server ID from user
function Get-ValidServerId {
    $validServerId = $false
    $serverId = ""

    while (-not $validServerId) {
        Write-InfoMessage "Please enter the Server ID (format: XXXXXX_YYYYY where X=alphanumeric, Y=numeric):"
        $serverId = Read-Host "Server ID"
        
        if ([string]::IsNullOrWhiteSpace($serverId)) {
            Write-ErrorMessage "Server ID is required."
            continue
        }
        
        if (Test-ServerIdFormat $serverId) {
            $validServerId = $true
        } else {
            Write-ErrorMessage "Invalid Server ID format. Must match pattern: 6 alphanumeric characters, underscore, 5 numeric characters."
        }
    }
    return $serverId
}

# Function to create SSRS web service proxy
function New-SSRSWebServiceProxy {
    param (
        [string]$SSRSUrl,
        [System.Management.Automation.PSCredential]$Credentials
    )
    
    try {
        $proxy = New-WebServiceProxy -Uri $SSRSUrl -Credential $Credentials
        
        if ($null -eq $proxy) {
            throw "Web Service Proxy is null"
        }

        return $proxy
    } catch {
        Write-ErrorMessage "Error creating Web Service Proxy: $_"
        throw
    }
}

# Function to normalize schedule type
function Get-NormalizedScheduleType {
    param (
        [string]$ScheduleType
    )
    
    switch ($ScheduleType) {
        "Monthly" { return "Weekly" }  # Convert Monthly to Weekly
        "DailyAllWeek" { return "Weekly" }  # Convert DailyAllWeek to Weekly with all days
        "WeeklyMonday" { return "Weekly" }
        "WeeklyFriday" { return "Weekly" }
        default { return $ScheduleType }
    }
}

# Function to get days of week for special schedule types
function Get-SpecialScheduleDays {
    param (
        [string]$ScheduleType,
        [string]$DaysOfWeek
    )
    
    # If days are already specified, use them (replacing semicolons with commas)
    if (-not [string]::IsNullOrWhiteSpace($DaysOfWeek)) {
        return $DaysOfWeek.Replace(";", ",")
    }
    
    # Otherwise, use the schedule type to determine days
    switch ($ScheduleType) {
        "Monthly" {
            # Convert monthly schedules to a specific day of the week (Monday)
            return "Monday"
        }
        "DailyAllWeek" { 
            return "Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday"
        }
        "WeeklyMonday" { 
            return "Monday"
        }
        "WeeklyFriday" { 
            return "Friday" 
        }
        default {
            return "" 
        }
    }
}

# Function to process a single subscription from CSV data
function New-SubscriptionFromCSVRow {
    param (
        [PSCustomObject]$Row,
        [string]$ServerId,
        $ReportServerProxy,
        $ParameterValueType,
        $ExtensionSettingsType,
        [int]$RowNumber = 0
    )
    
    try {
        # Construct report path from ServerId and ReportType
        $reportRootFolder = "/{0}_G1WH Reports" -f $ServerId
        $ReportType = $Row.ReportType
        
        # Combine paths, handling cases where ReportType might be empty or contains slashes
        if ([string]::IsNullOrEmpty($ReportType)) {
            $ReportPath = $reportRootFolder
        } else {
            # Remove any leading or trailing slashes and normalize internal slashes
            $ReportType = $ReportType.Trim('/').Replace('/', '_')
            $ReportPath = "$reportRootFolder/$ReportType"
        }
        
        # Handle special schedule types
        $normalizedScheduleType = Get-NormalizedScheduleType -ScheduleType $Row.ScheduleType
        $specialDays = Get-SpecialScheduleDays -ScheduleType $Row.ScheduleType -DaysOfWeek $Row.ScheduleDaysOfWeek
        
        # Modified interval for Monthly converted to Weekly (use 4 weeks as approximate month)
        $interval = $Row.ScheduleInterval
        if ($Row.ScheduleType -eq "Monthly" -and -not [string]::IsNullOrEmpty($interval)) {
            # For monthly intervals, multiply by 4 to get approximate weeks
            if ([int]::TryParse($interval, [ref]$null)) {
                $interval = ([int]$interval * 4).ToString()
            }
        }
        
        # Map CSV columns to variables
        $subscriptionParams = @{
            ReportPath = $ReportPath
            ReportConfigId = $Row.ReportConfigId
            Description = $Row.Description
            EmailTo = $Row.EmailTo
            EmailCC = $Row.EmailCC
            EmailReplyTo = $Row.EmailReplyTo
            RenderFormat = $Row.RenderFormat  # Keep original format (EXCELOPENXML, etc.)
            EmailSubject = $Row.EmailSubject
            IncludeReport = $Row.IncludeReport
            EmailPriority = $Row.EmailPriority
            ScheduleType = $normalizedScheduleType
            ScheduleTime = $Row.ScheduleTime
            ScheduleDaysOfWeek = $specialDays
            ScheduleDayOfMonth = $Row.ScheduleDayOfMonth
            ScheduleInterval = $interval
        }
        
        # Validate required fields
        if ([string]::IsNullOrEmpty($subscriptionParams.ReportConfigId)) {
            throw "CSV row is missing required field ReportConfigId"
        }
        
        # Display the parameters being used
        Write-InfoMessage "Processing subscription for: $ReportPath"
        Write-Host "  Report Path: $ReportPath" -ForegroundColor Cyan
        Write-Host "  Description: $($subscriptionParams.Description)" -ForegroundColor Cyan
        Write-Host "  Report Config ID: $($subscriptionParams.ReportConfigId)" -ForegroundColor Cyan
        Write-Host "  Email To: $($subscriptionParams.EmailTo)" -ForegroundColor Cyan
        Write-Host "  Schedule Type: $($subscriptionParams.ScheduleType)" -ForegroundColor Cyan
        Write-Host "  Render Format: $($subscriptionParams.RenderFormat)" -ForegroundColor Cyan
        
        if ($normalizedScheduleType -ne $Row.ScheduleType) {
            Write-DiagnosticMessage "  Normalized schedule type from '$($Row.ScheduleType)' to '$normalizedScheduleType'"
            
            # Special messaging for Monthly schedules
            if ($Row.ScheduleType -eq "Monthly") {
                Write-DiagnosticMessage "  Monthly schedule converted to Weekly (every $interval weeks on Monday)"
            }
            
            if ($specialDays) {
                Write-DiagnosticMessage "  Days of week: $specialDays"
            }
        }
        
        # Generate schedule XML
        $ScheduleXML = Get-ScheduleXML `
            -ScheduleType $subscriptionParams.ScheduleType `
            -Time $subscriptionParams.ScheduleTime `
            -DaysOfWeek $subscriptionParams.ScheduleDaysOfWeek `
            -DayOfMonth $subscriptionParams.ScheduleDayOfMonth `
            -Interval $subscriptionParams.ScheduleInterval
            
        # Create subscription objects and parameters
        $subscription = New-SSRSSubscription `
            -ReportServerProxy $ReportServerProxy `
            -ParameterValueType $ParameterValueType `
            -ExtensionSettingsType $ExtensionSettingsType `
            -Params $subscriptionParams `
            -ScheduleXML $ScheduleXML
        
        Write-SuccessMessage "  ✅ Subscription Created Successfully!"
        #Write-SuccessMessage "  Subscription ID: $($subscription.SubscriptionID)"
        
        return [SubscriptionResult]::new($true, $RowNumber, $ServerId, $ReportType, "")
        
    } catch {
        Write-ErrorMessage "Error processing subscription. Skipping and continuing with the next one..."
        return [SubscriptionResult]::new($false, $RowNumber, $ServerId, $ReportType, $_.Exception.Message)
    }
}

# Function to create SSRS subscription objects and parameters
function New-SSRSSubscription {
    param (
        $ReportServerProxy,
        $ParameterValueType,
        $ExtensionSettingsType,
        [hashtable]$Params,
        [string]$ScheduleXML
    )
    
    try {
        # Create email parameters
        $EmailParams = @()
        
        $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "TO" -Value $Params.EmailTo
        
        if (-not [string]::IsNullOrEmpty($Params.EmailCC)) {
            $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "CC" -Value $Params.EmailCC
        }
        
        if (-not [string]::IsNullOrEmpty($Params.EmailReplyTo)) {
            $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "ReplyTo" -Value $Params.EmailReplyTo
        }
        
        $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "RenderFormat" -Value $Params.RenderFormat
        $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "Subject" -Value $Params.EmailSubject
        $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "IncludeReport" -Value $Params.IncludeReport
        $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "IncludeLink" -Value "true"
        $EmailParams += New-TypedParameter -Type $ParameterValueType -Name "Priority" -Value $Params.EmailPriority
        
        # Create extension settings
        $ExtensionSettings = New-Object $ExtensionSettingsType
        $ExtensionSettings.Extension = "Report Server Email"
        $ExtensionSettings.ParameterValues = $EmailParams
        
        # Create report parameters
        $ReportParameters = @()
        $ReportParameters += New-TypedParameter -Type $ParameterValueType -Name "ReportConfigurationId" -Value $Params.ReportConfigId
        
        # Convert arrays to typed arrays if needed
        if ($ReportParameters -is [System.Array] -and $ReportParameters.Count -gt 0) {
            $ElementType = $ReportParameters[0].GetType()
            $TypedArray = [System.Array]::CreateInstance($ElementType, $ReportParameters.Count)
            
            for ($i = 0; $i -lt $ReportParameters.Count; $i++) {
                $TypedArray[$i] = $ReportParameters[$i]
            }
            
            $ReportParameters = $TypedArray
        }
        
        # Create subscription
        Write-InfoMessage "  Creating subscription..."
        $SubscriptionID = $ReportServerProxy.CreateSubscription(
            $Params.ReportPath,
            $ExtensionSettings,
            $Params.Description,
            "TimedSubscription",
            $ScheduleXML,
            $ReportParameters
        )
        
        return @{
            SubscriptionID = $SubscriptionID
            ExtensionSettings = $ExtensionSettings
            ReportParameters = $ReportParameters
        }
        
    } catch {
        throw
    }
}

# Function to create a typed parameter
function New-TypedParameter {
    param (
        $Type,
        [string]$Name,
        [string]$Value
    )
    
    $param = New-Object $Type
    $param.Name = $Name
    $param.Value = $Value
    return $param
}

# Function to run test mode with predefined parameters
function Start-TestMode {
    param (
        $ReportServerProxy,
        $ParameterValueType,
        $ExtensionSettingsType
    )
    
    Write-InfoMessage "Running in Test Mode with predefined parameters..."
    
    $testParams = @{
        ServerId = "TKS017_26790"
        ReportType = "WellBeing"
        ReportConfigId = "00000000-0000-0000-0000-000000000000"
        Description = "Test Subscription"
        EmailTo = "test@company.com"
        EmailCC = ""
        EmailReplyTo = "noreply@company.com"
        RenderFormat = "PDF"
        EmailSubject = "Test Report Subscription"
        IncludeReport = "true"
        EmailPriority = "NORMAL"
        ScheduleType = "Daily"
        ScheduleTime = "08:00"
        ScheduleDaysOfWeek = ""
        ScheduleDayOfMonth = ""
        ScheduleInterval = "1"
    }
    
    try {
        New-SubscriptionFromCSVRow `
            -Row ([PSCustomObject]$testParams) `
            -ServerId $testParams.ServerId `
            -ReportServerProxy $ReportServerProxy `
            -ParameterValueType $ParameterValueType `
            -ExtensionSettingsType $ExtensionSettingsType
            
        Write-SuccessMessage "Test Mode completed successfully."
    }
    catch {
        Write-ErrorMessage "Test Mode failed: $_"
    }
}

# Function to analyze and display CSV summary
function Show-CSVSummary {
    param (
        [array]$CsvData
    )
    
    $uniqueReportTypes = $CsvData | Select-Object -ExpandProperty ReportType -Unique
    
    Write-InfoMessage "`nSubscription Creation Summary:"
    Write-Host "Total Subscriptions: $($CsvData.Count)" -ForegroundColor Cyan
    Write-Host "`n Report Types ($($uniqueReportTypes.Count)):" -ForegroundColor Cyan
    $uniqueReportTypes | ForEach-Object { Write-Host "  - $_" }
    
    # Validate all entries
    $validationIssues = @()
    $rowIndex = 2  # Start at 2 to account for header row (row 1)
    
    foreach ($row in $CsvData) {
        if (-not (Test-ServerIdFormat $row.ServerId)) {
            $validationIssues += "Row $($rowIndex): Invalid Server ID format: $($row.ServerId)"
        }
        if ([string]::IsNullOrEmpty($row.ReportConfigId)) {
            $validationIssues += "Row $($rowIndex): Missing ReportConfigId for $($row.ServerId)"
        }
        if ([string]::IsNullOrEmpty($row.EmailTo)) {
            $validationIssues += "Row $($rowIndex): Missing EmailTo for $($row.ServerId)"
        }
        $rowIndex++
    }
    
    if ($validationIssues.Count -gt 0) {
        Write-Host "`nValidation Issues Found:" -ForegroundColor Red
        $validationIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        return $false
    }
    
    Write-Host "`nWould you like to proceed with creating these subscriptions? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    return $response -eq 'Y'
}

# Function to display execution summary
function Show-ExecutionSummary {
    param (
        [array]$Results
    )
    
    $successCount = ($Results | Where-Object { $_.Success }).Count
    $failureCount = ($Results | Where-Object { -not $_.Success }).Count
    $totalCount = $Results.Count
    
    Write-Host "`n========== Execution Summary ==========" -ForegroundColor Cyan
    Write-Host "Total Subscriptions Processed: $totalCount" -ForegroundColor Cyan
    Write-SuccessMessage "Successful: $successCount"
    
    if ($failureCount -gt 0) {
        Write-ErrorMessage "Failed: $failureCount"
        Write-Host "`nFailed Subscriptions:" -ForegroundColor Red
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  Row $($_.RowNumber): $($_.ServerId)/$($_.ReportType)" -ForegroundColor Red
            Write-Host "    Error: $($_.ErrorMessage)" -ForegroundColor DarkRed
        }
    }
    
    Write-Host "====================================" -ForegroundColor Cyan
}

# Function to process CSV mode
function Start-CSVMode {
    param (
        $ReportServerProxy,
        $ParameterValueType,
        $ExtensionSettingsType
    )
    
    Write-InfoMessage "`nPlease provide the path to your CSV file (or press Enter to exit):"
    $csvPath = Read-Host "CSV Path"
    
    if ([string]::IsNullOrWhiteSpace($csvPath)) {
        Write-InfoMessage "`nNo CSV path provided. Exiting script."
        return
    }
    
    if (-not (Test-Path $csvPath)) {
        Write-ErrorMessage "`nCSV file not found at path: $csvPath"
        return
    }
    
    try {
        Write-DiagnosticMessage "`nImporting parameters from CSV..."
        $csvData = Import-Csv -Path $csvPath
        
        if ($csvData.Count -eq 0) {
            throw "CSV file is empty"
        }
        
        # Show summary and get confirmation
        $proceed = Show-CSVSummary -CsvData $csvData
        if (-not $proceed) {
            Write-InfoMessage "`nOperation cancelled by user."
            return
        }
        
        Write-DiagnosticMessage "Processing $($csvData.Count) subscription(s)..."
        $results = @()
        $rowNumber = 1  # Start at 1 since we'll show actual data row numbers
        
        foreach ($row in $csvData) {
            # Debug information for monthly schedules
            if ($row.ScheduleType -eq "Monthly") {
                Write-DiagnosticMessage "Processing Monthly schedule in row $($rowNumber+1)"
                Write-DiagnosticMessage "  DayOfMonth: '$($row.ScheduleDayOfMonth)'"
                Write-DiagnosticMessage "  Interval: '$($row.ScheduleInterval)'"
            }
            
            $result = New-SubscriptionFromCSVRow `
                -Row $row `
                -ServerId $row.ServerId `
                -ReportServerProxy $ReportServerProxy `
                -ParameterValueType $ParameterValueType `
                -ExtensionSettingsType $ExtensionSettingsType `
                -RowNumber $rowNumber
            
            $results += $result
            $rowNumber++
            Write-Host "-------------------------------------------" -ForegroundColor DarkGray
        }
        
        # Display execution summary
        Show-ExecutionSummary -Results $results
        
        Write-SuccessMessage "CSV processing complete."
    }
    catch {
        Write-ErrorMessage "Error importing CSV: $_"
        Write-InfoMessage "CSV should contain columns: ReportConfigId, ServerId, ReportType, Description, EmailTo, EmailCC, EmailReplyTo, RenderFormat, EmailSubject, IncludeReport, EmailPriority, ScheduleType, ScheduleTime, ScheduleDaysOfWeek, ScheduleDayOfMonth, ScheduleInterval"
    }
}

# Main script execution
function Start-Main {
    # Pretty header on launch
    Write-Host "`n"
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "  SSRS Subscription Importer" -ForegroundColor Cyan
    Write-Host "  CSV-to-SSRS by: @mcarlssen" -ForegroundColor Cyan
    Write-Host "`n  Must be run on the report server!" -ForegroundColor DarkCyan
    Write-Host "  See CSV Guide.md for usage instructions." -ForegroundColor DarkCyan
    Write-Host "  Version 1.0.0 2025-03-20" -ForegroundColor DarkCyan
    Write-Host "`n  Contains 100% Daily Value of bugs and scheduling errors." -ForegroundColor DarkRed
    Write-Host "=======================================" -ForegroundColor Cyan

    # Get the current machine's hostname for the SSRS URL, and construct the SSRS URL using the hostname
    $hostname = [System.Net.Dns]::GetHostName()
    $SSRSUrl = "http://$hostname/ReportServer/ReportService2010.asmx?wsdl"
    Write-DiagnosticMessage "`nUsing local server SSRS URL: $SSRSUrl"
    
    # Ask user which mode to use
    Write-InfoMessage "`nChoose operation mode:"
    Write-Host "1. CSV Mode - Create subscriptions from CSV file" -ForegroundColor Cyan
    Write-Host "2. Test Mode - Create a test subscription" -ForegroundColor Cyan
    $choice = Read-Host "Enter your choice (1 or 2)"
    
    try {
        # Create web service proxy
        $ReportServerProxy = New-SSRSWebServiceProxy -SSRSUrl $SSRSUrl -Credentials $Creds
        
        # Get proxy types
        $ProxyTypes = $ReportServerProxy.GetType().Assembly.GetTypes()
        $ParameterValueType = ($ProxyTypes | Where-Object { $_.Name -eq "ParameterValue" })[0]
        $ExtensionSettingsType = ($ProxyTypes | Where-Object { $_.Name -eq "ExtensionSettings" })[0]
        
        if ($null -eq $ParameterValueType -or $null -eq $ExtensionSettingsType) {
            throw "Could not find required types in web service proxy"
        }
        
        switch ($choice) {
            "1" {
                Start-CSVMode -ReportServerProxy $ReportServerProxy -ParameterValueType $ParameterValueType -ExtensionSettingsType $ExtensionSettingsType
            }
            "2" {
                Start-TestMode -ReportServerProxy $ReportServerProxy -ParameterValueType $ParameterValueType -ExtensionSettingsType $ExtensionSettingsType
            }
            default {
                Write-ErrorMessage "Invalid choice. Please run the script again and select 1 or 2."
            }
        }
    }
    catch {
        Write-ErrorMessage "Error in subscription creation process: $_"
    }
}

# Start the script
Start-Main
