---
id: req-001-paginated-device-list
from: frontend
to: web-server
scope: external
type: api-addition
priority: high
status: approved
created: 2026-02-10T12:00:00Z
updated: 2026-02-10T12:00:00Z
related_contract: .accord/contracts/web-server.yaml
---

## What

Request web-server to expose a paginated device list endpoint at `GET /api/proxy/devices` that supports filtering by status, searching by name, sorting, and pagination.

## Proposed Change

Add the following endpoint to the web-server contract:

```yaml
/api/proxy/devices:
  get:
    summary: "List devices with pagination"
    operationId: getDevicesPaginated
    tags:
      - DeviceProxy
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
        $ref: '#/components/schemas/DeviceSummary'
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

The frontend needs a paginated device list page with filtering (by status), search (by name), and sorting capabilities. The current `/api/dashboard/devices` endpoint returns all devices without pagination, which doesn't scale and lacks query parameters. The frontend requires a proper paginated proxy endpoint to build the device management page.

## Impact

- **Effort**: Medium — web-server needs to add a new controller method that proxies to device-manager with query parameter forwarding, plus a `PaginatedDeviceResponse` wrapper.
- **Breaking changes**: None — this is a new endpoint addition.
- **Dependencies**: device-manager must support paginated queries (it already does via Spring Data pagination).
- **Migration**: No migration needed.
