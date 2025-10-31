<#
.SYNOPSIS
    Test script for Sentinel EMS Search Entitlements API (Direct Parameters)

.DESCRIPTION
    This script tests the Search Entitlements endpoint with command-line parameters.
    Retrieves all entitlements for a specific customer ID.

.PARAMETER BaseUrl
    The base URL of the Sentinel EMS instance

.PARAMETER Username
    Username for authentication

.PARAMETER Password
    Password for authentication

.PARAMETER CustomerId
    The customer ID to search entitlements for

.EXAMPLE
    .\test-search-entitlements-direct.ps1 -BaseUrl "https://ems.example.com" -Username "admin" -Password "pass123" -CustomerId "CUST123"

.NOTES
    Version:        1.0.0
    Creation Date:  2025-10-31
    Reference:      .claude/skills/ems-api/skill.md - Section 1. Search Entitlements
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$BaseUrl,

    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Password,

    [Parameter(Mandatory=$true)]
    [string]$CustomerId
)

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO"    { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

try {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  EMS Search Entitlements API Test" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Show configuration
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  Base URL: $BaseUrl"
    Write-Host "  Username: $Username"
    Write-Host "  Password: $('*' * $Password.Length)"
    Write-Host "  Customer ID: $CustomerId"
    Write-Host ""

    # Create Basic Auth credentials per ems-api skill documentation
    Write-Log "Initializing API headers..." "INFO"
    $credentials = "$($Username):$($Password)"
    $credentialsBytes = [System.Text.Encoding]::UTF8.GetBytes($credentials)
    $credentialsBase64 = [System.Convert]::ToBase64String($credentialsBytes)

    # Set up headers
    $headers = @{
        "Authorization" = "Basic $credentialsBase64"
        "Content-Type"  = "application/json"
        "Accept"        = "application/json"
    }

    Write-Log "API headers initialized successfully" "SUCCESS"

    # Construct the API URL per ems-api skill documentation
    # Endpoint: GET /ems/api/v5/entitlements?customerId={customerId}
    $apiUrl = "$BaseUrl/ems/api/v5/entitlements?customerId=$CustomerId"

    Write-Log "Calling Search Entitlements API..." "INFO"
    Write-Log "URL: $apiUrl" "INFO"

    # Make the API call
    $response = Invoke-RestMethod -Uri $apiUrl `
                                   -Method Get `
                                   -Headers $headers `
                                   -ErrorAction Stop

    Write-Log "API call successful" "SUCCESS"

    # Display response
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  API Response" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Convert response to JSON with pretty formatting
    $jsonResponse = $response | ConvertTo-Json -Depth 10
    Write-Host $jsonResponse
    Write-Host ""

    # Show summary
    if ($response.entitlements) {
        $count = if ($response.entitlements.count) { $response.entitlements.count } else { 0 }
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  Total entitlements found: $count"

        if ($count -gt 0 -and $response.entitlements.entitlement) {
            $entitlements = if ($response.entitlements.entitlement -is [array]) {
                $response.entitlements.entitlement
            } else {
                @($response.entitlements.entitlement)
            }

            Write-Host ""
            Write-Host "Entitlement Details:" -ForegroundColor Cyan
            foreach ($entitlement in $entitlements) {
                Write-Host "  - ID: $($entitlement.id)"
                Write-Host "    EID: $($entitlement.eId)"
                Write-Host "    State: $($entitlement.state)"
                Write-Host "    Start Date: $($entitlement.startDate)"

                if ($entitlement.expiry) {
                    if ($entitlement.expiry.neverExpires -eq $true) {
                        Write-Host "    Expiry: Never Expires"
                    } else {
                        Write-Host "    End Date: $($entitlement.expiry.endDate)"
                    }
                }

                if ($entitlement.customer) {
                    Write-Host "    Customer: $($entitlement.customer.name) (ID: $($entitlement.customer.id))"
                }

                if ($entitlement.marketGroup) {
                    Write-Host "    Market Group: $($entitlement.marketGroup.name)"
                }

                # Show product keys count if available
                if ($entitlement.productKeys -and $entitlement.productKeys.productKey) {
                    $pkCount = if ($entitlement.productKeys.productKey -is [array]) {
                        $entitlement.productKeys.productKey.Count
                    } else {
                        1
                    }
                    Write-Host "    Product Keys: $pkCount"
                }

                Write-Host ""
            }
        }
    } else {
        Write-Host "No entitlements found for customer ID: $CustomerId" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Log "Test completed successfully" "SUCCESS"
    exit 0
}
catch {
    Write-Log "Test failed: $($_.Exception.Message)" "ERROR"

    # Try to extract error details
    if ($_.ErrorDetails.Message) {
        Write-Log "Error Details: $($_.ErrorDetails.Message)" "ERROR"
    }

    # Get status code if available
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        Write-Log "HTTP Status Code: $statusCode" "ERROR"

        # Provide helpful error messages per ems-api skill documentation
        switch ($statusCode) {
            400 { Write-Log "Bad Request: Invalid request parameters" "ERROR" }
            401 { Write-Log "Unauthorized: Authentication failed" "ERROR" }
            403 { Write-Log "Forbidden: Insufficient permissions" "ERROR" }
            404 { Write-Log "Not Found: Resource not found" "ERROR" }
            500 { Write-Log "Internal Server Error: Server error" "ERROR" }
        }
    }

    exit 1
}
