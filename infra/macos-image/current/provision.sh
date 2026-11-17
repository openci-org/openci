#!/bin/bash
set -euo pipefail

[[ $(id -un) == admin && $HOME == /Users/admin && $(sysctl -n hw.model) == VirtualMac* ]]
config=/usr/local/share/openci-image/current.json
version=$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["patrol_cli_version"])' "$config")

dart pub global activate patrol_cli "$version"
# Keep Patrol available to the executor's non-login shell and custom scripts.
sudo -n mkdir -p /usr/local/bin
sudo -n ln -sfn "$HOME/.pub-cache/bin/patrol" /usr/local/bin/patrol
cp "$HOME/.pub-cache/global_packages/patrol_cli/pubspec.lock" \
  /usr/local/share/openci-image/patrol-cli-pubspec.lock
