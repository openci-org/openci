#!/bin/bash

NUM_WORKERS=${1:-2}
SA_PATH=${2:-~/service-account.json}
SESSION_NAME="openci-workers"

if ! command -v tmux &> /dev/null; then
  echo "Error: tmux is not installed. Install it with: brew install tmux"
  exit 1
fi

if ! command -v openci-worker &> /dev/null; then
  echo "Error: openci-worker is not installed. Install it with:"
  echo "  brew tap open-ci-io/tap && brew install openci-worker"
  exit 1
fi

if [ ! -f "$SA_PATH" ]; then
  echo "Error: Service account file not found: $SA_PATH"
  exit 1
fi

tmux kill-session -t "$SESSION_NAME" 2>/dev/null

tmux new-session -d -s "$SESSION_NAME" \
  "openci-worker --service-account $SA_PATH --worker-id worker-1"

for ((i = 2; i <= NUM_WORKERS; i++)); do
  tmux split-window -t "$SESSION_NAME" \
    "openci-worker --service-account $SA_PATH --worker-id worker-$i"
  tmux select-layout -t "$SESSION_NAME" tiled
done

tmux attach-session -t "$SESSION_NAME"
