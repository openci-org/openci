#!/bin/bash
set -euo pipefail

python=/usr/bin/python3
config=/usr/local/share/openci-image/toolchain.json
value() { "$python" -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$config" "$1"; }
[[ $(uname -m) == arm64 && $(id -un) == admin && $HOME == /Users/admin && $(sysctl -n hw.model) == VirtualMac* ]]
[[ $(sw_vers -productVersion) == "$(value macos_version)" ]]
[[ $(xcodebuild -version) == "$(printf 'Xcode %s\nBuild version %s' "$(value xcode_version)" "$(value xcode_build)")" ]]
sudo -n true

work=$(mktemp -d /tmp/openci-image-provision.XXXXXX)
trap 'rm -rf "$work"' EXIT
install_pkg() {
  local url=$1 checksum=$2
  curl --fail --location --retry 3 --proto '=https' --proto-redir '=https' "$url" -o "$work/package.pkg"
  printf '%s  %s\n' "$checksum" "$work/package.pkg" | shasum -a 256 -c -
  sudo -n installer -pkg "$work/package.pkg" -target /
  rm "$work/package.pkg"
}

# Bootstrap FVM with Cirrus's Flutter. All later steps use fvm/default.
export PATH="$PATH:$HOME/flutter/bin"
export FVM_CACHE_PATH="$HOME/fvm"
if [[ $(fvm --version 2>/dev/null || true) != "$(value fvm_version)" ]]; then
  dart pub global activate fvm "$(value fvm_version)"
fi
fvm install "$(value flutter_version)"
fvm global "$(value flutter_version)"
flutter config --no-analytics
dart --disable-analytics
flutter precache --android --ios --macos
dart pub global activate fvm "$(value fvm_version)"

# The source supplies mise; an explicit Python version avoids a brew upgrade.
mise install "python@$(value python_version)"
python="$(mise where "python@$(value python_version)")/bin/python3"

if [[ $(/usr/local/go/bin/go version 2>/dev/null || true) != "go version go$(value go_version) darwin/arm64" ]]; then
  install_pkg "$(value go_pkg_url)" "$(value go_pkg_sha256)"
fi
sudo -n mkdir -p /usr/local/bin
sudo -n ln -sfn /usr/local/go/bin/go /usr/local/bin/go
sudo -n ln -sfn /usr/local/go/bin/gofmt /usr/local/bin/gofmt

java_home=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
if ! "$java_home/bin/java" -version 2>&1 | grep -Fq "$(value java_runtime_version)"; then
  install_pkg "$(value java_pkg_url)" "$(value java_pkg_sha256)"
fi
export JAVA_HOME=$java_home
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT=$ANDROID_HOME
if [[ ! -d "$ANDROID_HOME" ]]; then
  test -d "$HOME/android-sdk"
  mkdir -p "$HOME/Library/Android"
  ln -s "$HOME/android-sdk" "$ANDROID_HOME"
fi
sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
while IFS= read -r package; do
  package_path=$(tr ';' '/' <<< "$package")
  if [[ ! -f "$ANDROID_HOME/$package_path/package.xml" ]]; then
    "$sdkmanager" "$package" </dev/null
  fi
done < <("$python" -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["android_packages"]))' "$config")
flutter config --android-sdk "$ANDROID_HOME" --jdk-dir "$JAVA_HOME"

shorebird="$HOME/.shorebird"
commit=$(value shorebird_commit)
if [[ $(git -C "$shorebird" rev-parse HEAD 2>/dev/null || true) != "$commit" ]]; then
  if [[ ! -d "$shorebird/.git" ]]; then
    git clone --no-checkout https://github.com/shorebirdtech/shorebird.git "$shorebird"
  fi
  git -C "$shorebird" remote set-url origin https://github.com/shorebirdtech/shorebird.git
  git -C "$shorebird" fetch --depth=1 origin "$commit"
  git -C "$shorebird" checkout --detach "$commit"
fi
sudo -n ln -sfn "$shorebird/bin/shorebird" /usr/local/bin/shorebird
shorebird --version

codemagic="/opt/codemagic-cli-tools/$(value codemagic_version)"
if [[ ! -x "$codemagic/bin/python" ]]; then
  sudo -n mkdir -p "$codemagic"
  sudo -n chown admin:staff "$codemagic"
  "$python" -m venv "$codemagic"
  "$codemagic/bin/python" -m pip install "codemagic-cli-tools==$(value codemagic_version)"
fi
for tool in app-store-connect keychain xcode-project google-play; do
  test -x "$codemagic/bin/$tool"
  sudo -n ln -sfn "$codemagic/bin/$tool" "/usr/local/bin/$tool"
done
"$codemagic/bin/python" -m pip freeze > /usr/local/share/openci-image/python-packages.txt

# Executor starts a non-login bash. Put CLIs it calls on that exact PATH.
sudo -n ln -sfn "$java_home/bin/java" /usr/local/bin/java
sudo -n ln -sfn "$java_home/bin/javac" /usr/local/bin/javac
sudo -n ln -sfn "$sdkmanager" /usr/local/bin/sdkmanager
sudo -n ln -sfn "$ANDROID_HOME/platform-tools/adb" /usr/local/bin/adb

# Cirrus configures Ruby in .zprofile; Orchard does not start a login shell.
rbenv rehash
for tool in ruby gem bundle pod fastlane; do
  test -x "$HOME/.rbenv/shims/$tool"
  sudo -n ln -sfn "$HOME/.rbenv/shims/$tool" "/usr/local/bin/$tool"
done
for tool in node npm npx; do
  test -x "/opt/homebrew/opt/node@24/bin/$tool"
  sudo -n ln -sfn "/opt/homebrew/opt/node@24/bin/$tool" "/usr/local/bin/$tool"
done
