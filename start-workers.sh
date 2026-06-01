#!/bin/bash

SCRIPT_VERSION="3.0.0"

# OS環境からプラットフォーム（mac または linux）を自動判別
PLATFORM="mac"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  PLATFORM="linux"
fi

CREDENTIALS_FILE="./worker_credentials.json"
SESSION_NAME="openci-workers"
BIN_PATH="./apps/openci_worker_cli/build/worker_bundle/bundle/bin/openci_worker_cli"

if [ ! -f "$CREDENTIALS_FILE" ]; then
  echo "Error: Credentials file not found at $CREDENTIALS_FILE"
  exit 1
fi

if [ ! -f "$BIN_PATH" ]; then
  echo "Error: Worker binary not found at $BIN_PATH. Please compile it first."
  exit 1
fi

if ! command -v tmux &> /dev/null; then
  echo "Error: tmux is not installed. Install it with: brew install tmux (or apt install tmux)"
  exit 1
fi

# 既存の同名 tmux セッションをキル
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

echo "Starting OpenCI Workers for platform: $PLATFORM..."

# Node.js を利用して JSON のパースおよび tmux コマンドの組み立てを行います
node -e "
const fs = require('fs');
const execSync = require('child_process').execSync;
const platform = '$PLATFORM';
const sessionName = '$SESSION_NAME';
const binPath = '$BIN_PATH';

const creds = JSON.parse(fs.readFileSync('$CREDENTIALS_FILE', 'utf8'));
const platformCreds = creds.filter(c => c.platform === platform);

if (platformCreds.length === 0) {
  console.log('No credentials found for platform: ' + platform);
  process.exit(1);
}

platformCreds.forEach((cred, index) => {
  const email = cred.email;
  const password = cred.password;
  const cmd = \`\${binPath} --supervised --email \"\${email}\" --password \"\${password}\"\`;

  if (index === 0) {
    execSync(\`tmux new-session -d -s \${sessionName} \"\${cmd}\"\`);
  } else {
    execSync(\`tmux split-window -t \${sessionName} \"\${cmd}\"\`);
    execSync(\`tmux select-layout -t \${sessionName} tiled\`);
  }
  console.log(\`✅ Launched worker \${cred.workerId} (\${email}) in tmux\`);
});
"

if [ $? -ne 0 ]; then
  echo "Failed to start workers."
  exit 1
fi

# tmux セッションにアタッチ
if [ -n "$TMUX" ]; then
  tmux switch-client -t "$SESSION_NAME"
else
  tmux attach-session -t "$SESSION_NAME"
fi
