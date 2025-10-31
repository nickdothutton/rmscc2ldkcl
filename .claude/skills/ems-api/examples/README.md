# API Examples

Place example JSON request and response payloads for each EMS API endpoint in this directory.

## Naming Convention

Use descriptive names that indicate the endpoint and whether it's a request or response:

- `{endpoint}-{operation}-request.json`
- `{endpoint}-{operation}-response.json`

## Example Files to Add

### Search Entitlements
- `search-entitlements-request.txt` - Query parameters
- `search-entitlements-response.json` - Sample response with entitlements
- `search-entitlements-response-empty.json` - Response when no entitlements found

### Add Entitlement
- `add-entitlement-request.json` - Sample create payload
- `add-entitlement-response.json` - Success response

### Update Entitlement
- `update-entitlement-request.json` - Sample update payload
- `update-entitlement-response.json` - Success response

### Search Customers
- `search-customers-request.txt` - Query parameters
- `search-customers-response.json` - Sample response with customers found 
- `search-customers-response-empty.json` - Response when no customers found

### Search Products
- `search-products-request.txt` - Query parameters
- `search-products-response.json` - Sample response with products found
- `search-products-response-empty.json` - Response when no products found

### Error Responses
- `error-400-response.json` - Bad request error
- `error-401-response.json` - Authentication error
- `error-404-response.json` - Not found error
- `error-500-response.json` - Server error

## Tips

- Include realistic sample data
- Document any special fields or formats in comments (if using JSON5) or in this README
- Include edge cases (empty arrays, null values, etc.)
