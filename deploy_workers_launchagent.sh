#!/bin/bash
set -e

# Deploys the OpenCI worker as a per-user LaunchAgent running inside the admin
# GUI (Aqua) session on each Mac worker.
#
# Why a GUI-session LaunchAgent (and not nohup or a root LaunchDaemon)?
#   * Apple's Virtualization.framework needs the logged-in user's security
#     session (keychain) to boot a macOS VM. A root system LaunchDaemon fails
#     with "Unable to access security information".
#   * On macOS 15+/26, Local Network privacy blocks a process launched via
#     `ssh + nohup` (it loses the SSH exemption when the session closes) from
#     reaching the VM's local network address ("No route to host"). A
#     launchd-managed agent plus talking to the guest exclusively through the
#     macOS system binaries (/usr/bin/ssh, /usr/bin/scp, /sbin/ping,
#     /usr/bin/nc) keeps that traffic exempt. The worker binary must be
#     openci_worker_cli >= 0.10.26 for the system-binary SSH path.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AVF_DART_VER="0.1.15"
HELPER_BIN="${SCRIPT_DIR}/packages/avf_dart/.dart_tool/avf_dart/avf_helper"
WORKER_BIN="${SCRIPT_DIR}/apps/openci_worker_cli/build/cli/macos_arm64/bundle/bin/openci_worker_cli"
LABEL="org.openci.worker"

# Worker credentials are read from worker_credentials.json (never hardcoded
# here). The script only maps each worker host IP to a workerId; the email and
# password for that workerId are looked up from the JSON at deploy time.
CREDENTIALS_FILE="${SCRIPT_DIR}/worker_credentials.json"

echo "=== Local check ==="
[ -f "$HELPER_BIN" ] || { echo "Error: $HELPER_BIN not found"; exit 1; }
[ -f "$WORKER_BIN" ] || { echo "Error: $WORKER_BIN not found"; exit 1; }
[ -f "$CREDENTIALS_FILE" ] || { echo "Error: $CREDENTIALS_FILE not found"; exit 1; }

# cred_field <workerId> <email|password>: extract a field from worker_credentials.json
cred_field() {
  python3 -c "import json,sys; d=json.load(open('$CREDENTIALS_FILE')); print(next(c['$2'] for c in d if c['workerId']=='$1'))"
}

SSH_OPTS=(-o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

remote() { sshpass -p admin ssh "${SSH_OPTS[@]}" "admin@$1" "$2"; }

deploy_to_host() {
  local host=$1 email=$2 pass=$3

  echo "=== Deploying LaunchAgent worker on $host ==="

  # 1. Copy the avf_helper to the versioned pub-cache path
  remote "$host" "mkdir -p '/Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart'"
  sshpass -p admin scp "${SSH_OPTS[@]}" "$HELPER_BIN" \
    "admin@$host:/Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart/avf_helper"
  remote "$host" "chmod +x '/Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart/avf_helper'"

  # 2. Stop any previous worker (nohup processes, old LaunchDaemon/Agent)
  echo "Stopping previous worker on $host..."
  remote "$host" "echo admin | sudo -S launchctl bootout system/${LABEL} 2>/dev/null; \
    launchctl bootout gui/\$(id -u admin)/${LABEL} 2>/dev/null; \
    echo admin | sudo -S rm -f /Library/LaunchDaemons/${LABEL}.plist; \
    echo admin | sudo -S pkill -9 -f openci_worker 2>/dev/null; \
    echo admin | sudo -S pkill -9 -f avf_helper 2>/dev/null; true"

  # 3. Copy the worker binary
  sshpass -p admin scp "${SSH_OPTS[@]}" "$WORKER_BIN" \
    "admin@$host:/Users/admin/Library/Application Support/Dart/install/bin/openci_worker"
  remote "$host" "chmod +x '/Users/admin/Library/Application Support/Dart/install/bin/openci_worker'"

  # 4. Write the LaunchAgent plist.
  #    Write to a temp file WITHOUT sudo first (so the heredoc is the only thing
  #    on stdin), then `sudo cp` it into place. Do NOT combine `sudo -S` (which
  #    reads the password from stdin) with a heredoc on the same command, or the
  #    heredoc body gets consumed as the sudo password and the file is corrupted.
  remote "$host" "cat > /tmp/${LABEL}.plist <<'PLIST'
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/admin/Library/Application Support/Dart/install/bin/openci_worker</string>
    <string>--supervised</string>
    <string>--email</string>
    <string>${email}</string>
    <string>--password</string>
    <string>${pass}</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/worker_1.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/worker_1.log</string>
</dict>
</plist>
PLIST
plutil -lint /tmp/${LABEL}.plist
echo admin | sudo -S cp /tmp/${LABEL}.plist /Library/LaunchAgents/${LABEL}.plist
echo admin | sudo -S chown root:wheel /Library/LaunchAgents/${LABEL}.plist
echo admin | sudo -S chmod 644 /Library/LaunchAgents/${LABEL}.plist"

  # 5. Bootstrap into the admin GUI session
  echo "Bootstrapping LaunchAgent on $host..."
  remote "$host" "launchctl bootstrap gui/\$(id -u admin) /Library/LaunchAgents/${LABEL}.plist; \
    launchctl enable gui/\$(id -u admin)/${LABEL}; true"

  sleep 2
  remote "$host" "launchctl print gui/\$(id -u admin)/${LABEL} 2>/dev/null | grep -E 'state =|pid =' | head -2"
}

# host IP -> workerId (one worker per host). Credentials come from the JSON.
HOSTS=(
  "100.104.145.82:worker-mac-1"
  "100.83.142.124:worker-mac-3"
  "100.112.30.120:worker-mac-5"
  "100.66.12.37:worker-mac-7"
)

for entry in "${HOSTS[@]}"; do
  host="${entry%%:*}"
  worker_id="${entry##*:}"
  email="$(cred_field "$worker_id" email)"
  pass="$(cred_field "$worker_id" password)"
  if [ -z "$email" ] || [ -z "$pass" ]; then
    echo "Error: missing credentials for $worker_id in $CREDENTIALS_FILE"
    exit 1
  fi
  deploy_to_host "$host" "$email" "$pass"
done

echo "=== All LaunchAgent deployments done ==="
