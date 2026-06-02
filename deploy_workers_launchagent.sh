#!/bin/bash
set -e

# Deploys the OpenCI worker(s) as per-user LaunchAgents inside the admin GUI
# (Aqua) session on each Mac worker host. Runs TWO workers per host.
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
#     /usr/bin/nc) keeps that traffic exempt.
#
# Two workers per host is safe because openci_worker_cli >= 0.10.27 assigns
# each worker a distinct MAC (derived from its worker number) to its cloned VM,
# so two VMs on the same host don't collide on the shared vmnet bridge.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AVF_DART_VER="0.1.16"
HELPER_BIN="${SCRIPT_DIR}/packages/avf_dart/.dart_tool/avf_dart/avf_helper"
WORKER_BIN="${SCRIPT_DIR}/apps/openci_worker_cli/build/cli/macos_arm64/bundle/bin/openci_worker_cli"
LABEL_PREFIX="org.openci.worker"

# Worker credentials are read from worker_credentials.json (never hardcoded
# here). The script only maps each host IP to its workerIds; the email and
# password for each workerId are looked up from the JSON at deploy time.
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

# Copy binaries and stop every previous worker/agent on the host.
prep_host() {
  local host=$1
  echo "=== Preparing $host (binaries + stop old workers) ==="

  remote "$host" "mkdir -p '/Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart'"
  sshpass -p admin scp "${SSH_OPTS[@]}" "$HELPER_BIN" \
    "admin@$host:/Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart/avf_helper"
  remote "$host" "chmod +x '/Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart/avf_helper'"

  echo "Stopping previous workers on $host..."
  remote "$host" "for L in ${LABEL_PREFIX} ${LABEL_PREFIX}.1 ${LABEL_PREFIX}.2; do \
      launchctl bootout gui/\$(id -u admin)/\$L 2>/dev/null; \
      echo admin | sudo -S launchctl bootout system/\$L 2>/dev/null; \
      echo admin | sudo -S rm -f /Library/LaunchDaemons/\$L.plist /Library/LaunchAgents/\$L.plist; \
    done; \
    echo admin | sudo -S pkill -9 -f openci_worker 2>/dev/null; \
    echo admin | sudo -S pkill -9 -f avf_helper 2>/dev/null; true"

  sshpass -p admin scp "${SSH_OPTS[@]}" "$WORKER_BIN" \
    "admin@$host:/Users/admin/Library/Application Support/Dart/install/bin/openci_worker"
  remote "$host" "chmod +x '/Users/admin/Library/Application Support/Dart/install/bin/openci_worker'"
}

# Install and bootstrap one worker LaunchAgent (slot 1 or 2) on the host.
install_agent() {
  local host=$1 slot=$2 email=$3 pass=$4
  local label="${LABEL_PREFIX}.${slot}"
  local logf="/tmp/worker_${slot}.log"
  echo "--- $host: $label ($email) ---"

  # Write to a temp file WITHOUT sudo first (so the heredoc is the only thing on
  # stdin), then `sudo cp` it into place. Never combine `sudo -S` (reads the
  # password from stdin) with a heredoc on the same command.
  remote "$host" "cat > /tmp/${label}.plist <<'PLIST'
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
  <key>Label</key>
  <string>${label}</string>
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
  <string>${logf}</string>
  <key>StandardErrorPath</key>
  <string>${logf}</string>
</dict>
</plist>
PLIST
plutil -lint /tmp/${label}.plist
echo admin | sudo -S cp /tmp/${label}.plist /Library/LaunchAgents/${label}.plist
echo admin | sudo -S chown root:wheel /Library/LaunchAgents/${label}.plist
echo admin | sudo -S chmod 644 /Library/LaunchAgents/${label}.plist"

  remote "$host" "launchctl bootstrap gui/\$(id -u admin) /Library/LaunchAgents/${label}.plist; \
    launchctl enable gui/\$(id -u admin)/${label}; true"
  sleep 2
  remote "$host" "launchctl print gui/\$(id -u admin)/${label} 2>/dev/null | grep -E 'state =|pid =' | head -2"
}

# host IP -> two workerIds (two workers per host). Credentials come from JSON.
HOSTS=(
  "100.104.145.82:worker-mac-1:worker-mac-2"
  "100.83.142.124:worker-mac-3:worker-mac-4"
  "100.112.30.120:worker-mac-5:worker-mac-6"
  "100.66.12.37:worker-mac-7:worker-mac-8"
)

for entry in "${HOSTS[@]}"; do
  IFS=':' read -r host w1 w2 <<< "$entry"
  prep_host "$host"
  slot=1
  for wid in "$w1" "$w2"; do
    email="$(cred_field "$wid" email)"
    pass="$(cred_field "$wid" password)"
    if [ -z "$email" ] || [ -z "$pass" ]; then
      echo "Error: missing credentials for $wid in $CREDENTIALS_FILE"
      exit 1
    fi
    install_agent "$host" "$slot" "$email" "$pass"
    slot=$((slot + 1))
  done
done

echo "=== All LaunchAgent deployments done (2 workers/host) ==="
