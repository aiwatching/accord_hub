# Accord Protocol (In-Project Reference)

Condensed protocol rules for participating agents. Full spec: see the Accord repository's `PROTOCOL.md`.

## Directory Layout (Centralized)

Everything lives under `.accord/`:

```
.accord/
├── config.yaml                        — Project configuration (services, modules, settings)
├── contracts/
│   ├── {service}.yaml                 — External contracts (OpenAPI). Only the owning module edits.
│   └── internal/
│       └── {module}.md                — Internal contracts (code-level interfaces)
└── comms/
    ├── inbox/{service-or-module}/     — Incoming requests
    ├── archive/                       — Completed/rejected requests
    ├── PROTOCOL.md                    — This file
    └── TEMPLATE.md                    — Request template
```

## Request Format

Markdown with YAML frontmatter. Required fields: `id`, `from`, `to`, `scope`, `type`, `priority`, `status`, `created`, `updated`. See `TEMPLATE.md`.

## State Machine

```
pending → approved → in-progress → completed
pending → rejected
```

## Rules

1. Never modify another module's contract directly — use a request.
2. Never auto-approve requests — human review is required.
3. A request cannot be `completed` unless the contract is updated.
4. Check your inbox on every session start (`git pull` first).
5. Use mock data / TODO markers while waiting for pending requests.

## Commit Convention

```
comms({module}): {action} - {summary}
contract({module}): {action} - {summary}
```

Actions: `request`, `approved`, `rejected`, `in-progress`, `completed`, `update`
