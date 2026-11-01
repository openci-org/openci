#!/bin/bash
set -euo pipefail

python=/usr/bin/python3
config=/usr/local/share/openci-image/toolchain.json
value() { "$python" -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$config" "$1"; }
[[ $(id -un) == admin && $(uname -m) == arm64 && $(sysctl -n hw.model) == VirtualMac* ]]
[[ $(sw_vers -productVersion) == "$(value macos_version)" ]]
[[ $(xcodebuild -version) == "$(printf 'Xcode %s\nBuild version %s' "$(value xcode_version)" "$(value xcode_build)")" ]]
[[ $(xcrun --sdk iphoneos --show-sdk-version) == "$(value iphoneos_sdk_version)" ]]
xcrun simctl list runtimes --json | "$python" -c 'import json,sys; assert any(r["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-") and r["version"] == sys.argv[1] and r["isAvailable"] for r in json.load(sys.stdin)["runtimes"])' "$(value ios_runtime_version)"
test -x "$HOME/fvm/default/bin/flutter"
[[ $(fvm --version) == "$(value fvm_version)" ]]
[[ $(flutter --version --machine | "$python" -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])') == "$(value flutter_version)" ]]
[[ $(go version) == "go version go$(value go_version) darwin/arm64" ]]
java -version 2>&1 | grep -F -- "$(value java_runtime_version)"
python="$(mise where "python@$(value python_version)")/bin/python3"
[[ $($python --version) == "Python $(value python_version)" ]]
pod --version
fastlane --version
ruby --version
node --version
shorebird --version | grep -F -- "Shorebird $(value shorebird_version) "
[[ $(git -C "$HOME/.shorebird" rev-parse HEAD) == "$(value shorebird_commit)" ]]
[[ $(app-store-connect --version | tail -1) == "app-store-connect $(value codemagic_version)" ]]
codemagic="/opt/codemagic-cli-tools/$(value codemagic_version)"
[[ $("$codemagic/bin/python" -c 'import importlib.metadata; print(importlib.metadata.version("codemagic-cli-tools"))') == "$(value codemagic_version)" ]]

sdk="$HOME/Library/Android/sdk"
grep -Fx "Pkg.Revision=$(value android_commandline_tools_version)" "$sdk/cmdline-tools/latest/source.properties"
grep -Fx "Pkg.Revision=$(value android_platform_tools_version)" "$sdk/platform-tools/source.properties"
while IFS= read -r package; do
  test -f "$sdk/${package//;/\/}/package.xml"
done < <("$python" -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["android_packages"]))' "$config")

# Only test for credentials; never print their contents into build logs.
for credential in \
  "$HOME/.aws/credentials" "$HOME/.config/gcloud/application_default_credentials.json" \
  "$HOME/.config/gcloud/credentials.db" \
  "$HOME/.config/gh/hosts.yml" "$HOME/.netrc" "$HOME/.git-credentials" \
  "$HOME/.docker/config.json" "$HOME/.pub-cache/credentials.json" \
  "$HOME/Library/Application Support/shorebird/credentials.json" \
  "$HOME/.config/shorebird/credentials.json" "$HOME/.config/dart/pub-credentials.json" \
  "$HOME/Library/Application Support/dart/pub-credentials.json" \
  "$HOME/actions-runner/.credentials"; do
  if [[ -s "$credential" ]]; then
    printf 'Refusing to bake credentials: %s\n' "$credential" >&2
    exit 1
  fi
done
if git config --global --get-regexp 'credential\..*password|http\..*extraheader' >/dev/null 2>&1; then
  echo 'Refusing to bake Git authentication configuration' >&2
  exit 1
fi
identities=$(security find-identity -p codesigning)
if grep -Eq '^[[:space:]]+[0-9]+\)' <<< "$identities"; then
  echo 'Refusing to bake signing identities' >&2
  exit 1
fi
echo OPENCI_IMAGE_TOOLCHAIN_VERIFIED
