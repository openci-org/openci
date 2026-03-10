#!/bin/bash
set -e

NUM_WORKERS=${1:-2}
SA_PATH=${2:-~/service-account.json}
SESSION_NAME="openci-setup"
REPO_BASE="https://raw.githubusercontent.com/open-ci-io/openci/develop"
INSTALL_DIR="$HOME/.openci"

# 0. Download scripts to ~/.openci (always fetch latest)
mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO_BASE/setup.sh" -o "$INSTALL_DIR/setup.sh"
curl -fsSL "$REPO_BASE/start-workers.sh" -o "$INSTALL_DIR/start-workers.sh"
chmod +x "$INSTALL_DIR/setup.sh" "$INSTALL_DIR/start-workers.sh"

echo "============================================"
echo "  OpenCI Worker Setup"
echo "============================================"
echo ""

# 1. Homebrew
if command -v brew &> /dev/null; then
  echo "✅ Homebrew already installed"
else
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. PATH setup
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo "✅ PATH already configured"
else
  echo "🔧 Configuring PATH..."
  echo 'export PATH="$PATH":"$HOME/.local/bin"' >> ~/.zshrc
  export PATH="$PATH":"$HOME/.local/bin"
fi

# 3. tmux
if command -v tmux &> /dev/null; then
  echo "✅ tmux already installed"
else
  echo "📦 Installing tmux..."
  brew install tmux
fi

# 4. If not in tmux, start remaining work in detached tmux session
if [ -z "$TMUX" ]; then
  echo ""
  tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
  tmux new-session -d -s "$SESSION_NAME" "$INSTALL_DIR/setup.sh $NUM_WORKERS $SA_PATH"
  echo "✅ Setup is running in tmux session '$SESSION_NAME'."
  echo "   Attach with: tmux attach -t $SESSION_NAME"
  echo ""
  exit 0
fi

# === From here, running inside tmux (safe from SSH disconnect) ===

# 5. Lume
if command -v lume &> /dev/null; then
  echo "✅ Lume already installed"
else
  echo "📦 Installing Lume..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"
fi

# 6. VM image
if lume ls 2>/dev/null | grep -q "tahoe-base"; then
  echo "✅ VM image already pulled"
else
  echo "📦 Pulling VM image (this may take a while)..."
  lume pull tahoe-base:v1.0.0 --organization open-ci-io
fi

# 7. Worker CLI
if command -v openci-worker &> /dev/null; then
  echo "✅ openci-worker already installed"
else
  echo "📦 Installing Worker CLI..."
  brew tap open-ci-io/tap
  brew install openci-worker
fi

echo ""
echo "============================================"
echo "  ✅ Setup complete!"
echo "============================================"
echo ""

# 8. Start workers if service account exists
SA_PATH_EXPANDED="${SA_PATH/#\~/$HOME}"
if [ -f "$SA_PATH_EXPANDED" ]; then
  echo "Starting $NUM_WORKERS worker(s)..."
  echo ""

  tmux rename-session -t "$SESSION_NAME" "openci-workers" 2>/dev/null || true

  WORKER_CMD='while true; do openci-worker --service-account '"$SA_PATH"' --worker-id WORKER_ID; echo "🔄 Worker exited. Restarting in 3s..."; sleep 3; done'

  for ((i = 2; i <= NUM_WORKERS; i++)); do
    tmux split-window "$(echo "$WORKER_CMD" | sed "s/WORKER_ID/worker-$i/")"
    tmux select-layout tiled
  done

  while true; do
    openci-worker --service-account "$SA_PATH_EXPANDED" --worker-id worker-1
    echo "🔄 Worker exited. Restarting in 3s..."
    sleep 3
  done
else
  echo "⚠️  Service account file not found: $SA_PATH"
  echo ""
  echo "Next steps:"
  echo "  1. Place your service account JSON at $SA_PATH"
  echo "  2. Start workers: $INSTALL_DIR/start-workers.sh $NUM_WORKERS $SA_PATH"
  echo ""
  echo "Press any key to exit..."
  read -n 1
fi
