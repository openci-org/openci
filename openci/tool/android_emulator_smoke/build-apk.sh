#!/usr/bin/env bash
set -euo pipefail

output=${1:?pass the destination APK path}
source_dir=$(cd "$(dirname "$0")" && pwd)
sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/opt/android-sdk}}
build_tools="$sdk/build-tools/35.0.0"
android_jar="$sdk/platforms/android-35/android.jar"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

mkdir "$work/classes" "$work/dex"
javac --release 8 -cp "$android_jar" -d "$work/classes" \
  "$source_dir/SmokeActivity.java" "$source_dir/SmokeInstrumentation.java"
"$build_tools/d8" --min-api 29 --lib "$android_jar" --output "$work/dex" \
  "$work/classes/org/openci/workersmoke/"*.class
"$build_tools/aapt2" link -I "$android_jar" --manifest "$source_dir/AndroidManifest.xml" \
  -o "$work/unsigned.apk"
zip -q -j "$work/unsigned.apk" "$work/dex/classes.dex"
"$build_tools/zipalign" -f 4 "$work/unsigned.apk" "$work/aligned.apk"

# Each disposable emulator gets a fresh test key.
keytool -genkeypair -alias smoke -keystore "$work/demo.p12" -storetype PKCS12 \
  -storepass android -keypass android -dname 'CN=OpenCI disposable E2E' \
  -keyalg RSA -keysize 2048 -validity 1 >/dev/null
"$build_tools/apksigner" sign --ks "$work/demo.p12" --ks-pass pass:android \
  --out "$output" "$work/aligned.apk"
