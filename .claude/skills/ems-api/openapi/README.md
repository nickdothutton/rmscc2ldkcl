# OpenAPI Specifications

Place OpenAPI/Swagger YAML or JSON files for each EMS API endpoint in this directory.

## Files to Add

- `entitlement.yaml` - Search/CRUD operations for entitlements
- `products.yaml` - Product management endpoints
- `customers.yaml` - Customer management endpoints
- Add other endpoint specs as needed

## Format

Use OpenAPI 3.0+ format. Example structure:

```yaml
openapi: 3.0.0
info:
  title: EMS Entitlements API
  version: v5
servers:
  - url: https://ems.example.com/ems/api/v5
paths:
  /entitlements:
    get:
      summary: Search entitlements
      parameters:
        - name: customerId
          in: query
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Entitlement'
```
