---
id: req-001-add-batch-delete-api
from: orchestrator
to: device-manager
scope: external
type: api-addition
priority: medium
status: in-progress
created: 2026-02-14T04:56:36.000Z
updated: '2026-02-14T04:57:36.661Z'
related_contract: contracts/device-manager.yaml
directive: dir-001-batch-delete-devices
on_behalf_of: user
attempts: 1
---

## What

Add a batch delete endpoint to the device-manager API that allows deleting multiple devices in a single operation.

## Proposed Change

Add the following endpoint to the device-manager API contract:

```yaml
paths:
  /api/devices/batch-delete:
    post:
      summary: "Batch delete devices"
      operationId: batchDeleteDevices
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                device_ids:
                  type: array
                  items:
                    type: string
                  description: "List of device IDs to delete"
                  minItems: 1
              required:
                - device_ids
      responses:
        '200':
          description: "Batch delete operation completed"
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                    description: "Whether all devices were successfully deleted"
                  deleted:
                    type: array
                    items:
                      type: string
                    description: "List of successfully deleted device IDs"
                  failed:
                    type: array
                    items:
                      type: object
                      properties:
                        device_id:
                          type: string
                        error:
                          type: string
                    description: "List of failed deletions with error messages"
                  total_requested:
                    type: integer
                    description: "Total number of devices requested for deletion"
                  total_deleted:
                    type: integer
                    description: "Number of devices successfully deleted"
        '400':
          description: "Bad request - invalid input"
        '500':
          description: "Internal server error"
```

## Why

Users need the ability to delete multiple devices at once to improve operational efficiency. Currently, deleting devices one by one is time-consuming when managing large numbers of devices. This is part of directive dir-001-batch-delete-devices.

## Impact

Implementation requirements:
- Add new POST endpoint `/api/devices/batch-delete`
- Implement batch deletion logic with proper transaction handling
- Ensure atomicity - either all succeed or none (or provide partial success with detailed results)
- Add proper error handling and validation
- Update API contract in `contracts/device-manager.yaml`
- Add tests for the new endpoint

Estimated effort: Medium (2-3 hours)
Breaking changes: None (this is a new endpoint)
Dependencies: None
