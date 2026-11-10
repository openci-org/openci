#!/bin/bash
set -euo pipefail
config=/usr/local/share/openci-image/toolchain.json
# Keep a pre-existing release login profile when it already resolves the
# pinned tools. The initial v0.1.0 foundation needs these exports.
check_login() {
  # The child shell must expand its own variables.
  # shellcheck disable=SC2016
  /usr/bin/env -i HOME="$HOME" USER=admin PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/zsh -lc \
    '[[ "$JAVA_HOME" == /Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home && "$ANDROID_SDK_ROOT" == "$HOME/Library/Android/sdk" && "$ANDROID_HOME" == "$ANDROID_SDK_ROOT" && "$(command -v adb)" == "$ANDROID_HOME/platform-tools/adb" && "$(command -v sdkmanager)" == "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]]'
}
if ! check_login; then
  cat >> "$HOME/.zshenv" <<'PROFILE'

# OpenCI Android toolchain
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
PROFILE
fi
check_login
revision=$(/usr/bin/python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["shorebird_flutter_revision"])' "$config")
version=$(/usr/bin/python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["flutter_version"])' "$config")
cache="$HOME/.shorebird/bin/cache/flutter"
default_checkout="$cache/$(cat "$HOME/.shorebird/bin/internal/flutter.version")"
# Shorebird resolves --flutter-version through this ref in its default checkout.
ref="refs/remotes/origin/flutter_release/$version"
if [[ $(git -C "$default_checkout" rev-parse --verify "$ref" 2>/dev/null || true) != "$revision" ]]; then
  git -C "$default_checkout" fetch origin "refs/heads/flutter_release/$version:$ref"
fi
resolved=$(git -C "$default_checkout" rev-parse --verify "$ref")
[[ $resolved == "$revision" ]]
flutter="$cache/$resolved/bin/flutter"
export FLUTTER_STORAGE_BASE_URL=https://download.shorebird.dev
"$flutter" --version --machine | /usr/bin/python3 -c 'import json,sys; sdk=json.load(sys.stdin); assert (sdk["frameworkVersion"],sdk["frameworkRevision"])==tuple(sys.argv[1:])' "$version" "$revision"
work=$(mktemp -d /private/tmp/openci-shorebird-smoke.XXXXXX)
trap 'rm -rf "$work"' EXIT
cd "$work"
"$flutter" create --platforms=ios,android --project-name shorebird_smoke app
cd app
"$flutter" test
"$flutter" build apk --release --target-platform android-arm64
"$flutter" build ios --release --no-codesign
test -s build/app/outputs/flutter-apk/app-release.apk
test -s build/ios/iphoneos/Runner.app/Runner
"$HOME/fvm/default/bin/flutter" --version --machine > "$work/standard.json"
"$flutter" --version --machine > "$work/shorebird.json"
/usr/bin/python3 - "$config" "$work" "$cache/$resolved" <<'PY'
import datetime, json, sys
from pathlib import Path
config_path, work, sdk = map(Path, sys.argv[1:])
lock = json.loads(config_path.read_text())
standard = json.loads((work / "standard.json").read_text())
fork = json.loads((work / "shorebird.json").read_text())
now = datetime.datetime.now(datetime.timezone.utc)
metadata = config_path.parent
(metadata / "flutter-sdk.json").write_text(json.dumps({
    "flutter_version": standard["frameworkVersion"], "framework_revision": standard["frameworkRevision"],
    "updated_at": now.date().isoformat(), "method": "Packer build verified on Android and unsigned iOS",
}, indent=2) + "\n")
(metadata / f"shorebird-flutter-{lock['flutter_version']}.json").write_text(json.dumps({
    "shorebird_cli": lock["shorebird_cli_version"], "shorebird_cli_revision": lock["shorebird_cli_revision"],
    "shorebird_flutter": lock["flutter_version"], "framework_revision": fork["frameworkRevision"],
    "flutter_reported_version": fork["frameworkVersion"], "engine_revision": lock["shorebird_engine_revision"],
    "sdk": str(sdk), "android_arm64_release": True, "ios_release": True,
    "default_flutter": standard["frameworkVersion"], "verified_at": now.isoformat(),
}, indent=2) + "\n")
PY
echo OPENCI_SHOREBIRD_BUILD_VERIFIED
