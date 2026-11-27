#!/usr/bin/env bash
set -euo pipefail

# Limit Gradle and Kotlin to the Linux Large VM's 8 GiB.
gradle_home=${GRADLE_USER_HOME:-"$HOME/.gradle"}
mkdir -p "$gradle_home"
cat >> "$gradle_home/gradle.properties" <<'PROPERTIES'

org.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m -Dfile.encoding=UTF-8
org.gradle.workers.max=2
kotlin.compiler.execution.strategy=in-process
PROPERTIES

if command -v shorebird >/dev/null; then
  exit 0
fi

toolchain="$(dirname "$0")/../../infra/macos-image/released/toolchain.json"
revision=$(python3 -c 'import json, sys; print(json.load(sys.stdin)["shorebird_cli_revision"])' < "$toolchain")
install_dir=$(mktemp -d "${TMPDIR:-/tmp}/openci-shorebird.XXXXXX")
git -C "$install_dir" init --quiet
git -C "$install_dir" remote add origin https://github.com/shorebirdtech/shorebird.git
git -C "$install_dir" fetch --quiet --depth=1 origin "$revision"
git -C "$install_dir" checkout --quiet --detach "$revision"

mkdir -p "$HOME/.pub-cache/bin"
ln -s "$install_dir/bin/shorebird" "$HOME/.pub-cache/bin/shorebird"
