# Force PowerShell to use TLS 1.2 for secure communication
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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

# Define SSRS Web Service URL
$SSRSUrl = "http://SQL-EastUS01-VM/ReportServer/ReportService2010.asmx?wsdl"

# Prompt user for credentials
Write-InfoMessage "Please enter your credentials for SQL Report Server access:"
$Creds = Get-Credential

# Define the ReportConfigurationId GUID
$ReportConfigId = "a5ddccb8-c5ea-4efa-8c2d-1e81630956bc"

# Ensure URL formatting is correct
$SSRSUrl = $SSRSUrl.Trim()
Write-InfoMessage "Connecting to SSRS Web Service at: $SSRSUrl"

# Create a Web Service Proxy with explicit credentials - PS 5.1 compatible approach
try {
    Write-InfoMessage "Creating Web Service Proxy with provided credentials..."
    $ReportServerProxy = New-WebServiceProxy -Uri $SSRSUrl -Credential $Creds
    
    if ($null -eq $ReportServerProxy) {
        throw "Web Service Proxy is null"
    }
    
    Write-SuccessMessage "Web Service Proxy created successfully"
} catch {
    Write-ErrorMessage "Error creating Web Service Proxy: $_"
    exit 1
}

# Define report parameters
$ReportPath = "/TKS017_27258_G1WH Reports/WellBeing"
$Description = "Weekly Sales Report Subscription"

# Create the necessary objects for the subscription
try {
    # Get the necessary types from the proxy assembly
    #Write-DiagnosticMessage "Discovering SSRS object types..."
    $ProxyTypes = $ReportServerProxy.GetType().Assembly.GetTypes()
    
    $ParameterValueType = ($ProxyTypes | Where-Object { $_.Name -eq "ParameterValue" })[0]
    $ExtensionSettingsType = ($ProxyTypes | Where-Object { $_.Name -eq "ExtensionSettings" })[0]
    
    if ($null -eq $ParameterValueType) {
        throw "Could not find ParameterValue type in the web service proxy"
    }
    
    if ($null -eq $ExtensionSettingsType) {
        throw "Could not find ExtensionSettings type in the web service proxy"
    }
    
    #Write-DiagnosticMessage "Found ParameterValue type: $($ParameterValueType.FullName)"
    #Write-DiagnosticMessage "Found ExtensionSettings type: $($ExtensionSettingsType.FullName)"
    
    # Function to create a parameter value
    function New-TypedParameter {
        param (
            [string]$Name,
            [string]$Value
        )
        
        $param = New-Object $ParameterValueType
        $param.Name = $Name
        $param.Value = $Value
        return $param
    }
    
    # Create email parameters
    Write-InfoMessage "Setting email parameters..."
    $EmailParams = @()
    
    $EmailParams += New-TypedParameter -Name "TO" -Value "mthorn@guard1.com"
    $EmailParams += New-TypedParameter -Name "CC" -Value "test@guard1.com"
    $EmailParams += New-TypedParameter -Name "ReplyTo" -Value "support@guard1.com"
    $EmailParams += New-TypedParameter -Name "RenderFormat" -Value "WORDOPENXML"
    $EmailParams += New-TypedParameter -Name "Subject" -Value "Your Weekly Sales Report"
    $EmailParams += New-TypedParameter -Name "IncludeReport" -Value "true"
    $EmailParams += New-TypedParameter -Name "Priority" -Value "NORMAL"
    
    # Create extension settings
    Write-InfoMessage "Setting extension settings..."
    $ExtensionSettings = New-Object $ExtensionSettingsType
    $ExtensionSettings.Extension = "Report Server Email"
    $ExtensionSettings.ParameterValues = $EmailParams
    
    #Write-SuccessMessage "Saved extension settings successfully"
    
    # Create report parameters
    Write-InfoMessage "Setting report parameters..."
    $ReportParameters = @()
    $ReportParameters += New-TypedParameter -Name "ReportConfigurationId" -Value $ReportConfigId
    
    Write-SuccessMessage "Report parameters set successfully"
} catch {
    Write-ErrorMessage "Error setting report parameters: $_"
    exit 1
}

