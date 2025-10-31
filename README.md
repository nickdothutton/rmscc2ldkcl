# rmscc2ldkcl

RMS-CloudConnected to LDK-CL Entitlement Migration Tool for Thales Sentinel EMS

## Overview

`rmscc2ldkcl` is a PowerShell-based migration tool designed to assist in the migration of entitlements from RMS-CloudConnected products to LDK-CL products within the Thales Sentinel Entitlement Management System (EMS). The tool leverages the standard REST APIs provided by Sentinel EMS v5 to perform secure and reliable entitlement migrations.

## Features

- ✅ **Automated entitlement migration** from RMS-CC to LDK-CL products
- ✅ **RESTful API integration** with Sentinel EMS v5
- ✅ **Two execution modes**: Interactive and Batch
- ✅ **Two migration modes**: Staging and Complete
- ✅ **Customer validation** before migration
- ✅ **Entitlement retrieval** with detailed logging
- ✅ **Basic authentication** with Sentinel EMS (UTF-8 encoding)
- ✅ **Comprehensive logging** with timestamps and severity levels
- ✅ **Error handling** with HTTP status code reporting
- ✅ **Test scripts** for API validation
- ✅ **Claude Code skills** for AI-assisted development

## Project Structure

```
Project01/
├── rmscc2ldkcl.ps1                      # Main migration tool
├── README.md                             # This file
├── .claude/                              # Claude Code skill definitions
│   └── skills/
│       └── ems-api/                      # EMS API skill documentation
│           ├── skill.md                  # Main skill file
│           ├── openapi/                  # OpenAPI specifications
│           │   ├── default.yml           # Master OpenAPI spec
│           │   ├── entitlement.yaml      # Entitlement endpoints
│           │   ├── customer.yaml         # Customer endpoints
│           │   └── product.yaml          # Product endpoints
│           ├── examples/                 # Example API responses
│           │   ├── search-entitlements-response.json
│           │   ├── search-customers-response.json
│           │   └── search-entitlements-response-empty.json
│           └── docs/                     # Documentation (TBD)
├── test-search-customers.ps1             # Interactive customer search test
├── test-search-customers-direct.ps1      # Direct customer search test (✅ tested)
├── test-search-entitlements.ps1          # Interactive entitlement search test
├── test-search-entitlements-direct.ps1   # Direct entitlement search test (✅ tested)
├── test-search-customers-curl.sh         # Curl-based test script
└── run-test-customers.sh                 # Bash wrapper for PowerShell tests
```

## Prerequisites

- PowerShell 5.1 or later (PowerShell 7+ recommended)
- Access to Thales Sentinel EMS instance
- Valid username and password for Sentinel EMS (basic authentication)
- Appropriate permissions to read and create entitlements
- Batch Code and Customer ID for migration operations
- Network connectivity to EMS instance

## Installation

1. Clone this repository:
   ```powershell
   git clone https://github.com/nickdothutton/rmscc2ldkcl.git
   cd rmscc2ldkcl
   ```

2. Ensure you have the required PowerShell version:
   ```powershell
   $PSVersionTable.PSVersion
   ```

3. **PowerShell Execution Policy** (Windows/WSL):

   PowerShell may block unsigned scripts by default. You have several options:

   **Option A - Bypass for single execution** (Recommended for testing):
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\rmscc2ldkcl.ps1 -EmsUrl "..." -Username "..." ...
   ```

   **Option B - Set for current user** (Permanent change):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

   **Option C - Use the bash wrapper** (Automatically handles execution policy):
   ```bash
   ./run-test-customers.sh
   ```

   Note: The provided bash wrappers automatically use `-ExecutionPolicy Bypass`.

## Usage

The script can be run in two different execution modes:

### Interactive Mode

In interactive mode, the script prompts you for all required parameters. This is ideal for one-time executions or when you prefer a guided experience.

```powershell
.\rmscc2ldkcl.ps1 -Interactive
```

The script will prompt you for:
1. Sentinel EMS URL (e.g., https://ems.example.com)
2. Username
3. Password (secure input - characters hidden)
4. Batch Code
5. Customer ID (UUID format)
6. Migration Mode (staging or complete)

After entering all parameters, you'll see a summary and be asked to confirm before proceeding.

### Batch Mode

In batch mode, all parameters must be provided via command-line arguments. This is ideal for automation, scheduled tasks, or integration with other systems.

```powershell
.\rmscc2ldkcl.ps1 `
    -EmsUrl "https://ems.example.com" `
    -Username "your-username" `
    -Password "your-password" `
    -BatchCode "BATCH001" `
    -CustomerId "782e27a1-22f2-4501-a873-5569d3f78792" `
    -Mode "staging"
