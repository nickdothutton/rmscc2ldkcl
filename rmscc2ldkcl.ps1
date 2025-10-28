<#
.SYNOPSIS
    RMS-CloudConnected to LDK-CL Entitlement Migration Tool

.DESCRIPTION
    This tool assists in the migration of entitlements from RMS-CloudConnected
    products to LDK-CL products within the Thales Sentinel Entitlement Management
    System (EMS). It utilizes the standard REST APIs provided by Sentinel EMS.

    The script can run in two modes:
    - Interactive Mode: Prompts user for all required parameters
    - Batch Mode: Accepts all parameters via command-line arguments

.PARAMETER EmsUrl
    The base URL of the Sentinel EMS instance

.PARAMETER Username
    Username for basic authentication with Sentinel EMS

.PARAMETER Password
    Password for basic authentication with Sentinel EMS

.PARAMETER BatchCode
    The batch code to identify the migration batch

.PARAMETER CustomerId
    The customer ID for the migration

.PARAMETER Mode
    Migration mode: 'staging' or 'complete'

.PARAMETER Interactive
    Run in interactive mode, prompting for all parameters

.EXAMPLE
    .\rmscc2ldkcl.ps1 -Interactive

.EXAMPLE
    .\rmscc2ldkcl.ps1 -EmsUrl "https://ems.example.com" -Username "admin" -Password "pass123" -BatchCode "BATCH001" -CustomerId "CUST123" -Mode "staging"

.NOTES
    Version:        2.0.0
    Author:
    Creation Date:  2025-10-28
    Purpose:        Entitlement migration from RMS-CC to LDK-CL
#>

