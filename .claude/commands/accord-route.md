# /accord-route

Route escalated requests from the orchestrator inbox to the correct service.

## Instructions

1. **Check for escalated requests**:
   - Look in `comms/inbox/orchestrator/` for request files (req-*.md)
   - If none found, report: "No escalated requests to route."
   - If multiple found, list them with summaries

2. **Analyze each request**:
   - Read the request file
   - Consult `registry/*.md` to determine which service owns the relevant data/capability
   - Show the user:
     ```
     Escalated: {req-id}
       From: {original-sender}
       What: {brief description}
       Proposed target: {service} (reason: owns {domain})
     ```
   - Ask user to confirm or redirect

3. **Create routed request**:
   - Determine next request ID (check all inboxes + archive)
   - Create a new request in `comms/inbox/{target-service}/` with:
     - `from:` = original sender (preserve the requester)
     - `to:` = target service
     - Add v2 fields (uncomment from template):
       - `routed_by: orchestrator`
       - `originated_from: {original-req-id}`
     - Copy the What/Proposed Change/Why/Impact sections from the original

4. **Complete the original request**:
   - Set `status: completed`
   - Update `updated:` timestamp
   - Add a `## Resolution` section: "Routed to {target} as {new-req-id}"
   - Move from `comms/inbox/orchestrator/` to `comms/archive/`

5. **Write history entries**:
   ```
   bash protocol/history/write-history.sh \
     --history-dir comms/history \
     --request-id {original-req-id} \
     --from-status pending \
     --to-status completed \
     --actor orchestrator \
     --detail "Routed to {target} as {new-req-id}"
   ```

6. **Commit and push**:
   ```
   git add .
   git commit -m "orchestrator: route - {original-req-id} → {target}"
   git push
   ```

7. **Report**: "Routed {original-req-id} to {target} as {new-req-id}."
