#!/usr/bin/env bash
# Hook: Stop
# Fires when Claude finishes responding (session end or /clear).
# Archives the session transcript to the artifacts repo before it can be overwritten.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

LOG_DIR="${PROJECT_ROOT}/.claude/hook-logs"
mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/on_stop.log" 2>&1

HOOK_DATA=$(cat)
echo "[$(date -Iseconds)] on_stop: received payload: $HOOK_DATA"
TRANSCRIPT_PATH=$(echo "$HOOK_DATA" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$HOOK_DATA" | jq -r '.session_id // "unknown"')
AGENT_TYPE=$(echo "$HOOK_DATA" | jq -r '.agent_type // "default"')

# Only archive sessions from interactive agents
ALLOWED_AGENTS=("coco" "ethnographer")
if [[ ! " ${ALLOWED_AGENTS[@]} " =~ " ${AGENT_TYPE} " ]]; then
  exit 0
fi

# Bail if no transcript path provided
if [[ -z "$TRANSCRIPT_PATH" ]]; then
  echo "on_stop: no transcript_path in hook payload, skipping" >&2
  exit 0
fi

# Bail if transcript file doesn't exist or is empty
if [[ ! -s "$TRANSCRIPT_PATH" ]]; then
  echo "on_stop: transcript file missing or empty at $TRANSCRIPT_PATH, skipping" >&2
  exit 0
fi

# Archive to the artifacts repo's pending directory
ARCHIVE_DIR="${CLAUDE_TRANSCRIPTS_PATH}"
mkdir -p "$ARCHIVE_DIR"

DEST="${ARCHIVE_DIR}/${SESSION_ID}.jsonl"

# Coco experiment data: archive transcript if the session produced logged work
SANCTUM_HOME="/workspace/nexus-mk2"
COCO_TRANSCRIPT_DIR="${SANCTUM_HOME}/experiments/data/transcripts"

# Defer the copy until the transcript file stops being written to
(
  # Wait for the file to exist and stabilize (mtime stops changing)
  for i in $(seq 1 20); do
    sleep 0.5
    [[ -s "$TRANSCRIPT_PATH" ]] || continue
    BEFORE=$(stat -c %Y "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    sleep 0.5
    AFTER=$(stat -c %Y "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    if [[ "$BEFORE" == "$AFTER" ]]; then
      cp "$TRANSCRIPT_PATH" "$DEST"
      echo "[$(date -Iseconds)] on_stop: deferred copy completed -> $DEST" >> "$LOG_DIR/on_stop.log"

      # For Coco sessions: archive transcript if coco-log has entries for this session
      if [[ "$AGENT_TYPE" == "coco" ]] && grep -q "session: $SESSION_ID" "$SANCTUM_HOME/experiments/data/coco-log.yaml" 2>/dev/null; then
        mkdir -p "$COCO_TRANSCRIPT_DIR"
        cp "$TRANSCRIPT_PATH" "${COCO_TRANSCRIPT_DIR}/${SESSION_ID}.jsonl"
        echo "[$(date -Iseconds)] on_stop: coco transcript archived -> ${COCO_TRANSCRIPT_DIR}/${SESSION_ID}.jsonl" >> "$LOG_DIR/on_stop.log"
      fi

      exit 0
    fi
  done
  echo "[$(date -Iseconds)] on_stop: timed out waiting for transcript to stabilize" >> "$LOG_DIR/on_stop.log"
) &
disown $!
