#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd "$(dirname "$0")" && pwd)
sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/opt/android-sdk}}
adb="$sdk/platform-tools/adb"
emulator="$sdk/emulator/emulator"
serial='emulator-5554'
work=$(mktemp -d)
emulator_pid=

cleanup() {
  if [[ -n "$emulator_pid" ]] && kill -0 "$emulator_pid" 2>/dev/null; then
    kill "$emulator_pid" 2>/dev/null || true
    for _ in {1..10}; do
      kill -0 "$emulator_pid" 2>/dev/null || break
      sleep 1
    done
    kill -KILL "$emulator_pid" 2>/dev/null || true
    wait "$emulator_pid" 2>/dev/null || true
  fi
  rm -rf -- "$work"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

device() { timeout 20 "$adb" -s "$serial" "$@" </dev/null; }

if [[ ! -c /dev/kvm || ! -r /dev/kvm || ! -w /dev/kvm ]]; then
  echo "The Linux guest needs read/write access to /dev/kvm" >&2
  exit 1
fi
"$emulator" -accel-check
"$emulator" -list-avds | grep -Fx openci-api35
timeout 30 "$adb" start-server
if "$adb" devices | awk -v serial="$serial" '$1 == serial {found = 1} END {exit !found}'; then
  echo "$serial is already in use" >&2
  exit 1
fi

"$emulator" -avd openci-api35 -port 5554 -no-window -no-audio -no-boot-anim \
  -no-snapshot -data "$work/userdata.img" -gpu swiftshader -accel on -cores 2 -memory 2048 \
  </dev/null >"$work/emulator.log" 2>&1 &
emulator_pid=$!
bash "$source_dir/build-apk.sh" "$work/smoke.apk"

until [[ "$(device shell -n getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)" == 1 ]]; do
  if ! kill -0 "$emulator_pid" 2>/dev/null || (( SECONDS >= 420 )); then
    tail -30 "$work/emulator.log" >&2
    exit 1
  fi
  sleep 3
done
api_level=$(device shell -n getprop ro.build.version.sdk | tr -d '\r')
abi=$(device shell -n getprop ro.product.cpu.abi | tr -d '\r')
if [[ "$api_level" != 35 || "$abi" != x86_64 ]]; then
  echo "Expected API 35 x86_64, got API $api_level $abi" >&2
  exit 1
fi
for setting in window_animation_scale transition_animation_scale animator_duration_scale; do
  device shell -n settings put global "$setting" 0
done
device shell -n wm size 720x1280
device shell -n svc power stayon true
device shell -n input keyevent KEYCODE_WAKEUP
device shell -n wm dismiss-keyguard
device install --no-streaming -r "$work/smoke.apk"
timeout 90 "$adb" -s "$serial" shell -n am instrument -w -r \
  org.openci.workersmoke/.SmokeInstrumentation | tr -d '\r' | tee "$work/result.log"
grep -Fxq 'INSTRUMENTATION_RESULT: openci=BUTTON_TAPPED' "$work/result.log"
grep -Fxq 'INSTRUMENTATION_CODE: -1' "$work/result.log"
printf 'Android E2E PASS API=%s ABI=%s button=tapped elapsed=%ss\n' \
  "$api_level" "$abi" "$SECONDS"
