---
id: req-001-device-search-api
from: frontend
to: web-server
scope: external
type: api-addition
priority: high
status: completed
created: 2026-02-10T15:10:00Z
updated: 2026-02-10T15:30:00Z
related_contract: .accord/contracts/web-server.yaml
---

## What

Add a device search endpoint that supports full-text search across multiple device fields (name, IP address, MAC address).

## Proposed Change

```yaml
paths:
  /api/devices/search:
    get:
      summary: "Search devices by query"
      operationId: searchDevices
      parameters:
        - name: q
          in: query
          required: true
          schema:
            type: string
          description: "Search query — matched against device name, ipAddress, macAddress (case-insensitive substring)"
        - name: page
          in: query
          required: false
          schema:
            type: integer
            default: 0
        - name: size
          in: query
          required: false
          schema:
            type: integer
            default: 20
      responses:
        '200':
          description: "Paginated search results"
          content:
            application/json:
              schema:
                type: object
                properties:
                  content:
                    type: array
                    items:
                      $ref: '#/components/schemas/Device'
                  page:
                    type: integer
                  size:
                    type: integer
                  totalElements:
                    type: integer
                    format: int64
                  totalPages:
                    type: integer
                  first:
                    type: boolean
                  last:
                    type: boolean
```

## Why

The frontend needs to provide a device search feature to users. The current `/api/proxy/devices` endpoint only supports filtering by exact status and name substring independently. We need a single `q` parameter that searches across name, IP, and MAC address simultaneously.

## Impact

- New endpoint — no breaking changes to existing APIs
- Requires query logic to match `q` against `name`, `ipAddress`, and `macAddress` fields
- Should return the same paginated response format as existing device list endpoints
- Estimated effort: small
