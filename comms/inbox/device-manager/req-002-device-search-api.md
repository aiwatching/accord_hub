---
id: req-002-device-search-api
from: web-server
to: device-manager
scope: external
type: api-addition
priority: high
status: pending
created: 2026-02-10T15:15:00Z
updated: 2026-02-10T15:15:00Z
related_contract: .accord/contracts/device-manager.yaml
---

## What

Add a device search endpoint that supports full-text search across multiple device fields (name, IP address, MAC address) with pagination.

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

The frontend has requested a device search feature (req-001-device-search-api). web-server acts as a BFF proxy and needs device-manager to provide the actual search logic across name, ipAddress, and macAddress fields. The current `/api/devices` endpoint only supports filtering by exact status and name independently — we need a unified `q` parameter for cross-field search.

## Impact

- New endpoint — no breaking changes to existing APIs
- Requires query logic to match `q` against `name`, `ipAddress`, and `macAddress` fields (case-insensitive substring)
- Must return the same paginated response format as existing `/api/devices` endpoint
- Estimated effort: small
