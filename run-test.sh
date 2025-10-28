#!/bin/bash
# Bash wrapper to run the PowerShell script for testing

# Convert WSL path to Windows path
SCRIPT_PATH=$(wslpath -w "$(pwd)/rmscc2ldkcl.ps1")

echo "=========================================="
echo "Testing rmscc2ldkcl PowerShell Script"
echo "=========================================="
echo ""
echo "Running in batch mode with test parameters..."
echo "Script path: $SCRIPT_PATH"
echo ""

# Execute PowerShell script with test parameters
# Using -Command instead of -File to properly handle parameters
powershell.exe -ExecutionPolicy Bypass -Command "& '$SCRIPT_PATH' -EmsUrl 'https://ems.example.com' -Username 'testuser' -Password 'testpass123' -BatchCode 'BATCH001' -CustomerId 'CUST123' -Mode 'staging'"

EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Script execution completed with exit code: $EXIT_CODE"
echo "=========================================="

exit $EXIT_CODE
