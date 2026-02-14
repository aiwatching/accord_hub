---
id: req-000-service-joined-device-manager
from: device-manager
to: web-server
scope: external
type: other
priority: low
status: completed
created: 2026-02-12T01:23:49.000Z
updated: '2026-02-14T03:56:23.997Z'
attempts: 1
---

## What

Service **device-manager** has joined the project. Run `bash .accord/accord-sync.sh pull --target-dir .` to fetch the latest contracts.

## Proposed Change

No contract changes. This is an informational notification.

## Why

New service registered in the Accord hub. Other services should pull to get the updated contract list.

## Impact

None — informational only. Pull when convenient.
