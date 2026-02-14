# /accord-remote

Send diagnostic commands to one, several, or all services via the Accord protocol.

## Usage

```
/accord-remote {command}                            → send to ALL services
/accord-remote {command} --services svc1,svc2       → send to specific services
```

Supported commands: `status`, `scan`, `check-inbox`, `validate`

## Instructions

1. **Parse arguments**:
   - `{command}` (required): one of `status`, `scan`, `check-inbox`, `validate`
   - `--services` (optional): comma-separated list of target services. If omitted, send to ALL services listed in `config.yaml`.

2. **Resolve target services**:
   - If `--services` is provided, use that list
   - Otherwise, read `config.yaml` → parse all `- name: {svc}` entries under `services:` → target every service

3. **For each target service**, create a command request:

   a. **Determine next request ID**: scan `comms/inbox/` and `comms/archive/` for existing `req-*` files. Find the highest request number across ALL services, increment by 1. Each service gets its own sequential ID.

   b. **Create** `comms/inbox/{service}/req-{NNN}-cmd-{command}.md`:

      ```yaml
      ---
      id: req-{NNN}-cmd-{command}
      from: orchestrator
      to: {service}
      scope: external
      type: command
      command: {command}
      command_args: ""
      priority: medium
      status: pending
      created: {ISO-8601 timestamp}
      updated: {ISO-8601 timestamp}
      ---

      ## What

      Remote command: `{command}`

      ## Proposed Change

      N/A — diagnostic command, no contract changes.

      ## Why

      Orchestrator diagnostic: requested by user.

      ## Impact

      None — read-only diagnostic command.
      ```

   c. **Write history entry**:
      ```
      bash protocol/history/write-history.sh \
        --history-dir comms/history \
        --request-id req-{NNN}-cmd-{command} \
        --from-status "new" \
        --to-status pending \
        --actor orchestrator \
        --detail "Sent remote command: {command} to {service}"
      ```

4. **Single commit + push** (batch all files in one commit):
   ```
   git add comms/
   git commit -m "orchestrator: command - send {command} to {N} service(s)"
   git push
   ```

5. **Report** a summary table:

   | Service | Request ID | Command |
   |---------|-----------|---------|
   | svc-a   | req-005-cmd-status | status |
   | svc-b   | req-006-cmd-status | status |

   Then remind: "Use `/accord-check-results` to see output after services process the commands."
