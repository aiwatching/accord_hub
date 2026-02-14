# /accord-check-results

Check the status and results of remote command requests.

## Usage

```
/accord-check-results                      → show all command results
/accord-check-results --services svc1,svc2 → show results for specific services only
```

## Instructions

1. **Pull latest**:
   ```
   git pull --quiet
   ```

2. **Parse arguments**:
   - `--services` (optional): comma-separated list of services to filter by. If omitted, show all.

3. **Scan for command requests**:
   - Check `comms/archive/` for completed `req-*-cmd-*.md` files
   - Check `comms/inbox/*/` for pending or in-progress `req-*-cmd-*.md` files
   - If `--services` was provided, only include requests where `to:` matches one of the specified services

4. **Build a results table**:

   | Request | Service | Command | Status | Result |
   |---------|---------|---------|--------|--------|
   | req-005-cmd-status | frontend | status | completed | 3 endpoints, 2 contracts |
   | req-006-cmd-scan | backend | scan | pending | (waiting) |

5. **For completed commands**: show the full `## Result` section content from the archived request file

6. **For pending/in-progress commands**: show "(waiting — service has not processed yet)"

7. **If no command requests found**: report "No remote commands have been sent. Use `/accord-remote` to send one."
