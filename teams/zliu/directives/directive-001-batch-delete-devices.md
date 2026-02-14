---
# Accord Directive Template
# See docs/DESIGN-V2.md for full specification.

id: dir-001-batch-delete-devices
  # Format: dir-{NNN}-{short-description}

title: Add Batch Delete Devices Feature
  # Human-readable title for the directive

priority: medium
  # One of: low, medium, high, critical

status: in-progress
  # One of: pending, in-progress, completed, failed
  # New directives always start as pending

created: 2026-02-14T04:56:36Z
  # ISO 8601 format, e.g. 2026-02-11T10:00:00Z

updated: 2026-02-14T04:56:36Z
  # ISO 8601 format, updated on each status transition

requests:
  - req-001-add-batch-delete-api
  - req-002-add-batch-delete-ui
  # List of request IDs spawned from this directive
---

## Requirement

Add a batch delete functionality to the device management system. Users should be able to select multiple devices and delete them in a single operation instead of deleting devices one by one. This feature will improve operational efficiency when managing large numbers of devices.

## Acceptance Criteria

- [ ] Device Manager API provides a batch delete endpoint that accepts a list of device IDs
- [ ] The batch delete operation is atomic - either all devices are deleted successfully or none are deleted
- [ ] The API returns detailed results indicating which devices were successfully deleted and which failed (if any)
- [ ] Appropriate error handling for cases like: invalid device IDs, permission issues, devices that don't exist
- [ ] Frontend UI allows users to select multiple devices and trigger batch deletion
- [ ] Frontend displays clear feedback on the batch delete operation results

## Decomposition

| Request | Target | Status |
|---------|--------|--------|
| req-001-add-batch-delete-api | device-manager | in-progress |
| req-002-add-batch-delete-ui | frontend | pending |

<!-- Populated by the orchestrator when decomposing.
     Each row links to a dispatched request.
     Example:
     | req-010-add-search-api | device-manager | pending |
     | req-011-add-search-ui  | frontend       | pending | -->