```

### Example (Tested Configuration)

```powershell
.\rmscc2ldkcl.ps1 `
    -EmsUrl "https://gtoclients.dev.sentinelcloud.com" `
    -Username "nhutton" `
    -Password "Test123!" `
    -BatchCode "TEST001" `
    -CustomerId "782e27a1-22f2-4501-a873-5569d3f78792" `
    -Mode "staging"
```

**Test Results** (2025-10-31):
- ✅ Customer validated: SMO_TEST
- ✅ Retrieved 1 entitlement successfully
- ✅ All API calls working correctly

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `Interactive` | No | Switch to run in interactive mode (prompts for all inputs) |
| `EmsUrl` | Yes* | The base URL of your Sentinel EMS instance (without trailing slash) |
| `Username` | Yes* | Username for basic authentication with Sentinel EMS |
| `Password` | Yes* | Password for basic authentication with Sentinel EMS |
| `BatchCode` | Yes* | The batch code to identify the migration batch |
| `CustomerId` | Yes* | The customer ID (UUID) for the migration |
| `Mode` | Yes* | Migration mode: 'staging' or 'complete' |
| `LogFile` | No | Path to log file (auto-generated: `rmscc2ldkcl_YYYYMMDD_HHmmss.log`) |

\* Required when not using `-Interactive` mode

### Migration Modes

#### Staging Mode
Use staging mode to prepare and validate the migration without making permanent changes.

```powershell
.\rmscc2ldkcl.ps1 `
    -EmsUrl "https://ems.example.com" `
    -Username "admin" `
    -Password "securepass123" `
    -BatchCode "BATCH001" `
    -CustomerId "782e27a1-22f2-4501-a873-5569d3f78792" `
    -Mode "staging"
```

**Status**: 🔄 In Development

#### Complete Mode
Use complete mode to execute the full migration process.

```powershell
.\rmscc2ldkcl.ps1 `
    -EmsUrl "https://ems.example.com" `
    -Username "admin" `
    -Password "securepass123" `
    -BatchCode "BATCH001" `
    -CustomerId "782e27a1-22f2-4501-a873-5569d3f78792" `
    -Mode "complete"
