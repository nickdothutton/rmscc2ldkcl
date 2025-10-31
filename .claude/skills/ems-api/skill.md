# Thales Sentinel EMS REST API

## Overview

This skill provides comprehensive documentation for the Thales Sentinel Entitlement Management System (EMS) REST API endpoints used in the rmscc2ldkcl migration tool.

## When to Use This Skill

- When implementing API calls to Sentinel EMS
- When parsing or constructing request/response payloads
- When handling EMS API errors
- When understanding entitlement data structures

## Base Configuration

### Base URL
```
{EMS_BASE_URL}/ems/api/v5
```

### Authentication
- **Method**: HTTP Basic Authentication
- **Header**: `Authorization: Basic {base64(username:password)}`

### Common Headers
```
Content-Type: application/json
Accept: application/json
Authorization: Basic {credentials}
```

## API Endpoints

### 1. Search Entitlements

**Endpoint**: `GET /ems/api/v5/entitlements`

**Description**: Retrieves entitlements for a specific customer.

**Query Parameters**:
- `customerId` (required): The customer ID to search for

**OpenAPI Spec**: See `openapi/entitlements.yaml`

**Example Request**:
```http
GET /ems/api/v5/entitlements?customerId=CUST123
Authorization: Basic dGVzdHVzZXI6dGVzdHBhc3M=
```

**Example Response**: See `examples/search-entitlements-response.json`

---

### 2. Add Entitlement

**Endpoint**: `POST /ems/api/v5/entitlements`

**Description**: Add an entitlement.

**Query Parameters**:
- The POST body contains the information used to create the entitlement.

**OpenAPI Spec**: See `openapi/entitlements.yaml`

**Example Request**:
```http
POST /ems/api/v5/entitlements?comments={comments}&executedBy={executedBy}&returnResource={returnResource}
Authorization: Basic dGVzdHVzZXI6dGVzdHBhc3M=
```

**Example Response**: See `examples/add-entitlements-response.json`

---

### 3. Update Entitlement

**Endpoint**: `PATCH /ems/api/v5/entitlements{entitlementId}`

**Description**: Update an entitlement.

**Query Parameters**:
- The PATCH body contains the information used to update the entitlement.

**OpenAPI Spec**: See `openapi/entitlements.yaml`

**Example Request**:
```http
PATCH /ems/api/v5/entitlements/{entitlementId}?regenerateLicense={regenerateLicense}&comments={comments}&executedBy={executedBy}&returnResource={returnResource}
Authorization: Basic dGVzdHVzZXI6dGVzdHBhc3M=
```

**Example Response**: See `examples/add-entitlements-response.json`

---

### 4. [Search Customers]

**Endpoint**: `GET /ems/api/v5/customers`

**Description**: Retrieve a list of records which match the query parameters. If you do not specify any query parameters, the endpoint returns all records.

**Example Request**:
```http
GET /ems/api/v5/customers?id={id}&name={name}&identifier={identifier}&externalId={externalId}&refId={refId}&crmId={crmId}&description={description}&marketGroupId={marketGroupId}&marketGroupName={marketGroupName}&state={state}&contactEmailId={contactEmailId}&contactId={contactId}&contactExternalId={contactExternalId}&pageStartIndex={pageStartIndex}&pageSize={pageSize}&searchPattern={searchPattern}&sortByAsc={sortByAsc}&sortByDesc={sortByDesc}&creationDateFrom={creationDateFrom}&creationDateTo={creationDateTo}&raw={raw}&embed={embed}
Authorization: Basic dGVzdHVzZXI6dGVzdHBhc3M=
```

**Example Response**: See `examples/search-customers-response.json`

---

### 5. [Search Products]

**Endpoint**: `GET /ems/api/v5/products`

**Description**: Retrieve a list of records which match the query parameters. If you do not specify any query parameters, the endpoint returns all records.

**Example Request**:
```http
GET /ems/api/v5/enforcements/{enforcementId}/licenseModels?id={id}&name={name}&state={state}&description={description}&createdBy={createdBy}&creationDateFrom={creationDateFrom}&creationDateTo={creationDateTo}&lastModifiedBy={lastModifiedBy}&pageStartIndex={pageStartIndex}&pageSize={pageSize}&searchPattern={searchPattern}&sortByAsc={sortByAsc}&sortByDesc={sortByDesc}&embed={embed}
```

**Example Response**: See `examples/search-products-response.json`

---

## Data Structures

### Entitlement Object

```json
{
  "id": "string",
  "customerId": "string",
  "productId": "string",
  "features": [],
  "status": "string",
  "createdDate": "string",
  "expirationDate": "string"
}
```

## Error Handling

### Common HTTP Status Codes

- `200 OK`: Successful request
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Authentication failed
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

### Error Response Format

```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": []
  }
}
```

See `docs/error-handling.md` for detailed error handling guidance.

## Migration Workflows

### RMS-CC to LDK-CL Migration Process

1. **Search Entitlements**: Retrieve all RMS-CC entitlements for customer
2. **[Stage 2]**: TBD - Add next step
3. **[Stage 3]**: TBD - Add next step

## Best Practices

1. Always use HTTPS for API calls
2. Handle rate limiting appropriately
3. Implement retry logic for transient failures
4. Log all API requests and responses for audit purposes
5. Validate response data before processing

## References

- OpenAPI Specifications: `./openapi/`
- Request/Response Examples: `./examples/`
- Detailed Documentation: `./docs/`
- Official EMS API Documentation: https://docs.sentinel.thalesgroup.com/softwareandservices/ems/EMSdocs/WSG/APIRef/index.html

## Notes

- API version: v5
- Last updated: 2025-10-28
- This skill should be invoked when working with EMS API endpoints
