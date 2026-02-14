# /accord-monitor

Monitor directive progress and update statuses.

## Instructions

1. **List all directives**:
   - Read all files in `directives/`
   - Group by status: pending, in-progress, completed, failed
   - If no directives exist, report: "No directives found."

2. **Check in-progress directives**:
   - For each directive with `status: in-progress`:
     - Read the `requests:` list from frontmatter
     - For each linked request ID:
       - Check `comms/inbox/*/` for the request file and read its current `status:`
       - Check `comms/archive/` if not found in inboxes (likely completed/rejected)
     - Calculate progress: completed / total requests

3. **Update directive files** if status changed:
   - Update the Decomposition table with current request statuses
   - If ALL requests are `completed` → set directive `status: completed`
   - If any request is `rejected` → set directive `status: failed`
   - Update `updated:` timestamp on any change

4. **Write history entries** for any directive status changes:
   ```
   bash protocol/history/write-history.sh \
     --history-dir comms/history \
     --request-id {dir-id} \
     --from-status in-progress \
     --to-status {new-status} \
     --actor orchestrator \
     --directive-id {dir-id} \
     --detail "{summary of change}"
   ```

5. **Commit and push** if any changes were made:
   ```
   git add .
   git commit -m "orchestrator: monitor - updated directive statuses"
   git push
   ```

6. **Report** a progress summary:
   ```
   Directive Status Summary:

   | Directive | Title | Status | Progress |
   |-----------|-------|--------|----------|
   | dir-001-... | Add OAuth | in-progress | 2/3 (67%) |
   | dir-002-... | Fix login | completed | 1/1 (100%) |

   In-progress details:
   - dir-001: req-010 (completed), req-011 (in-progress), req-012 (pending)
   ```
