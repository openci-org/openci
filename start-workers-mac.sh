#!/bin/bash

SCRIPT_VERSION="3.1.0"
PLATFORM="mac"

# Homebrew と Dart へのパスを通す
export PATH="/opt/homebrew/bin:/Users/admin/.local/node/current/bin:$PATH"

CREDENTIALS_FILE="./worker_credentials.json"
BIN_PATH="dart"

if [ ! -f "$CREDENTIALS_FILE" ]; then
  echo "Error: Credentials file not found at $CREDENTIALS_FILE"
  exit 1
fi

if ! command -v "$BIN_PATH" &> /dev/null; then
  echo "Error: dart command not found. Please install Dart SDK."
  exit 1
fi

# 起動前に最新の openci_worker_cli をアクティベート
echo "Activating latest openci_worker_cli..."
dart pub global activate openci_worker_cli

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

activeCreds.forEach((cred) => {
  const email = cred.email;
  const password = cred.password;
  const logFile = \`/Users/admin/openci-worker-\${cred.workerId}.log\`;
  
  // AOTバイナリの代わりに dart pub global run openci_worker_cli を使用
  const cmd = \`nohup \${binPath} pub global run openci_worker_cli --supervised --email \"\${email}\" --password \"\${password}\" > \${logFile} 2>&1 &\`;
  
  execSync(cmd);
  console.log(\`✅ Launched worker \${cred.workerId} (\${email}) in background (log: \${logFile})\`);
});
"

if [ $? -ne 0 ]; then
  echo "Failed to start workers."
  exit 1
fi

echo "Workers successfully started in background."
