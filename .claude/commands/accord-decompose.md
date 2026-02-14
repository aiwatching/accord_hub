# /accord-decompose

Decompose a pending directive into per-service requests.

## Instructions

1. **List pending directives**:
   - Check `directives/` for files with `status: pending`
   - If none found, report: "No pending directives to decompose."
   - If multiple found, list them and ask the user which one to process

2. **Analyze the directive**:
   - Read the selected directive file
   - Read all `registry/*.md` to understand service ownership and capabilities
   - Read all `contracts/*.yaml` to understand existing APIs
   - Determine which services need changes to fulfill the requirement

3. **Plan the decomposition**:
   - For each service that needs work, identify:
     - What the service needs to do
     - Which contract will be affected
     - Dependencies between requests (ordering)
   - Present the plan to the user for approval:
     ```
     Directive: {dir-id} — {title}
     Decomposition plan:
       1. {service-a}: {what it needs to do}
       2. {service-b}: {what it needs to do} (depends on #1)
     ```

4. **Determine request IDs**:
   - Check existing request files in all `comms/inbox/*/` and `comms/archive/`
   - Assign sequential numbers: `req-{NNN}-{short-description}`

5. **Create request files**:
   - Use `comms/TEMPLATE.md` as the template
   - For each request:
     - Set `from: orchestrator`
     - Set `scope: external`
     - Set `priority:` matching the directive's priority
     - Set `status: pending`
     - Set timestamps to current time (ISO 8601)
     - Add v2 fields in the frontmatter (uncomment from template):
       - `directive: {dir-id}`
       - `on_behalf_of: {stakeholder}` (if known)
   - Place in `comms/inbox/{target-service}/`

6. **Update the directive**:
   - Set `status: in-progress`
   - Update `updated:` timestamp
   - Populate `requests:` list with the new request IDs
   - Fill in the Decomposition table:
     ```
     | req-010-add-search-api | device-manager | pending |
     | req-011-add-search-ui  | frontend       | pending |
     ```

7. **Write history entries**:
   ```
   bash protocol/history/write-history.sh \
     --history-dir comms/history \
     --request-id {dir-id} \
     --from-status pending \
     --to-status in-progress \
     --actor orchestrator \
     --directive-id {dir-id} \
     --detail "Decomposed into N requests: {list}"
   ```

8. **Commit and push**:
   ```
   git add .
   git commit -m "orchestrator: decompose - {dir-id}"
   git push
   ```

9. **Report**:
   - List all created requests with targets and summaries
   - Note any dependencies between requests
   - "Directive {dir-id} decomposed into N requests. Services will pick them up on next sync."
