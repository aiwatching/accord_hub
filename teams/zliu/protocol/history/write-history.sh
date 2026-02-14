#!/usr/bin/env bash
# Accord History Writer — appends a JSONL audit entry
#
# Usage:
#   write-history.sh --history-dir <dir> --request-id <id> --from-status <s> --to-status <s> --actor <name> \
#     [--directive-id <id>] [--detail <text>]
#
# Produces one JSON line in {YYYY-MM-DD}-{actor}.jsonl

set -euo pipefail

HISTORY_DIR=""
REQUEST_ID=""
FROM_STATUS=""
TO_STATUS=""
ACTOR=""
DIRECTIVE_ID=""
DETAIL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --history-dir)   HISTORY_DIR="$2"; shift 2 ;;
        --request-id)    REQUEST_ID="$2"; shift 2 ;;
        --from-status)   FROM_STATUS="$2"; shift 2 ;;
        --to-status)     TO_STATUS="$2"; shift 2 ;;
        --actor)         ACTOR="$2"; shift 2 ;;
        --directive-id)  DIRECTIVE_ID="$2"; shift 2 ;;
        --detail)        DETAIL="$2"; shift 2 ;;
        *)               echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Validate required fields (from-status may be empty for new requests)
[[ -z "$HISTORY_DIR" ]] && { echo "ERROR: --history-dir is required" >&2; exit 1; }
[[ -z "$REQUEST_ID" ]] && { echo "ERROR: --request-id is required" >&2; exit 1; }
[[ -z "$TO_STATUS" ]] && { echo "ERROR: --to-status is required" >&2; exit 1; }
[[ -z "$ACTOR" ]] && { echo "ERROR: --actor is required" >&2; exit 1; }

# Create history dir if missing
mkdir -p "$HISTORY_DIR"

# Compute filename: {YYYY-MM-DD}-{actor}.jsonl
DATE_PART="$(date -u +"%Y-%m-%d")"
FILENAME="${DATE_PART}-${ACTOR}.jsonl"
FILEPATH="$HISTORY_DIR/$FILENAME"

# Build timestamp
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build JSON line (using printf to avoid dependency on jq)
# Escape double quotes in detail text
DETAIL_ESCAPED="$(echo "$DETAIL" | sed 's/"/\\"/g')"

JSON="{\"ts\":\"${TS}\",\"request_id\":\"${REQUEST_ID}\",\"from_status\":\"${FROM_STATUS}\",\"to_status\":\"${TO_STATUS}\",\"actor\":\"${ACTOR}\""

if [[ -n "$DIRECTIVE_ID" ]]; then
    JSON="${JSON},\"directive_id\":\"${DIRECTIVE_ID}\""
fi

if [[ -n "$DETAIL" ]]; then
    JSON="${JSON},\"detail\":\"${DETAIL_ESCAPED}\""
fi

JSON="${JSON}}"

# Atomic append
echo "$JSON" >> "$FILEPATH"
