#!/usr/bin/env bash
# Read and consume stdin completely to prevent blocking
cat > /dev/null

# Debounce lock file (user-scoped to avoid permission issues)
LOCK_FILE="/tmp/antigravity_notify_stop_${USER:-default}.lock"
NOW=$(date +%s)

if [ -f "$LOCK_FILE" ]; then
  LAST_RUN=$(cat "$LOCK_FILE" 2>/dev/null || echo 0)
  # Validate that LAST_RUN is a valid integer
  case "$LAST_RUN" in
    ''|*[!0-9]*) LAST_RUN=0 ;;
  esac

  DIFF=$((NOW - LAST_RUN))
  if [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt 2 ]; then
    # Return valid empty JSON and exit early
    echo "{}"
    exit 0
  fi
fi

echo "$NOW" > "$LOCK_FILE" 2>/dev/null || true

# Play sound and trigger desktop notification asynchronously on macOS
(
  if command -v afplay &>/dev/null && [ -f "/System/Library/Sounds/Glass.aiff" ]; then
    afplay /System/Library/Sounds/Glass.aiff &
  fi

  if command -v osascript &>/dev/null; then
    osascript -e 'display notification "作業が完了しました" with title "Antigravity"' &
  fi
) 2>/dev/null

# Always return valid JSON for the Stop hook contract
echo "{}"
