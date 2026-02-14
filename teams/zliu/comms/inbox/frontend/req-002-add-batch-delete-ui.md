---
# Accord Request Template
# See PROTOCOL.md Section 3 for full specification.

id: req-002-add-batch-delete-ui
  # Format: req-{NNN}-{short-description}

from: orchestrator
  # Requesting module/service name

to: frontend
  # Target module/service name

scope: external
  # One of: external, internal
  # external = cross-service request (targets a module's OpenAPI contract)
  # internal = cross-module request (targets a module's interface contract)

type: api-addition
  # External types: api-addition, api-change, api-deprecation
  # Internal types: interface-addition, interface-change, interface-deprecation
  # Shared types: bug-report, question, other

priority: medium
  # One of: low, medium, high, critical

status: pending
  # One of: pending, approved, rejected, in-progress, completed
  # New requests always start as pending

created: 2026-02-14T04:56:36Z
  # ISO 8601 format, e.g. 2026-02-09T10:30:00Z

updated: 2026-02-14T04:56:36Z
  # ISO 8601 format, updated on each status transition

related_contract: contracts/frontend.yaml
  # Optional. Path to the related contract file.
  # External: .accord/contracts/{service-name}.yaml
  # Internal: .accord/contracts/internal/{module-name}.md

# --- v2 fields (optional, backward-compatible) ---
directive: dir-001-batch-delete-devices
  # Links to parent directive (orchestrator tracking)
on_behalf_of: user
  # Business stakeholder (for orchestrator-initiated requests)
---

## What

Add batch delete functionality to the device management UI that allows users to select multiple devices and delete them in a single operation.

## Proposed Change

Add the following features to the device management interface:

1. **Multi-select capability**: Add checkboxes to the device list view allowing users to select multiple devices
2. **Batch delete button**: Add a "Delete Selected" button that becomes enabled when one or more devices are selected
3. **Confirmation dialog**: Show a confirmation dialog displaying:
   - Number of devices to be deleted
   - List of device names/IDs
   - "Confirm" and "Cancel" buttons
4. **API integration**: Call the device-manager batch delete endpoint (POST `/api/devices/batch-delete`)
5. **Result feedback**: Display operation results to the user:
   - Success message showing number of devices deleted
   - Error message if the operation fails
   - Partial success message showing which devices were deleted and which failed
6. **UI updates**: Refresh the device list after successful deletion

## Why

Users need the ability to efficiently delete multiple devices at once. This improves user experience and operational efficiency when managing large numbers of devices. This is part of directive dir-001-batch-delete-devices and depends on req-001-add-batch-delete-api.

## Impact

Implementation requirements:
- Add checkbox column to device list table
- Add "Select All" checkbox in table header
- Add "Delete Selected" button to device list toolbar
- Implement multi-selection state management
- Create confirmation dialog component
- Integrate with device-manager batch delete API endpoint
- Add error handling and user feedback (success/error notifications)
- Update device list state after deletion
- Add unit tests for new components

Dependencies:
- Requires req-001-add-batch-delete-api to be completed first (device-manager batch delete endpoint)

Estimated effort: Medium (3-4 hours)
Breaking changes: None (UI enhancement only)