```

**Status**: 📋 Planned

## Testing

### Test Scripts

The project includes several test scripts to validate API connectivity:

1. **Test Search Customers** (✅ Verified Working)
   ```powershell
   .\test-search-customers-direct.ps1 `
       -BaseUrl "https://ems.example.com" `
       -Username "user" `
       -Password "pass" `
       -CustomerId "customer-uuid"
   ```

2. **Test Search Entitlements** (✅ Verified Working)
   ```powershell
   .\test-search-entitlements-direct.ps1 `
       -BaseUrl "https://ems.example.com" `
       -Username "user" `
       -Password "pass" `
       -CustomerId "customer-uuid"
   ```

3. **Bash Wrapper** (for Linux/WSL environments)
   ```bash
   ./run-test-customers.sh
   ```

### Verified Test Results (2025-10-31)

- ✅ Authentication with EMS API successful
- ✅ Customer retrieval working (SMO_TEST customer)
- ✅ Entitlement retrieval working (1 entitlement found)
- ✅ Error handling for 400, 401, 403, 404, 500 errors
- ✅ Logging to timestamped files

## Authentication

The tool uses HTTP Basic Authentication with the Sentinel EMS REST API:
- Credentials are UTF-8 encoded and base64-encoded
- All API calls use HTTPS
- Authentication headers are applied automatically to all requests
- Format: `Authorization: Basic {base64(username:password)}`

## API Endpoints

The tool interacts with the following EMS REST API v5 endpoints:

| Endpoint | Method | Purpose | Status |
|----------|--------|---------|--------|
| `/ems/api/v5/customers` | GET | Retrieve customer details | ✅ Implemented & Tested |
| `/ems/api/v5/entitlements` | GET | Search/retrieve entitlements | ✅ Implemented & Tested |
| `/ems/api/v5/products` | GET | Search products | 📋 Documented |
| `/ems/api/v5/entitlements` | POST | Create entitlement | 📋 Planned |
| `/ems/api/v5/entitlements/{id}` | PATCH | Update entitlement | 📋 Planned |

For detailed API documentation, see: `.claude/skills/ems-api/skill.md`

## Logging

The tool automatically creates detailed log files with timestamps for each execution:
- Default log location: `rmscc2ldkcl_YYYYMMDD_HHMMSS.log`
- Logs include timestamps, severity levels, and detailed operation information
- All API calls and results are logged for audit purposes

### Log Levels
- **Info**: General information and API requests
- **Success**: Successful operations
- **Warning**: Non-critical issues (e.g., health check endpoint not available)
- **Error**: Critical errors with stack traces and HTTP status codes

### Example Log Output

```
[2025-10-31 22:10:15] [Info] === RMS-CC to LDK-CL Migration Tool ===
[2025-10-31 22:10:15] [Info] Version     : 2.0.0
[2025-10-31 22:10:16] [Info] Step 1: Validating customer...
[2025-10-31 22:10:17] [Success] Customer found: SMO_TEST (ID: 782e27a1-22f2-4501-a873-5569d3f78792)
[2025-10-31 22:10:17] [Info]   State: ENABLE, Market Group: Saif_Cloud
[2025-10-31 22:10:17] [Info] Step 2: Retrieving entitlements...
[2025-10-31 22:10:17] [Success] Retrieved 1 entitlement(s)
[2025-10-31 22:10:17] [Info]   - Entitlement ID: 18b68037-8685-4556-84ba-a6bb14b562fe, EID: 345661ca-1c17-4e9f-a771-faea72080e50, State: ENABLE
[2025-10-31 22:10:17] [Success] Initialization complete - Ready to proceed with migration
```

## Security Considerations

- Store credentials securely (consider using environment variables or secure vaults)
- Never commit passwords or credentials to version control
- Use HTTPS for all EMS connections
- In batch mode, avoid hardcoding passwords in scripts - use secure parameter passing
- Review logs for sensitive information before sharing
- Test thoroughly in a non-production environment first
- Use interactive mode when manually running the script to avoid password exposure in command history

## Workflow

### Current Implementation

1. **Initialize** - Validate parameters and setup authentication headers
2. **Step 1: Validate Customer** - Verify customer exists and is in ENABLE state
3. **Step 2: Retrieve Entitlements** - Get all entitlements for customer
4. **Step 3: Process Migration** - Execute staging or complete mode (in development)

### Planned Migration Workflow

```
┌─────────────────────────────────────────────────────────┐
│ 1. Validate Customer & Retrieve Entitlements            │
└─────────────────┬───────────────────────────────────────┘
                  │
         ┌────────▼────────┐
         │  Staging Mode   │
         └────────┬────────┘
                  │
    ┌─────────────▼─────────────┐
    │ 2. Analyze RMS-CC Products │
    │    - Identify enforcement  │
    │    - Map to LDK-CL         │
    └─────────────┬──────────────┘
                  │
    ┌─────────────▼─────────────┐
    │ 3. Preview Changes         │
    │    - Show transformations  │
    │    - Generate report       │
    └─────────────┬──────────────┘
                  │
         User Approval?
                  │
         ┌────────▼────────┐
         │  Complete Mode  │
         └────────┬────────┘
                  │
    ┌─────────────▼─────────────┐
    │ 4. Execute Migration       │
    │    - Create new ents       │
    │    - Update existing       │
    │    - Mark batch code       │
    └─────────────┬──────────────┘
                  │
    ┌─────────────▼─────────────┐
    │ 5. Verify & Report         │
    │    - Validate migration    │
    │    - Generate report       │
    └────────────────────────────┘
