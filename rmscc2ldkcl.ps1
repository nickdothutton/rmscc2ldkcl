<#
.SYNOPSIS
    RMS-CloudConnected to LDK-CL Entitlement Migration Tool

.DESCRIPTION
    This tool assists in the migration of entitlements from RMS-CloudConnected
    products to LDK-CL products within the Thales Sentinel Entitlement Management
    System (EMS). It utilizes the standard REST APIs provided by Sentinel EMS.

.PARAMETER EmsUrl
    The base URL of the Sentinel EMS instance

.PARAMETER ApiKey
    API Key for authenticating with Sentinel EMS

.PARAMETER SourceProductId
    The RMS-CloudConnected product ID to migrate from

.PARAMETER TargetProductId
    The LDK-CL product ID to migrate to

.PARAMETER DryRun
    Performs a dry run without making actual changes

.EXAMPLE
    .\rmscc2ldkcl.ps1 -EmsUrl "https://ems.example.com" -ApiKey "your-api-key" -SourceProductId "RMS-123" -TargetProductId "LDK-456"

.NOTES
    Version:        1.0.0
    Author:
    Creation Date:  2025-10-28
    Purpose:        Entitlement migration from RMS-CC to LDK-CL
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EmsUrl,

    [Parameter(Mandatory = $true)]
    [string]$ApiKey,

    [Parameter(Mandatory = $false)]
    [string]$SourceProductId,

    [Parameter(Mandatory = $false)]
    [string]$TargetProductId,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [string]$LogFile = "rmscc2ldkcl_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Global variables
$script:ApiHeaders = @{
    "Authorization" = "Bearer $ApiKey"
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
}

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
        $uri = "$EmsUrl$Endpoint"
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
        Retrieves entitlements for a specific product
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProductId
    )

    Write-Log "Fetching entitlements for product: $ProductId" -Level Info

    try {
        $endpoint = "/api/entitlements?productId=$ProductId"
        $entitlements = Invoke-EmsApiRequest -Endpoint $endpoint -Method GET

        Write-Log "Retrieved $($entitlements.Count) entitlements" -Level Success
        return $entitlements
    }
    catch {
        Write-Log "Failed to retrieve entitlements: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Copy-Entitlement {
    <#
    .SYNOPSIS
        Copies an entitlement from source to target product
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$SourceEntitlement,

        [Parameter(Mandatory = $true)]
        [string]$TargetProductId
    )

    Write-Log "Migrating entitlement: $($SourceEntitlement.id)" -Level Info

    if ($DryRun) {
        Write-Log "[DRY RUN] Would migrate entitlement $($SourceEntitlement.id) to product $TargetProductId" -Level Warning
        return $true
    }

    try {
        # Create new entitlement object for target product
        $newEntitlement = @{
            productId   = $TargetProductId
            customerId  = $SourceEntitlement.customerId
            features    = $SourceEntitlement.features
            # Add other relevant properties
        }

        $endpoint = "/api/entitlements"
        $result = Invoke-EmsApiRequest -Endpoint $endpoint -Method POST -Body $newEntitlement

        Write-Log "Successfully migrated entitlement: $($SourceEntitlement.id)" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to migrate entitlement $($SourceEntitlement.id): $($_.Exception.Message)" -Level Error
        return $false
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
    Write-Log "EMS URL: $EmsUrl" -Level Info
    Write-Log "Dry Run: $DryRun" -Level Info

    # Test API connectivity
    Write-Log "Testing EMS connectivity..." -Level Info

    try {
        $testEndpoint = "/api/health"
        Invoke-EmsApiRequest -Endpoint $testEndpoint -Method GET
        Write-Log "EMS connection successful" -Level Success
    }
    catch {
        Write-Log "Failed to connect to EMS: $($_.Exception.Message)" -Level Error
        return $false
    }

    return $true
}

function Start-Migration {
    <#
    .SYNOPSIS
        Executes the entitlement migration process
    #>

    # Validate parameters
    if (-not $SourceProductId -or -not $TargetProductId) {
        Write-Log "Source and Target Product IDs are required for migration" -Level Error
        return
    }

    # Get source entitlements
    $sourceEntitlements = Get-EmsEntitlements -ProductId $SourceProductId

    if (-not $sourceEntitlements -or $sourceEntitlements.Count -eq 0) {
        Write-Log "No entitlements found for source product: $SourceProductId" -Level Warning
        return
    }

    # Initialize counters
    $totalCount = $sourceEntitlements.Count
    $successCount = 0
    $failureCount = 0

    Write-Log "Starting migration of $totalCount entitlements..." -Level Info

    # Process each entitlement
    foreach ($entitlement in $sourceEntitlements) {
        $result = Copy-Entitlement -SourceEntitlement $entitlement -TargetProductId $TargetProductId

        if ($result) {
            $successCount++
        }
        else {
            $failureCount++
        }
    }

    # Summary
    Write-Log "=== Migration Complete ===" -Level Info
    Write-Log "Total: $totalCount | Success: $successCount | Failed: $failureCount" -Level Info
}

#endregion

#region Main Execution

try {
    # Initialize
    if (Initialize-Migration) {
        # Execute migration if product IDs are provided
        if ($SourceProductId -and $TargetProductId) {
            Start-Migration
        }
        else {
            Write-Log "No migration parameters provided. Use -SourceProductId and -TargetProductId to start migration." -Level Warning
        }
    }
}
catch {
    Write-Log "Unexpected error occurred: $($_.Exception.Message)" -Level Error
    exit 1
}
finally {
    Write-Log "Log file saved to: $LogFile" -Level Info
}

#endregion
