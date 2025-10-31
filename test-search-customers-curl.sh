#!/bin/bash

###############################################################################
# Script: test-search-customers-curl.sh
# Description: Test script for Sentinel EMS Search Customers API using curl
# Usage: ./test-search-customers-curl.sh
###############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display messages
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Header
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  EMS Search Customers API Test${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Get user input
read -p "Enter Sentinel EMS Base URL (e.g., https://ems.example.com): " BASE_URL
read -p "Enter Username: " USERNAME
read -s -p "Enter Password: " PASSWORD
echo ""
read -p "Enter Customer ID: " CUSTOMER_ID

echo ""
echo -e "${CYAN}Configuration Summary:${NC}"
echo "  EMS Base URL: $BASE_URL"
echo "  Username: $USERNAME"
echo "  Password: $(echo "$PASSWORD" | sed 's/./*/g')"
echo "  Customer ID: $CUSTOMER_ID"
echo ""

read -p "Proceed with API call? (Y/N): " CONFIRMATION
if [[ ! "$CONFIRMATION" =~ ^[Yy]$ ]]; then
    log_warning "Operation cancelled by user"
    exit 0
fi

echo ""

# Construct API URL
API_URL="${BASE_URL}/ems/api/v5/customers?id=${CUSTOMER_ID}"

log_info "Calling Search Customers API..."
log_info "URL: $API_URL"
echo ""

# Create temporary file for response
RESPONSE_FILE=$(mktemp)
HTTP_CODE_FILE=$(mktemp)

# Make API call with curl
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$RESPONSE_FILE" \
    -X GET \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -u "${USERNAME}:${PASSWORD}" \
    "$API_URL")

# Check HTTP status code
echo ""
log_info "HTTP Status Code: $HTTP_CODE"
echo ""

if [[ "$HTTP_CODE" == "200" ]]; then
    log_success "API call successful"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  API Response${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # Display formatted JSON response
    if command -v jq &> /dev/null; then
        cat "$RESPONSE_FILE" | jq '.'
    else
        cat "$RESPONSE_FILE"
        echo ""
        log_warning "Install 'jq' for prettier JSON formatting"
    fi

    echo ""

    # Try to extract summary information
    if command -v jq &> /dev/null; then
        CUSTOMER_COUNT=$(cat "$RESPONSE_FILE" | jq -r '.customers.count // 0')
        echo -e "${CYAN}Summary:${NC}"
        echo "  Total customers found: $CUSTOMER_COUNT"

        if [[ "$CUSTOMER_COUNT" -gt 0 ]]; then
            echo ""
            echo -e "${CYAN}Customer Details:${NC}"

            # Extract customer details
            cat "$RESPONSE_FILE" | jq -r '
                .customers.customer[] |
                "  - ID: \(.id)\n    Name: \(.name)\n    Identifier: \(.identifier // "N/A")\n    State: \(.state)\n    Market Group: \(.marketGroup.name // "N/A")\n"
            '
        fi
    fi

    # Clean up
    rm -f "$RESPONSE_FILE" "$HTTP_CODE_FILE"

    echo ""
    log_success "Test completed successfully"
    exit 0

elif [[ "$HTTP_CODE" == "401" ]]; then
    log_error "Authentication failed (401 Unauthorized)"
    echo ""
    echo "Response:"
    cat "$RESPONSE_FILE"
    echo ""
    rm -f "$RESPONSE_FILE" "$HTTP_CODE_FILE"
    exit 1

elif [[ "$HTTP_CODE" == "404" ]]; then
    log_error "Resource not found (404)"
    echo ""
    echo "Response:"
    cat "$RESPONSE_FILE"
    echo ""
    rm -f "$RESPONSE_FILE" "$HTTP_CODE_FILE"
    exit 1

elif [[ "$HTTP_CODE" == "400" ]]; then
    log_error "Bad request (400)"
    echo ""
    echo "Response:"
    cat "$RESPONSE_FILE"
    echo ""
    rm -f "$RESPONSE_FILE" "$HTTP_CODE_FILE"
    exit 1

else
    log_error "API call failed with HTTP status code: $HTTP_CODE"
    echo ""
    echo "Response:"
    cat "$RESPONSE_FILE"
    echo ""
    rm -f "$RESPONSE_FILE" "$HTTP_CODE_FILE"
    exit 1
fi