```

## Error Handling

The tool includes comprehensive error handling with HTTP status codes:

| Status Code | Description | Action |
|-------------|-------------|--------|
| 200 | OK | Success - operation completed |
| 400 | Bad Request | Check request parameters and format |
| 401 | Unauthorized | Verify username and password |
| 403 | Forbidden | Check user permissions in EMS |
| 404 | Not Found | Verify resource IDs (customer, entitlement) |
| 500 | Internal Server Error | Contact EMS administrator |

All errors are logged with detailed information to facilitate troubleshooting.

## Troubleshooting

### Common Issues

**Issue**: "Failed to connect to EMS"
- **Solution**: Verify the EMS URL is correct and accessible (include https://)
- Check firewall/network settings
- Ensure the EMS instance is running

**Issue**: "Authentication failed (401 Unauthorized)"
- **Solution**: Verify your username and password are correct
- Ensure the account has appropriate permissions
- Check if the account is locked or expired

**Issue**: "Customer not found"
- **Solution**: Verify the customer ID is correct (must be UUID format)
- Check that the customer exists in EMS

**Issue**: "No entitlements found for customer"
- **Solution**: Verify the customer has entitlements assigned
- Check the customerId parameter is correct

**Issue**: "Operation cancelled by user"
- **Solution**: This occurs when you select 'N' at the confirmation prompt in interactive mode
- Re-run the script and select 'Y' to proceed

## Current Status

**Version**: 2.0.0 (Updated 2025-10-31)

### ✅ Completed
- Interactive and batch mode parameter handling
- HTTP Basic Authentication with EMS API (UTF-8 encoding)
- Customer validation and retrieval
- Entitlement search and retrieval for customers
- Comprehensive logging infrastructure with file output
- Error handling framework with HTTP status codes
- Test scripts for API validation
- EMS API skill documentation with OpenAPI specs
- Verified working integration with live EMS instance

### 🔄 In Development
- Staging mode implementation (data validation and preview)
- Complete mode implementation (actual migration logic)
- Entitlement migration logic (RMS-CC to LDK-CL)
- Product mapping and transformation

### 📋 Planned
- Entitlement creation/update via POST/PATCH
- Batch processing for multiple customers
- Rollback functionality
- Migration reporting and statistics

## Claude Code Integration

This project includes a Claude Code skill (`.claude/skills/ems-api/`) that provides:
- Comprehensive EMS REST API documentation
- OpenAPI specifications for all endpoints
- Example request/response payloads
- Error handling patterns
- Authentication guidance

The skill can be invoked by Claude Code to assist with API integration and development.

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Test thoroughly (run test scripts)
5. Submit a pull request

## License

[Specify your license here]

## Support

For issues, questions, or contributions, please:
- Open an issue on GitHub: https://github.com/nickdothutton/rmscc2ldkcl
- Refer to Thales Sentinel EMS documentation: [EMS REST API Reference](https://docs.sentinel.thalesgroup.com/softwareandservices/ems/EMSdocs/WSG/APIRef/index.html)
- Contact your Thales support representative

## Version History

### 2.0.0 (2025-10-31)
- ✅ Integrated tested and verified API patterns
- ✅ Added customer validation before migration
- ✅ Updated authentication to use UTF-8 encoding
- ✅ Enhanced error handling with HTTP status codes
- ✅ Added comprehensive test scripts
- ✅ Created EMS API skill with OpenAPI specifications
- ✅ Verified working with live EMS instance
- ✅ Improved logging with blank line support
- ✅ Added detailed entitlement logging
- ✅ Enhanced Initialize-Migration with 2-step validation

### 2.0.0 (2025-10-28)
- Added interactive and batch execution modes
- Implemented staging and complete migration modes
- Changed authentication from API key to basic auth (username/password)
- Added batch code and customer ID parameters
- Enhanced user prompts and confirmation in interactive mode
- Improved parameter validation and error handling

### 1.0.0 (2025-10-28)
- Initial release
- Basic migration functionality
- REST API integration
- Logging capabilities

## Acknowledgments

- Thales Sentinel EMS team for API documentation
- PowerShell community for best practices
- Claude Code for AI-assisted development tools

## Disclaimer

This tool is provided as-is. Always test in a non-production environment before using in production. Ensure you have proper backups before performing migrations.
