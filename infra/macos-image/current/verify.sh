#!/bin/bash
set -euo pipefail

[[ $(id -un) == admin && $HOME == /Users/admin && $(sysctl -n hw.model) == VirtualMac* ]]
config=/usr/local/share/openci-image/current.json
version=$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["patrol_cli_version"])' "$config")
mise_bin=$(command -v mise || true)

# Deliberately omit .pub-cache/bin, as some callers use a minimal CI PATH.
export PATH="$HOME/fvm/default/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# A preinstalled CLI must work without contacting pub.dev to activate packages.
export PUB_HOSTED_URL=http://127.0.0.1:9
[[ $(patrol --version) == "patrol_cli v$version" ]]
[[ $(dart pub global run patrol_cli:main --version) == "patrol_cli v$version" ]]
patrol test --help >/dev/null
patrol build android --help >/dev/null
patrol build ios --help >/dev/null
dart pub global list | grep -Fx "patrol_cli $version"

node_versions=$(/usr/bin/python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["node_versions"]))' "$config")
while IFS= read -r node_version; do
  [[ -n $node_version ]] || continue
  [[ -n $mise_bin ]]
  node_dir=$("$mise_bin" where "node@$node_version")
  [[ $("$node_dir/bin/node" --version) == "v$node_version" ]]
done <<< "$node_versions"

echo OPENCI_IMAGE_PATROL_VERIFIED
