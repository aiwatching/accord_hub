---
id: req-002-paginated-device-list-api
from: web-server
to: device-manager
scope: external
type: api-change
priority: high
status: completed
created: 2026-02-10T14:00:00Z
updated: 2026-02-10T00:00:00Z
related_contract: .accord/contracts/device-manager.yaml
---

## What

Request device-manager to enhance `GET /api/devices` to support full pagination response wrapper, name search, sorting, and sort direction.

## Proposed Change

Modify the existing `GET /api/devices` endpoint to add query parameters and return a paginated response:

```yaml
/api/devices:
  get:
    summary: "List all devices (paginated)"
    operationId: listDevices
    parameters:
      - name: page
        in: query
        required: false
        schema:
          type: integer
          default: 0
        description: "Zero-based page index"
      - name: size
        in: query
        required: false
        schema:
          type: integer
          default: 20
        description: "Number of items per page"
      - name: status
        in: query
        required: false
        schema:
          type: string
          enum: [ONLINE, OFFLINE, MAINTENANCE, UNKNOWN]
        description: "Filter by device status"
      - name: name
        in: query
        required: false
        schema:
          type: string
        description: "Search by device name (case-insensitive contains)"
      - name: sort
        in: query
        required: false
        schema:
          type: string
          default: "name"
          enum: ["name", "lastSeen", "status"]
        description: "Field to sort by"
      - name: direction
        in: query
        required: false
        schema:
          type: string
          default: "asc"
          enum: ["asc", "desc"]
        description: "Sort direction"
    responses:
      '200':
        description: "Paginated list of devices"
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PaginatedDeviceResponse'

# Add to components/schemas:
PaginatedDeviceResponse:
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
  required:
    - content
    - page
    - size
    - totalElements
    - totalPages
```

## Why

The web-server BFF layer needs to proxy paginated device queries to device-manager for a new frontend device management page. The current contract only supports `status`, `page`, and `size` params, and returns a plain array instead of a paginated response wrapper. Web-server needs `name` search, `sort`, `direction` params and the full pagination metadata (`totalElements`, `totalPages`, `first`, `last`).

## Impact

- **Effort**: Low-Medium — device-manager uses Spring Data, so pagination and sorting are mostly built-in. Adding name search requires a repository query method.
- **Breaking changes**: The response type changes from `array` to `PaginatedDeviceResponse` object. Existing consumers that expect a raw array will need to read `.content` instead. Coordinate with any other consumers.
- **Dependencies**: None.
- **Migration**: Consumers should update to read paginated response wrapper.
