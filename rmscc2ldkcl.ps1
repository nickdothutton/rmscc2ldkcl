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

# Script-level variables (initialized in Initialize-Parameters function)
# Note: Do NOT initialize string variables here as it interferes with parameter values
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
            "1" { $script:MigrationMode = "staging" }
            "2" { $script:MigrationMode = "complete" }
            default {
                Write-Host "Invalid choice. Please enter 1 or 2." -ForegroundColor Red
                $script:MigrationMode = ""
            }
        }
    } while ([string]::IsNullOrWhiteSpace($script:MigrationMode))

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Configuration Summary:" -ForegroundColor Green
    Write-Host "  EMS URL     : $($script:EmsUrl)" -ForegroundColor White
    Write-Host "  Username    : $($script:Username)" -ForegroundColor White
    Write-Host "  Password    : ********" -ForegroundColor White
    Write-Host "  Batch Code  : $($script:BatchCode)" -ForegroundColor White
    Write-Host "  Customer ID : $($script:CustomerId)" -ForegroundColor White
    Write-Host "  Mode        : $($script:MigrationMode)" -ForegroundColor White
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
        $script:MigrationMode = $Mode
    }

    # Create Basic Auth header using UTF8 encoding (verified working pattern)
    $credentials = "$($script:Username):$($script:Password)"
    $credentialsBytes = [System.Text.Encoding]::UTF8.GetBytes($credentials)
    $base64AuthInfo = [System.Convert]::ToBase64String($credentialsBytes)

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
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Message = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    # Handle empty messages (for blank lines)
    if ([string]::IsNullOrEmpty($Message)) {
        # Write blank line to log file
        Add-Content -Path $LogFile -Value ""
        # Write blank line to console
        Write-Host ""
        return
    }

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

function Get-EmsCustomer {
    <#
    .SYNOPSIS
        Retrieves customer details from Sentinel EMS
    .DESCRIPTION
        Calls the Search Customers REST API endpoint (GET /ems/api/v5/customers)
        with the customer ID as a query parameter.

        Response format (verified from API):
        {
            "customers": {
                "count": N,
                "customer": [ ... ]
            }
        }
    .REFERENCE
        .claude/skills/ems-api/skill.md - Section 4. Search Customers
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CustomerId
    )

    Write-Log "Fetching customer details for: $CustomerId" -Level Info

    try {
        # Construct endpoint URL per ems-api skill documentation
        $endpoint = "/ems/api/v5/customers?id=$CustomerId"
        $response = Invoke-EmsApiRequest -Endpoint $endpoint -Method GET

        if ($response -and $response.customers -and $response.customers.customer) {
            $customer = if ($response.customers.customer -is [array]) {
                $response.customers.customer[0]
            } else {
                $response.customers.customer
            }

            Write-Log "Customer found: $($customer.name) (ID: $($customer.id))" -Level Success
            Write-Log "  State: $($customer.state), Market Group: $($customer.marketGroup.name)" -Level Info

            return $customer
        }
        else {
            Write-Log "Customer not found: $CustomerId" -Level Warning
            return $null
        }
    }
    catch {
        Write-Log "Failed to retrieve customer: $($_.Exception.Message)" -Level Error
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Log "HTTP Status Code: $statusCode" -Level Error
        }
        return $null
    }
}

