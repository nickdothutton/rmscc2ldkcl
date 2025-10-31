<#
.SYNOPSIS
    Test script for Sentinel EMS Search Customers API

.DESCRIPTION
    This script tests the Search Customers endpoint of the Thales Sentinel EMS REST API.
    It prompts for connection parameters and displays the API response.

.EXAMPLE
    .\test-search-customers.ps1

.NOTES
    Version:        1.0.0
    Author:
    Creation Date:  2025-10-31
    Purpose:        Test EMS Search Customers API endpoint
#>

[CmdletBinding()]
param()

#region Functions

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

function Get-UserInput {
    <#
    .SYNOPSIS
        Prompts user for all required parameters
    #>

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  EMS Search Customers API Test" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # EMS Base URL
    do {
        $script:EmsBaseUrl = Read-Host "Enter Sentinel EMS Base URL (e.g., https://ems.example.com)"
        if ([string]::IsNullOrWhiteSpace($script:EmsBaseUrl)) {
            Write-Host "EMS Base URL is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:EmsBaseUrl))

    # Username
    do {
        $script:Username = Read-Host "Enter Username"
        if ([string]::IsNullOrWhiteSpace($script:Username)) {
            Write-Host "Username is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:Username))

    # Password (secure input)
    do {
        $securePassword = Read-Host "Enter Password" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $script:Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        if ([string]::IsNullOrWhiteSpace($script:Password)) {
            Write-Host "Password is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:Password))

    # Customer ID
    do {
        $script:CustomerId = Read-Host "Enter Customer ID"
        if ([string]::IsNullOrWhiteSpace($script:CustomerId)) {
            Write-Host "Customer ID is required. Please try again." -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($script:CustomerId))

    Write-Host ""
}

function Show-Configuration {
    <#
    .SYNOPSIS
        Display configuration summary
    #>

    Write-Host "Configuration Summary:" -ForegroundColor Cyan
    Write-Host "  EMS Base URL: $script:EmsBaseUrl"
    Write-Host "  Username: $script:Username"
    Write-Host "  Password: $('*' * $script:Password.Length)"
    Write-Host "  Customer ID: $script:CustomerId"
    Write-Host ""
}

function Initialize-ApiHeaders {
    <#
    .SYNOPSIS
        Initialize API headers with Basic Authentication
    #>

    try {
        Write-Log "Initializing API headers..." "INFO"

        # Create Basic Auth credentials
        $credentials = "$($script:Username):$($script:Password)"
        $credentialsBytes = [System.Text.Encoding]::UTF8.GetBytes($credentials)
        $credentialsBase64 = [System.Convert]::ToBase64String($credentialsBytes)

        # Set up headers
        $script:ApiHeaders = @{
            "Authorization" = "Basic $credentialsBase64"
            "Content-Type"  = "application/json"
            "Accept"        = "application/json"
        }

        Write-Log "API headers initialized successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to initialize API headers: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-SearchCustomers {
    <#
    .SYNOPSIS
        Call the Search Customers API endpoint
    #>

    try {
        # Construct the API URL
        $apiUrl = "$script:EmsBaseUrl/ems/api/v5/customers"

        # Add query parameter for customer ID
        $apiUrl += "?id=$script:CustomerId"

        Write-Log "Calling Search Customers API..." "INFO"
        Write-Log "URL: $apiUrl" "INFO"

        # Make the API call
        $response = Invoke-RestMethod -Uri $apiUrl `
                                       -Method Get `
                                       -Headers $script:ApiHeaders `
                                       -ErrorAction Stop

        Write-Log "API call successful" "SUCCESS"

        return $response
    }
    catch {
        Write-Log "API call failed: $($_.Exception.Message)" "ERROR"

        # Try to extract error details from response
        if ($_.ErrorDetails.Message) {
            Write-Log "Error Details: $($_.ErrorDetails.Message)" "ERROR"
        }

        # Get status code if available
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Log "HTTP Status Code: $statusCode" "ERROR"
        }

        throw
    }
}

function Show-Response {
    <#
    .SYNOPSIS
        Display the API response in a formatted way
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Response
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  API Response" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Convert response to JSON with pretty formatting
    $jsonResponse = $Response | ConvertTo-Json -Depth 10

    Write-Host $jsonResponse
    Write-Host ""

    # Show summary information
    if ($Response.customers) {
        $count = if ($Response.customers.count) { $Response.customers.count } else { 0 }
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  Total customers found: $count"

        if ($count -gt 0 -and $Response.customers.customer) {
            $customers = if ($Response.customers.customer -is [array]) {
                $Response.customers.customer
            } else {
                @($Response.customers.customer)
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
}

#endregion

#region Main Script

try {
    # Get user input
    Get-UserInput

    # Show configuration
    Show-Configuration

    # Confirm before proceeding
    $confirmation = Read-Host "Proceed with API call? (Y/N)"
    if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
        Write-Log "Operation cancelled by user" "WARNING"
        exit 0
    }

    Write-Host ""

    # Initialize API headers
    Initialize-ApiHeaders

    # Call the API
    $response = Invoke-SearchCustomers

    # Display the response
    Show-Response -Response $response

    Write-Log "Test completed successfully" "SUCCESS"
    exit 0
}
catch {
    Write-Log "Test failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

#endregion
