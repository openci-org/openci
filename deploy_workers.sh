#!/bin/bash
set -e

# Files to transfer
AVF_DART_VER="0.1.14"
HELPER_BIN="/Users/mafreud/Developers/openci_inc/openci/packages/avf_dart/.dart_tool/avf_dart/avf_helper"
WORKER_BIN="/Users/mafreud/Developers/openci_inc/openci/apps/openci_worker_cli/build/bundle/bin/openci_worker_cli"

echo "=== Local check ==="
if [ ! -f "$HELPER_BIN" ]; then
  echo "Error: $HELPER_BIN not found"
  exit 1
fi
if [ ! -f "$WORKER_BIN" ]; then
  echo "Error: $WORKER_BIN not found"
  exit 1
fi

deploy_to_host() {
  local host=$1
  local email1=$2
  local pass1=$3

  echo "=== Deploying and launching on $host ==="

  # Create pub-cache directory for helper
  sshpass -p admin ssh -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$host \
    "mkdir -p /Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart"
  
  # Copy avf_helper to versioned path
  sshpass -p admin scp -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$HELPER_BIN" admin@$host:/Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart/avf_helper
    
  # Set executable permission for helper
  sshpass -p admin ssh -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$host \
    "chmod +x /Users/admin/.pub-cache/hosted/pub.dev/avf_dart-${AVF_DART_VER}/.dart_tool/avf_dart/avf_helper"
    
  # Kill running openci_worker and leftover virtualization processes
  echo "Killing running openci_worker and potential zombie VM processes on $host..."
  sshpass -p admin ssh -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$host \
    "pkill -f openci_worker || true; pkill -f avf_helper || true; pkill -f Virtualization || true"
  
  # Copy openci_worker
  sshpass -p admin scp -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$WORKER_BIN" admin@$host:"/Users/admin/Library/Application Support/Dart/install/bin/openci_worker"
    
  # Set executable permission for worker
  sshpass -p admin ssh -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$host \
    "chmod +x \"/Users/admin/Library/Application Support/Dart/install/bin/openci_worker\""
 
  # Launch ONLY ONE worker on this host (to prevent MAC address conflicts with VM simultaneous boots)
  echo "Launching worker on $host..."
  sshpass -p admin ssh -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$host \
    "nohup \"/Users/admin/Library/Application Support/Dart/install/bin/openci_worker\" --supervised --email $email1 --password $pass1 > /tmp/worker_1.log 2>&1 &"
 
  echo "Verifying running processes on $host..."
  sleep 2
  sshpass -p admin ssh -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$host \
    "ps aux | grep openci_worker"
}

# Mac 1
deploy_to_host "100.104.145.82" "m.aoki+worker-mac-1@openci.org" "vENpV8Rd/e1Oy9VC"
sleep 5

# Mac 2
deploy_to_host "100.83.142.124" "m.aoki+worker-mac-3@openci.org" "KWmvrTMjVPUm1Dh8"
sleep 5

# Mac 3
deploy_to_host "100.112.30.120" "m.aoki+worker-mac-5@openci.org" "S24zlaVwxoDKZLAo"
sleep 5

# Mac 4
deploy_to_host "100.66.12.37" "m.aoki+worker-mac-7@openci.org" "QYEjn0ANDjJ4c+d0"

echo "=== All Deployments and Launches Done ==="