function Get-EmsEntitlements {
    <#
    .SYNOPSIS
        Retrieves entitlements for a specific customer from Sentinel EMS
    .DESCRIPTION
        Calls the Search Entitlements REST API endpoint (GET /ems/api/v5/entitlements)
        with the customerId as a query parameter.

        Response format (verified from API):
        {
            "entitlements": {
                "count": N,
                "entitlement": [ ... ]
            }
        }
    .REFERENCE
        .claude/skills/ems-api/skill.md - Section 1. Search Entitlements
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CustomerId
    )

    Write-Log "Fetching entitlements for customer: $CustomerId" -Level Info

    try {
        # Construct endpoint URL per ems-api skill documentation
        $endpoint = "/ems/api/v5/entitlements?customerId=$CustomerId"
        $response = Invoke-EmsApiRequest -Endpoint $endpoint -Method GET

        if ($response -and $response.entitlements) {
            # Extract count from response structure
            $count = if ($response.entitlements.count) { $response.entitlements.count } else { 0 }

            if ($count -gt 0) {
                Write-Log "Retrieved $count entitlement(s)" -Level Success

                # Log summary of entitlements found
                if ($response.entitlements.entitlement) {
                    $entitlements = if ($response.entitlements.entitlement -is [array]) {
                        $response.entitlements.entitlement
                    } else {
                        @($response.entitlements.entitlement)
                    }

                    foreach ($ent in $entitlements) {
                        Write-Log "  - Entitlement ID: $($ent.id), EID: $($ent.eId), State: $($ent.state)" -Level Info
                    }
                }
            }
            else {
                Write-Log "No entitlements found for customer: $CustomerId" -Level Warning
            }
        }
        else {
            Write-Log "No entitlements found for customer: $CustomerId" -Level Warning
        }

        return $response
    }
    catch {
        Write-Log "Failed to retrieve entitlements: $($_.Exception.Message)" -Level Error
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Log "HTTP Status Code: $statusCode" -Level Error

            # Provide helpful error messages per ems-api skill documentation
            switch ($statusCode) {
                400 { Write-Log "Bad Request: Invalid request parameters" -Level Error }
                401 { Write-Log "Unauthorized: Authentication failed" -Level Error }
                403 { Write-Log "Forbidden: Insufficient permissions" -Level Error }
                404 { Write-Log "Not Found: Resource not found" -Level Error }
                500 { Write-Log "Internal Server Error: Server error" -Level Error }
            }
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
    Write-Log "Version     : 2.0.0" -Level Info
    Write-Log "EMS URL     : $($script:EmsUrl)" -Level Info
    Write-Log "Username    : $($script:Username)" -Level Info
    Write-Log "Batch Code  : $($script:BatchCode)" -Level Info
    Write-Log "Customer ID : $($script:CustomerId)" -Level Info
    Write-Log "Mode        : $($script:MigrationMode)" -Level Info
    Write-Log "" -Level Info

    # Test API connectivity (optional - endpoint may not exist in all EMS versions)
    Write-Log "Testing EMS connectivity..." -Level Info

    try {
        $testEndpoint = "/api/health"
        Invoke-EmsApiRequest -Endpoint $testEndpoint -Method GET
        Write-Log "EMS health check successful" -Level Success
    }
    catch {
        Write-Log "Health check endpoint not available (this is normal for some EMS versions)" -Level Warning
        # Continue execution - the health endpoint may not exist in all EMS versions
    }

    # Validate customer exists
    Write-Log "" -Level Info
    Write-Log "Step 1: Validating customer..." -Level Info
    $customer = Get-EmsCustomer -CustomerId $script:CustomerId

    if ($null -eq $customer) {
        Write-Log "Customer validation failed. Cannot proceed." -Level Error
        return $false
    }

    if ($customer.state -ne "ENABLE") {
        Write-Log "Warning: Customer state is '$($customer.state)' (not ENABLE)" -Level Warning
    }

    # Retrieve entitlements for the customer
    Write-Log "" -Level Info
    Write-Log "Step 2: Retrieving entitlements..." -Level Info
    $script:Entitlements = Get-EmsEntitlements -CustomerId $script:CustomerId

    if ($null -eq $script:Entitlements) {
        Write-Log "Failed to retrieve entitlements. Cannot proceed." -Level Error
        return $false
    }

    # Check if any entitlements were found
    $entitlementCount = if ($script:Entitlements.entitlements.count) {
        $script:Entitlements.entitlements.count
    } else {
        0
    }

    if ($entitlementCount -eq 0) {
        Write-Log "No entitlements found for customer. Nothing to migrate." -Level Warning
        return $false
    }

    Write-Log "" -Level Info
    Write-Log "Initialization complete - Ready to proceed with migration" -Level Success
    Write-Log "" -Level Info

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

    switch ($script:MigrationMode) {
        'staging' {
            Start-StagingMode
        }
        'complete' {
            Start-CompleteMode
        }
        default {
            Write-Log "Invalid mode: $($script:MigrationMode)" -Level Error
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