# Define the subscription schedule
$ScheduleXML = @"
<ScheduleDefinition>
    <StartDateTime>2025-03-06T08:00:00-05:00</StartDateTime>
    <WeeklyRecurrence>
        <WeeksInterval>1</WeeksInterval>
        <DaysOfWeek>
            <Monday>true</Monday>
        </DaysOfWeek>
    </WeeklyRecurrence>
</ScheduleDefinition>
"@

# Create subscription
try {
    Write-InfoMessage "Creating subscription for report: $ReportPath"
    
    # Get all available methods for debugging
    #Write-DiagnosticMessage "Checking available methods on proxy..."
    $Methods = $ReportServerProxy | Get-Member -Type Method | Where-Object { $_.Name -eq "CreateSubscription" }
    
    if ($null -eq $Methods) {
        throw "CreateSubscription method not found on proxy"
    }
    
    #Write-DiagnosticMessage "Found CreateSubscription method with signature: $($Methods.Definition)"
    
    # Get parameter types and positions
    $MethodInfo = $ReportServerProxy.GetType().GetMethod("CreateSubscription")
    $ParameterInfos = $MethodInfo.GetParameters()
    
    #Write-DiagnosticMessage "CreateSubscription expects these parameters:"
    #foreach ($param in $ParameterInfos) {
    #    Write-DiagnosticMessage "  $($param.Position): $($param.Name) ($($param.ParameterType.FullName))"
    #}
    
    # Call the method with explicit type conversion
    #Write-InfoMessage "Calling CreateSubscription method..."
    
    # Convert arrays to typed arrays if needed
    if ($ReportParameters -is [System.Array] -and $ReportParameters.Count -gt 0) {
        $ElementType = $ReportParameters[0].GetType()
        $TypedArray = [System.Array]::CreateInstance($ElementType, $ReportParameters.Count)
        
        for ($i = 0; $i -lt $ReportParameters.Count; $i++) {
            $TypedArray[$i] = $ReportParameters[$i]
        }
        
        $ReportParameters = $TypedArray
    }
    
    $SubscriptionID = $ReportServerProxy.CreateSubscription(
        $ReportPath,
        $ExtensionSettings,
        $Description,
        "TimedSubscription",
        $ScheduleXML,
        $ReportParameters
    )
    
    Write-SuccessMessage "✅ Subscription Created Successfully!"
    Write-SuccessMessage "Subscription ID: $SubscriptionID"
} catch {
    Write-ErrorMessage "❌ Error: Failed to create SSRS subscription."
    
    # Try to extract error details
    Write-ErrorMessage "Exception Message: $($_.Exception.Message)"
    Write-DiagnosticMessage "Exception Type: $($_.Exception.GetType().FullName)"
    
    if ($_.Exception.InnerException) {
        Write-DiagnosticMessage "Inner Exception: $($_.Exception.InnerException.Message)"
    }
    
    # Try to fix type incompatibility issues by dynamically invoking the method
    Write-InfoMessage "Attempting to fix type incompatibility issues..."
    
    try {
        # Get the method info
        $MethodInfo = $ReportServerProxy.GetType().GetMethod("CreateSubscription")
        
        # Invoke the method
        Write-DiagnosticMessage "Dynamically invoking CreateSubscription method..."
        $Result = $MethodInfo.Invoke($ReportServerProxy, @(
            $ReportPath,
            $ExtensionSettings,
            $Description,
            "TimedSubscription",
            $ScheduleXML,
            $ReportParameters
        ))
        
        Write-SuccessMessage "✅ Subscription Created Successfully via dynamic invocation!"
        Write-SuccessMessage "Subscription ID: $Result"
    } catch {
        Write-ErrorMessage "Dynamic invocation approach also failed."
        Write-DiagnosticMessage "Exception: $_"
    }
}