[CmdletBinding(DefaultParameterSetName = 'Batch')]
param(
    [Parameter(ParameterSetName = 'Interactive', Mandatory = $false)]
    [switch]$Interactive,

    [Parameter(ParameterSetName = 'Batch', Mandatory = $true)]
    [string]$EmsUrl,

    [Parameter(ParameterSetName = 'Batch', Mandatory = $true)]
    [string]$Username,

    [Parameter(ParameterSetName = 'Batch', Mandatory = $true)]
    [string]$Password,

    [Parameter(ParameterSetName = 'Batch', Mandatory = $true)]
    [string]$BatchCode,

    [Parameter(ParameterSetName = 'Batch', Mandatory = $true)]
    [string]$CustomerId,

    [Parameter(ParameterSetName = 'Batch', Mandatory = $true)]
    [ValidateSet('staging', 'complete')]
    [string]$Mode,

    [Parameter(Mandatory = $false)]
    [string]$LogFile = "rmscc2ldkcl_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Script-level variables
$script:EmsUrl = $null
$script:Username = $null
$script:Password = $null
$script:BatchCode = $null
$script:CustomerId = $null
$script:Mode = $null
$script:ApiHeaders = $null
$script:Entitlements = $null

#region Interactive Mode Functions

function Get-InteractiveInput {
    <#
    .SYNOPSIS
        Prompts user for all required parameters in interactive mode
    #>

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  RMS-CC to LDK-CL Migration Tool" -ForegroundColor Cyan
    Write-Host "  Interactive Mode" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # EMS URL
    do {
        $script:EmsUrl = Read-Host "Enter Sentinel EMS URL (e.g., https://ems.example.com)"
        if ([string]::IsNullOrWhiteSpace($script:EmsUrl)) {
            Write-Host "EMS URL is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:EmsUrl))

    # Username
    do {
        $script:Username = Read-Host "Enter Username for EMS authentication"
        if ([string]::IsNullOrWhiteSpace($script:Username)) {
            Write-Host "Username is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:Username))

    # Password (secure input)
    do {
        $securePassword = Read-Host "Enter Password for EMS authentication" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $script:Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        if ([string]::IsNullOrWhiteSpace($script:Password)) {
            Write-Host "Password is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:Password))

    # Batch Code
    do {
        $script:BatchCode = Read-Host "Enter Batch Code"
        if ([string]::IsNullOrWhiteSpace($script:BatchCode)) {
            Write-Host "Batch Code is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:BatchCode))

    # Customer ID
    do {
        $script:CustomerId = Read-Host "Enter Customer ID"
        if ([string]::IsNullOrWhiteSpace($script:CustomerId)) {
            Write-Host "Customer ID is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:CustomerId))

    # Mode
    do {
        Write-Host ""
        Write-Host "Select Migration Mode:" -ForegroundColor Yellow
        Write-Host "  1. staging" -ForegroundColor White
        Write-Host "  2. complete" -ForegroundColor White
        $modeChoice = Read-Host "Enter choice (1 or 2)"

        switch ($modeChoice) {
            "1" { $script:Mode = "staging" }
            "2" { $script:Mode = "complete" }
            default {
                Write-Host "Invalid choice. Please enter 1 or 2." -ForegroundColor Red
                $script:Mode = $null
            }
        }
    } while ([string]::IsNullOrWhiteSpace($script:Mode))

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Configuration Summary:" -ForegroundColor Green
    Write-Host "  EMS URL     : $($script:EmsUrl)" -ForegroundColor White
    Write-Host "  Username    : $($script:Username)" -ForegroundColor White
    Write-Host "  Password    : ********" -ForegroundColor White
    Write-Host "  Batch Code  : $($script:BatchCode)" -ForegroundColor White
    Write-Host "  Customer ID : $($script:CustomerId)" -ForegroundColor White
    Write-Host "  Mode        : $($script:Mode)" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Confirmation
    do {
        $confirm = Read-Host "Proceed with these settings? (Y/N)"
        if ($confirm -eq 'Y' -or $confirm -eq 'y') {
            return $true
        }
        elseif ($confirm -eq 'N' -or $confirm -eq 'n') {
            Write-Host "Operation cancelled by user." -ForegroundColor Yellow
            return $false
        }
        else {
            Write-Host "Please enter Y or N." -ForegroundColor Red
        }
    } while ($true)
}

function Initialize-Parameters {
    <#
    .SYNOPSIS
        Initializes parameters based on execution mode (Interactive or Batch)
    #>

    if ($Interactive) {
        # Interactive mode - prompt user
        $proceed = Get-InteractiveInput
        if (-not $proceed) {
            Write-Host "Exiting script." -ForegroundColor Yellow
            exit 0
        }
    }
    else {
        # Batch mode - use command-line parameters
        $script:EmsUrl = $EmsUrl
        $script:Username = $Username
        $script:Password = $Password
        $script:BatchCode = $BatchCode
        $script:CustomerId = $CustomerId
        $script:Mode = $Mode
    }

    # Create Basic Auth header
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $script:Username, $script:Password)))
    $script:ApiHeaders = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type"  = "application/json"
        "Accept"        = "application/json"
    }
}

#endregion

#region Logging Functions

function Write-Log {
    <#
    .SYNOPSIS
        Writes messages to both console and log file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to log file
    Add-Content -Path $LogFile -Value $logMessage

    # Write to console with color
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor White }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

#endregion

#region API Helper Functions

function Invoke-EmsApiRequest {
    <#
    .SYNOPSIS
        Makes REST API requests to Sentinel EMS
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $false)]
        [object]$Body
    )

    try {
        $uri = "$($script:EmsUrl)$Endpoint"
        Write-Log "Making $Method request to: $uri" -Level Info

        $params = @{
            Uri     = $uri
            Method  = $Method
            Headers = $script:ApiHeaders
        }

        if ($Body) {
            $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
        }

        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        Write-Log "API request failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Get-EmsEntitlements {
    <#
    .SYNOPSIS
        Retrieves entitlements for a specific customer from Sentinel EMS
    .DESCRIPTION
        Calls the Search Entitlements REST API endpoint (GET /ems/api/v5/entitlements)
        with the customerId as a query parameter
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CustomerId
    )

    Write-Log "Fetching entitlements for customer: $CustomerId" -Level Info

    try {
        $endpoint = "/ems/api/v5/entitlements?customerId=$CustomerId"
        $entitlements = Invoke-EmsApiRequest -Endpoint $endpoint -Method GET

        if ($entitlements) {
            $count = 0
            if ($entitlements -is [array]) {
                $count = $entitlements.Count
            }
            elseif ($entitlements.items) {
                $count = $entitlements.items.Count
            }
            elseif ($entitlements.entitlements) {
                $count = $entitlements.entitlements.Count
            }
            else {
                $count = 1
            }

            Write-Log "Retrieved $count entitlement(s)" -Level Success
        }
        else {
            Write-Log "No entitlements found for customer: $CustomerId" -Level Warning
        }

        return $entitlements
    }
    catch {
        Write-Log "Failed to retrieve entitlements: $($_.Exception.Message)" -Level Error
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Log "HTTP Status Code: $statusCode" -Level Error
        }
        return $null
    }
}

#endregion

#region Main Functions

function Initialize-Migration {
    <#
    .SYNOPSIS
        Validates prerequisites and initializes the migration process
    #>

    Write-Log "=== RMS-CC to LDK-CL Migration Tool ===" -Level Info
    Write-Log "EMS URL     : $($script:EmsUrl)" -Level Info
    Write-Log "Username    : $($script:Username)" -Level Info
    Write-Log "Batch Code  : $($script:BatchCode)" -Level Info
    Write-Log "Customer ID : $($script:CustomerId)" -Level Info
    Write-Log "Mode        : $($script:Mode)" -Level Info
    Write-Log ""

    # Test API connectivity
    Write-Log "Testing EMS connectivity..." -Level Info

    try {
        $testEndpoint = "/api/health"
        Invoke-EmsApiRequest -Endpoint $testEndpoint -Method GET
        Write-Log "EMS connection successful" -Level Success
    }
    catch {
        Write-Log "Failed to connect to EMS: $($_.Exception.Message)" -Level Error
        Write-Log "Note: If /api/health endpoint doesn't exist, this is not critical" -Level Warning
        # Continue execution - the health endpoint may not exist in all EMS versions
    }

    Write-Log ""

    # Retrieve entitlements for the customer
    Write-Log "Retrieving entitlements for customer: $($script:CustomerId)" -Level Info
    $script:Entitlements = Get-EmsEntitlements -CustomerId $script:CustomerId

    if ($null -eq $script:Entitlements) {
        Write-Log "Failed to retrieve entitlements. Cannot proceed." -Level Error
        return $false
    }

    Write-Log ""
    return $true
}

function Start-StagingMode {
    <#
    .SYNOPSIS
        Executes staging mode operations
    #>

    Write-Log "=== Starting STAGING Mode ===" -Level Info
    Write-Log "Batch Code: $($script:BatchCode)" -Level Info
    Write-Log "Customer ID: $($script:CustomerId)" -Level Info

    # Entitlements are available in $script:Entitlements
    if ($script:Entitlements) {
        Write-Log "Processing entitlements data..." -Level Info
        # TODO: Implement staging mode logic here
        # The entitlements data is available in $script:Entitlements
        Write-Log "Staging mode functionality to be implemented" -Level Warning
    }
    else {
        Write-Log "No entitlements data available" -Level Error
        return
    }

    Write-Log "=== STAGING Mode Complete ===" -Level Info
}

function Start-CompleteMode {
    <#
    .SYNOPSIS
        Executes complete mode operations
    #>

    Write-Log "=== Starting COMPLETE Mode ===" -Level Info
    Write-Log "Batch Code: $($script:BatchCode)" -Level Info
    Write-Log "Customer ID: $($script:CustomerId)" -Level Info

    # Entitlements are available in $script:Entitlements
    if ($script:Entitlements) {
        Write-Log "Processing entitlements data..." -Level Info
        # TODO: Implement complete mode logic here
        # The entitlements data is available in $script:Entitlements
        Write-Log "Complete mode functionality to be implemented" -Level Warning
    }
    else {
        Write-Log "No entitlements data available" -Level Error
        return
    }

    Write-Log "=== COMPLETE Mode Complete ===" -Level Info
}

function Start-Migration {
    <#
    .SYNOPSIS
        Executes the entitlement migration process based on selected mode
    #>

    switch ($script:Mode) {
        'staging' {
            Start-StagingMode
        }
        'complete' {
            Start-CompleteMode
        }
        default {
            Write-Log "Invalid mode: $($script:Mode)" -Level Error
            return
        }
    }
}

#endregion

#region Main Execution

try {
    # Initialize parameters (Interactive or Batch mode)
    Initialize-Parameters

    # Initialize and validate migration
    if (Initialize-Migration) {
        # Execute migration
        Start-Migration
    }
    else {
        Write-Log "Migration initialization failed" -Level Error
        exit 1
    }
}
catch {
    Write-Log "Unexpected error occurred: $($_.Exception.Message)" -Level Error
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
finally {
    Write-Log "Log file saved to: $LogFile" -Level Info
}

#endregion
