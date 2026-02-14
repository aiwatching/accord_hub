---
id: req-001-device-list-page
from: orchestrator
to: frontend
scope: external
type: other
priority: high
status: in-progress
created: 2026-02-14T08:04:52.000Z
updated: '2026-02-14T08:05:25.158Z'
related_contract: contracts/frontend.yaml
on_behalf_of: user
attempts: 1
---

## What

Develop a device list page for the frontend application to display all devices.

## Proposed Change

Create a new page component that:
1. Displays a list/table of devices
2. Fetches device data from the device-manager service API
3. Shows key device information (ID, name, status, etc.)
4. Provides basic UI for viewing devices

The page should be simple and functional - a basic list or table view that clearly shows the devices available in the system.

## Why

The frontend application currently has no pages implemented. We need to start with a fundamental feature - viewing the list of devices. This is the foundation for device management functionality and will allow users to see what devices exist in the system.

## Impact

The frontend team needs to:
1. Create a new page component (e.g., DeviceListPage or similar)
2. Implement data fetching from device-manager API (use the API endpoint from device-manager contract)
3. Design and implement a simple UI to display the device list (table or card layout)
4. Add routing to make this page accessible
5. Handle loading and error states appropriately

**Effort estimate:** Small to medium - this is a straightforward list page implementation.

**Dependencies:**
- Requires device-manager service to have a working device list API endpoint (check contracts/device-manager.yaml for available endpoints)
- If the API doesn't exist yet, coordinate with device-manager service to add it first

**Technical approach:**
- Use the frontend framework/stack already in place
- Keep the UI simple and clean - focus on functionality over aesthetics for this initial version
- Follow existing frontend code patterns and conventions
