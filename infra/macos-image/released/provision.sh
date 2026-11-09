#!/bin/bash
set -euo pipefail
config=/usr/local/share/openci-image/toolchain.json
value() { /usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$config" "$1"; }
inputs="/Volumes/My Shared Files/installers"
work=$(mktemp -d /private/tmp/openci-release.XXXXXX)
trap 'rm -rf "$work"' EXIT
[[ $(sysctl -n hw.model) == VirtualMac* && $(id -un) == admin ]]
[[ $(sw_vers -buildVersion) == "$(value macos_build)" ]]
[[ $(xcodebuild -version) == "$(printf 'Xcode %s\nBuild version %s' "$(value xcode_version)" "$(value xcode_build)")" ]]
test -f "$inputs/temurin@17.rb"
sudo -n true
export HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ENV_HINTS=1

echo "Installing iOS simulator runtime"
if ! xcrun simctl list runtimes | grep -Fq "$(value ios_runtime_build)"; then
  if [[ -f "$inputs/iOS-26.5-23F73.dmg" ]]; then
    xcrun simctl runtime add "$inputs/iOS-26.5-23F73.dmg" ||
      xcodebuild -downloadPlatform iOS -buildVersion 26.5 -architectureVariant arm64
  else
    xcodebuild -downloadPlatform iOS -buildVersion 26.5 -architectureVariant arm64
  fi
fi
xcrun simctl list runtimes

echo "Installing Python 3.13 and its bottle dependencies"
installed_formulae=$(brew list --formula --versions)
for item in 'mpdecimal 4.0.1' 'xz 5.8.4' 'python@3.13 3.13.15'; do
  if grep -Fxq "$item" <<< "$installed_formulae"; then continue; fi
  formula=${item%% *}
  bottles=("$inputs/$formula"--*.bottle*.tar.gz)
  # Homebrew 6 permits explicit local bottles in developer mode. Each bottle
  # checksum is verified before boot and its pinned dependencies are present.
  HOMEBREW_DEVELOPER=1 brew install --formula --ignore-dependencies "${bottles[0]}"
done

echo "Installing Android Studio and Temurin from the historical Homebrew casks"
installed_casks=$(brew list --cask --versions)
for row in 'android-studio 2026.1.4.8,quail4-patch1 android-studio-2026.1.4.8.dmg' 'temurin@17 17.0.20,8 OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.20_8.pkg'; do
  read -r cask version archive <<< "$row"
  if grep -Fxq "$cask $version" <<< "$installed_casks"; then continue; fi
  tap="$(brew --repository)/Library/Taps/openci/homebrew-image"
  if [[ ! -d "$tap/.git" ]]; then
    mkdir -p "$tap/Casks"
    cp "$inputs/android-studio.rb" "$inputs/temurin@17.rb" "$tap/Casks/"
    git init -q "$tap"
    git -C "$tap" add Casks
    git -C "$tap" -c user.name=OpenCI -c user.email=image@localhost commit -qm "Pin Android Studio and Temurin installers"
    if brew command trust >/dev/null 2>&1; then brew trust openci/image; fi
  fi
  cache=$(brew --cache --cask "openci/image/$cask")
  mkdir -p "$(dirname "$cache")"
  cp "$inputs/$archive" "$cache"
  brew install --cask "openci/image/$cask"
done

echo "Installing Go"
if [[ $(/usr/local/go/bin/go version 2>/dev/null || true) != 'go version go1.27.3 darwin/arm64' ]]; then
  sudo -n installer -pkg "$inputs/go1.27.3.darwin-arm64.pkg" -target /
fi
sudo -n mkdir -p /usr/local/bin
for tool in go gofmt; do sudo -n ln -sfn "/usr/local/go/bin/$tool" "/usr/local/bin/$tool"; done

echo "Installing the Android SDK"
export ANDROID_HOME="$HOME/Library/Android/sdk" ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
mkdir -p "$ANDROID_HOME/cmdline-tools"
if ! grep -Fxq 'Pkg.Revision=22.0' "$ANDROID_HOME/cmdline-tools/latest/source.properties" 2>/dev/null; then
  ditto -x -k "$inputs/commandlinetools-mac_arm64-15859902_latest.zip" "$work/android"
  if [[ -e "$ANDROID_HOME/cmdline-tools/latest" ]]; then mv "$ANDROID_HOME/cmdline-tools/latest" "$work/previous-cmdline-tools"; fi
  mv "$work/android/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi
if ! grep -Fxq 'Pkg.Revision=37.0.1' "$ANDROID_HOME/platform-tools/source.properties" 2>/dev/null; then
  if [[ -e "$ANDROID_HOME/platform-tools" ]]; then mv "$ANDROID_HOME/platform-tools" "$work/previous-platform-tools"; fi
  ditto -x -k "$inputs/platform-tools_r37.0.1-darwin.zip" "$ANDROID_HOME"
fi
sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
missing=()
while IFS= read -r package; do
  package_path=$(tr ';' '/' <<< "$package")
  if [[ ! -f "$ANDROID_HOME/$package_path/package.xml" ]]; then missing+=("$package"); fi
done < <(/usr/bin/python3 -c 'import json,sys;print("\n".join(json.load(open(sys.argv[1]))["android_packages"]))' "$config")
if [[ ${#missing[@]} -gt 0 ]]; then
  "$sdkmanager" --sdk_root="$ANDROID_HOME" --licenses < <(yes)
  "$sdkmanager" --sdk_root="$ANDROID_HOME" "${missing[@]}" </dev/null
fi

echo "Installing Codemagic and xcodeproj"
codemagic=/opt/codemagic-cli-tools/0.69.1
requirements=/usr/local/share/openci-image/codemagic-requirements.txt
if [[ $("$codemagic/bin/python" --version 2>/dev/null || true) != 'Python 3.13.15' ]]; then
  if [[ -e "$codemagic" ]]; then sudo -n mv "$codemagic" "$work/previous-codemagic"; fi
  sudo -n mkdir -p "$codemagic"
  sudo -n chown admin:staff "$codemagic"
  /opt/homebrew/bin/python3.13 -m venv "$codemagic"
fi
if ! diff -q <("$codemagic/bin/python" -m pip freeze | LC_ALL=C sort) <(LC_ALL=C sort "$requirements") >/dev/null; then
  "$codemagic/bin/python" -m pip install -r "$requirements"
fi
for tool in android-app-bundle android-keystore app-store-connect codemagic-cli-tools firebase-app-distribution git-changelog google-play keychain universal-apk xcode-project; do
  test -x "$codemagic/bin/$tool"
  sudo -n ln -sfn "$codemagic/bin/$tool" "/usr/local/bin/$tool"
done
gem install --conservative --user-install --no-document --ignore-dependencies atomos:0.1.3 CFPropertyList:2.3.6 claide:1.1.0 colored2:3.1.2 nanaimo:0.4.0 rexml:3.4.2 xcodeproj:1.27.0
sudo -n ln -sfn "$HOME/.gem/ruby/2.6.0/bin/xcodeproj" /usr/local/bin/xcodeproj

echo "Installing the release's standard Flutter SDK"
export FVM_CACHE_PATH="$HOME/fvm"
fvm install "$(value flutter_version)" --skip-pub-get
fvm global "$(value flutter_version)"
flutter config --no-analytics --android-sdk "$ANDROID_HOME" --jdk-dir "$JAVA_HOME"
flutter precache --android --ios --macos

echo "Installing Shorebird and both of its Flutter revisions"
root="$HOME/.shorebird"
if [[ ! -d "$root/.git" ]]; then
  git clone --filter=blob:none https://github.com/shorebirdtech/shorebird.git "$root"
fi
if [[ $(git -C "$root" rev-parse HEAD) != "$(value shorebird_cli_revision)" ]]; then
  git -C "$root" fetch https://github.com/shorebirdtech/shorebird.git "$(value shorebird_cli_revision)"
  git -C "$root" checkout --detach "$(value shorebird_cli_revision)"
fi
sudo -n ln -sfn "$root/bin/shorebird" /usr/local/bin/shorebird
shorebird --version
revision=$(value shorebird_flutter_revision)
sdk="$root/bin/cache/flutter/$revision"
if [[ ! -d "$sdk/.git" ]]; then
  git clone --filter=tree:0 --no-checkout https://github.com/shorebirdtech/flutter.git "$sdk"
  git -C "$sdk" checkout --detach "$revision"
fi
[[ $(git -C "$sdk" rev-parse HEAD) == "$revision" ]]
[[ $(cat "$sdk/bin/internal/engine.version") == "$(value shorebird_engine_revision)" ]]
export FLUTTER_STORAGE_BASE_URL=https://download.shorebird.dev
"$sdk/bin/flutter" precache --android --ios
test -d "$sdk/bin/cache/artifacts/engine/android-arm64-release"
test -d "$sdk/bin/cache/artifacts/engine/ios-release"
touch "$sdk/.shorebird_precache"
