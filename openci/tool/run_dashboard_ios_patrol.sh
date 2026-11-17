#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$script_dir/../../apps/dashboard"

simulator_id=''
cleanup() {
  local result=$?
  trap - EXIT
  if [[ -n "$simulator_id" ]]; then
    xcrun simctl shutdown "$simulator_id" >/dev/null 2>&1 || true
    if xcrun simctl delete "$simulator_id"; then
      printf 'Deleted Patrol simulator %s\n' "$simulator_id"
    elif [[ "$result" -eq 0 ]]; then
      result=1
    fi
  fi
  exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

runtime_id=$(xcrun simctl list runtimes --json | python3 -c '
import json
import sys

runtimes = [
    runtime for runtime in json.load(sys.stdin)["runtimes"]
    if runtime.get("isAvailable")
    and runtime["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
    and int(runtime["version"].split(".")[0]) >= 26
]
if not runtimes:
    sys.exit("No available iOS 26 or later simulator runtime found.")
latest = max(runtimes, key=lambda runtime: tuple(map(int, runtime["version"].split("."))))
print(latest["identifier"])
')

simulator_id=$(xcrun simctl create 'OpenCI Dashboard Patrol' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro "$runtime_id")
printf 'Created Patrol simulator %s with %s\n' "$simulator_id" "$runtime_id"
xcrun simctl boot "$simulator_id"
python3 - "$simulator_id" <<'PY'
import subprocess
import sys

try:
    subprocess.run(
        ["xcrun", "simctl", "bootstatus", sys.argv[1], "-b"],
        check=True,
        timeout=600,
    )
except subprocess.TimeoutExpired:
    sys.exit("Patrol simulator did not finish booting within 10 minutes.")
PY

dart run patrol_cli:main test \
  --target patrol_test/app_startup_test.dart \
  --device "$simulator_id"
