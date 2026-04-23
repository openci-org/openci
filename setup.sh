#!/bin/bash
set -e

SCRIPT_VERSION="1.0.0"

NUM_WORKERS=${1:-2}
SA_PATH=${2:-~/service-account.json}
SESSION_NAME="openci-setup"
REPO_BASE="https://raw.githubusercontent.com/openci-org/openci/develop"
INSTALL_DIR="$HOME/.openci"

# 0. Download scripts to ~/.openci (always fetch latest)
mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO_BASE/setup.sh" -o "$INSTALL_DIR/setup.sh"
curl -fsSL "$REPO_BASE/start-workers.sh" -o "$INSTALL_DIR/start-workers.sh"
chmod +x "$INSTALL_DIR/setup.sh" "$INSTALL_DIR/start-workers.sh"

echo "============================================"
echo "  OpenCI Worker Setup v${SCRIPT_VERSION}"
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
NEED_PATH_UPDATE=false
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  NEED_PATH_UPDATE=true
  echo 'export PATH="$PATH":"$HOME/.local/bin"' >> ~/.zshrc
  export PATH="$PATH":"$HOME/.local/bin"
fi
DART_PUB_CACHE_BIN="${PUB_CACHE:-$HOME/.pub-cache}/bin"
if ! echo ":$PATH:" | grep -q ":$DART_PUB_CACHE_BIN:"; then
  NEED_PATH_UPDATE=true
  echo 'export PATH="$PATH":"${PUB_CACHE:-$HOME/.pub-cache}/bin"' >> ~/.zshrc
  export PATH="$PATH:$DART_PUB_CACHE_BIN"
fi
if [ "$NEED_PATH_UPDATE" = true ]; then
  echo "🔧 PATH configured"
else
  echo "✅ PATH already configured"
fi

# 3. tmux
if command -v tmux &> /dev/null; then
  echo "✅ tmux already installed"
else
  echo "📦 Installing tmux..."
  brew install tmux
fi

# 4. Enable tmux mouse mode for scrolling
if [ ! -f "$HOME/.tmux.conf" ] || ! grep -q "set -g mouse on" "$HOME/.tmux.conf" 2>/dev/null; then
  echo "set -g mouse on" >> "$HOME/.tmux.conf"
  echo "set -g history-limit 50000" >> "$HOME/.tmux.conf"
fi

# 5. If not in tmux, start remaining work in detached tmux session
if [ -z "$TMUX" ]; then
  echo ""
  tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
  tmux new-session -d -s "$SESSION_NAME" "$INSTALL_DIR/setup.sh $NUM_WORKERS $SA_PATH"
  echo "✅ Setup is running in tmux session."
  echo "   Attach with: tmux attach -t openci-workers"
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
if lume ls 2>/dev/null | grep -q "tahoe-base_v1.1.1"; then
  echo "✅ VM image already pulled"
else
  echo "📦 Pulling VM image (this may take a while)..."
  lume pull tahoe-base:v1.1.1 --organization openci-org
fi

# 7. Worker CLI
if ! command -v dart &> /dev/null; then
  echo "📦 Installing Dart SDK..."
  brew tap dart-lang/dart
  brew install dart
fi

if command -v openci_worker &> /dev/null; then
  echo "✅ openci_worker already installed"
else
  echo "📦 Installing Worker CLI..."
  dart pub global activate openci_worker_cli
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

  WORKER_CMD='while true; do openci_worker --service-account '"$SA_PATH"' --worker-id WORKER_ID; echo "🔄 Worker exited. Restarting in 3s..."; sleep 3; done'

  for ((i = 2; i <= NUM_WORKERS; i++)); do
    tmux split-window "$(echo "$WORKER_CMD" | sed "s/WORKER_ID/worker-$i/")"
    tmux select-layout tiled
  done

  while true; do
    openci_worker --service-account "$SA_PATH_EXPANDED" --worker-id worker-1
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
