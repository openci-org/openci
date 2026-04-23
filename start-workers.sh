#!/bin/bash

SCRIPT_VERSION="1.0.0"

NUM_WORKERS=${1:-2}
SA_PATH=${2:-~/service-account.json}
SESSION_NAME="openci-workers"

# Ensure dart pub global executables are on PATH
DART_PUB_CACHE_BIN="${PUB_CACHE:-$HOME/.pub-cache}/bin"
if ! echo ":$PATH:" | grep -q ":$DART_PUB_CACHE_BIN:"; then
  export PATH="$PATH:$DART_PUB_CACHE_BIN"
fi

if ! command -v tmux &> /dev/null; then
  echo "Error: tmux is not installed. Install it with: brew install tmux"
  exit 1
fi

if ! command -v openci_worker &> /dev/null; then
  echo "Error: openci_worker is not installed. Install it with:"
  echo "  dart pub global activate openci_worker_cli"
  exit 1
fi

if [ ! -f "$SA_PATH" ]; then
  echo "Error: Service account file not found: $SA_PATH"
  exit 1
fi

WORKER_CMD='while true; do openci_worker --service-account '"$SA_PATH"' --worker-id WORKER_ID; echo "🔄 Worker exited. Restarting in 3s..."; sleep 3; done'

tmux kill-session -t "$SESSION_NAME" 2>/dev/null

tmux new-session -d -s "$SESSION_NAME" \
  "$(echo "$WORKER_CMD" | sed "s/WORKER_ID/worker-1/")"

for ((i = 2; i <= NUM_WORKERS; i++)); do
  tmux split-window -t "$SESSION_NAME" \
    "$(echo "$WORKER_CMD" | sed "s/WORKER_ID/worker-$i/")"
  tmux select-layout -t "$SESSION_NAME" tiled
done

if [ -n "$TMUX" ]; then
  tmux switch-client -t "$SESSION_NAME"
else
  tmux attach-session -t "$SESSION_NAME"
fi
