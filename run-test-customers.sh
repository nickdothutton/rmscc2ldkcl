#!/bin/bash

###############################################################################
# Script: run-test-customers.sh
# Description: Wrapper script to run the test-search-customers.ps1 PowerShell
#              script with proper execution policy settings
# Usage: ./run-test-customers.sh
###############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script information
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  EMS Search Customers API Test Runner${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POWERSHELL_SCRIPT="${SCRIPT_DIR}/test-search-customers.ps1"

# Check if PowerShell script exists
if [ ! -f "$POWERSHELL_SCRIPT" ]; then
    echo -e "${RED}Error: PowerShell script not found at: ${POWERSHELL_SCRIPT}${NC}"
    exit 1
fi

# Detect the operating system
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS_TYPE="Windows"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
else
    OS_TYPE="Unknown"
fi

echo -e "${CYAN}Detected OS: ${OS_TYPE}${NC}"
echo ""

# Check for PowerShell
if command -v pwsh &> /dev/null; then
    POWERSHELL_CMD="pwsh"
    PS_VERSION=$(pwsh --version 2>&1)
    echo -e "${GREEN}Found PowerShell: ${PS_VERSION}${NC}"
elif command -v powershell &> /dev/null; then
    POWERSHELL_CMD="powershell"
    PS_VERSION=$(powershell -Command '$PSVersionTable.PSVersion.ToString()' 2>&1)
    echo -e "${GREEN}Found PowerShell: ${PS_VERSION}${NC}"
else
    echo -e "${RED}Error: PowerShell not found. Please install PowerShell:${NC}"
    echo -e "${YELLOW}  - Windows: PowerShell is pre-installed${NC}"
    echo -e "${YELLOW}  - Linux/macOS: Install PowerShell Core from https://github.com/PowerShell/PowerShell${NC}"
    exit 1
fi

echo ""

# Run the PowerShell script with Bypass execution policy
echo -e "${CYAN}Running test-search-customers.ps1...${NC}"
echo ""

if [ "$OS_TYPE" == "Windows" ]; then
    # Windows: Use -ExecutionPolicy Bypass
    "$POWERSHELL_CMD" -ExecutionPolicy Bypass -File "$POWERSHELL_SCRIPT"
else
    # Linux/macOS: PowerShell Core doesn't have execution policy restrictions by default
    "$POWERSHELL_CMD" -File "$POWERSHELL_SCRIPT"
fi

# Capture exit code
EXIT_CODE=$?

echo ""

# Display result
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Test completed successfully${NC}"
else
    echo -e "${RED}✗ Test failed with exit code: ${EXIT_CODE}${NC}"
fi

exit $EXIT_CODE
