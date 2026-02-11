---
id: req-003-add-plugin-to-device
from: frontend
to: device-manager
scope: external
type: api-change
priority: high
status: completed
created: 2026-02-11T00:00:00Z
updated: 2026-02-11T00:00:00Z
related_contract: .accord/contracts/device-manager.yaml
---

## What

Add plugin association data to the Device schema so that device list and detail responses include the network protocol plugins (SNMP, Netconf, SSH, etc.) associated with each device.

## Proposed Change

Add the following schemas and modify the Device schema in the device-manager contract:

```yaml
PluginProtocol:
  type: string
  enum:
    - SNMP
    - NETCONF
    - SSH
    - TELNET
    - HTTP
  description: "Network protocol type supported by a plugin"

Plugin:
  type: object
  properties:
    id:
      type: string
      description: "Unique plugin identifier"
    name:
      type: string
      description: "Display name of the plugin (e.g. 'SNMP v3')"
    protocol:
      $ref: '#/components/schemas/PluginProtocol'
    version:
      type: string
      description: "Plugin version"
    enabled:
      type: boolean
      description: "Whether the plugin is enabled"
  required:
    - id
    - name
    - protocol

# Add to existing Device schema:
Device:
  properties:
    # ... existing fields ...
    plugins:
      type: array
      items:
        $ref: '#/components/schemas/Plugin'
      description: "Network protocol plugins associated with this device"
```

Affected endpoints:
- `GET /api/devices` — each device in the paginated response should include `plugins`
- `GET /api/devices/{id}` — device detail should include `plugins`
- `GET /api/devices/search` — search results should include `plugins`

## Why

The frontend needs to display which network protocol plugins (SNMP, Netconf, SSH, TELNET, HTTP) are associated with each device in the device list view. This helps network administrators quickly see device management capabilities at a glance.

The frontend has already implemented the model, mock data, and response parsing for this field. Once device-manager provides real plugin data, the frontend will consume it without further changes.

## Impact

- **New schemas**: `Plugin` and `PluginProtocol` need to be added to the device-manager domain model
- **Device entity change**: A `plugins` relationship needs to be added to the Device entity
- **Response serialization**: All device-returning endpoints must include the `plugins` list
- **Effort estimate**: Medium — requires new entity/table, relationship mapping, and response DTO update
- **Breaking changes**: None — this is an additive change (new field on existing response)
- **Migration**: Database migration needed if plugins are stored in a separate table
