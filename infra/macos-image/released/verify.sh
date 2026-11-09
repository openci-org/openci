#!/bin/bash
set -euo pipefail
config=/usr/local/share/openci-image/toolchain.json
value() { /usr/bin/python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$config" "$1"; }
[[ $(sw_vers -productVersion) == "$(value macos_version)" && $(sw_vers -buildVersion) == "$(value macos_build)" ]]
if [[ ${OPENCI_EXPECT_RELEASE_OS:-0} == 1 ]]; then
  [[ $(readlink /var/db/timezone/zoneinfo) == "/var/db/timezone/tz/$(value release_timezone_data)/zoneinfo" ]]
fi
[[ $(xcodebuild -version) == "$(printf 'Xcode %s\nBuild version %s' "$(value xcode_version)" "$(value xcode_build)")" ]]
[[ $(xcrun --sdk iphoneos --show-sdk-version) == "$(value iphoneos_sdk)" ]]
xcrun simctl list runtimes --json | /usr/bin/python3 -c 'import json,sys; assert any(r["isAvailable"] and r["buildversion"]==sys.argv[1] for r in json.load(sys.stdin)["runtimes"])' "$(value ios_runtime_build)"
[[ $(fvm --version) == 4.1.4 && $(go version) == 'go version go1.27.3 darwin/arm64' ]]
[[ $(/opt/homebrew/bin/python3.13 --version) == 'Python 3.13.15' ]]
java -version 2>&1 | grep -F '17.0.20+8'
[[ $(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' '/Applications/Android Studio.app/Contents/Info.plist') == AI-261.26222.65.2614.16379836 ]]
sdk="$HOME/Library/Android/sdk"
grep -Fx 'Pkg.Revision=22.0' "$sdk/cmdline-tools/latest/source.properties"
grep -Fx 'Pkg.Revision=37.0.1' "$sdk/platform-tools/source.properties"
/usr/bin/python3 - "$config" "$sdk" <<'PY'
import json, sys
from pathlib import Path
from xml.etree import ElementTree
for package, expected in json.loads(Path(sys.argv[1]).read_text())["android_packages"].items():
    root = ElementTree.parse(Path(sys.argv[2]).joinpath(*package.split(";"), "package.xml")).getroot()
    installed = root.find("localPackage")
    assert installed is not None and installed.get("path") == package, package
    actual = ".".join(part.text for part in installed.find("revision") if part.text)
    assert actual == expected, (package, actual, expected)
PY
flutter --version --machine | /usr/bin/python3 -c 'import json,sys; sdk=json.load(sys.stdin); assert [sdk[k] for k in ("frameworkVersion","frameworkRevision","engineRevision","dartSdkVersion")] == sys.argv[1:]' \
  "$(value flutter_version)" "$(value flutter_revision)" "$(value flutter_engine_revision)" "$(value dart_version)"
[[ $(git -C "$HOME/.shorebird" rev-parse HEAD) == "$(value shorebird_cli_revision)" ]]
fork="$HOME/.shorebird/bin/cache/flutter/$(value shorebird_flutter_revision)"
[[ $(git -C "$fork" rev-parse HEAD) == "$(value shorebird_flutter_revision)" && $(cat "$fork/bin/internal/engine.version") == "$(value shorebird_engine_revision)" ]]
test -f "$fork/.shorebird_precache"
app-store-connect --version | grep -F 'app-store-connect 0.69.1'
xcodeproj --version | grep -F '1.27.0'
for path in "$HOME/.aws/credentials" "$HOME/.config/gcloud/application_default_credentials.json" "$HOME/.config/gcloud/credentials.db" "$HOME/.config/gh/hosts.yml" "$HOME/.netrc" "$HOME/.git-credentials" "$HOME/.docker/config.json" "$HOME/Library/Application Support/shorebird/credentials.json" "$HOME/Library/Application Support/dart/pub-credentials.json"; do
  if [[ -s "$path" ]]; then echo "Found credentials in $path" >&2; exit 1; fi
done
if git config --global --get-regexp 'credential\..*password|http\..*extraheader' >/dev/null 2>&1; then exit 1; fi
identities=$(security find-identity -p codesigning)
if grep -Eq '^[[:space:]]+[0-9]+\)' <<< "$identities"; then exit 1; fi
echo OPENCI_IMAGE_TOOLCHAIN_VERIFIED
