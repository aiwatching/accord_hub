---
id: req-000-service-joined-device-manager
from: device-manager
to: frontend
scope: external
type: other
priority: low
status: pending
created: 2026-02-13T01:19:41Z
updated: 2026-02-13T01:19:41Z
---

## What

Service **device-manager** has joined the project. Run `bash .accord/accord-sync.sh pull --target-dir .` to fetch the latest contracts.

## Proposed Change

No contract changes. This is an informational notification.

## Why

New service registered in the Accord hub. Other services should pull to get the updated contract list.

## Impact

None — informational only. Pull when convenient.
