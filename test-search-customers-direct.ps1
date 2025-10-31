<#
.SYNOPSIS
    Test script for Sentinel EMS Search Customers API (Direct Parameters)

.DESCRIPTION
    This script tests the Search Customers endpoint with command-line parameters.

.PARAMETER BaseUrl
    The base URL of the Sentinel EMS instance

.PARAMETER Username
    Username for authentication

.PARAMETER Password
    Password for authentication

.PARAMETER CustomerId
    The customer ID to search for

.EXAMPLE
    .\test-search-customers-direct.ps1 -BaseUrl "https://ems.example.com" -Username "admin" -Password "pass123" -CustomerId "CUST123"

.NOTES
    Version:        1.0.0
    Creation Date:  2025-10-31
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
    Write-Host "  EMS Search Customers API Test" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Show configuration
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  Base URL: $BaseUrl"
    Write-Host "  Username: $Username"
    Write-Host "  Password: $('*' * $Password.Length)"
    Write-Host "  Customer ID: $CustomerId"
    Write-Host ""

    # Create Basic Auth credentials
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

    # Construct the API URL
    $apiUrl = "$BaseUrl/ems/api/v5/customers?id=$CustomerId"

    Write-Log "Calling Search Customers API..." "INFO"
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
    if ($response.customers) {
        $count = if ($response.customers.count) { $response.customers.count } else { 0 }
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  Total customers found: $count"

        if ($count -gt 0 -and $response.customers.customer) {
            $customers = if ($response.customers.customer -is [array]) {
                $response.customers.customer
            } else {
                @($response.customers.customer)
            }

            Write-Host ""
            Write-Host "Customer Details:" -ForegroundColor Cyan
            foreach ($customer in $customers) {
                Write-Host "  - ID: $($customer.id)"
                Write-Host "    Name: $($customer.name)"
                Write-Host "    Identifier: $($customer.identifier)"
                Write-Host "    State: $($customer.state)"
                if ($customer.marketGroup) {
                    Write-Host "    Market Group: $($customer.marketGroup.name)"
                }
                Write-Host ""
            }
        }
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
    }

    exit 1
}
