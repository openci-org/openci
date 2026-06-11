#!/bin/bash

SCRIPT_VERSION="3.2.0"
PLATFORM="mac"

# Homebrew と Dart へのパスを通す
export PATH="/opt/homebrew/bin:/Users/admin/.local/node/current/bin:$PATH"

CREDENTIALS_FILE="./worker_credentials.json"
SESSION_NAME="openci-workers"
BIN_PATH="dart"

if [ ! -f "$CREDENTIALS_FILE" ]; then
  echo "Error: Credentials file not found at $CREDENTIALS_FILE"
  exit 1
fi

if ! command -v "$BIN_PATH" &> /dev/null; then
  echo "Error: dart command not found. Please install Dart SDK."
  exit 1
fi

if ! command -v tmux &> /dev/null; then
  echo "Error: tmux is not installed. Install it with: brew install tmux"
  exit 1
fi

# 既存の同名 tmux セッションをキル
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

MACHINE_INDEX=1
for i in "$@"; do
  case $i in
    -m=*|--machine-index=*)
      MACHINE_INDEX="${i#*=}"
      shift
      ;;
  esac
done

echo "Starting OpenCI Workers for platform: $PLATFORM, machine-index: $MACHINE_INDEX..."

node -e "
const fs = require('fs');
const execSync = require('child_process').execSync;
const platform = '$PLATFORM';
const binPath = '$BIN_PATH';
const sessionName = '$SESSION_NAME';
const machineIndex = parseInt('$MACHINE_INDEX', 10);

const creds = JSON.parse(fs.readFileSync('$CREDENTIALS_FILE', 'utf8'));
const platformCreds = creds.filter(c => c.platform === platform);

if (platformCreds.length === 0) {
  console.log('No credentials found for platform: ' + platform);
  process.exit(1);
}

// machineIndex = 1 -> indices 0, 1 (worker-mac-1, worker-mac-2)
// machineIndex = 2 -> indices 2, 3 (worker-mac-3, worker-mac-4)
// etc.
const startIndex = (machineIndex - 1) * 2;
const endIndex = startIndex + 2;

const activeCreds = platformCreds.slice(startIndex, endIndex);

if (activeCreds.length === 0) {
  console.log('No credentials assigned for machine index: ' + machineIndex);
  process.exit(1);
}

activeCreds.forEach((cred, index) => {
  const email = cred.email;
  const password = cred.password;
  
  // dart install でビルドされた AOT バイナリを直接実行
  const binaryPath = '/Users/admin/Library/Application Support/Dart/install/bin/openci_worker';
  const cmd = \`OPENCI_PROJECT_ID=\"openci-b1b91\" OPENCI_API_KEY=\"AIzaSyCvYYkNYRMsTzlei8rWRO0WTkT_YRq9LIs\" OPENCI_SERVER_URL=\"https://api.openci.org\" OPENCI_EMAIL=\"\${email}\" OPENCI_PASSWORD=\"\${password}\" '\${binaryPath}' --supervised\`;
  
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

