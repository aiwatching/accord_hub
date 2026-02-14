---
# Accord Request Template
# See PROTOCOL.md Section 3 for full specification.

id: req-{{REQUEST_NUMBER}}-{{SHORT_DESCRIPTION}}
  # Format: req-{NNN}-{short-description}

from: {{FROM_MODULE}}
  # Requesting module/service name

to: {{TO_MODULE}}
  # Target module/service name

scope: {{SCOPE}}
  # One of: external, internal
  # external = cross-service request (targets a module's OpenAPI contract)
  # internal = cross-module request (targets a module's interface contract)

type: {{REQUEST_TYPE}}
  # External types: api-addition, api-change, api-deprecation
  # Internal types: interface-addition, interface-change, interface-deprecation
  # Shared types: bug-report, question, other

priority: {{PRIORITY}}
  # One of: low, medium, high, critical

status: pending
  # One of: pending, approved, rejected, in-progress, completed
  # New requests always start as pending

created: {{CREATED_TIMESTAMP}}
  # ISO 8601 format, e.g. 2026-02-09T10:30:00Z

updated: {{CREATED_TIMESTAMP}}
  # ISO 8601 format, updated on each status transition

related_contract: {{RELATED_CONTRACT_PATH}}
  # Optional. Path to the related contract file.
  # External: .accord/contracts/{service-name}.yaml
  # Internal: .accord/contracts/internal/{module-name}.md

# --- v2 fields (optional, backward-compatible) ---
# directive: dir-NNN-description
#   # Links to parent directive (orchestrator tracking)
# on_behalf_of: stakeholder-name
#   # Business stakeholder (for orchestrator-initiated requests)
# routed_by: orchestrator
#   # Set when orchestrator re-routes an escalated request
# originated_from: req-NNN-description
#   # Original escalated request ID (when re-routed)

# --- command fields (for type: command) ---
# command: status
#   # One of: status, scan, check-inbox, validate
# command_args: ""
#   # Optional arguments for the command
---

## What

{{BRIEF_DESCRIPTION}}

<!-- One or two sentences describing the request. -->

## Proposed Change

{{PROPOSED_CHANGE}}

<!-- Concrete details of the proposed change.
     For external (api-addition/api-change): include the proposed OpenAPI snippet.
     For internal (interface-addition/interface-change): include the proposed method signature(s).
     For bug-report/question: describe the issue or question clearly. -->

## Why

{{JUSTIFICATION}}

<!-- Why is this change needed? What use case does it support?
     Reference the feature or task driving this request. -->

## Impact

{{IMPACT_DESCRIPTION}}

<!-- What the receiving module needs to implement.
     Include: effort estimate, breaking changes, dependencies, migration steps. -->
