# /accord-check-inbox

Check the orchestrator inbox for escalated requests and show directive status overview.

## Instructions

1. **Pull latest** (if this is a git repo):
   ```
   git pull --quiet
   ```

2. **Check escalated requests**:
   - Look in `comms/inbox/orchestrator/` for request files (req-*.md)
   - For each request found, read the YAML frontmatter
   - Report:
     ```
     Escalated requests (comms/inbox/orchestrator/):
       - {req-id}: from {sender}, type: {type}, priority: {priority} — "{brief what}"
     ```
   - If none: "No escalated requests."

3. **Directive status overview**:
   - Read all files in `directives/`
   - Report:
     ```
     Directives:
       Pending:     N
       In-progress: N
       Completed:   N
       Failed:      N
     ```
   - For in-progress directives, show a one-line summary with progress

4. **Recommended actions**:
   - If there are pending directives: "Use /accord-decompose to process pending directives."
   - If there are escalated requests: "Use /accord-route to route escalated requests."
   - If there are in-progress directives: "Use /accord-monitor to check directive progress."
